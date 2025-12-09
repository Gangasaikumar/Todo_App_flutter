import 'dart:async';
import 'dart:io';
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
        if (kDebugMode) {
          debugPrint('Could not set location to Asia/Kolkata, using UTC: $e');
        }
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      const WindowsInitializationSettings initializationSettingsWindows =
          WindowsInitializationSettings(
            appName: 'Daily Focus',
            appUserModelId: 'com.example.daily_focus',
            guid: 'a26517b0-f6cd-49eb-b877-543f62e0b1fb',
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            linux: initializationSettingsLinux,
            windows: initializationSettingsWindows,
          );

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
      if (kDebugMode) {
        debugPrint('NotificationService init failed: $e');
      }
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
      // On non-Android platforms, we assume permissions are either not needed or handled differently for now
      // For Windows, creating the local notification doesn't require run-time permission in the same way
      return !Platform.isAndroid;
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
      'App opened',
      'He Hi welcome to our app!',
      notificationDetails,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
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
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Use a unique ID based on time to avoid overwriting
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
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
        if (kDebugMode) {
          debugPrint('Exact Alarm Permission Granted: $exactAlarmGranted');
        }
        if (exactAlarmGranted == false) {
          if (kDebugMode) {
            debugPrint(
              'WARNING: Exact alarms not granted. Notification might be delayed or not shown.',
            );
          }
        }
      }

      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

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
      if (kDebugMode) {
        debugPrint('✅ Notification scheduled successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error scheduling notification: $e');
      }
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
