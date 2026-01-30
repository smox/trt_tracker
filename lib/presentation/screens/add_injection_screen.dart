import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../data/models/enums.dart';
import '../../data/models/injection_model.dart';
import '../../logic/providers.dart';

class AddInjectionScreen extends ConsumerStatefulWidget {
  // Optional: Wenn das hier gesetzt ist, sind wir im "Bearbeiten"-Modus
  final InjectionModel? injectionToEdit;

  const AddInjectionScreen({super.key, this.injectionToEdit});

  @override
  ConsumerState<AddInjectionScreen> createState() => _AddInjectionScreenState();
}

class _AddInjectionScreenState extends ConsumerState<AddInjectionScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late EsterType _selectedEster;
  late ApplicationMethod _selectedMethod;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _spotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vorbefüllen, falls wir bearbeiten
    if (widget.injectionToEdit != null) {
      final inj = widget.injectionToEdit!;
      _selectedDate = inj.timestamp;
      _selectedTime = TimeOfDay.fromDateTime(inj.timestamp);
      _selectedEster = inj.ester;
      _selectedMethod = inj.method;
      _amountController.text = inj.amountMg.toString();
      _spotController.text = inj.spot ?? "";
    } else {
      // Defaults für "Neu anlegen"
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedEster = EsterType.enanthate;
      _selectedMethod = ApplicationMethod.im;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _spotController.dispose();
    super.dispose();
  }

  void _saveInjection() async {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      // ID behalten beim Bearbeiten, sonst neue UUID
      final id = widget.injectionToEdit?.id ?? const Uuid().v4();
      // CreatedAt behalten, sonst Jetzt
      final createdAt = widget.injectionToEdit?.createdAt ?? DateTime.now();

      final injection = InjectionModel(
        id: id,
        timestamp: dateTime,
        amountMg: amount,
        ester: _selectedEster,
        method: _selectedMethod,
        spot: _spotController.text.isEmpty ? null : _spotController.text,
        createdAt: createdAt,
      );

      // Speichern (addInjection überschreibt bei gleicher ID dank ConflictAlgorithm.replace)
      await ref.read(injectionListProvider.notifier).addInjection(injection);

      // Zwinge den Rechner sofort zum Neuberechnen!
      ref.invalidate(currentLevelProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildDateTimeRow(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64FFDA)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey)),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);
    final isEditing = widget.injectionToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isEditing ? "Injektion bearbeiten" : "Injektion eintragen"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateTimeRow(
                "Datum",
                dateStr,
                Icons.calendar_today,
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF64FFDA),
                            onPrimary: Colors.black,
                            surface: Color(0xFF1E1E1E),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const Divider(color: Colors.white10),
              _buildDateTimeRow(
                "Uhrzeit",
                timeStr,
                Icons.access_time,
                () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),

              const SizedBox(height: 30),

              DropdownButtonFormField<EsterType>(
                value: _selectedEster,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Ester",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.science,
                    color: Color(0xFF64FFDA),
                  ),
                ),
                items:
                    EsterType.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedEster = val!),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: "Menge Wirkstoff (mg)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  suffixText: "mg",
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.scale, color: Color(0xFF64FFDA)),
                ),
                validator:
                    (val) =>
                        (val == null || val.isEmpty) ? "Pflichtfeld" : null,
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Intramuskulär (IM)"),
                      selected: _selectedMethod == ApplicationMethod.im,
                      onSelected:
                          (bool selected) => setState(
                            () => _selectedMethod = ApplicationMethod.im,
                          ),
                      selectedColor: const Color(0xFF64FFDA),
                      labelStyle: TextStyle(
                        color:
                            _selectedMethod == ApplicationMethod.im
                                ? Colors.black
                                : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Subkutan (SubQ)"),
                      selected: _selectedMethod == ApplicationMethod.subq,
                      onSelected:
                          (bool selected) => setState(
                            () => _selectedMethod = ApplicationMethod.subq,
                          ),
                      selectedColor: const Color(0xFF64FFDA),
                      labelStyle: TextStyle(
                        color:
                            _selectedMethod == ApplicationMethod.subq
                                ? Colors.black
                                : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _spotController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Injektionsstelle (Optional)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: "z.B. Oberschenkel rechts",
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0xFF64FFDA),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveInjection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64FFDA),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Änderungen speichern" : "Eintragen",
                    style: const TextStyle(
                      fontSize: 18,
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
}
