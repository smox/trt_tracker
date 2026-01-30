import 'enums.dart';

class InjectionModel {
  final String id;
  final DateTime timestamp;
  final double amountMg;
  final EsterType ester;
  final ApplicationMethod method;
  final String? spot;
  final int createdAt;

  InjectionModel({
    required this.id,
    required this.timestamp,
    required this.amountMg,
    required this.ester,
    required this.method,
    this.spot,
    required this.createdAt,
  });

  // WICHTIG: Die Keys hier müssen exakt den Spaltennamen in database_service.dart entsprechen!
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'amount_mg': amountMg,
      'ester_index': ester.index, // Datenbank erwartet ester_index (int)
      'method_index': method.index, // Datenbank erwartet method_index (int)
      'spot': spot,
      'created_at': createdAt,
    };
  }

  factory InjectionModel.fromMap(Map<String, dynamic> map) {
    return InjectionModel(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      amountMg: map['amount_mg'],
      // Hier wandeln wir den Int aus der DB zurück in das Enum
      ester: EsterType.values[map['ester_index']],
      method: ApplicationMethod.values[map['method_index']],
      spot: map['spot'],
      createdAt: map['created_at'] ?? 0,
    );
  }
}
