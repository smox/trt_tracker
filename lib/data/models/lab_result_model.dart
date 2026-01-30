class LabResultModel {
  final String id;
  final DateTime dateDrawn;
  final double measuredValueRaw;
  final String unitRaw;
  final double valueNormalized; // Immer ng/dl
  final bool usedForCalibration;
  final double? resultingCorrectionFactor;
  final DateTime createdAt;

  LabResultModel({
    required this.id,
    required this.dateDrawn,
    required this.measuredValueRaw,
    required this.unitRaw,
    required this.valueNormalized,
    this.usedForCalibration = false,
    this.resultingCorrectionFactor, // <--- NEU
    required this.createdAt,
  });

  factory LabResultModel.fromMap(Map<String, dynamic> map) {
    return LabResultModel(
      id: map['id'] as String,
      dateDrawn: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp_drawn'] as int,
      ),
      measuredValueRaw: (map['measured_value_raw'] as num).toDouble(),
      unitRaw: map['unit_raw'] as String,
      valueNormalized: (map['value_normalized_ng_ml'] as num).toDouble(),
      usedForCalibration: (map['used_for_calibration'] as int) == 1,
      // <--- NEU
      resultingCorrectionFactor:
          map['resulting_correction_factor'] != null
              ? (map['resulting_correction_factor'] as num).toDouble()
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp_drawn': dateDrawn.millisecondsSinceEpoch,
      'measured_value_raw': measuredValueRaw,
      'unit_raw': unitRaw,
      'value_normalized_ng_ml': valueNormalized,
      'used_for_calibration': usedForCalibration ? 1 : 0,
      'resulting_correction_factor': resultingCorrectionFactor, // <--- NEU
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
