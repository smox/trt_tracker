import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trt_tracker/data/models/enums.dart';
import 'package:trt_tracker/logic/notification_service.dart';
import 'package:trt_tracker/logic/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final hapticEnabled = ref.watch(hapticFeedbackProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Einstellungen"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader("Allgemein"),

                // WOCHENSTART
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  title: "Wochenstart",
                  subtitle: "Legt fest, an welchem Tag der Kalender beginnt.",
                  trailing: DropdownButton<int>(
                    value: userProfile.startOfWeek,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Montag")),
                      DropdownMenuItem(value: 7, child: Text("Sonntag")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(userProfileProvider.notifier)
                            .updateSettings(startOfWeek: val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // EINHEITEN
                _buildSettingsTile(
                  icon: Icons.science,
                  title: "Bevorzugte Einheit",
                  subtitle: "Für die Anzeige im Dashboard und Graphen.",
                  trailing: DropdownButton<MassUnit>(
                    value: userProfile.preferredUnit,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: MassUnit.ng_ml,
                        child: Text("ng/mL"),
                      ),
                      DropdownMenuItem(
                        value: MassUnit.ng_dl,
                        child: Text("ng/dL"),
                      ),
                      DropdownMenuItem(
                        value: MassUnit.nmol_l,
                        child: Text("nmol/L"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(userProfileProvider.notifier)
                            .updateSettings(preferredUnit: val);
                        ref.invalidate(currentLevelProvider);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // NEU: KOLLISONS-PUFFER
                _buildSectionHeader("Analyse & Pläne"),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.merge, color: Color(0xFF64FFDA)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Injektions-Fenster",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Pufferzeit für Erkennung von geplanten vs. echten Injektionen (+/- ${userProfile.injectionWindowHours} Std.)",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            "1h",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: userProfile.injectionWindowHours
                                  .toDouble(),
                              min: 1,
                              max: 24,
                              divisions: 23,
                              label: "${userProfile.injectionWindowHours}h",
                              activeColor: const Color(0xFF64FFDA),
                              inactiveColor: Colors.white10,
                              onChanged: (val) {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .updateSettings(
                                      injectionWindowHours: val.toInt(),
                                    );
                              },
                            ),
                          ),
                          const Text(
                            "24h",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _buildSectionHeader("Benachrichtigungen"),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF64FFDA),
                  ),
                  title: const Text(
                    "Erinnerungen aktivieren",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Erlaubnis für Push-Nachrichten prüfen",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () async {
                    await NotificationService().requestPermissions();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Berechtigungen angefordert/geprüft"),
                        ),
                      );
                    }
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white24,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ), // Kleiner Abstand zwischen den beiden
                // 2. NEU: DIAGNOSE & TEST
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: const Color(0xFF1E1E1E),
                  // HIER WAR DER FEHLER: Shape hinzugefügt
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.bug_report, color: Colors.orange),
                  title: const Text(
                    "System-Check",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Status prüfen & Test-Nachricht senden",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () async {
                    final service = NotificationService();

                    // A) Status prüfen
                    final allowed = await service.checkPermissionStatus();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Darf senden: $allowed"),
                          backgroundColor: (allowed == true)
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    }

                    // B) Wenn erlaubt, sofort feuern
                    if (allowed == true) {
                      await service.showInstantNotification();
                    }
                  },
                ),

                const SizedBox(height: 16),
                _buildSectionHeader("Bedienung"),

                // HAPTIK
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  secondary: const Icon(
                    Icons.vibration,
                    color: Color(0xFF64FFDA),
                  ),
                  title: const Text(
                    "Haptisches Feedback",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Vibration bei Interaktionen",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  value: hapticEnabled,
                  activeColor: const Color(0xFF64FFDA),
                  onChanged: (val) {
                    ref.read(hapticFeedbackProvider.notifier).state = val;
                  },
                ),

                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Version 1.0.0",
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64FFDA),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64FFDA)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
