enum EsterType {
  propionate,
  enanthate,
  cypionate,
  undecanoate, // Nebido
  sustanon, // Mischung (im MVP behandeln wir das ggf. als Custom oder ignorieren es erstmal)
}

enum ApplicationMethod {
  im, // Intramuskulär
  subq, // Subkutan
}

enum MassUnit {
  ng_ml, // Nanogramm pro Milliliter (Standard)
  ng_dl, // Nanogramm pro Deziliter (US Standard)
  nmol_l, // Nanomol pro Liter (International / EU oft)
}

// Extension für schöne UI-Namen (Optional, aber hilfreich)
extension EsterTypeExtension on EsterType {
  String get label {
    switch (this) {
      case EsterType.propionate:
        return 'Propionat';
      case EsterType.enanthate:
        return 'Enantat';
      case EsterType.cypionate:
        return 'Cypionat';
      case EsterType.undecanoate:
        return 'Undecanoat';
      case EsterType.sustanon:
        return 'Sustanon';
    }
  }
}
