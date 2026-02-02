import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    debugPrint("🔵 INIT: Starte Notification Service...");

    // Zeitzone ermitteln
    String timeZoneName;
    try {
      var result = await FlutterTimezone.getLocalTimezone();
      timeZoneName = result.toString();
    } catch (e) {
      debugPrint("⚠️ FEHLER beim Lesen der Zeitzone: $e");
      timeZoneName = 'UTC';
    }

    // Location setzen
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("✅ INIT: Zeitzone erfolgreich auf '$timeZoneName' gesetzt.");

      // Test: Was ist "Jetzt" in dieser Zeitzone?
      final nowTz = tz.TZDateTime.now(tz.local);
      debugPrint(
        "🕒 INIT: Lokale Zeit laut System ist: $nowTz (Offset: ${nowTz.timeZoneOffset})",
      );
    } catch (e) {
      debugPrint(
        "⚠️ INIT: Zeitzone '$timeZoneName' nicht gefunden. Fallback auf UTC/Berlin.",
      );
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notification geklickt: ${response.payload}");
      },
    );
  }

  Future<bool?> checkPermissionStatus() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? enabled = await androidImplementation
        ?.areNotificationsEnabled();
    debugPrint("🔍 DIAGNOSE: Notifications erlaubt? $enabled");
    return enabled;
  }

  Future<void> requestPermissions() async {
    debugPrint("🔵 Frage Berechtigungen an...");
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? grantedNotif = await androidImplementation
          ?.requestNotificationsPermission();
      debugPrint("👉 Push-Permission Result: $grantedNotif");

      await androidImplementation?.requestExactAlarmsPermission();
      debugPrint("👉 Exact-Alarm Permission angefordert");
    }
  }

  Future<void> showInstantNotification() async {
    debugPrint("🚀 Versuche SOFORT-TEST-Nachricht zu senden...");
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'trt_test_channel',
          'Test Channel',
          channelDescription: 'Kanal für Funktionstests',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        999,
        'Test Nachricht',
        'Dies ist ein Test!',
        platformChannelSpecifics,
      );
      debugPrint("✅ SOFORT-TEST: Befehl an System übergeben.");
    } catch (e) {
      debugPrint("❌ SOFORT-TEST FEHLER: $e");
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // ... (Zeit-Check und TZ-Umwandlung wie gehabt) ...
    // ...
    tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint("📅 Geplanter Alarm für: $tzDate");

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'trt_reminders_final', // Neuer Channel Name
            'TRT Erinnerung',
            channelDescription: 'Erinnerungen für Injektionen',
            importance: Importance.max,
            priority: Priority.high,

            // HIER IST DER FIX: Wir nutzen das PNG aus dem drawable Ordner!
            // Das '@mipmap/ic_launcher' ist oft fehlerhaft bei Alarmen.
            icon: 'app_icon',

            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),

        // Wir gehen auf exactAllowWhileIdle zurück, das ist zuverlässig genug für Notifications
        // (AlarmClock ist manchmal zickig mit Bannern)
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint("✅ NOTIFICATION GEPLANT (Icon: app_icon.png)");
    } catch (e) {
      debugPrint("❌ FATALER FEHLER: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint("🗑️ Notification gecancelt (ID: $id)");
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
