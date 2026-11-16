import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/cache/quran_content_store.dart';
import 'package:huda/core/services/android_prayer_countdown.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/services/app_lifecycle_manager.dart';
import 'package:huda/core/services/background_task.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_notification_background_scheduler.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/quran_widget_service.dart';
import 'package:huda/core/services/service_initialization_tracker.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/sahur_alarm_gateway.dart';
import 'package:huda/core/utils/performance_utils.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/data/repository/chat_history_repository.dart';
import 'package:workmanager/workmanager.dart';

Future<void> initializeCriticalServices() async {
  await PerformanceUtils.timeAsyncOperation('Critical Services', () async {
    final tracker = ServiceInitializationTracker();

    await getIt<CacheHelper>().init();
    await getIt<PrayerLocationRepository>().initialize();
    await getIt<ChatHistoryRepository>().initialize();
    await getIt<HijriCalendarService>().initialize();
    unawaited(getIt<HijriCalendarService>().refreshAutomaticAdjustmentIfDue());
    tracker.markServiceReady('cache');
  });
}

Future<void> initializeNotifications() async {
  final tracker = ServiceInitializationTracker();
  await getIt<NotificationServices>().initialize();
  tracker.markServiceReady('notifications');
}

Future<void> initializeNonCriticalServicesAsync() async {
  await PerformanceUtils.timeAsyncOperation('Non-Critical Services', () async {
    try {
      if (PlatformUtils.isMobile) {
        try {
          await Workmanager().initialize(callbackDispatcher);
          await PrayerNotificationBackgroundScheduler.ensureRegistered();
        } catch (error) {
          debugPrint('Background refresh registration failed: $error');
        }
      }

      await Future.wait([
        _initializeWidgetServices(),
        _initializeNotificationServices(),
        _initializePrayerServices(),
        _initializeDataServices(),
        _initializeBackgroundServices(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Non-critical service initialization error: $e');
      }
    }
  });
}

Future<void> _initializeWidgetServices() async {
  if (!PlatformUtils.isMobile && !PlatformUtils.isMacOS) return;

  final tracker = ServiceInitializationTracker();
  await QuranWidgetService.initialize();
  if (PlatformUtils.isMacOS) {
    await PrayerWidgetService.initialize();
  }
  tracker.markServiceReady('widgets');
}

Future<void> _initializeNotificationServices() async {
  final reminders = NotificationOrchestrator.shared;
  Future<void> syncReminders(String reason) async {
    try {
      await reminders.syncNow(reason);
    } catch (error) {
      debugPrint('Reminder notification sync failed: $error');
    }
  }

  await syncReminders('app-startup');
  final result = await getIt<PrayerNotificationScheduler>().reconcile(
    reason: 'app-startup',
  );
  debugPrint(
    'Prayer notification startup status: ${result.status.name}, '
    'coverage: ${result.coverageUntil}',
  );
  if (PlatformUtils.isMobile) {
    try {
      await NativeSahurAlarmGateway.sync(getIt<CacheHelper>(), requestPermission: true);
    } catch (error) {
      debugPrint('Sahur alarm sync failed: $error');
    }
  }
  if (PlatformUtils.isMacOS) {
    // macOS discards reminders while its pending queue is full. The prayer
    // reconcile above releases capacity, so restore anything it dropped.
    await syncReminders('app-startup-after-prayers');
  }
}

Future<void> _initializePrayerServices() async {
  final tracker = ServiceInitializationTracker();
  if (PlatformUtils.isAndroid) {
    // Native code keeps the countdown alive by itself; this only repairs it,
    // for example after Huda was force-stopped and its alarms were dropped.
    try {
      await AndroidPrayerCountdown.refresh();
    } catch (error) {
      debugPrint('Prayer countdown refresh failed: $error');
    }
  }
  tracker.markServiceReady('prayer');
}

Future<void> _initializeDataServices() async {
  await SurahCubit.preloadSurahData();
  await getIt<QuranContentStore>().migrateLegacyContent();
}

Future<void> _initializeBackgroundServices() async {
  final tracker = ServiceInitializationTracker();
  AppLifecycleManager().initialize();
  tracker.markServiceReady('background');
}
