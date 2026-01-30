import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trt_tracker/data/database_service.dart';
import 'package:trt_tracker/presentation/screens/splash_screen.dart';
import 'package:trt_tracker/logic/notification_service.dart'; // NEU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lädt die Formatierungsregeln für Deutsch
  await initializeDateFormatting('de_DE', null);

  // DB Initialisierung
  await DatabaseService().database;

  // NEU: Notifications initialisieren
  await NotificationService().init();

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
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64FFDA),
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
