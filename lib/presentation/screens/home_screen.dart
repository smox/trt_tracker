import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

import 'package:trt_tracker/logic/ui_logic.dart';
import 'package:trt_tracker/presentation/screens/calendar_screen.dart';
import 'package:trt_tracker/presentation/screens/plans_screen.dart';
import 'package:trt_tracker/presentation/screens/settings_screen.dart';
import 'package:trt_tracker/presentation/widgets/particle_background.dart';
import '../../logic/providers.dart';
import '../../data/models/enums.dart';
import 'add_injection_screen.dart';
import 'analytics_screen.dart';
import '../../logic/trt_milestones.dart';
import 'milestones_screen.dart';
import '../../logic/calculator.dart';
// NEU: Import für Notification Service, falls wir ihn hier direkt bräuchten (aktuell nicht zwingend, aber gut zu haben)
import '../../logic/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Notification Permission Check beim Start (leicht verzögert)
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService().requestPermissions();
    });

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 2.0, end: 15.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      ref.invalidate(currentLevelProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentLevelProvider);
      ref.invalidate(injectionListProvider);
    }
  }

  void _onGaugeTap() {
    final hapticsEnabled = ref.read(hapticFeedbackProvider);
    if (hapticsEnabled) HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  String _formatUnit(String? unitEnumString) {
    if (unitEnumString == null) return 'ng/mL';
    String clean = unitEnumString.split('.').last;
    if (clean == 'ng_dl') return 'ng/dL';
    if (clean == 'nmol_l') return 'nmol/L';
    return 'ng/mL';
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = ref.watch(currentLevelProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.value;
    final injections = ref.watch(injectionListProvider).value ?? [];

    final userName = userProfile?.name ?? "User";
    final unitLabel = _formatUnit(userProfile?.preferredUnit.toString());

    // HIER: Deutsches Datumsformat erzwingen, falls System-Locale noch spinnt
    final dateString = DateFormat(
      'EEE, d. MMM',
      'de_DE',
    ).format(DateTime.now());

    DateTime startDate;
    if (injections.isNotEmpty) {
      final oldestInjection = injections.reduce(
        (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
      );
      startDate = oldestInjection.timestamp;
    } else {
      final startMillis =
          userProfile?.therapyStart ?? DateTime.now().millisecondsSinceEpoch;
      startDate = DateTime.fromMillisecondsSinceEpoch(startMillis);
    }
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final milestone = TRTEffectsLogic.getCurrentMilestone(daysPassed);

    final unit = userProfile?.preferredUnit ?? MassUnit.ng_dl;
    double normalizedForColor = TestosteroneCalculator.normalizeToNgDl(
      currentLevel,
      unit,
    );
    final dynamicColor = TRTColors.getColorForLevel(normalizedForColor);
    final statusText = TRTColors.getStatusText(normalizedForColor);
    String displayString = currentLevel.toStringAsFixed(2);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            // Offline Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateString,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  "Hi, $userName",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // FIX: SETTINGS BUTTON WIEDER OBEN RECHTS
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 50.0,
          right: 10.0,
        ), // Schiebt den Button über die Nav-Bar
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddInjectionScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF64FFDA),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          const ParticleBackground(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  // GAUGE
                  GestureDetector(
                    onTap: _onGaugeTap,
                    child: AnimatedBuilder(
                      animation: _breathingController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: CustomPaint(
                            painter: GaugePainter(
                              color: dynamicColor,
                              glowRadius: _glowAnimation.value,
                            ),
                            child: Container(
                              width: 280,
                              height: 280,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayString,
                                    style: const TextStyle(
                                      fontSize: 54,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    unitLabel,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: dynamicColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // MILESTONE
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MilestonesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                milestone.iconEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Tag $daysPassed: ${milestone.title}",
                                style: const TextStyle(
                                  color: Color(0xFF64FFDA),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            milestone.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // BOTTOM NAV (3 ICONS: Home, Kalender, Pläne)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Home (Aktiv)
                      Icon(Icons.home_filled, color: dynamicColor, size: 30),

                      // 2. Kalender
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 26,
                        ),
                        color: Colors.grey,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        ),
                      ),

                      // 3. Pläne
                      IconButton(
                        icon: const Icon(Icons.fact_check_outlined, size: 26),
                        color: Colors.grey,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlansScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final Color color;
  final double glowRadius;
  GaugePainter({required this.color, required this.glowRadius});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    const startAngle = 135 * 3.14159 / 180;
    const sweepAngle = 270 * 3.14159 / 180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      tileMode: TileMode.repeated,
      colors: [color.withOpacity(0.5), color],
      transform: GradientRotation(startAngle - 0.1),
    );
    final valuePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowRadius != glowRadius;
}
