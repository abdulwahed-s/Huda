import 'package:flutter/material.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';

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
      await getIt<HijriCalendarService>().refreshAutomaticAdjustmentIfDue();
    } catch (error) {
      debugPrint('Hijri calendar refresh check failed: $error');
    }

    try {
      debugPrint(
        '📱 App resumed - checking for interrupted scheduling and coverage',
      );

      final cacheHelper = getIt<CacheHelper>();
      final randomAthkarEnabled =
          cacheHelper.getData(key: 'randomAthkar') ?? false;

      final pending = await _notificationHelper.getPendingNotifications();
      final randomAthkarPending = pending
          .where((n) => n.id >= 1100 && n.id < 1550)
          .length;
      final randomAthkarLimit =
          NotificationCapacityPolicy.current.randomAthkarLimit;
      final renewalThreshold = randomAthkarLimit == 0
          ? 0
          : (randomAthkarLimit / 4).ceil().clamp(1, randomAthkarLimit);

      debugPrint(
        '📊 Random athkar notifications remaining: $randomAthkarPending',
      );

      if (randomAthkarEnabled &&
          randomAthkarLimit > 0 &&
          randomAthkarPending < renewalThreshold) {
        debugPrint(
          '⚠️ Low notification coverage detected - triggering renewal',
        );

        final configured = cacheHelper.getData(key: 'randomAthkarFrequency');
        final frequency = configured is int ? configured : 60;
        await _notificationHelper.scheduleRandomAthkar(true, frequency);

        debugPrint('✅ App lifecycle notification renewal completed');
      } else {
        debugPrint('✅ Notification coverage sufficient - no renewal needed');
      }
    } catch (e) {
      debugPrint('❌ Error in app lifecycle notification check: $e');
    }

    try {
      final result = await getIt<PrayerNotificationScheduler>().reconcile(
        reason: 'app-resumed',
      );
      debugPrint(
        'Prayer notification resume status: ${result.status.name}; '
        'coverage=${result.coverageUntil}',
      );
    } catch (error) {
      debugPrint('Prayer notification resume check failed: $error');
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
