import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:trt_tracker/data/models/enums.dart'; // Für .label Extension
import '../../data/models/injection_model.dart';
import '../../logic/providers.dart';
import 'add_injection_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Filtert Injektionen für einen bestimmten Tag
  List<InjectionModel> _getInjectionsForDay(
    DateTime day,
    List<InjectionModel> allInjections,
  ) {
    return allInjections.where((injection) {
      return isSameDay(injection.timestamp, day);
    }).toList();
  }

  void _deleteInjection(String id) async {
    await ref.read(injectionListProvider.notifier).deleteInjection(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eintrag gelöscht'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Daten laden
    final injectionsAsync = ref.watch(injectionListProvider);
    // NEU: User Profile laden, um den Start der Woche zu wissen
    final userProfile = ref.watch(userProfileProvider).value;

    // Logik: Wenn im Profil 7 steht -> Sonntag, sonst -> Montag
    final startOfWeek =
        (userProfile?.startOfWeek == 7)
            ? StartingDayOfWeek.sunday
            : StartingDayOfWeek.monday;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Kalender & Historie"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: injectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (allInjections) {
          // Injektionen für den aktuell ausgewählten Tag
          final selectedInjections = _getInjectionsForDay(
            _selectedDay!,
            allInjections,
          );

          return Column(
            children: [
              // --- KALENDER WIDGET ---
              TableCalendar(
                locale: 'de_DE',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,

                // HIER IST DIE ÄNDERUNG: Starttag festlegen
                startingDayOfWeek: startOfWeek,

                // 1. HEADER STYLE (Monatsname & Pfeile)
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false, // "2 Weeks" Button ausblenden
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),

                // 2. CALENDAR STYLE (Tage, Kreise, Marker)
                calendarStyle: const CalendarStyle(
                  // Textfarben
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  outsideTextStyle: TextStyle(color: Colors.white24),

                  // Der ausgewählte Tag (Kreis)
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF64FFDA), // Türkis
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),

                  // Der heutige Tag (wenn nicht ausgewählt)
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFF64FFDA), width: 1),
                    ),
                  ),
                  todayTextStyle: TextStyle(color: Color(0xFF64FFDA)),

                  // Marker (Punkte für Events)
                  markerDecoration: BoxDecoration(
                    color: Color(0xFFD946EF), // Lila Punkte
                    shape: BoxShape.circle,
                  ),
                ),

                // Logik
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format)
                    setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,

                // Event Loader (Zeigt die Punkte im Kalender an)
                eventLoader: (day) => _getInjectionsForDay(day, allInjections),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12),

              // --- LISTE DER INJEKTIONEN ---
              Expanded(
                child:
                    selectedInjections.isEmpty
                        ? Center(
                          child: Text(
                            "Keine Einträge am ${DateFormat('dd.MM.').format(_selectedDay!)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: selectedInjections.length,
                          itemBuilder: (context, index) {
                            final injection = selectedInjections[index];
                            return Dismissible(
                              key: Key(injection.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red.shade900,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed:
                                  (_) => _deleteInjection(injection.id),
                              child: Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF333333),
                                    child: Icon(
                                      injection.method == ApplicationMethod.im
                                          ? Icons.vaccines
                                          : Icons.api,
                                      color: const Color(0xFF64FFDA),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "${injection.amountMg} mg ${injection.ester.label}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${DateFormat('HH:mm').format(injection.timestamp)} Uhr • ${injection.spot ?? 'Kein Spot'}",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      // Navigation zum Bearbeiten
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AddInjectionScreen(
                                                injectionToEdit: injection,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64FFDA),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInjectionScreen()),
          );
        },
      ),
    );
  }
}
