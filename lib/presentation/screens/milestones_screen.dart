import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trt_tracker/logic/providers.dart';
import '../../logic/trt_milestones.dart';

class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final injections = ref.watch(injectionListProvider).value ?? [];

    // --- 1. Startdatum Berechnung ---
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

    final today = DateTime.now();
    final daysPassed = today.difference(startDate).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Deine Journey"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // HIER IST DER FIX: SafeArea sorgt dafür, dass System-Ränder respektiert werden
      body: SafeArea(
        child: ListView.builder(
          // HIER IST DER FIX: Extra viel Platz unten (bottom: 100), 
          // damit der letzte Punkt frei schwebt und nicht am Rand klebt.
          padding: const EdgeInsets.only(
            left: 24, 
            right: 24, 
            top: 24, 
            bottom: 100
          ),
          itemCount: TRTEffectsLogic.allMilestones.length,
          itemBuilder: (context, index) {
            final milestone = TRTEffectsLogic.allMilestones[index];

            // --- LOGIK FÜR DARSTELLUNG ---

            // 1. Datum dieses Meilensteins
            final milestoneDate = startDate.add(
              Duration(days: milestone.startsAtDay),
            );
            final dateString = DateFormat(
              'd. MMM yyyy',
              'de_DE',
            ).format(milestoneDate);

            // 2. Status
            final bool isPast = daysPassed >= milestone.startsAtDay;
            final currentActive = TRTEffectsLogic.getCurrentMilestone(daysPassed);
            final bool isCurrent = currentActive == milestone;

            // --- LOGIK FÜR BALKEN-FÜLLUNG ---

            // A) Linie OBEN
            double topLineFill = 0.0;
            if (index > 0) {
              final prevMilestone = TRTEffectsLogic.allMilestones[index - 1];
              final phaseLength =
                  milestone.startsAtDay - prevMilestone.startsAtDay;
              final daysIntoPhase = daysPassed - prevMilestone.startsAtDay;

              double phaseProgress = (daysIntoPhase / phaseLength).clamp(
                0.0,
                1.0,
              );
              topLineFill = ((phaseProgress - 0.5) / 0.5).clamp(0.0, 1.0);
            }

            // B) Linie UNTEN
            double bottomLineFill = 0.0;
            if (index < TRTEffectsLogic.allMilestones.length - 1) {
              final nextMilestone = TRTEffectsLogic.allMilestones[index + 1];

              final phaseLength =
                  nextMilestone.startsAtDay - milestone.startsAtDay;
              final daysIntoPhase = daysPassed - milestone.startsAtDay;

              double phaseProgress = (daysIntoPhase / phaseLength).clamp(
                0.0,
                1.0,
              );
              bottomLineFill = (phaseProgress / 0.5).clamp(0.0, 1.0);
            }

            if (isPast && index < TRTEffectsLogic.allMilestones.length - 1) {
              if (daysPassed >=
                  TRTEffectsLogic.allMilestones[index + 1].startsAtDay) {
                bottomLineFill = 1.0;
              }
            }
            if (isPast) {
              topLineFill = 1.0;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TIMELINE STRANG (Links)
                  Column(
                    children: [
                      // --- LINIE OBEN ---
                      Expanded(
                        child:
                            index == 0
                                ? const SizedBox(width: 2)
                                : Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [
                                        0.0,
                                        topLineFill,
                                        topLineFill,
                                        1.0,
                                      ],
                                      colors: const [
                                        Color(0xFF64FFDA),
                                        Color(0xFF64FFDA),
                                        Colors.white12,
                                        Colors.white12,
                                      ],
                                    ),
                                  ),
                                ),
                      ),

                      // --- DER PUNKT ---
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              isCurrent
                                  ? const Color(0xFF64FFDA).withOpacity(0.2)
                                  : (isPast
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isPast
                                    ? const Color(0xFF64FFDA)
                                    : Colors.white24,
                            width: 2,
                          ),
                          boxShadow:
                              isCurrent
                                  ? [
                                    const BoxShadow(
                                      color: Color(0xFF64FFDA),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Center(
                          child:
                              isPast
                                  ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF64FFDA),
                                  )
                                  : Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                        ),
                      ),

                      // --- LINIE UNTEN ---
                      Expanded(
                        child:
                            index == TRTEffectsLogic.allMilestones.length - 1
                                ? const SizedBox(width: 2)
                                : Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [
                                        0.0,
                                        bottomLineFill,
                                        bottomLineFill,
                                        1.0,
                                      ],
                                      colors: const [
                                        Color(0xFF64FFDA),
                                        Color(0xFF64FFDA),
                                        Colors.white12,
                                        Colors.white12,
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // 2. CARD INHALT (Rechts)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                milestone.iconEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  milestone.title,
                                  style: TextStyle(
                                    color:
                                        isPast ? Colors.white : Colors.white54,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isCurrent
                                      ? const Color(0xFF64FFDA)
                                      : Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPast
                                  ? (isCurrent
                                      ? "Aktuell seit $dateString"
                                      : "Erreicht: $dateString")
                                  : "Erwartet: $dateString",
                              style: TextStyle(
                                color:
                                    isCurrent ? Colors.black : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            milestone.description,
                            style: TextStyle(
                              color: isPast ? Colors.white70 : Colors.white38,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}