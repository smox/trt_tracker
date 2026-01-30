import 'dart:math';
import '../data/models/enums.dart';
import '../data/models/injection_model.dart';
import '../data/models/user_profile_model.dart';
import '../data/models/lab_result_model.dart';

class TestosteroneCalculator {
  // --- KONSTANTEN ---

  // Halbwertszeiten (Elimination)
  static const Map<EsterType, double> _eliminationHalfLives = {
    EsterType.propionate: 0.8,
    EsterType.enanthate: 4.5,
    EsterType.cypionate: 5.0,
    EsterType.undecanoate: 20.9,
    EsterType.sustanon: 4.0, // Vereinfacht
  };

  // NEU: Ester-Gewichtskorrektur
  // Wie viel reines Testosteron ist wirklich drin?
  // Enantat hat z.B. nur ca. 70-72% Testosteron-Anteil, der Rest ist der Ester.
  static const Map<EsterType, double> _esterWeightCorrection = {
    EsterType.propionate: 0.83, // Kurzer Ester, mehr Testo
    EsterType.enanthate: 0.72, // Dein Fall!
    EsterType.cypionate: 0.70,
    EsterType.undecanoate: 0.63, // Sehr schwerer Ester
    EsterType.sustanon: 0.72, // Mix, ca. Mittelwert
  };

  static const double _absorptionHalfLifeIM = 1.0;
  static const double _absorptionHalfLifeSubQ = 1.8;

  // Umrechnungsfaktoren
  // Wir nutzen intern jetzt ng/dL als Basis, da es die feinste Ganzzahl-Einheit ist.
  static const double _factorNmolToNgDl = 28.85;
  static const double _factorNgMlToNgDl = 100.0;

  // --- HELPER: Einheiten Normalisierung ---

  // Alles in ng/dL umwandeln (unsere neue interne Basis)
  static double normalizeToNgDl(double value, MassUnit unit) {
    switch (unit) {
      case MassUnit.ng_dl:
        return value;
      case MassUnit.ng_ml:
        return value * 100.0; // 11.28 -> 1128
      case MassUnit.nmol_l:
        return value * _factorNmolToNgDl; // 30 -> ~865
    }
  }

  // Von interner Basis (ng/dL) in Anzeige-Einheit
  static double convertFromNormalized(double valueNgDl, MassUnit targetUnit) {
    switch (targetUnit) {
      case MassUnit.ng_dl:
        return valueNgDl;
      case MassUnit.ng_ml:
        return valueNgDl / 100.0; // 1128 -> 11.28
      case MassUnit.nmol_l:
        return valueNgDl / _factorNmolToNgDl;
    }
  }

  // --- KERN-LOGIK 1: BATEMAN (RAW) ---
  // Gibt jetzt ng/dL zurück!
  double calculateRawLevelAt({
    required DateTime targetTime,
    required List<InjectionModel> injections,
    required UserProfileModel userProfile,
  }) {
    if (userProfile.weight == 0) return 0.0;

    double totalConcentrationNgDl = 0.0;

    // Verteilungsvolumen (Vd)
    // Wir nehmen an, Testosteron verteilt sich nicht im Fettgewebe (hydrophil im Serum/Muskel)
    double kfa =
        userProfile.bodyFatPercentage > 0
            ? userProfile.bodyFatPercentage
            : 0.15;
    double leanBodyMassKg = userProfile.weight * (1 - kfa);

    // Vd Korrektur: In der Literatur oft höher als reines Körpergewicht wegen Clearance.
    // Wir bleiben beim LeanBodyMass Modell, aber die Bateman-Formel skaliert das Ergebnis.
    double volumeOfDistributionL = leanBodyMassKg;

    for (var injection in injections) {
      final diff = targetTime.difference(injection.timestamp);
      double tDays = diff.inMinutes / 1440.0;

      if (tDays < 0) continue; // Injektion in der Zukunft

      double tHalf = _eliminationHalfLives[injection.ester] ?? 4.5;

      // Nach 5-6 Halbwertszeiten ist der Wirkstoff raus
      if (tDays > (tHalf * 7)) continue;

      double ke = log(2) / tHalf;
      double tHalfAbsorption =
          (injection.method == ApplicationMethod.im)
              ? _absorptionHalfLifeIM
              : _absorptionHalfLifeSubQ;
      double ka = log(2) / tHalfAbsorption;

      // NEU: Korrektur um das Ester-Gewicht!
      // 80mg Enantat -> 57.6mg Testosteron
      double esterCorrection = _esterWeightCorrection[injection.ester] ?? 0.72;
      double doseMg = injection.amountMg * esterCorrection;

      // Bateman Formel
      double exponentialPart = exp(-ke * tDays) - exp(-ka * tDays);

      // PreFactor berechnet die Konzentration in mg/L
      double preFactor = (doseMg * ka) / (volumeOfDistributionL * (ka - ke));

      // Umrechnung mg/L -> ng/dL
      // 1 mg/L = 100,000 ng/dL
      // ABER: Das ist die theoretische Volldistribution. Serumspiegel sind niedriger
      // (gebunden an SHBG/Albumin).
      // Basierend auf empirischen TRT-Daten (80mg -> ~800-1100 ng/dL Peak)
      // liefert der Faktor 1000.0 (wie vorher) zufällig die korrekte MAGNITUDE für ng/dL.
      // Wir fixieren das jetzt als "ng/dL" Output.
      double empiricalScaling = 1000.0;

      totalConcentrationNgDl += preFactor * exponentialPart * empiricalScaling;
    }
    return totalConcentrationNgDl;
  }

  // --- KERN-LOGIK 2: INTERPOLATION + ENDERGEBNIS ---
  double calculateLevelAt({
    required DateTime targetTime,
    required List<InjectionModel> injections,
    required UserProfileModel userProfile,
    required List<LabResultModel> calibrationPoints,
  }) {
    // 1. Raw Value (ng/dL)
    double raw = calculateRawLevelAt(
      targetTime: targetTime,
      injections: injections,
      userProfile: userProfile,
    );

    // 2. Faktor interpolieren
    double factor = _getInterpolatedFactor(targetTime, calibrationPoints);

    return raw * factor;
  }

  // --- KERN-LOGIK 3: FAKTOR FINDEN ---
  double _getInterpolatedFactor(DateTime time, List<LabResultModel> points) {
    if (points.isEmpty) return 1.0;

    // Wir gehen davon aus, dass 'points' sortiert ist

    // Vor dem ersten Blutbild -> Faktor vom ersten Bild
    if (time.isBefore(points.first.dateDrawn)) {
      return points.first.resultingCorrectionFactor ?? 1.0;
    }

    // Nach dem letzten -> Faktor vom letzten
    if (time.isAfter(points.last.dateDrawn)) {
      return points.last.resultingCorrectionFactor ?? 1.0;
    }

    // Dazwischen -> Interpolieren
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (time.isAfter(p1.dateDrawn) &&
          (time.isBefore(p2.dateDrawn) ||
              time.isAtSameMomentAs(p2.dateDrawn))) {
        double totalDuration =
            p2.dateDrawn.difference(p1.dateDrawn).inMilliseconds.toDouble();
        double currentDuration =
            time.difference(p1.dateDrawn).inMilliseconds.toDouble();
        double t = currentDuration / totalDuration;

        double f1 = p1.resultingCorrectionFactor ?? 1.0;
        double f2 = p2.resultingCorrectionFactor ?? 1.0;

        return f1 + (f2 - f1) * t;
      }
    }

    return 1.0;
  }
}
