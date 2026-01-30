import 'package:flutter/material.dart';
import 'enums.dart';

class InjectionPlanModel {
  final String id;
  final double amountMg;
  final EsterType ester;
  final ApplicationMethod method;
  final int intervalDays;
  final DateTime nextDueDate;
  final int reminderTimeHour;
  final int reminderTimeMinute;
  final bool isActive;
  final String? spot;

  InjectionPlanModel({
    required this.id,
    required this.amountMg,
    required this.ester,
    required this.method,
    required this.intervalDays,
    required this.nextDueDate,
    required this.reminderTimeHour,
    required this.reminderTimeMinute,
    this.isActive = true,
    this.spot,
  });

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderTimeHour, minute: reminderTimeMinute);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount_mg': amountMg,
      'ester_index': ester.index,
      'method_index': method.index,
      'interval_days': intervalDays,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'reminder_hour': reminderTimeHour,
      'reminder_minute': reminderTimeMinute,
      'is_active': isActive ? 1 : 0,
      'spot': spot,
    };
  }

  factory InjectionPlanModel.fromMap(Map<String, dynamic> map) {
    return InjectionPlanModel(
      id: map['id'],
      amountMg: map['amount_mg'],
      ester: EsterType.values[map['ester_index']],
      method: ApplicationMethod.values[map['method_index']],
      intervalDays: map['interval_days'],
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date']),
      reminderTimeHour: map['reminder_hour'],
      reminderTimeMinute: map['reminder_minute'],
      isActive: map['is_active'] == 1,
      spot: map['spot'],
    );
  }

  InjectionPlanModel copyWith({
    String? id,
    double? amountMg,
    EsterType? ester,
    ApplicationMethod? method,
    int? intervalDays,
    DateTime? nextDueDate,
    int? reminderTimeHour,
    int? reminderTimeMinute,
    bool? isActive,
    String? spot,
  }) {
    return InjectionPlanModel(
      id: id ?? this.id,
      amountMg: amountMg ?? this.amountMg,
      ester: ester ?? this.ester,
      method: method ?? this.method,
      intervalDays: intervalDays ?? this.intervalDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      reminderTimeHour: reminderTimeHour ?? this.reminderTimeHour,
      reminderTimeMinute: reminderTimeMinute ?? this.reminderTimeMinute,
      isActive: isActive ?? this.isActive,
      spot: spot ?? this.spot,
    );
  }
}
