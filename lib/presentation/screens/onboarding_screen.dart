import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trt_tracker/data/models/enums.dart';
import 'package:trt_tracker/logic/providers.dart';
import 'package:trt_tracker/presentation/screens/home_screen.dart'; // WICHTIG

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  // Wir nutzen Keys pro Seite, um gezielt zu validieren
  final _personalFormKey = GlobalKey<FormState>();
  final _statsFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _therapyStartDate;
  MassUnit _selectedUnit = MassUnit.ng_ml;

  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _submitData() async {
    // Letzter Check: Haben wir ein Startdatum?
    if (_therapyStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte wähle den Start deiner Therapie.")),
      );
      return;
    }

    final String name = _nameController.text;
    final double weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final int height = int.tryParse(_heightController.text) ?? 0;

    // Fallback falls null (sollte durch Validierung vorher nicht passieren)
    final birth = _birthDate ?? DateTime(1990);
    final start = _therapyStartDate!;

    try {
      // 1. Speichern
      await ref
          .read(userProfileProvider.notifier)
          .saveOnboardingData(
            name: name,
            weightKg: weight,
            heightCm: height,
            birthDate: birth,
            therapyStart: start,
            preferredUnit: _selectedUnit,
          );

      // 2. Navigation zum Home Screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("FEHLER BEIM SPEICHERN: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate ? DateTime(1990) : DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF64FFDA),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _therapyStartDate = picked;
        }
      });
    }
  }

  void _nextPage() {
    bool canProceed = false;

    // VALIDIERUNG PRO SEITE
    if (_currentPage == 0) {
      // Info Seite -> immer weiter
      canProceed = true;
    } else if (_currentPage == 1) {
      // Personal Seite -> Form validieren + Geburtsdatum prüfen
      if (_personalFormKey.currentState!.validate()) {
        if (_birthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bitte gib dein Geburtsdatum an.")),
          );
        } else {
          canProceed = true;
        }
      }
    } else if (_currentPage == 2) {
      // Stats Seite -> Form validieren
      if (_statsFormKey.currentState!.validate()) {
        canProceed = true;
      }
    } else if (_currentPage == 3) {
      // Therapie Seite -> Datum prüfen und Absenden
      if (_therapyStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bitte wähle ein Startdatum.")),
        );
      } else {
        _submitData(); // Daten senden, nicht mehr blättern
      }
      return;
    }

    if (canProceed) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fortschrittsanzeige
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: Colors.grey[800],
                color: const Color(0xFF64FFDA),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
            ),

            // 2. Inhalt
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Benutzer muss Buttons nutzen
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage0Info(),
                  _buildPage1Personal(),
                  _buildPage2BodyStats(),
                  _buildPage3Therapy(),
                ],
              ),
            ),

            // 3. Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        "Zurück",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    const SizedBox(),

                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64FFDA),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? "Starten" : "Weiter",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEITE 0 ---
  Widget _buildPage0Info() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.info_outline,
                size: 60,
                color: Color(0xFF64FFDA),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                "Wichtiges vorab",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoBlock(
              icon: Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              title: "Keine Medizinische Beratung",
              text:
                  "Diese App dient ausschließlich deiner persönlichen Information. Die Werte sind Schätzungen.",
            ),
            const SizedBox(height: 24),
            _buildInfoBlock(
              icon: Icons.auto_graph,
              color: const Color(0xFF64FFDA),
              title: "Wie wir berechnen",
              text:
                  "Die App nutzt pharmakokinetische Formeln (Bateman), um deinen Spiegel zu schätzen. Mit echten Blutwerten kalibriert sich das System automatisch.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SEITE 1 (Personal) ---
  Widget _buildPage1Personal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        // Hier ein eigenes Formular für Seite 1
        key: _personalFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Über dich",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Richten wir dein Profil ein.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _nameController,
              label: "Dein Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildDateSelector(
              label: "Geburtsdatum",
              date: _birthDate,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MassUnit>(
              value: _selectedUnit,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _getInputDecoration(
                "Bevorzugte Einheit",
                Icons.science,
              ),
              iconEnabledColor: const Color(0xFF64FFDA),
              items: const [
                DropdownMenuItem(
                  value: MassUnit.ng_ml,
                  child: Text("ng/mL (Standard)"),
                ),
                DropdownMenuItem(
                  value: MassUnit.ng_dl,
                  child: Text("ng/dL (US)"),
                ),
                DropdownMenuItem(
                  value: MassUnit.nmol_l,
                  child: Text("nmol/L (International)"),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedUnit = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- SEITE 2 (Stats) ---
  Widget _buildPage2BodyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        // Hier ein eigenes Formular für Seite 2
        key: _statsFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.monitor_weight_outlined,
              size: 80,
              color: Color(0xFF64FFDA),
            ),
            const SizedBox(height: 24),
            const Text(
              "Deine Stats",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Das Gewicht hilft uns, das Verteilungsvolumen zu schätzen.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: "Größe (cm)",
                    icon: Icons.height,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: "Gewicht (kg)",
                    icon: Icons.line_weight,
                    isNumber: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SEITE 3 (Therapy) ---
  Widget _buildPage3Therapy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 80,
            color: Color(0xFF64FFDA),
          ),
          const SizedBox(height: 24),
          const Text(
            "Therapie Start",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Seit wann bist du in Behandlung?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          _buildDateSelector(
            label: "Startdatum",
            date: _therapyStartDate,
            onTap: () => _selectDate(context, false),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF64FFDA)),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF64FFDA), width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF64FFDA),
      decoration: _getInputDecoration(label, icon),
      validator:
          (value) => (value == null || value.isEmpty) ? 'Pflichtfeld' : null,
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF64FFDA)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null
                      ? "Bitte wählen"
                      : "${date.day}.${date.month}.${date.year}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        date == null ? FontWeight.normal : FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
