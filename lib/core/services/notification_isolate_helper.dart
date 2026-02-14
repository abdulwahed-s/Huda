import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

Future<void> windowsCancelAllAndRescheduleFixed(
    FlutterLocalNotificationsPlugin plugin) async {
  debugPrint(
      '🔄 Windows: Using native cancelAll() + rescheduling fixed notifications');

  await plugin.cancelAll();

  await _rescheduleFixedNotificationsFromCache(plugin);

  debugPrint('✅ Windows: cancelAll + fixed reschedule complete');
}

Future<void> _rescheduleFixedNotificationsFromCache(
    FlutterLocalNotificationsPlugin plugin) async {
  try {
    final cacheHelper = getIt<CacheHelper>();

    if (cacheHelper.getData(key: 'kahfFriday') == true) {
      await _scheduleFixed(plugin, 1001, RepeatInterval.weekly);
    }

    if (cacheHelper.getData(key: 'sabahMasaa') == true) {
      await _scheduleFixed(plugin, 1002, RepeatInterval.daily);
      await _scheduleFixed(plugin, 1003, RepeatInterval.daily);
    }

    if (cacheHelper.getData(key: 'quranReminder') == true) {
      await _scheduleFixed(plugin, 1004, RepeatInterval.daily);
    }

    if (cacheHelper.getData(key: 'checklistReminder') == true) {
      await _scheduleFixed(plugin, 1005, RepeatInterval.daily);
    }

    debugPrint('✅ Fixed notifications rescheduled from cache');
  } catch (e) {
    debugPrint('⚠️ Error rescheduling fixed notifications from cache: $e');
  }
}

Future<void> _scheduleFixed(FlutterLocalNotificationsPlugin plugin, int id,
    RepeatInterval interval) async {
  try {
    await plugin.periodicallyShow(
      id,
      'Reminder',
      'Islamic reminder',
      interval,
      const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  } catch (e) {
    debugPrint('⚠️ Could not reschedule fixed notification $id: $e');
  }
}
