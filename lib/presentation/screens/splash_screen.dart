import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trt_tracker/presentation/widgets/particle_background.dart';
import '../../logic/providers.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animation Setup (Pulsieren)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 2. Start Logik
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // A: Mindest-Wartezeit für den "Coolness-Faktor" (Logo Animation)
    final minWait = Future.delayed(
      const Duration(seconds: 2, milliseconds: 500),
    );

    // B: Daten laden (Parallel)
    // Wir warten auf das UserProfile. .future erzwingt das Laden.
    try {
      final userProfile = await ref.read(userProfileProvider.future);

      // Wir warten, bis BEIDES fertig ist (Daten & Animation)
      await minWait;

      if (!mounted) return;

      // C: Entscheidung & Navigation
      // Check: Hat der User ein Gewicht angegeben? (Indikator für abgeschlossenes Onboarding)
      if (userProfile.weight > 0) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      // Fallback bei Fehler (z.B. DB noch nicht bereit) -> Onboarding
      await minWait;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Hintergrund
          const ParticleBackground(),

          // 2. Logo & Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animiertes Icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF64FFDA,
                          ).withOpacity(0.1 * _fadeAnimation.value),
                          border: Border.all(
                            color: const Color(0xFF64FFDA).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF64FFDA).withOpacity(0.2),
                              blurRadius: 20 * _scaleAnimation.value,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.water_drop, // Oder Icons.science
                          size: 60,
                          color: const Color(
                            0xFF64FFDA,
                          ).withOpacity(_fadeAnimation.value),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // App Name
                const Text(
                  "TRT TRACKER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Optimize your Life",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // 3. Lade-Indikator unten (ganz dezent)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
