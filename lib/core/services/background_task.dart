import 'package:flutter/widgets.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/prayer_notification_background_scheduler.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/widget_background_service.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:workmanager/workmanager.dart';

const String dailyTaskKey =
    PrayerNotificationBackgroundScheduler.legacyTaskName;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      switch (task) {
        case PrayerNotificationBackgroundScheduler.taskName:
        case PrayerNotificationBackgroundScheduler.legacyTaskName:
        case PrayerNotificationBackgroundScheduler.iosIdentifier:
          return _reconcilePrayerNotifications();
        case 'renewAthkarNotifications':
        case 'retryAthkarScheduling':
          return _renewAthkar(inputData);
        case 'updateHomeWidget':
          return _updateHomeWidget();
        default:
          debugPrint('Unknown Workmanager task: $task');
          return true;
      }
    } catch (error, stackTrace) {
      debugPrint('Workmanager task $task failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  });
}

Future<bool> _reconcilePrayerNotifications() async {
  final cache = CacheHelper();
  await cache.init();
  final result = await PrayerNotificationScheduler(cacheHelper: cache)
      .reconcile(reason: 'background-refresh');
  return result.isSuccess ||
      result.status == PrayerScheduleStatus.locationUnavailable ||
      result.status == PrayerScheduleStatus.permissionDenied;
}

Future<bool> _renewAthkar(Map<String, dynamic>? inputData) async {
  final cache = CacheHelper();
  await cache.init();
  if (cache.getData(key: 'randomAthkar') != true) return true;

  final configured = cache.getData(key: 'randomAthkarFrequency');
  final inputFrequency = inputData?['frequency'];
  final frequency = inputFrequency is int
      ? inputFrequency
      : configured is int
          ? configured
          : 60;
  final helper = NotificationPageHelper();
  await helper.init();
  await helper.scheduleRandomAthkar(true, frequency);
  return true;
}

Future<bool> _updateHomeWidget() async {
  await WidgetService.initialize();
  await WidgetService.forceUpdateWidget();
  await WidgetBackgroundService.updateLastUpdateTime();
  return true;
}
