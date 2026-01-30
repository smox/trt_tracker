class TRTMilestone {
  final int startsAtDay;
  final String title;
  final String description;
  final String iconEmoji;

  const TRTMilestone({
    required this.startsAtDay,
    required this.title,
    required this.description,
    required this.iconEmoji,
  });
}

class TRTEffectsLogic {
  // Basierend auf: Saad F, Aversa A, Isidori AM, et al.
  // "Onset of effects of testosterone treatment..." (European Journal of Endocrinology, 2011)
  static const List<TRTMilestone> allMilestones = [
    TRTMilestone(
      startsAtDay: 0,
      title: "Vorbereitung & Start",
      description:
          "Der Beginn deiner Reise. Du hast die Entscheidung getroffen, dein Leben zu optimieren.",
      iconEmoji: "🏁",
    ),
    TRTMilestone(
      startsAtDay: 3,
      title: "Serum-Anstieg",
      description:
          "Das Testosteron flutet an. Der Spiegel im Blut steigt rapide. Erste innere Unruhe oder gesteigerter Antrieb sind möglich.",
      iconEmoji: "📈",
    ),
    TRTMilestone(
      startsAtDay: 10, // ~1.5 Wochen
      title: "Insulin & Vitalität",
      // TEXT ANGEPASST: "Nach wenigen Tagen" entfernt, stattdessen Fokus auf den laufenden Prozess.
      description:
          "Der Stoffwechsel beginnt sich anzupassen. Die Insulinsensitivität verbessert sich schrittweise, was oft schon jetzt für mehr Tagesenergie sorgt.",
      iconEmoji: "🔋",
    ),
    TRTMilestone(
      startsAtDay: 21, // Woche 3 (Zitzmann: Onset of libido)
      title: "Libido-Erwachen",
      description:
          "Klassischer Zeitpunkt für erste Effekte auf die Libido, sexuelle Gedanken und morgendliche Erektionen.",
      iconEmoji: "❤️‍🔥",
    ),
    TRTMilestone(
      startsAtDay: 42, // Woche 6 (Zitzmann: Depression/Mood onset 3-6 weeks)
      title: "Mentale Balance",
      description:
          "Stimmungsaufhellende Effekte setzen ein. Depressive Verstimmungen und 'Brain Fog' nehmen spürbar ab.",
      iconEmoji: "☀️",
    ),
    TRTMilestone(
      startsAtDay: 60, // Monat 2
      title: "Glykogen & Volumen",
      description:
          "Noch kein reiner Muskelzuwachs, aber die Muskeln speichern mehr Wasser und Glykogen. Sie wirken praller ('Pump').",
      iconEmoji: "💧",
    ),
    TRTMilestone(
      startsAtDay: 90, // Monat 3 (Zitzmann: Erythropoiesis starts)
      title: "Blutbild & Ausdauer",
      description:
          "Die Bildung roter Blutkörperchen (Erythropoiese) nimmt zu. Bessere Sauerstoffversorgung kann die Ausdauer steigern.",
      iconEmoji: "🩸",
    ),
    TRTMilestone(
      startsAtDay:
          112, // Woche 16 / Monat 4 (Zitzmann: Anabolic effects start 12-16 weeks)
      title: "Physische Transformation",
      description:
          "Jetzt beginnt der echte anabole Effekt: Signifikante Zunahme der fettfreien Körpermasse und Kraft, sofern Training erfolgt.",
      iconEmoji: "💪",
    ),
    TRTMilestone(
      startsAtDay: 180, // Monat 6 (Zitzmann: Bone density starts)
      title: "Knochen & Struktur",
      description:
          "Die Knochendichte beginnt messbar zu steigen. Der Körperfettanteil reduziert sich weiter stetig.",
      iconEmoji: "🦴",
    ),
    TRTMilestone(
      startsAtDay: 270, // Monat 9
      title: "Maximale Libido",
      description:
          "Die Verbesserungen der erektilen Funktion und Libido erreichen oft jetzt erst ihr absolutes Plateau.",
      iconEmoji: "🚀",
    ),
    TRTMilestone(
      startsAtDay: 365, // 1 Jahr (Zitzmann: Insulin/Lipid max effects)
      title: "Metabolische Balance",
      description:
          "Blutfettwerte (Lipide) und Blutzuckerwerte haben sich auf dem neuen Niveau stabilisiert und eingependelt.",
      iconEmoji: "⚖️",
    ),
    TRTMilestone(
      startsAtDay: 730, // 2 Jahre
      title: "Langzeit-Plateau",
      description:
          "Alle Parameter sind stabil. Fokus liegt nun auf dem Erhalt der Lebensqualität (Maintenance).",
      iconEmoji: "🏆",
    ),
  ];

  static TRTMilestone getCurrentMilestone(int daysPassed) {
    TRTMilestone current = allMilestones.first;
    for (var m in allMilestones) {
      if (daysPassed >= m.startsAtDay) {
        current = m;
      } else {
        break;
      }
    }
    return current;
  }
}
