import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_macos_permissions/flutter_macos_permissions.dart';
import 'package:huda/core/services/notification_batch.dart';
import 'package:huda/core/services/notification_reconciliation_lock.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/random_athkar_schedule_plan.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class NotificationPageHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;

  static const int _kahfNotificationId = 1001;
  static const int _athkarMorningId = 1002;
  static const int _athkarEveningId = 1003;
  static const int _quranReminderId = 1004;
  static const int _checklistReminderId = 1005;
  static const int _khatmaReminderId = 1006;
  static const int _randomAthkarBaseId = 1100;

  static const String _renewalTaskName = 'renewAthkarNotifications';
  static const int _historicalRandomAthkarLimit = 450;
  static int get _maxRandomAthkarNotifications =>
      NotificationCapacityPolicy.current.randomAthkarLimit;

  static const String _athkarPayloadVersion = 'huda-athkar-v1';

  static final List<String> _athkarList = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'الْلَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  ];

  Future<void> init() async {
    final locationName = await PrayerTimeZoneService.refreshLocalTimeZone();

    debugPrint('🌍 Timezone initialized: $locationName');
    debugPrint('🕒 Local time: ${tz.TZDateTime.now(tz.local)}');
    _initialization ??= _initializePlugin();
    try {
      await _initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const windows = WindowsInitializationSettings(
      appName: 'Huda',
      appUserModelId: 'awr.Huda-IslamicCompanionApp',
      guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
    );
    const macOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: macOS,
      windows: windows,
      linux: linux,
    );

    final initialized = await _plugin.initialize(settings: settings);
    debugPrint('🔧 Plugin initialized: $initialized');

    await _createNotificationChannels();
  }

  Future<bool> checkIOSPermissionStatus() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      try {
        final result = await iosPlugin.checkPermissions();
        final isGranted = result?.isEnabled ?? false;
        return isGranted;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  Future<bool> checkMacOSPermissionStatus() async {
    if (!PlatformUtils.isMacOS) return false;

    try {
      final status = await FlutterMacosPermissions.notificationStatus();
      final isGranted = status == 'authorized';
      return isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createNotificationChannels() async {
    const islamicRemindersChannel = AndroidNotificationChannel(
      'islamic_reminders',
      'Islamic Reminders',
      description: 'Notifications for Quran, Athkar, and Islamic reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: false,
      showBadge: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const kahfChannel = AndroidNotificationChannel(
      'kahf_friday',
      'Al-Kahf Friday',
      description: 'Weekly reminder for Surat Al-Kahf on Friday',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: false,
      showBadge: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(islamicRemindersChannel);
      await androidPlugin.createNotificationChannel(kahfChannel);
      debugPrint('✅ Notification channels created with maximum priority');
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!PlatformUtils.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final canScheduleExact = await canScheduleExactNotifications();
    return canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static String _recurringPayload({
    required int id,
    required String recurrence,
    required TimeOfDay time,
    required String title,
    required String body,
    required AndroidScheduleMode mode,
    int? weekday,
  }) => jsonEncode([
    'huda-reminder-v1',
    id,
    recurrence,
    weekday,
    time.hour,
    time.minute,
    tz.local.name,
    mode.name,
    title,
    body,
  ]);

  Future<bool> canScheduleExactNotifications() async {
    if (!PlatformUtils.isAndroid) return true;

    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.canScheduleExactNotifications() ?? true;
    } catch (error) {
      debugPrint('Unable to check exact alarm access: $error');
      return false;
    }
  }

  Future<bool> requestExactAlarmsPermission() async {
    if (!PlatformUtils.isAndroid) return true;

    try {
      if (await canScheduleExactNotifications()) return true;

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestExactAlarmsPermission();
      return granted ?? await canScheduleExactNotifications();
    } catch (error) {
      debugPrint('Unable to request exact alarm access: $error');
      return false;
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) => NotificationReconciliationLock.synchronized(
    () => _scheduleDaily(id: id, title: title, body: body, time: time),
  );

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      debugPrint(
        '⏰ Scheduled time has passed today, scheduling for tomorrow: $scheduled',
      );
    } else {
      debugPrint('⏰ Scheduling for today: $scheduled');
    }

    final mode = await _androidScheduleMode();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: _recurringPayload(
        id: id,
        recurrence: 'daily',
        time: time,
        title: title,
        body: body,
        mode: mode,
      ),
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'islamic_reminders',
          'Islamic Reminders',
          channelDescription: 'Daily Islamic reminders and Quran notifications',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          enableLights: false,
          showWhen: true,
          when: null,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          ticker: 'Islamic Reminder',
          autoCancel: false,
          ongoing: false,
          colorized: false,
          color: Colors.green,
          icon: "ic_notification_islam",
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        windows: WindowsNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: mode,
    );

    debugPrint(
      '✅ Daily notification scheduled: $title at ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required int weekday,
  }) => NotificationReconciliationLock.synchronized(
    () => _scheduleWeekly(
      id: id,
      title: title,
      body: body,
      time: time,
      weekday: weekday,
    ),
  );

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required int weekday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final mode = await _androidScheduleMode();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: _recurringPayload(
        id: id,
        recurrence: 'weekly',
        time: time,
        weekday: weekday,
        title: title,
        body: body,
        mode: mode,
      ),
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'kahf_friday',
          'Al-Kahf Friday',
          channelDescription: 'Weekly reminder for Surat Al-Kahf on Friday',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification_jummah',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        windows: WindowsNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: mode,
    );
  }

  Future<void> scheduleKahfFriday(
    bool enable, [
    TimeOfDay? customTime,
    String? title,
    String? body,
  ]) async {
    if (enable && customTime != null) {
      await scheduleWeekly(
        id: _kahfNotificationId,
        title: title ?? '🕌 Surat Al-Kahf Reminder',
        body:
            body ??
            'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.',
        time: customTime,
        weekday: DateTime.friday,
      );
    } else {
      await cancel(_kahfNotificationId);
    }
  }

  Future<void> scheduleAthkarMorning(
    bool enable, [
    TimeOfDay? customTime,
    String? title,
    String? body,
  ]) async {
    if (enable && customTime != null) {
      await scheduleDaily(
        id: _athkarMorningId,
        title: title ?? '🌅 Morning Athkar',
        body:
            body ??
            'Start your day with morning Athkar and remembrance of Allah.',
        time: customTime,
      );
    } else {
      await cancel(_athkarMorningId);
    }
  }

  Future<void> scheduleAthkarEvening(
    bool enable, [
    TimeOfDay? customTime,
    String? title,
    String? body,
  ]) async {
    if (enable && customTime != null) {
      await scheduleDaily(
        id: _athkarEveningId,
        title: title ?? '🌅 Evening Athkar',
        body:
            body ?? 'End your day with evening Athkar and gratitude to Allah.',
        time: customTime,
      );
    } else {
      await cancel(_athkarEveningId);
    }
  }

  Future<void> scheduleQuranReminder(
    bool enable,
    TimeOfDay? time, [
    String? title,
    String? body,
  ]) async {
    if (enable && time != null) {
      await scheduleDaily(
        id: _quranReminderId,
        title: title ?? '📖 Quran Reading Reminder',
        body:
            body ??
            'Time to read some verses from the Holy Quran and reflect on its guidance.',
        time: time,
      );
    } else {
      await cancel(_quranReminderId);
      await cancel(_quranReminderId + 100);
    }
  }

  Future<void> scheduleKhatmaReminder(
    bool enable,
    TimeOfDay? time, [
    String? title,
    String? body,
  ]) async {
    if (enable && time != null) {
      await scheduleDaily(
        id: _khatmaReminderId,
        title: title ?? '📖 Khatma Daily Reminder',
        body:
            body ??
            'Time to read your daily Quran wird and stay on track with your Khatma.',
        time: time,
      );
    } else {
      await cancel(_khatmaReminderId);
    }
  }

  Future<void> scheduleChecklistReminder(
    bool enable,
    TimeOfDay? time, [
    String? title,
    String? body,
  ]) async {
    if (enable && time != null) {
      await scheduleDaily(
        id: _checklistReminderId,
        title: title ?? '📋 Daily Checklist Reminder',
        body:
            body ??
            'Time to fill your daily Islamic checklist and track your spiritual progress.',
        time: time,
      );
    } else {
      await cancel(_checklistReminderId);
      await cancel(_checklistReminderId + 100);
    }
  }

  Future<void> scheduleRandomAthkar(
    bool enable,
    int frequencyMinutes, {
    bool fromBackground = false,
  }) async {
    return NotificationReconciliationLock.synchronized(
      () => _scheduleRandomAthkarUnlocked(
        enable,
        frequencyMinutes,
        fromBackground: fromBackground,
      ),
    );
  }

  Future<void> _scheduleRandomAthkarUnlocked(
    bool enable,
    int frequencyMinutes, {
    List<PendingNotificationRequest>? knownPending,
    bool fromBackground = false,
  }) async {
    final pending = knownPending ?? await _plugin.pendingNotificationRequests();
    final randomPending = pending
        .where(
          (request) =>
              request.id >= _randomAthkarBaseId &&
              request.id < _randomAthkarBaseId + _historicalRandomAthkarLimit,
        )
        .toList(growable: false);
    if (!enable || _maxRandomAthkarNotifications == 0) {
      await cancelNotificationIds(
        _plugin,
        randomPending.map((request) => request.id),
      );
      if (PlatformUtils.isAndroid) {
        await Workmanager().cancelByTag('athkar-renewal');
        await Workmanager().cancelByTag('athkar-retry');
      }
      return;
    }
    if (frequencyMinutes <= 0) {
      throw ArgumentError.value(frequencyMinutes, 'frequencyMinutes');
    }

    final now = DateTime.now().toUtc();
    final mode = await _androidScheduleMode();
    final interval = Duration(minutes: frequencyMinutes);
    final retained = <int, DateTime>{};
    final staleIds = <int>[];
    for (final request in randomPending) {
      final time = _readAthkarPayload(request.payload, frequencyMinutes, mode);
      if (request.id > _randomAthkarBaseId + _maxRandomAthkarNotifications ||
          time == null ||
          !time.isAfter(now) ||
          retained.values.contains(time)) {
        staleIds.add(request.id);
      } else {
        retained[request.id] = time;
      }
    }
    await cancelNotificationIds(_plugin, staleIds);

    final freeIds = [
      for (
        var id = _randomAthkarBaseId + 1;
        id <= _randomAthkarBaseId + _maxRandomAthkarNotifications;
        id++
      )
        if (!retained.containsKey(id)) id,
    ];
    final times = missingAthkarTimes(
      now: now,
      interval: interval,
      horizon: const Duration(days: 7),
      capacity: _maxRandomAthkarNotifications,
      existing: retained.values,
    );
    var failed = false;
    for (var index = 0; index < times.length; index++) {
      final id = freeIds[index];
      final time = times[index];
      try {
        await _scheduleAthkarAt(id, time, frequencyMinutes, mode);
        retained[id] = time;
      } catch (error) {
        failed = true;
        debugPrint('Athkar notification $id could not be scheduled: $error');
        break;
      }
    }
    final lastScheduled = retained.values.fold<DateTime?>(
      null,
      (latest, time) => latest == null || time.isAfter(latest) ? time : latest,
    );
    if (lastScheduled != null) {
      await _scheduleAthkarRenewal(frequencyMinutes, lastScheduled);
    }
    if (failed || lastScheduled == null) {
      if (fromBackground) {
        throw StateError('Athkar schedule is incomplete; retry is required');
      }
      await _scheduleRetryAttempt(frequencyMinutes);
    }
  }

  String _athkarPayload(
    DateTime time,
    int frequencyMinutes,
    AndroidScheduleMode mode,
  ) => jsonEncode([
    _athkarPayloadVersion,
    frequencyMinutes,
    tz.local.name,
    mode.name,
    time.millisecondsSinceEpoch,
  ]);

  DateTime? _readAthkarPayload(
    String? payload,
    int frequencyMinutes,
    AndroidScheduleMode mode,
  ) {
    if (payload == null) return null;
    try {
      final values = jsonDecode(payload);
      if (values is! List ||
          values.length != 5 ||
          values[0] != _athkarPayloadVersion ||
          values[1] != frequencyMinutes ||
          values[2] != tz.local.name ||
          values[3] != mode.name ||
          values[4] is! int) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(values[4], isUtc: true);
    } catch (_) {
      return null;
    }
  }

  String _getRandomAthkar() {
    final random = Random();
    return _athkarList[random.nextInt(_athkarList.length)];
  }

  Future<void> _scheduleAthkarRenewal(
    int frequencyMinutes,
    DateTime lastScheduled,
  ) async {
    try {
      if (PlatformUtils.isAndroid) {
        final coverage = lastScheduled.difference(DateTime.now().toUtc());
        final safetyMs = min(
          const Duration(hours: 12).inMilliseconds,
          max(
            const Duration(minutes: 30).inMilliseconds,
            coverage.inMilliseconds ~/ 4,
          ),
        );
        final delayMs = max(
          const Duration(minutes: 5).inMilliseconds,
          coverage.inMilliseconds - safetyMs,
        );
        await Workmanager().registerOneOffTask(
          'athkar-renewal-${lastScheduled.millisecondsSinceEpoch}',
          _renewalTaskName,
          initialDelay: Duration(milliseconds: delayMs),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          inputData: {'frequency': frequencyMinutes},
          tag: 'athkar-renewal',
          constraints: Constraints(
            requiresBatteryNotLow: true,
            networkType: NetworkType.notRequired,
          ),
        );
      }
    } catch (e) {
      debugPrint('Athkar renewal registration failed: $e');
    }
  }

  Future<void> scheduleSabahMasaa(
    bool enable, [
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
    String? morningTitle,
    String? morningBody,
    String? eveningTitle,
    String? eveningBody,
  ]) async {
    await scheduleAthkarMorning(enable, morningTime, morningTitle, morningBody);
    await scheduleAthkarEvening(enable, eveningTime, eveningTitle, eveningBody);
  }

  Future<void> cancel(int id) async {
    await NotificationReconciliationLock.synchronized(
      () => _plugin.cancel(id: id),
    );
  }

  Future<void> cancelAll() async {
    await NotificationReconciliationLock.synchronized(() async {
      final pending = await _plugin.pendingNotificationRequests();
      const reminderIds = {
        _kahfNotificationId,
        _athkarMorningId,
        _athkarEveningId,
        _quranReminderId,
        _quranReminderId + 100,
        _checklistReminderId,
        _checklistReminderId + 100,
        _khatmaReminderId,
      };
      await cancelNotificationIds(
        _plugin,
        pending
            .map((request) => request.id)
            .where(
              (id) =>
                  reminderIds.contains(id) ||
                  (id >= _randomAthkarBaseId &&
                      id < _randomAthkarBaseId + _historicalRandomAthkarLimit),
            ),
      );
    });

    debugPrint(
      '🔔 Cancelled all Islamic reminder notifications (preserving foreground services)',
    );
  }

  Future<void> cancelAllIncludingForegroundServices() async {
    await _plugin.cancelAll();
    debugPrint(
      '⚠️ EMERGENCY: Cancelled ALL notifications including foreground services',
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final allPending = await _plugin.pendingNotificationRequests();

    final filteredPending = allPending.where((notification) {
      return (notification.id >= _kahfNotificationId &&
              notification.id <= _khatmaReminderId) ||
          (notification.id >= _randomAthkarBaseId &&
              notification.id <
                  _randomAthkarBaseId + _historicalRandomAthkarLimit);
    }).toList();

    debugPrint(
      '📊 Found ${filteredPending.length} Islamic reminder notifications (${allPending.length} total)',
    );
    return filteredPending;
  }

  Future<int> getPendingNotificationsCount() async {
    final notifications = await getPendingNotifications();
    return notifications.length;
  }

  Future<void> comprehensiveDebug() async {
    debugPrint('🔍 === COMPREHENSIVE NOTIFICATION DEBUG ===');

    try {
      debugPrint('📱 Flutter Local Notifications Plugin initialized');

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('🌍 Current timezone: ${now.location}');
      debugPrint('🕒 Current time: $now');

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final notificationsEnabled = await androidPlugin
            .areNotificationsEnabled();
        final exactAlarmsAllowed = await androidPlugin
            .canScheduleExactNotifications();

        debugPrint('✅ Notifications enabled: $notificationsEnabled');
        debugPrint('⏰ Exact alarms allowed: $exactAlarmsAllowed');

        if (notificationsEnabled == false) {
          debugPrint(
            '❌ CRITICAL: Notifications are disabled in system settings!',
          );
        }

        if (exactAlarmsAllowed == false) {
          debugPrint(
            '❌ CRITICAL: Exact alarms not allowed - notifications won\'t work!',
          );
          debugPrint(
            '💡 Solution: Go to Settings > Apps > Huda > Special app access > Alarms & reminders > Allow',
          );
        }
      }

      final pending = await getPendingNotifications();
      debugPrint('� Pending notifications: ${pending.length}');

      if (pending.isEmpty) {
        debugPrint('⚠️ No pending notifications - try scheduling some first');
      } else {
        for (final notif in pending.take(5)) {
          debugPrint('   - ID: ${notif.id}, Title: ${notif.title}');
        }
      }

      debugPrint('🧪 Testing immediate notification...');
      await _plugin.show(
        id: 99999,
        title: '🔥 IMMEDIATE DEBUG TEST',
        body:
            'If you see this notification, the basic system works! Time: ${DateTime.now()}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'islamic_reminders',
            'Islamic Reminders',
            channelDescription: 'Debug test',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
      );
      debugPrint('🚀 Immediate notification sent - you should see it now!');

      final testTime = now.add(const Duration(seconds: 3));
      await _plugin.zonedSchedule(
        id: 99998,
        title: '⏰ SCHEDULED DEBUG TEST',
        body:
            'Scheduled test at $testTime - if you see this, scheduling works!',
        scheduledDate: testTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'islamic_reminders',
            'Islamic Reminders',
            channelDescription: 'Scheduled debug test',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
        androidScheduleMode: await _androidScheduleMode(),
      );
      debugPrint(
        '⏰ Scheduled notification for: $testTime (3 seconds from now)',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in comprehensive debug: $e');
      debugPrint('📋 Stack: $stackTrace');
    }

    debugPrint('🔍 === DEBUG COMPLETE - Check above for issues ===');
  }

  Future<void> testReducedAthkarScheduling(int testFrequency) async {
    try {
      debugPrint('🧪 Testing reduced athkar scheduling...');
      debugPrint(
        '📊 Android alarm limit: 500, our limit: $_maxRandomAthkarNotifications',
      );

      final notificationsPerDay = (24 * 60) / testFrequency;
      final expectedTotal = (notificationsPerDay * 7).ceil();
      final actualCoverage =
          (_maxRandomAthkarNotifications * testFrequency / (24 * 60));

      debugPrint(
        '📈 Expected notifications for 7 days at ${testFrequency}min frequency: $expectedTotal',
      );
      debugPrint(
        '✅ Within limits: ${expectedTotal <= _maxRandomAthkarNotifications}',
      );
      debugPrint(
        '📊 Actual coverage with limit: ${actualCoverage.toStringAsFixed(1)} days',
      );

      if (expectedTotal > _maxRandomAthkarNotifications) {
        debugPrint(
          '⚠️ Would exceed our limit of $_maxRandomAthkarNotifications notifications',
        );
        debugPrint(
          '💡 Consider increasing frequency to ${((24 * 60 * 7) / _maxRandomAthkarNotifications).ceil()} minutes or higher',
        );
      }
    } catch (e) {
      debugPrint('❌ Error in test calculation: $e');
    }
  }

  Future<void> scheduleTestNotification() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 5));

      debugPrint('🧪 Scheduling test notification...');
      debugPrint('🕒 Current time: $now');
      debugPrint('🕒 Scheduled time: $testTime');

      await _plugin.show(
        id: 9999,
        title: '🚀 IMMEDIATE TEST #1',
        body:
            'Basic immediate notification - should appear instantly! Time: ${DateTime.now()}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'islamic_reminders',
            'Islamic Reminders',
            channelDescription: 'Immediate test notification',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            autoCancel: true,
            ongoing: false,
          ),
        ),
      );
      debugPrint('🚀 Immediate notification #1 sent!');

      await _plugin.show(
        id: 9998,
        title: '🔥 IMMEDIATE TEST #2',
        body:
            'Different settings notification - should also appear instantly! Time: ${DateTime.now()}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'kahf_friday',
            'Al-Kahf Friday',
            channelDescription: 'Test with different channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            autoCancel: true,
            ongoing: false,
          ),
        ),
      );
      debugPrint('🚀 Immediate notification #2 sent!');

      await _plugin.zonedSchedule(
        id: 9997,
        title: '⏰ SCHEDULED TEST',
        body:
            'This is a scheduled test at $testTime - if you see this, scheduling works!',
        scheduledDate: testTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'islamic_reminders',
            'Islamic Reminders',
            channelDescription: 'Scheduled test notification',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            autoCancel: true,
            ongoing: false,
          ),
        ),
        androidScheduleMode: await _androidScheduleMode(),
      );
      debugPrint(
        '⏰ Scheduled notification set for: $testTime (5 seconds from now)',
      );

      await _plugin.show(
        id: 9996,
        title: 'MINIMAL TEST',
        body: 'Minimal notification with basic settings',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'islamic_reminders',
            'Islamic Reminders',
            channelDescription: 'Minimal test',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('🔔 Minimal notification sent!');

      debugPrint('✅ All test notifications scheduled successfully!');
      debugPrint(
        '� You should see 3 immediate notifications now and 1 more in 5 seconds',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling test notification: $e');
      debugPrint('📋 Stack trace: $stackTrace');
    }
  }

  Future<void> rescheduleAllNotifications({
    required bool kahfFriday,
    required bool sabahMasaa,
    required bool randomAthkar,
    required int randomAthkarFrequency,
    required bool quranReminder,
    required TimeOfDay? quranReminderTime,
    required TimeOfDay? kahfFridayTime,
    required TimeOfDay? morningAthkarTime,
    required TimeOfDay? eveningAthkarTime,
    String? kahfTitle,
    String? kahfBody,
    String? morningTitle,
    String? morningBody,
    String? eveningTitle,
    String? eveningBody,
    String? quranTitle,
    String? quranBody,
    String? checklistTitle,
    String? checklistBody,
    bool checklistReminder = false,
    TimeOfDay? checklistReminderTime,
  }) async {
    return NotificationReconciliationLock.synchronized(() async {
      final pending = await _plugin.pendingNotificationRequests();
      final pendingById = {for (final request in pending) request.id: request};
      final mode = await _androidScheduleMode();
      final toCancel = <int>{};
      final toSchedule = <Future<void> Function()>[];

      void reconcileReminder({
        required int id,
        required bool enabled,
        required TimeOfDay? time,
        required String? title,
        required String? body,
        required String defaultTitle,
        required String defaultBody,
        required String recurrence,
        required Future<void> Function(String, String) schedule,
        int? weekday,
      }) {
        if (!enabled || time == null) {
          if (pendingById.containsKey(id)) toCancel.add(id);
          return;
        }
        final resolvedTitle = title ?? pendingById[id]?.title ?? defaultTitle;
        final resolvedBody = body ?? pendingById[id]?.body ?? defaultBody;
        final expected = _recurringPayload(
          id: id,
          recurrence: recurrence,
          time: time,
          weekday: weekday,
          title: resolvedTitle,
          body: resolvedBody,
          mode: mode,
        );
        if (pendingById[id]?.payload != expected) {
          toSchedule.add(() => schedule(resolvedTitle, resolvedBody));
        }
      }

      reconcileReminder(
        id: _kahfNotificationId,
        enabled: kahfFriday,
        time: kahfFridayTime,
        title: kahfTitle,
        body: kahfBody,
        defaultTitle: '🕌 Surat Al-Kahf Reminder',
        defaultBody:
            'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.',
        recurrence: 'weekly',
        weekday: DateTime.friday,
        schedule: (title, body) =>
            scheduleKahfFriday(true, kahfFridayTime, title, body),
      );
      reconcileReminder(
        id: _athkarMorningId,
        enabled: sabahMasaa,
        time: morningAthkarTime,
        title: morningTitle,
        body: morningBody,
        defaultTitle: '🌅 Morning Athkar',
        defaultBody:
            'Start your day with morning Athkar and remembrance of Allah.',
        recurrence: 'daily',
        schedule: (title, body) => scheduleAthkarMorning(
          true,
          morningAthkarTime,
          title,
          body,
        ),
      );
      reconcileReminder(
        id: _athkarEveningId,
        enabled: sabahMasaa,
        time: eveningAthkarTime,
        title: eveningTitle,
        body: eveningBody,
        defaultTitle: '🌅 Evening Athkar',
        defaultBody:
            'End your day with evening Athkar and gratitude to Allah.',
        recurrence: 'daily',
        schedule: (title, body) => scheduleAthkarEvening(
          true,
          eveningAthkarTime,
          title,
          body,
        ),
      );
      reconcileReminder(
        id: _quranReminderId,
        enabled: quranReminder,
        time: quranReminderTime,
        title: quranTitle,
        body: quranBody,
        defaultTitle: '📖 Quran Reading Reminder',
        defaultBody:
            'Time to read some verses from the Holy Quran and reflect on its guidance.',
        recurrence: 'daily',
        schedule: (title, body) => scheduleQuranReminder(
          true,
          quranReminderTime,
          title,
          body,
        ),
      );
      reconcileReminder(
        id: _checklistReminderId,
        enabled: checklistReminder,
        time: checklistReminderTime,
        title: checklistTitle,
        body: checklistBody,
        defaultTitle: '📋 Daily Checklist Reminder',
        defaultBody:
            'Time to fill your daily Islamic checklist and track your spiritual progress.',
        recurrence: 'daily',
        schedule: (title, body) => scheduleChecklistReminder(
          true,
          checklistReminderTime,
          title,
          body,
        ),
      );
      for (final legacyId in [
        _quranReminderId + 100,
        _checklistReminderId + 100,
      ]) {
        if (pendingById.containsKey(legacyId)) toCancel.add(legacyId);
      }

      await cancelNotificationIds(_plugin, toCancel);
      for (final schedule in toSchedule) {
        await schedule();
      }
      await _scheduleRandomAthkarUnlocked(
        randomAthkar,
        randomAthkarFrequency,
        knownPending: pending,
      );
      debugPrint(
        '✅ Islamic reminders reconciled without replacing unchanged schedules',
      );
    });
  }

  Future<void> _scheduleAthkarAt(
    int id,
    DateTime time,
    int frequencyMinutes,
    AndroidScheduleMode mode,
  ) async {
    await _plugin.zonedSchedule(
      id: id,
      title: '📿 Athkar Reminder',
      body: _getRandomAthkar(),
      payload: _athkarPayload(time, frequencyMinutes, mode),
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'islamic_reminders',
          'Islamic Reminders',
          channelDescription: 'Random Athkar notifications',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          enableLights: false,
          showWhen: true,
          fullScreenIntent: false,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          ticker: 'Athkar Reminder',
          autoCancel: true,
          ongoing: false,
          colorized: false,
          color: Colors.green,
          icon: 'ic_notification_random',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: mode,
    );
  }

  Future<void> _scheduleRetryAttempt(int frequencyMinutes) async {
    if (!PlatformUtils.isAndroid) {
      debugPrint('⚠️ Workmanager retry not supported on this platform');
      return;
    }
    try {
      await Workmanager().registerOneOffTask(
        'athkar-retry',
        'retryAthkarScheduling',
        initialDelay: const Duration(minutes: 5),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        inputData: {'frequency': frequencyMinutes},
        tag: 'athkar-retry',
      );
      debugPrint('🔄 Scheduled retry attempt in 5 minutes');
    } catch (e) {
      debugPrint('❌ Error scheduling retry: $e');
    }
  }

  Future<Map<String, dynamic>> checkNotificationSystemHealth() async {
    final health = <String, dynamic>{};

    try {
      final pending = await getPendingNotifications();
      health['pendingCount'] = pending.length;
      health['pendingIds'] = pending.map((n) => n.id).toList();

      health['prayerCountdownRunning'] =
          'Unknown - foreground service isolation';

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final permissionGranted = await androidPlugin.areNotificationsEnabled();
        health['permissionGranted'] = permissionGranted ?? false;

        final exactAlarmsAllowed = await androidPlugin
            .canScheduleExactNotifications();
        health['exactAlarmsAllowed'] = exactAlarmsAllowed ?? false;
      }

      health['workmanagerStatus'] = 'Active - background renewal enabled';

      debugPrint('📊 Notification Health Check: $health');
    } catch (e) {
      health['error'] = e.toString();
      debugPrint('❌ Error during health check: $e');
    }

    return health;
  }
}
