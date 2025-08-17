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
import 'package:upgrader/upgrader.dart';
import 'package:workmanager/workmanager.dart';

// Initialize only critical services that are absolutely needed for app startup
Future<void> initializeCriticalServices() async {
  await PerformanceUtils.timeAsyncOperation('Critical Services', () async {
    final tracker = ServiceInitializationTracker();

    setupServiceLocator();

    // Initialize cache and basic notifications in parallel
    await Future.wait([
      getIt<CacheHelper>()
          .init()
          .then((_) => tracker.markServiceReady('cache')),
      NotificationServices()
          .initialize()
          .then((_) => tracker.markServiceReady('notifications')),
    ]);
  });
}

// Initialize non-critical services asynchronously after app starts
Future<void> initializeNonCriticalServicesAsync() async {
  await PerformanceUtils.timeAsyncOperation('Non-Critical Services', () async {
    try {
      // Initialize these services in parallel for maximum speed
      await Future.wait([
        _initializeWidgetServices(),
        _initializeNotificationServices(),
        _initializePrayerServices(),
        _initializeDataServices(),
        _initializeBackgroundServices(),
      ]);
    } catch (e) {
      // Log error but don't crash the app
      if (kDebugMode) {
        print('Non-critical service initialization error: $e');
      }
    }
  });
}

Future<void> _initializeWidgetServices() async {
  final tracker = ServiceInitializationTracker();
  await WidgetService.initialize();
  await WidgetService.registerInteractivity();
  await WidgetBackgroundService.initialize();
  tracker.markServiceReady('widgets');
}

Future<void> _initializeNotificationServices() async {
  await CalendarNotificationService().init();
  await NotificationBootService.rescheduleAfterBoot();
}

Future<void> _initializePrayerServices() async {
  final tracker = ServiceInitializationTracker();
  await getIt<PersistentPrayerCountdownService>().initialize();
  await getIt<PersistentPrayerCountdownService>().startIfEnabled();
  tracker.markServiceReady('prayer');
}

Future<void> _initializeDataServices() async {
  // Load Surah data lazily - only when needed
  await SurahCubit.preloadSurahData(); // Remove this to load on-demand
  final upgrader = getIt<Upgrader>();
  await upgrader.initialize();
}

Future<void> _initializeBackgroundServices() async {
  final tracker = ServiceInitializationTracker();
  AppLifecycleManager().initialize();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );
  tracker.markServiceReady('background');
}

// Legacy method for compatibility - can be removed once all references are updated
@deprecated
Future<void> initializeServices() async {
  await initializeCriticalServices();
  initializeNonCriticalServicesAsync(); // Fire and forget
}
