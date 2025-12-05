import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class CalendarNotificationService {
  static final CalendarNotificationService _instance =
      CalendarNotificationService._internal();

  factory CalendarNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  CalendarNotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));
    const android = AndroidInitializationSettings('ic_calendar_notification');
    const windows = WindowsInitializationSettings(
      appName: 'Huda',
      appUserModelId: 'com.huda.app',
      guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
    );
    const settings = InitializationSettings(android: android, windows: windows);

    await _plugin.initialize(settings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required Color color,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminder',
          'Event Reminder',
          importance: Importance.max,
          priority: Priority.high,
          color: color,
          icon: 'ic_calendar_notification',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> sendImmediateNotification() async {
    await _plugin.show(
      0,
      "Immediate Notification",
      "This shows immediately on Windows",
      const NotificationDetails(windows: WindowsNotificationDetails()),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
