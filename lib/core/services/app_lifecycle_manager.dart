import 'package:flutter/material.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/cache/cache_helper.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  final NotificationPageHelper _notificationHelper = NotificationPageHelper();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkAndResumeScheduling();
    }
  }

  Future<void> _checkAndResumeScheduling() async {
    try {
      debugPrint(
          '📱 App resumed - checking for interrupted scheduling and coverage');

      final cacheHelper = getIt<CacheHelper>();
      final randomAthkarEnabled =
          cacheHelper.getData(key: 'randomAthkar') ?? false;

      if (randomAthkarEnabled) {
        final frequency =
            cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60;

        await _notificationHelper.scheduleRandomAthkar(true, frequency);
        debugPrint('🛡️ Interrupted scheduling check completed');
      }

      final pending = await _notificationHelper.getPendingNotifications();
      final randomAthkarPending =
          pending.where((n) => n.id >= 1100 && n.id < 1550).length;

      debugPrint(
          '📊 Random athkar notifications remaining: $randomAthkarPending');

      if (randomAthkarPending < 100) {
        debugPrint(
            '⚠️ Low notification coverage detected - triggering renewal');

        final cacheHelper = getIt<CacheHelper>();

        final kahfFriday = cacheHelper.getData(key: 'kahfFriday') ?? false;
        final sabahMasaa = cacheHelper.getData(key: 'sabahMasaa') ?? false;
        final quranReminder =
            cacheHelper.getData(key: 'quranReminder') ?? false;
        final randomAthkar = cacheHelper.getData(key: 'randomAthkar') ?? false;
        final randomAthkarFrequency =
            cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60;

        final kahfFridayTimeStr =
            cacheHelper.getData(key: 'kahfFridayTime') ?? '09:00';
        final morningAthkarTimeStr =
            cacheHelper.getData(key: 'morningAthkarTime') ?? '07:00';
        final eveningAthkarTimeStr =
            cacheHelper.getData(key: 'eveningAthkarTime') ?? '18:00';
        final quranReminderTimeStr =
            cacheHelper.getData(key: 'quranReminderTime') ?? '19:30';

        TimeOfDay? kahfTime, morningTime, eveningTime, quranTime;

        if (kahfFriday) {
          final parts = kahfFridayTimeStr.split(':');
          kahfTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }

        if (sabahMasaa) {
          final morningParts = morningAthkarTimeStr.split(':');
          morningTime = TimeOfDay(
              hour: int.parse(morningParts[0]),
              minute: int.parse(morningParts[1]));

          final eveningParts = eveningAthkarTimeStr.split(':');
          eveningTime = TimeOfDay(
              hour: int.parse(eveningParts[0]),
              minute: int.parse(eveningParts[1]));
        }

        if (quranReminder) {
          final parts = quranReminderTimeStr.split(':');
          quranTime =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }

        await _notificationHelper.rescheduleAllNotifications(
          kahfFriday: kahfFriday,
          sabahMasaa: sabahMasaa,
          randomAthkar: randomAthkar,
          randomAthkarFrequency: randomAthkarFrequency,
          quranReminder: quranReminder,
          quranReminderTime: quranTime,
          kahfFridayTime: kahfTime,
          morningAthkarTime: morningTime,
          eveningAthkarTime: eveningTime,
        );

        debugPrint('✅ App lifecycle notification renewal completed');
      } else {
        debugPrint('✅ Notification coverage sufficient - no renewal needed');
      }
    } catch (e) {
      debugPrint('❌ Error in app lifecycle notification check: $e');
    }
  }

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔄 App lifecycle manager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔄 App lifecycle manager disposed');
  }
}
