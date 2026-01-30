import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trt_tracker/data/models/enums.dart';
import 'package:trt_tracker/data/models/injection_model.dart';
import 'package:trt_tracker/logic/providers.dart';
import 'package:uuid/uuid.dart';

class AddInjectionScreen extends ConsumerStatefulWidget {
  final InjectionModel? injectionToEdit;
  final DateTime? initialDate;
  final String? fulfilledPlanId;
  final double? prefillAmount;
  final EsterType? prefillEster;

  const AddInjectionScreen({
    super.key,
    this.injectionToEdit,
    this.initialDate,
    this.fulfilledPlanId,
    this.prefillAmount,
    this.prefillEster,
  });

  @override
  ConsumerState<AddInjectionScreen> createState() => _AddInjectionScreenState();
}

class _AddInjectionScreenState extends ConsumerState<AddInjectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late double _amount;
  late EsterType _selectedEster;
  late ApplicationMethod _selectedMethod;
  String? _spot;

  @override
  void initState() {
    super.initState();
    if (widget.injectionToEdit != null) {
      _selectedDate = widget.injectionToEdit!.timestamp;
      _amount = widget.injectionToEdit!.amountMg;
      _selectedEster = widget.injectionToEdit!.ester;
      _selectedMethod = widget.injectionToEdit!.method;
      _spot = widget.injectionToEdit!.spot;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _amount = widget.prefillAmount ?? 125.0;
      _selectedEster = widget.prefillEster ?? EsterType.enanthate;
      _selectedMethod = ApplicationMethod.im;
      _spot = '';
    }
  }

  void _saveInjection() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newInjection = InjectionModel(
        id: widget.injectionToEdit?.id ?? const Uuid().v4(),
        timestamp: _selectedDate,
        amountMg: _amount,
        ester: _selectedEster,
        method: _selectedMethod,
        spot: _spot?.isEmpty == true ? null : _spot,
        // FIX: createdAt ist jetzt INT. Fallback auf Millisekunden.
        createdAt:
            widget.injectionToEdit?.createdAt ??
            DateTime.now().millisecondsSinceEpoch,
      );

      if (widget.injectionToEdit != null) {
        await ref
            .read(injectionListProvider.notifier)
            .deleteInjection(newInjection.id);
        await ref
            .read(injectionListProvider.notifier)
            .addInjection(newInjection);
      } else {
        await ref
            .read(injectionListProvider.notifier)
            .addInjection(newInjection);

        if (widget.fulfilledPlanId != null) {
          await ref
              .read(injectionPlanProvider.notifier)
              .markPlanAsDone(widget.fulfilledPlanId!);
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.injectionToEdit != null
              ? "Eintrag bearbeiten"
              : "Neue Injektion",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Wann?"),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF64FFDA),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        DateFormat('dd.MM.yyyy, HH:mm').format(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Substanz"),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<EsterType>(
                      value: _selectedEster,
                      dropdownColor: const Color(0xFF1E1E1E),
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
                      onChanged: (val) => setState(() => _selectedEster = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _amount.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Menge (mg)"),
                      onSaved: (val) => _amount = double.parse(val!),
                      validator:
                          (val) =>
                              (val == null || val.isEmpty) ? 'Pflicht' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Applikation"),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ApplicationMethod>(
                      value: _selectedMethod,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Methode"),
                      items: [
                        DropdownMenuItem(
                          value: ApplicationMethod.im,
                          child: Text("Intramuskulär"),
                        ),
                        DropdownMenuItem(
                          value: ApplicationMethod.subq,
                          child: Text("Subkutan"),
                        ),
                      ],
                      onChanged:
                          (val) => setState(() => _selectedMethod = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _spot,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Stelle (z.B. Oberschenkel rechts)",
                ),
                onSaved: (val) => _spot = val,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64FFDA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveInjection,
                  child: const Text(
                    "Speichern",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF64FFDA)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    );
  }
}
