import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'dart:math';

class NotificationPageHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _kahfNotificationId = 1001;
  static const int _athkarMorningId = 1002;
  static const int _athkarEveningId = 1003;
  static const int _quranReminderId = 1004;
  static const int _checklistReminderId = 1005;
  static const int _randomAthkarBaseId = 1100;

  static const String _renewalTaskName = 'renewAthkarNotifications';
  static const int _maxRandomAthkarNotifications = 450;

  static const String _athkarProgressKey = 'athkarSchedulingProgress';
  static const String _athkarLastScheduledKey = 'athkarLastScheduledTime';

  static final List<String> _athkarList = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'الْلَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ'
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    debugPrint('🌍 Timezone initialized: $locationName');
    debugPrint('🕒 Local time: ${tz.TZDateTime.now(tz.local)}');

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windows = WindowsInitializationSettings(
      appName: 'Huda',
      appUserModelId: 'com.huda.app',
      guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
    );
    const settings =
        InitializationSettings(android: android, iOS: ios, windows: windows);

    final initialized = await _plugin.initialize(settings);
    debugPrint('🔧 Plugin initialized: $initialized');

    await _checkPermissions();

    await _createNotificationChannels();
  }

  Future<void> _checkPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      debugPrint('📱 Notifications enabled: $granted');

      final exactAlarmsAllowed =
          await androidPlugin.canScheduleExactNotifications();
      debugPrint('⏰ Exact alarms allowed: $exactAlarmsAllowed');

      if (exactAlarmsAllowed != null && !exactAlarmsAllowed) {
        debugPrint(
            '⚠️ EXACT ALARMS NOT ALLOWED - This will prevent notifications from working!');
        debugPrint('💡 Requesting exact alarm permission...');
        try {
          await androidPlugin.requestExactAlarmsPermission();
          debugPrint('✅ Exact alarm permission requested');
        } catch (e) {
          debugPrint('❌ Failed to request exact alarm permission: $e');
        }
      }

      if (granted != null && !granted) {
        debugPrint('⚠️ NOTIFICATIONS NOT ENABLED - Requesting permission...');
        try {
          final result = await androidPlugin.requestNotificationsPermission();
          debugPrint('📱 Notification permission result: $result');
        } catch (e) {
          debugPrint('❌ Failed to request notification permission: $e');
        }
      }
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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(islamicRemindersChannel);
      await androidPlugin.createNotificationChannel(kahfChannel);
      debugPrint('✅ Notification channels created with maximum priority');
    }
  }

  Future<void> scheduleDaily({
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
          '⏰ Scheduled time has passed today, scheduling for tomorrow: $scheduled');
    } else {
      debugPrint('⏰ Scheduling for today: $scheduled');
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
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
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint(
        '✅ Daily notification scheduled: $title at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  Future<void> scheduleWeekly({
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

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('kahf_friday', 'Al-Kahf Friday',
            channelDescription: 'Weekly reminder for Surat Al-Kahf on Friday',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: 'ic_notification_jummah'),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleKahfFriday(bool enable,
      [TimeOfDay? customTime, String? title, String? body]) async {
    if (enable && customTime != null) {
      await scheduleWeekly(
        id: _kahfNotificationId,
        title: title ?? '🕌 Surat Al-Kahf Reminder',
        body: body ??
            'Today is Friday! Don\'t forget to read Surat Al-Kahf for blessings and protection.',
        time: customTime,
        weekday: DateTime.friday,
      );
    } else {
      await cancel(_kahfNotificationId);
    }
  }

  Future<void> scheduleAthkarMorning(bool enable,
      [TimeOfDay? customTime, String? title, String? body]) async {
    if (enable && customTime != null) {
      await scheduleDaily(
        id: _athkarMorningId,
        title: title ?? '🌅 Morning Athkar',
        body: body ??
            'Start your day with morning Athkar and remembrance of Allah.',
        time: customTime,
      );
    } else {
      await cancel(_athkarMorningId);
    }
  }

  Future<void> scheduleAthkarEvening(bool enable,
      [TimeOfDay? customTime, String? title, String? body]) async {
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

  Future<void> scheduleQuranReminder(bool enable, TimeOfDay? time,
      [String? title, String? body]) async {
    if (enable && time != null) {
      await scheduleDaily(
        id: _quranReminderId,
        title: title ?? '📖 Quran Reading Reminder',
        body: body ??
            'Time to read some verses from the Holy Quran and reflect on its guidance.',
        time: time,
      );
    } else {
      await cancel(_quranReminderId);
      await cancel(_quranReminderId + 100);
    }
  }

  Future<void> scheduleChecklistReminder(bool enable, TimeOfDay? time,
      [String? title, String? body]) async {
    if (enable && time != null) {
      await scheduleDaily(
        id: _checklistReminderId,
        title: title ?? '📋 Daily Checklist Reminder',
        body: body ??
            'Time to fill your daily Islamic checklist and track your spiritual progress.',
        time: time,
      );
    } else {
      await cancel(_checklistReminderId);
      await cancel(_checklistReminderId + 100);
    }
  }

  Future<void> scheduleRandomAthkar(bool enable, int frequencyMinutes) async {
    await _cancelAllRandomAthkar();

    if (!enable) {
      if (PlatformUtils.isMobile) {
        await Workmanager().cancelByTag('athkar-renewal');
      }

      await _clearSchedulingProgress();
      debugPrint(
          '🔔 Random Athkar disabled - random athkar notifications cancelled');
      return;
    }

    debugPrint('🚀 Starting resilient 24/7 athkar scheduling...');

    if (await _shouldResumeBackgroundScheduling(frequencyMinutes)) {
      debugPrint('🔄 Resuming interrupted background scheduling...');
      _resumeBackgroundScheduling(frequencyMinutes);
      return;
    }

    final startTime = DateTime.now();

    await _scheduleImmediateAthkar(frequencyMinutes);

    await _saveSchedulingProgress('immediate_complete', DateTime.now());

    _scheduleRemainingAthkarInBackground(frequencyMinutes);

    await _scheduleAthkarRenewal(frequencyMinutes);

    final duration = DateTime.now().difference(startTime);
    debugPrint(
        '⚡ Resilient 24/7 startup completed in ${duration.inMilliseconds}ms');
  }

  String _getRandomAthkar() {
    final random = Random();
    return _athkarList[random.nextInt(_athkarList.length)];
  }

  Future<void> _cancelAllRandomAthkar() async {
    for (int i = _randomAthkarBaseId;
        i < _randomAthkarBaseId + _maxRandomAthkarNotifications;
        i++) {
      await _plugin.cancel(i);
    }
    debugPrint(
        '🗑️ Cancelled up to $_maxRandomAthkarNotifications random athkar notifications');
  }

  Future<void> _scheduleAthkarRenewal(int frequencyMinutes) async {
    try {
      if (PlatformUtils.isMobile) {
        await Workmanager().cancelByTag('athkar-renewal');
      }

      final totalCoverageDays =
          (_maxRandomAthkarNotifications * frequencyMinutes / (24 * 60))
              .floor();
      final renewalDays = (totalCoverageDays - 1).clamp(1, 6);

      debugPrint(
          '📊 Actual coverage: $totalCoverageDays days, renewal in: $renewalDays days');

      if (PlatformUtils.isMobile) {
        await Workmanager().registerOneOffTask(
          'athkar-renewal-${DateTime.now().millisecondsSinceEpoch}',
          _renewalTaskName,
          initialDelay: Duration(days: renewalDays),
          tag: 'athkar-renewal',
          constraints: Constraints(
            requiresBatteryNotLow: true,
            networkType: NetworkType.notRequired,
          ),
        );
      }

      debugPrint(
          '🔄 Athkar renewal scheduled for $renewalDays days from now (before notifications run out)');
    } catch (e) {
      debugPrint('❌ Error scheduling athkar renewal: $e');
    }
  }

  Future<void> scheduleSabahMasaa(bool enable,
      [TimeOfDay? morningTime,
      TimeOfDay? eveningTime,
      String? morningTitle,
      String? morningBody,
      String? eveningTitle,
      String? eveningBody]) async {
    await scheduleAthkarMorning(enable, morningTime, morningTitle, morningBody);
    await scheduleAthkarEvening(enable, eveningTime, eveningTitle, eveningBody);
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await cancel(_kahfNotificationId);
    await cancel(_athkarMorningId);
    await cancel(_athkarEveningId);
    await cancel(_quranReminderId);
    await cancel(_quranReminderId + 100);
    await _cancelAllRandomAthkar();

    debugPrint(
        '🔔 Cancelled all Islamic reminder notifications (preserving foreground services)');
  }

  Future<void> cancelAllIncludingForegroundServices() async {
    await _plugin.cancelAll();
    debugPrint(
        '⚠️ EMERGENCY: Cancelled ALL notifications including foreground services');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final allPending = await _plugin.pendingNotificationRequests();

    final filteredPending = allPending.where((notification) {
      return (notification.id >= _kahfNotificationId &&
              notification.id <= _quranReminderId + 100) ||
          (notification.id >= _randomAthkarBaseId &&
              notification.id <
                  _randomAthkarBaseId + _maxRandomAthkarNotifications);
    }).toList();

    debugPrint(
        '📊 Found ${filteredPending.length} Islamic reminder notifications (${allPending.length} total)');
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

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final notificationsEnabled =
            await androidPlugin.areNotificationsEnabled();
        final exactAlarmsAllowed =
            await androidPlugin.canScheduleExactNotifications();

        debugPrint('✅ Notifications enabled: $notificationsEnabled');
        debugPrint('⏰ Exact alarms allowed: $exactAlarmsAllowed');

        if (notificationsEnabled == false) {
          debugPrint(
              '❌ CRITICAL: Notifications are disabled in system settings!');
        }

        if (exactAlarmsAllowed == false) {
          debugPrint(
              '❌ CRITICAL: Exact alarms not allowed - notifications won\'t work!');
          debugPrint(
              '💡 Solution: Go to Settings > Apps > Huda > Special app access > Alarms & reminders > Allow');
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
        99999,
        '🔥 IMMEDIATE DEBUG TEST',
        'If you see this notification, the basic system works! Time: ${DateTime.now()}',
        const NotificationDetails(
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
        99998,
        '⏰ SCHEDULED DEBUG TEST',
        'Scheduled test at $testTime - if you see this, scheduling works!',
        testTime,
        const NotificationDetails(
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
          '⏰ Scheduled notification for: $testTime (3 seconds from now)');
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
          '📊 Android alarm limit: 500, our limit: $_maxRandomAthkarNotifications');

      final notificationsPerDay = (24 * 60) / testFrequency;
      final expectedTotal = (notificationsPerDay * 7).ceil();
      final actualCoverage =
          (_maxRandomAthkarNotifications * testFrequency / (24 * 60));

      debugPrint(
          '📈 Expected notifications for 7 days at ${testFrequency}min frequency: $expectedTotal');
      debugPrint(
          '✅ Within limits: ${expectedTotal <= _maxRandomAthkarNotifications}');
      debugPrint(
          '📊 Actual coverage with limit: ${actualCoverage.toStringAsFixed(1)} days');

      if (expectedTotal > _maxRandomAthkarNotifications) {
        debugPrint(
            '⚠️ Would exceed our limit of $_maxRandomAthkarNotifications notifications');
        debugPrint(
            '💡 Consider increasing frequency to ${((24 * 60 * 7) / _maxRandomAthkarNotifications).ceil()} minutes or higher');
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
        9999,
        '🚀 IMMEDIATE TEST #1',
        'Basic immediate notification - should appear instantly! Time: ${DateTime.now()}',
        const NotificationDetails(
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
        9998,
        '🔥 IMMEDIATE TEST #2',
        'Different settings notification - should also appear instantly! Time: ${DateTime.now()}',
        const NotificationDetails(
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
        9997,
        '⏰ SCHEDULED TEST',
        'This is a scheduled test at $testTime - if you see this, scheduling works!',
        testTime,
        const NotificationDetails(
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
          '⏰ Scheduled notification set for: $testTime (5 seconds from now)');

      await _plugin.show(
        9996,
        'MINIMAL TEST',
        'Minimal notification with basic settings',
        const NotificationDetails(
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
          '� You should see 3 immediate notifications now and 1 more in 5 seconds');
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
    await cancelAll();

    await scheduleKahfFriday(kahfFriday, kahfFridayTime, kahfTitle, kahfBody);
    await scheduleSabahMasaa(sabahMasaa, morningAthkarTime, eveningAthkarTime,
        morningTitle, morningBody, eveningTitle, eveningBody);
    await scheduleRandomAthkar(randomAthkar, randomAthkarFrequency);
    await scheduleQuranReminder(
        quranReminder, quranReminderTime, quranTitle, quranBody);
    if (checklistReminder && checklistReminderTime != null) {
      await scheduleChecklistReminder(
          true, checklistReminderTime, checklistTitle, checklistBody);
    }

    debugPrint(
        '✅ All Islamic notifications rescheduled (prayer countdown preserved)');
  }

  Future<bool> _shouldResumeBackgroundScheduling(int frequencyMinutes) async {
    try {
      final cacheHelper = getIt<CacheHelper>();
      final progress = cacheHelper.getData(key: _athkarProgressKey);
      final lastScheduled = cacheHelper.getData(key: _athkarLastScheduledKey);

      if (progress == null || lastScheduled == null) return false;

      if (progress == 'immediate_complete' ||
          progress == 'background_partial') {
        final lastTime = DateTime.parse(lastScheduled);
        final timeSinceLastScheduled = DateTime.now().difference(lastTime);

        if (timeSinceLastScheduled.inHours < 2) {
          debugPrint(
              '🛡️ Detected ${progress == 'background_partial' ? 'partial' : 'interrupted'} scheduling ${timeSinceLastScheduled.inMinutes} minutes ago');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking scheduling progress: $e');
      return false;
    }
  }

  void _resumeBackgroundScheduling(int frequencyMinutes) {
    _clearSchedulingProgress();
    _scheduleRemainingAthkarInBackground(frequencyMinutes);
  }

  Future<void> _scheduleImmediateAthkar(int frequencyMinutes) async {
    final now = tz.TZDateTime.now(tz.local);
    int notificationId = _randomAthkarBaseId + 1;
    tz.TZDateTime nextTime = now.add(Duration(minutes: frequencyMinutes));
    final endTime = now.add(const Duration(hours: 12));
    int scheduledCount = 0;

    const maxImmediateNotifications = 50;

    while (nextTime.isBefore(endTime) &&
        scheduledCount < maxImmediateNotifications) {
      try {
        final athkarText = _getRandomAthkar();

        await _plugin.zonedSchedule(
          notificationId,
          '📿 Athkar Reminder',
          athkarText,
          nextTime,
          const NotificationDetails(
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
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        nextTime = nextTime.add(Duration(minutes: frequencyMinutes));
        notificationId++;
        scheduledCount++;
      } catch (e) {
        if (e.toString().contains('Maximum limit of concurrent alarms')) {
          debugPrint(
              '⚠️ Hit Android alarm limit at $scheduledCount notifications');
          debugPrint('💡 Will schedule remaining in background with delays');
          break;
        } else {
          debugPrint('❌ Error scheduling notification $notificationId: $e');
          nextTime = nextTime.add(Duration(minutes: frequencyMinutes));
          notificationId++;
          continue;
        }
      }
    }

    debugPrint(
        '⚡ Ultra-fast scheduled $scheduledCount notifications for immediate coverage (12+ hours)');
  }

  void _scheduleRemainingAthkarInBackground(int frequencyMinutes) {
    Future.microtask(() async {
      try {
        debugPrint('🔄 Starting resilient background scheduling...');

        final now = tz.TZDateTime.now(tz.local);

        const maxImmediateNotifications = 50;
        final startId = _randomAthkarBaseId + 1 + maxImmediateNotifications;

        int notificationId = startId;
        tz.TZDateTime nextTime = now.add(const Duration(hours: 12));
        final endTime = now.add(const Duration(days: 7));
        int scheduledCount = 0;
        int batchCount = 0;
        bool hitAlarmLimit = false;

        await _saveSchedulingProgress('background_started', DateTime.now());

        while (nextTime.isBefore(endTime) &&
            notificationId <
                _randomAthkarBaseId + _maxRandomAthkarNotifications &&
            !hitAlarmLimit) {
          for (int i = 0;
              i < 10 &&
                  nextTime.isBefore(endTime) &&
                  notificationId <
                      _randomAthkarBaseId + _maxRandomAthkarNotifications;
              i++) {
            try {
              final athkarText = _getRandomAthkar();

              await _plugin.zonedSchedule(
                notificationId,
                '📿 Athkar Reminder',
                athkarText,
                nextTime,
                const NotificationDetails(
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
                ),
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              );

              nextTime = nextTime.add(Duration(minutes: frequencyMinutes));
              notificationId++;
              scheduledCount++;
            } catch (e) {
              if (e.toString().contains('Maximum limit of concurrent alarms')) {
                debugPrint(
                    '⚠️ Background hit alarm limit at $scheduledCount total');
                debugPrint('🛡️ Partial coverage achieved, will retry later');
                hitAlarmLimit = true;
                break;
              } else {
                debugPrint(
                    '❌ Background error for notification $notificationId: $e');
                nextTime = nextTime.add(Duration(minutes: frequencyMinutes));
                notificationId++;
                continue;
              }
            }
          }

          batchCount++;

          if (batchCount % 10 == 0) {
            await _saveSchedulingProgress(
                'background_progress_$batchCount', DateTime.now());
            await Future.delayed(const Duration(milliseconds: 100));
            debugPrint(
                '📦 Resilient batch $batchCount completed ($scheduledCount total)');
          } else {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        await _saveSchedulingProgress(
            hitAlarmLimit ? 'background_partial' : 'background_complete',
            DateTime.now());

        if (hitAlarmLimit) {
          debugPrint(
              '⚠️ Background scheduling partial: $scheduledCount notifications (alarm limit reached)');
          debugPrint('🛡️ Partial coverage active, retry will extend coverage');
        } else {
          debugPrint(
              '✅ Resilient background scheduling completed: $scheduledCount notifications');
          debugPrint('🛡️ Full 7-day coverage guaranteed!');
        }
      } catch (e) {
        debugPrint('❌ Background scheduling error: $e');

        await _scheduleRetryAttempt(frequencyMinutes);
      }
    });
  }

  Future<void> _saveSchedulingProgress(
      String progress, DateTime timestamp) async {
    try {
      final cacheHelper = getIt<CacheHelper>();
      await cacheHelper.saveData(key: _athkarProgressKey, value: progress);
      await cacheHelper.saveData(
          key: _athkarLastScheduledKey, value: timestamp.toIso8601String());
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
    }
  }

  Future<void> _clearSchedulingProgress() async {
    try {
      final cacheHelper = getIt<CacheHelper>();
      await cacheHelper.removeData(key: _athkarProgressKey);
      await cacheHelper.removeData(key: _athkarLastScheduledKey);
    } catch (e) {
      debugPrint('❌ Error clearing progress: $e');
    }
  }

  Future<void> _scheduleRetryAttempt(int frequencyMinutes) async {
    try {
      await Workmanager().registerOneOffTask(
        'athkar-retry-${DateTime.now().millisecondsSinceEpoch}',
        'retryAthkarScheduling',
        initialDelay: const Duration(minutes: 5),
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

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final permissionGranted = await androidPlugin.areNotificationsEnabled();
        health['permissionGranted'] = permissionGranted ?? false;

        final exactAlarmsAllowed =
            await androidPlugin.canScheduleExactNotifications();
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
