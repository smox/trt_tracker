import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // NEU
import 'package:intl/date_symbol_data_local.dart';
import 'package:trt_tracker/data/database_service.dart';
import 'package:trt_tracker/presentation/screens/splash_screen.dart';
import 'package:trt_tracker/logic/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisierung für Formatter
  await initializeDateFormatting('de_DE', null);

  await DatabaseService().database;
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

      // --- HIER IST DIE MAGIE FÜR DEN WOCHENSTART ---
      locale: const Locale('de', 'DE'), // Erzwingt Deutsch (Montag Start)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'), // Deutsch
        Locale('en', 'US'), // Englisch
      ],

      // ----------------------------------------------
      home: const SplashScreen(),
    );
  }
}
