import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

class NotificationServices implements PrayerNotificationGateway {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;
  static String _timeZoneName = 'UTC';

  FlutterLocalNotificationsPlugin get notificationPlugin => _plugin;
  bool get isReady => _initialization != null;

  @override
  String get timeZoneName => _timeZoneName;

  @override
  Future<void> initialize() async {
    _initialization ??= _initializePlugin();
    try {
      await _initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    PrayerTimeZoneService.initializeDatabase();
    await refreshTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      windows: WindowsInitializationSettings(
        appName: 'Huda',
        appUserModelId: 'awr.Huda-IslamicCompanionApp',
        guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
      ),
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _createNotificationChannel();
  }

  @override
  Future<String> refreshTimeZone() async {
    _timeZoneName = await PrayerTimeZoneService.refreshLocalTimeZone();
    return _timeZoneName;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    App.navigatorKey.currentState?.pushNamed('/prayerTimes');
  }

  @override
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return (await ios?.checkPermissions())?.isEnabled ?? false;
    }
    if (Platform.isMacOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      return (await mac?.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> canScheduleExactNotifications() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
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
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
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
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'adhan.caf',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      windows: WindowsNotificationDetails(
        duration: WindowsNotificationDuration.long,
      ),
      linux: LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      ),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(id, title, body, notificationDetails());
  }

  @override
  Future<bool> schedulePrayerEvent(PrayerNotificationEvent event) async {
    await initialize();
    final now = DateTime.now().toUtc();
    final scheduled = event.scheduledDateTime;
    if (!event.scheduledInstantUtc.isAfter(now)) {
      return false;
    }

    var mode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid && !await canScheduleExactNotifications()) {
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    try {
      await _plugin.zonedSchedule(
        event.id,
        event.title,
        event.body,
        scheduled,
        notificationDetails(),
        payload: event.payload,
        androidScheduleMode: mode,
      );
      return true;
    } catch (error) {
      if (Platform.isAndroid &&
          mode != AndroidScheduleMode.inexactAllowWhileIdle) {
        try {
          await _plugin.zonedSchedule(
            event.id,
            event.title,
            event.body,
            scheduled,
            notificationDetails(),
            payload: event.payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          return true;
        } catch (fallbackError) {
          debugPrint('Prayer notification fallback failed: $fallbackError');
        }
      } else {
        debugPrint('Prayer notification scheduling failed: $error');
      }
      return false;
    }
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();
    await refreshTimeZone();
    await schedulePrayerEvent(PrayerNotificationEvent(
      id: 2000 + id,
      prayer: Prayer.none,
      scheduledTime: scheduledTime,
      scheduledInstantUtc: PrayerTimeZoneService.fromWallClock(
        scheduledTime,
        _timeZoneName,
      ).toUtc(),
      timeZoneName: _timeZoneName,
      title: title,
      body: body,
    ));
  }

  Future<void> schedulePrayerNotificationWithDate({
    required Prayer prayer,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int dayOffset,
  }) async {
    await initialize();
    await refreshTimeZone();
    await schedulePrayerEvent(PrayerNotificationEvent(
      id: PrayerNotificationEvent.idFor(scheduledTime, prayer),
      prayer: prayer,
      scheduledTime: scheduledTime,
      scheduledInstantUtc: PrayerTimeZoneService.fromWallClock(
        scheduledTime,
        _timeZoneName,
      ).toUtc(),
      timeZoneName: _timeZoneName,
      title: title,
      body: body,
    ));
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    await initialize();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelNotifications(Iterable<int> ids) async {
    await initialize();
    for (final id in ids.toSet()) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAllPrayerNotifications() async {
    final pending = await pendingNotificationRequests();
    await cancelNotifications(
      pending.map((request) => request.id).where(
            PrayerNotificationEvent.isPrayerId,
          ),
    );

    await cancelNotifications([
      for (var id = 2000; id <= 2599; id++) id,
    ]);
  }

  Future<void> cancelAllNotifications() => cancelAllPrayerNotifications();

  Future<void> cancelAllNotificationsIncludingIslamicReminders() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await pendingNotificationRequests();
    return pending
        .where((request) => PrayerNotificationEvent.isPrayerId(request.id))
        .toList(growable: false);
  }
}
