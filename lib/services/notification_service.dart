import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();

  factory AppNotificationService() {
    return _instance;
  }

  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (e) {
        debugPrint('Could not set location to Asia/Kolkata, using UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
              // Handle notification tap
            },
      );

      // Create the notification channel explicitly for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'task_reminders_v2', // ID
        'Task Reminders V2', // title
        description: 'Notifications for task reminders', // description
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    await init();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) {
      return false;
    }

    final bool? exactAlarmGranted = await androidImplementation
        .requestExactAlarmsPermission();

    final bool? notificationGranted = await androidImplementation
        .requestNotificationsPermission();

    return (exactAlarmGranted ?? true) && (notificationGranted ?? true);
  }

  Future<void> showImmediateNotification() async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders_v2',
          'Task Reminders V2',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'If you see this, notifications are working!',
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await init();

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? exactAlarmGranted = await androidImplementation
            .requestExactAlarmsPermission();
        debugPrint('Exact Alarm Permission Granted: $exactAlarmGranted');
        if (exactAlarmGranted == false) {
          debugPrint(
            'WARNING: Exact alarms not granted. Notification might be delayed or not shown.',
          );
        }
      }

      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      debugPrint('=== NOTIFICATION SCHEDULING DEBUG ===');
      debugPrint('ID: $id');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Scheduled DateTime (input): $scheduledDate');
      debugPrint('Scheduled TZDateTime (converted): $scheduledTZDate');
      debugPrint('Current DateTime: ${DateTime.now()}');
      debugPrint('Current TZDateTime: ${tz.TZDateTime.now(tz.local)}');
      debugPrint(
        'Time until notification: ${scheduledTZDate.difference(tz.TZDateTime.now(tz.local))}',
      );
      debugPrint('=====================================');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders_v2',
            'Task Reminders V2',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('✅ Notification scheduled successfully!');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await init();
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await init();
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
