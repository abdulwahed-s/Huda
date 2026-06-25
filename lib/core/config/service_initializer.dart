import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/app_lifecycle_manager.dart';
import 'package:huda/core/services/background_task.dart';
import 'package:huda/core/services/calendar_notification_service.dart';
import 'package:huda/core/services/notification_boot_service.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/services/service_initialization_tracker.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/widget_background_service.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:huda/core/utils/performance_utils.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:workmanager/workmanager.dart';

Future<void> initializeCriticalServices() async {
  await PerformanceUtils.timeAsyncOperation('Critical Services', () async {
    final tracker = ServiceInitializationTracker();

    await getIt<CacheHelper>().init();
    tracker.markServiceReady('cache');
  });
}

Future<void> initializeNotifications() async {
  final tracker = ServiceInitializationTracker();
  await NotificationServices().initialize();
  tracker.markServiceReady('notifications');
}

Future<void> initializeNonCriticalServicesAsync() async {
  await PerformanceUtils.timeAsyncOperation('Non-Critical Services', () async {
    try {
      if (PlatformUtils.isMobile) {
        await Workmanager().initialize(
          callbackDispatcher,
        );
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
  if (!PlatformUtils.isMobile) return;

  final tracker = ServiceInitializationTracker();
  await WidgetService.initialize();
  await WidgetBackgroundService.initialize();
  tracker.markServiceReady('widgets');
}

Future<void> _initializeNotificationServices() async {
  await CalendarNotificationService().init();
  await NotificationBootService.rescheduleAfterBoot();
}

Future<void> _initializePrayerServices() async {
  final tracker = ServiceInitializationTracker();
  if (PlatformUtils.isMobile) {
    await getIt<PersistentPrayerCountdownService>().initialize();
    await getIt<PersistentPrayerCountdownService>().startIfEnabled();
  }
  tracker.markServiceReady('prayer');
}

Future<void> _initializeDataServices() async {
  await SurahCubit.preloadSurahData();
}

Future<void> _initializeBackgroundServices() async {
  final tracker = ServiceInitializationTracker();
  AppLifecycleManager().initialize();
  tracker.markServiceReady('background');
}
