import 'enums.dart';

class InjectionModel {
  final String id; // UUID
  final DateTime timestamp;
  final double amountMg;
  final EsterType ester;
  final ApplicationMethod method;
  final String? spot;
  final DateTime createdAt;

  InjectionModel({
    required this.id,
    required this.timestamp,
    required this.amountMg,
    required this.ester,
    required this.method,
    this.spot,
    required this.createdAt,
  });

  factory InjectionModel.fromMap(Map<String, dynamic> map) {
    return InjectionModel(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      amountMg: (map['amount_mg'] as num).toDouble(),
      // Wir speichern Enums als String in der DB (z.B. "EsterType.enanthate")
      ester: EsterType.values.firstWhere(
        (e) => e.toString() == map['ester_type'],
        orElse: () => EsterType.enanthate, // Fallback
      ),
      method: ApplicationMethod.values.firstWhere(
        (e) => e.toString() == map['application_method'],
        orElse: () => ApplicationMethod.im,
      ),
      spot: map['spot'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'amount_mg': amountMg,
      'ester_type': ester.toString(),
      'application_method': method.toString(),
      'spot': spot,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
