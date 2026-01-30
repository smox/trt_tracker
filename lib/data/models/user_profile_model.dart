import 'dart:convert';
import 'package:trt_tracker/data/models/enums.dart';

class UserProfileModel {
  final String id;
  final String name;
  final double weight;
  final int height;
  final double bodyFatPercentage;
  final double correctionFactor;
  final MassUnit preferredUnit;
  final int birthDate;
  final int therapyStart;
  final int createdAt;
  final int startOfWeek; // 1 = Montag, 7 = Sonntag

  UserProfileModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.height,
    required this.bodyFatPercentage,
    required this.correctionFactor,
    required this.preferredUnit,
    required this.birthDate,
    required this.therapyStart,
    required this.createdAt,
    this.startOfWeek = 1, // Default Montag
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'height': height,
      'body_fat_percentage':
          bodyFatPercentage, // Name konsistent mit fromMap gemacht
      'correction_factor': correctionFactor,
      // WICHTIG: Wir speichern jetzt den String, damit fromMap funktioniert!
      'preferred_unit': preferredUnit.toString(),
      'birth_date': birthDate,
      'therapy_start': therapyStart,
      'created_at': createdAt,
      'start_of_week': startOfWeek, // NEU
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    double? weight,
    int? height,
    double? bodyFatPercentage,
    double? correctionFactor,
    MassUnit? preferredUnit,
    int? birthDate,
    int? therapyStart,
    int? createdAt,
    int? startOfWeek,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      correctionFactor: correctionFactor ?? this.correctionFactor,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      birthDate: birthDate ?? this.birthDate,
      therapyStart: therapyStart ?? this.therapyStart,
      createdAt: createdAt ?? this.createdAt,
      startOfWeek: startOfWeek ?? this.startOfWeek,
    );
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      bodyFatPercentage:
          (map['body_fat_percentage'] as num?)?.toDouble() ?? 0.0,
      correctionFactor: (map['correction_factor'] as num?)?.toDouble() ?? 1.0,
      preferredUnit: MassUnit.values.firstWhere(
        (e) => e.toString() == map['preferred_unit'],
        orElse: () => MassUnit.ng_ml,
      ),
      birthDate:
          (map['birth_date'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      therapyStart:
          (map['therapy_start'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      createdAt:
          (map['created_at'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      startOfWeek:
          map['start_of_week'] != null ? (map['start_of_week'] as int) : 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfileModel.fromJson(String source) =>
      UserProfileModel.fromMap(json.decode(source));
}
