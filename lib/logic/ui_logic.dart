import 'package:flutter/material.dart';

// --- FARB LOGIK ---
class TRTColors {
  // Deine definierte Palette
  static const Color low = Color(0xFFFF3B30); // Rot (Kritisch)
  static const Color lowNormal = Color(0xFFFF9500); // Orange (Warnung)
  static const Color normal = Color(0xFF34C759); // Grün (Optimal)
  static const Color highNormal = Color(0xFF64FFDA); // Türkis (Dein App Akzent)
  static const Color supra = Color(0xFFD946EF); // Lila (Magic/Blast)

  // Berechnet die Farbe basierend auf dem exakten Wert (Interpolation)
  static Color getColorForLevel(double value) {
    if (value < 300) {
      // 0 bis 300: Rot -> Orange
      return Color.lerp(low, lowNormal, value / 300)!;
    } else if (value < 500) {
      // 300 bis 500: Orange -> Grün
      double t = (value - 300) / (500 - 300);
      return Color.lerp(lowNormal, normal, t)!;
    } else if (value < 801) {
      // 500 bis 801: Grün -> Türkis (Normbereich)
      double t = (value - 500) / (801 - 500);
      return Color.lerp(normal, highNormal, t)!;
    } else if (value < 1100) {
      // 801 bis 1100: Türkis -> Lila (Hoch -> Supra Übergang)
      double t = (value - 801) / (1100 - 801);
      return Color.lerp(highNormal, supra, t)!;
    } else {
      // Über 1100: Bleibt Lila (evtl. heller/weißer für "Glühen")
      return supra;
    }
  }

  // Gibt den Text-Status zurück (Optional für UI)
  static String getStatusText(double value) {
    if (value < 300) return "Unterversorgung";
    if (value < 500) return "Unterer Bereich";
    if (value < 801) return "Optimaler Bereich";
    if (value < 1100) return "Oberer Bereich";
    return "Supraphysiologisch";
  }
}
