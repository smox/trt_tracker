import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trt_tracker/data/database_service.dart';
// WICHTIG: Importiere den Splash Screen
import 'package:trt_tracker/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lädt die Formatierungsregeln für Deutsch
  await initializeDateFormatting('de_DE', null);

  // DB Initialisierung vor dem UI-Start
  await DatabaseService().database;

  runApp(const ProviderScope(child: TRTApp()));
}

class TRTApp extends StatelessWidget {
  const TRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRT Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Sehr dunkles Grau
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64FFDA), // Türkis/Cyan Akzent
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E), // Karten Hintergrund
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // HIER IST DIE ÄNDERUNG:
      // Wir starten immer mit dem SplashScreen.
      // Der SplashScreen entscheidet dann selbstständig (nach der Animation),
      // ob es zum HomeScreen oder zum OnboardingScreen geht.
      home: const SplashScreen(),
    );
  }
}
