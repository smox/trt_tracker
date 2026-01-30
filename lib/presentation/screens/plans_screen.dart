import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:trt_tracker/data/models/enums.dart';
import 'package:trt_tracker/data/models/injection_plan_model.dart';
import 'package:trt_tracker/logic/providers.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(injectionPlanProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Injektionspläne"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    "Keine Pläne aktiv",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showAddPlanDialog(context, ref, null),
                    child: const Text(
                      "Ersten Plan erstellen",
                      style: TextStyle(color: Color(0xFF64FFDA)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildPlanCard(context, ref, plan);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context, ref, null),
        backgroundColor: const Color(0xFF64FFDA),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    InjectionPlanModel plan,
  ) {
    final nextDate = DateFormat(
      'EEE, dd.MM. HH:mm',
      'de_DE',
    ).format(plan.nextDueDate);

    // Logik für den Anzeigetext (Wochentag oder Intervall)
    String intervalText;
    if (plan.intervalDays == 7) {
      final weekday = DateFormat('EEEE', 'de_DE').format(plan.nextDueDate);
      intervalText = "Jeden $weekday";
    } else {
      intervalText = "Alle ${plan.intervalDays} Tage";
    }

    // Formatierung der Menge: "62.5" statt "63" und "60" statt "60.0"
    String amountText = plan.amountMg.toString();
    if (amountText.endsWith(".0")) {
      amountText = amountText.substring(0, amountText.length - 2);
    } else {
      // Auf deutsch sieht Komma schöner aus
      amountText = amountText.replaceAll('.', ',');
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddPlanDialog(context, ref, plan),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$amountText mg ${plan.ester.label}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        intervalText,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: plan.isActive,
                    activeColor: const Color(0xFF64FFDA),
                    onChanged: (val) {
                      ref
                          .read(injectionPlanProvider.notifier)
                          .updatePlan(plan.copyWith(isActive: val));
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.next_plan,
                        size: 16,
                        color: Color(0xFF64FFDA),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Nächste: $nextDate",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () {
                      ref
                          .read(injectionPlanProvider.notifier)
                          .deletePlan(plan.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPlanDialog(
    BuildContext context,
    WidgetRef ref,
    InjectionPlanModel? planToEdit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPlanSheet(planToEdit: planToEdit),
    );
  }
}

class _AddPlanSheet extends ConsumerStatefulWidget {
  final InjectionPlanModel? planToEdit;

  const _AddPlanSheet({this.planToEdit});

  @override
  ConsumerState<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends ConsumerState<_AddPlanSheet> {
  // Mode: 0 = Wochentag (Default), 1 = Intervall
  int _mode = 0;

  double _amount = 62.5;
  EsterType _ester = EsterType.enanthate;
  ApplicationMethod _method = ApplicationMethod.im;

  // Für Mode 0 (Wochentag)
  int _selectedWeekday = DateTime.now().weekday; // 1 = Mo, 7 = So

  // Für Mode 1 (Intervall)
  int _intervalInput = 3;

  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    // Falls wir bearbeiten, Daten laden
    if (widget.planToEdit != null) {
      final p = widget.planToEdit!;
      _amount = p.amountMg;
      _ester = p.ester;
      _method = p.method;
      _time = TimeOfDay(hour: p.reminderTimeHour, minute: p.reminderTimeMinute);

      // Smart Mode Detection
      if (p.intervalDays == 7) {
        _mode = 0;
        _selectedWeekday = p.nextDueDate.weekday;
      } else {
        _mode = 1;
        _intervalInput = p.intervalDays;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // HIER IST DER FINALE FIX FÜR DAS LAYOUT
    return Padding(
      // 1. Wir heben das Modal an, wenn die Tastatur (viewInsets) kommt
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        // 2. SafeArea garantiert, dass wir NICHT im Home-Balken landen
        child: SingleChildScrollView(
          child: Padding(
            // 3. Normales Padding für den Inhalt
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.planToEdit != null
                      ? "Plan bearbeiten"
                      : "Neuer Injektionsplan",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. WAS?
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<EsterType>(
                        value: _ester,
                        dropdownColor: const Color(0xFF333333),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Ester"),
                        items:
                            EsterType.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _ester = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        // FIX: Punkt statt Komma für die initiale Anzeige
                        initialValue: _amount.toString().replaceAll('.', ','),
                        // FIX: Erlaubt Kommas und Punkte auf der Tastatur
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Menge (mg)"),
                        onChanged: (v) {
                          // FIX: Komma zu Punkt konvertieren für den Parser
                          String clean = v.replaceAll(',', '.');
                          _amount = double.tryParse(clean) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. MODUS WAHL (Tabs)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Wochentag", 0),
                      _buildTabButton("Intervall", 1),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. WIE OFT? (Abhängig vom Mode)
                if (_mode == 0) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedWeekday,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Wochentag"),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Montag")),
                      DropdownMenuItem(value: 2, child: Text("Dienstag")),
                      DropdownMenuItem(value: 3, child: Text("Mittwoch")),
                      DropdownMenuItem(value: 4, child: Text("Donnerstag")),
                      DropdownMenuItem(value: 5, child: Text("Freitag")),
                      DropdownMenuItem(value: 6, child: Text("Samstag")),
                      DropdownMenuItem(value: 7, child: Text("Sonntag")),
                    ],
                    onChanged: (v) => setState(() => _selectedWeekday = v!),
                  ),
                ] else ...[
                  TextFormField(
                    initialValue: _intervalInput.toString(),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Alle X Tage"),
                    onChanged: (v) => _intervalInput = int.tryParse(v) ?? 1,
                  ),
                ],

                const SizedBox(height: 16),

                // 4. WANN (Uhrzeit)?
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (t != null) setState(() => _time = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Uhrzeit:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _time.format(context),
                          style: const TextStyle(
                            color: Color(0xFF64FFDA),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SAVE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64FFDA),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _savePlan,
                    child: const Text("Plan Speichern"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _savePlan() {
    int finalInterval;
    DateTime nextDate;

    // --- Datum Logik ---
    final now = DateTime.now();

    if (_mode == 0) {
      // Wochentag Logik
      finalInterval = 7;

      int todayWeekday = now.weekday;
      int daysUntil = _selectedWeekday - todayWeekday;

      if (daysUntil == 0) {
        final planTime = DateTime(
          now.year,
          now.month,
          now.day,
          _time.hour,
          _time.minute,
        );
        if (planTime.isBefore(now)) {
          // Uhrzeit heute schon vorbei -> nächste Woche
          daysUntil = 7;
        }
      } else if (daysUntil < 0) {
        daysUntil += 7;
      }

      final targetDate = now.add(Duration(days: daysUntil));
      nextDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        _time.hour,
        _time.minute,
      );
    } else {
      // Intervall Logik
      finalInterval = _intervalInput;
      // Startet ab "Heute" + Uhrzeit (oder Morgen wenn Zeit vorbei)
      DateTime baseDate = DateTime(
        now.year,
        now.month,
        now.day,
        _time.hour,
        _time.minute,
      );
      if (baseDate.isBefore(now)) {
        baseDate = baseDate.add(const Duration(days: 1));
      }
      nextDate = baseDate;
    }

    // --- Objekt erstellen ---
    final newPlan = InjectionPlanModel(
      // ID behalten wenn Edit, sonst neu generieren
      id: widget.planToEdit?.id ?? const Uuid().v4(),
      amountMg: _amount,
      ester: _ester,
      method: _method,
      intervalDays: finalInterval,
      nextDueDate: nextDate,
      reminderTimeHour: _time.hour,
      reminderTimeMinute: _time.minute,
      isActive: widget.planToEdit?.isActive ?? true,
    );

    // --- Speichern ---
    if (widget.planToEdit != null) {
      ref.read(injectionPlanProvider.notifier).updatePlan(newPlan);
    } else {
      ref.read(injectionPlanProvider.notifier).addPlan(newPlan);
    }

    Navigator.pop(context);
  }

  Widget _buildTabButton(String label, int modeIndex) {
    final isSelected = _mode == modeIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = modeIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF64FFDA) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF64FFDA)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
    );
  }
}
