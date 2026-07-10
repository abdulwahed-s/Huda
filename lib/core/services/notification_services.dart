import 'dart:io';

import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:huda/core/services/notification_isolate_helper.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationServices {
  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();

  bool isInitialized = false;

  static const int _prayerNotificationBaseId = 2000;
  static const int _fajrId = 2001;
  static const int _dhuhrId = 2002;
  static const int _asrId = 2003;
  static const int _maghribId = 2004;
  static const int _ishaId = 2005;

  bool get isReady => isInitialized;

  Future<void> initialize() async {
    if (isInitialized) return;

    tz.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Huda',
      appUserModelId: 'awr.Huda-IslamicCompanionApp',
      guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
    );

    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      windows: initializationSettingsWindows,
      linux: initializationSettingsLinux,
    );

    await notificationPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final iosPlugin = notificationPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      debugPrint('Requesting iOS notification permissions on app startup...');
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permission result: $result');
    }

    await _createNotificationChannel();

    isInitialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    App.navigatorKey.currentState?.pushNamed('/prayerTimes');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_times_channel',
      'Prayer Times',
      description: 'Notifications for daily prayer times (Adhan)',
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('azan_sound'),
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(prayerChannel);
    debugPrint(
        '✅ Prayer times notification channel created (isolated from Islamic reminders)');
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_times_channel',
        'Prayer Times',
        channelDescription: 'Notifications for prayer times',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan_sound'),
        icon: 'ic_pray_notification',
        color: Color(0xFF98FB98),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'adhan.caf',
      ),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    await notificationPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    final prayerNotificationId = _getPrayerNotificationId(title, id);

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Prayer notification for $title skipped - time has passed');
      return;
    }

    try {
      await notificationPlugin.zonedSchedule(
        prayerNotificationId,
        title,
        body,
        tzScheduledTime,
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
          '✅ Prayer notification scheduled for $title at $scheduledTime (ID: $prayerNotificationId)');
    } catch (e) {
      debugPrint('❌ Error scheduling prayer notification for $title: $e');

      try {
        await notificationPlugin.zonedSchedule(
          prayerNotificationId,
          title,
          body,
          tzScheduledTime,
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exact,
        );
        debugPrint(
            '✅ Prayer notification scheduled (fallback mode) for $title');
      } catch (fallbackError) {
        debugPrint(
            '❌ Fallback prayer notification also failed for $title: $fallbackError');
      }
    }
  }

  int _getPrayerNotificationIdWithDate(Prayer prayer, int dayOffset) {
    const baseIds = {
      Prayer.fajr: 2100,
      Prayer.dhuhr: 2200,
      Prayer.asr: 2300,
      Prayer.maghrib: 2400,
      Prayer.isha: 2500,
    };

    return (baseIds[prayer] ?? 2000) + dayOffset;
  }

  Future<void> schedulePrayerNotificationWithDate({
    required Prayer prayer,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int dayOffset,
  }) async {
    if (!isInitialized) {
      await initialize();
    }

    final prayerNotificationId =
        _getPrayerNotificationIdWithDate(prayer, dayOffset);

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Prayer notification for $title skipped - time has passed');
      return;
    }

    try {
      await notificationPlugin.zonedSchedule(
        prayerNotificationId,
        title,
        body,
        tzScheduledTime,
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
          '✅ Prayer notification scheduled for $title at $scheduledTime (ID: $prayerNotificationId, Day: $dayOffset)');
    } catch (e) {
      debugPrint('❌ Error scheduling prayer notification for $title: $e');

      try {
        await notificationPlugin.zonedSchedule(
          prayerNotificationId,
          title,
          body,
          tzScheduledTime,
          notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exact,
        );
        debugPrint(
            '✅ Prayer notification scheduled (fallback mode) for $title');
      } catch (fallbackError) {
        debugPrint(
            '❌ Fallback prayer notification also failed for $title: $fallbackError');
      }
    }
  }

  int _getPrayerNotificationId(String prayerName, int fallbackId) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return _fajrId;
      case 'dhuhr':
        return _dhuhrId;
      case 'asr':
        return _asrId;
      case 'maghrib':
        return _maghribId;
      case 'isha':
        return _ishaId;
      default:
        return _prayerNotificationBaseId + fallbackId;
    }
  }

  Future<void> cancelAllNotifications() async {
    await cancelAllPrayerNotifications();
    debugPrint(
        '🔔 Cancelled all prayer time notifications (preserving Islamic reminders)');
  }

  Future<void> cancelAllPrayerNotifications() async {
    if (Platform.isWindows) {
      await windowsCancelAllAndRescheduleFixed(notificationPlugin);
    } else {
      final ids = <int>[
        _fajrId,
        _dhuhrId,
        _asrId,
        _maghribId,
        _ishaId,
        for (int i = _prayerNotificationBaseId;
            i <= _prayerNotificationBaseId + 10;
            i++)
          i,
        for (int day = 0; day < 30; day++) ...[
          2100 + day,
          2200 + day,
          2300 + day,
          2400 + day,
          2500 + day,
        ],
      ];
      for (final id in ids) {
        await notificationPlugin.cancel(id);
      }
    }

    debugPrint(
        '🕌 All prayer time notifications cancelled (including multi-day)');
  }

  Future<void> cancelAllNotificationsIncludingIslamicReminders() async {
    await notificationPlugin.cancelAll();
    debugPrint(
        '⚠️ EMERGENCY: All notifications cancelled (including Islamic reminders)');
  }

  Future<void> cancelNotification(int id) async {
    await notificationPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final allPending = await notificationPlugin.pendingNotificationRequests();

    final prayerNotifications = allPending.where((notification) {
      final id = notification.id;
      return (id >= _prayerNotificationBaseId &&
              id <= _prayerNotificationBaseId + 10) ||
          [_fajrId, _dhuhrId, _asrId, _maghribId, _ishaId].contains(id) ||
          (id >= 2100 && id <= 2599);
    }).toList();

    debugPrint(
        '📊 Found ${prayerNotifications.length} prayer time notifications');
    return prayerNotifications;
  }
}
