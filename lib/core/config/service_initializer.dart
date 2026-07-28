import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/app_lifecycle_manager.dart';
import 'package:huda/core/services/background_task.dart';
import 'package:huda/core/services/calendar_notification_service.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/notification_boot_service.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/services/prayer_notification_background_scheduler.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
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
    await getIt<HijriCalendarService>().initialize();
    unawaited(
      getIt<HijriCalendarService>().refreshAutomaticAdjustmentIfDue(),
    );
    tracker.markServiceReady('cache');
  });
}

Future<void> initializeNotifications() async {
  final tracker = ServiceInitializationTracker();
  await getIt<NotificationServices>().initialize(requestPermissions: true);
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
  if (!PlatformUtils.isMobile) return;

  final tracker = ServiceInitializationTracker();
  await WidgetService.initialize();
  await WidgetBackgroundService.initialize();
  tracker.markServiceReady('widgets');
}

Future<void> _initializeNotificationServices() async {
  try {
    await CalendarNotificationService().init();
  } catch (error) {
    debugPrint('Calendar notification initialization failed: $error');
  }
  try {
    await NotificationBootService.rescheduleAfterBoot();
  } catch (error) {
    debugPrint('Reminder notification restoration failed: $error');
  }
  final result = await getIt<PrayerNotificationScheduler>()
      .reconcile(reason: 'app-startup');
  debugPrint(
    'Prayer notification startup status: ${result.status.name}, '
    'coverage: ${result.coverageUntil}',
  );
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
