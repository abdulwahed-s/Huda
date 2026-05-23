import 'package:adhan/adhan.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/widget_background_service.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'renewAthkarNotifications':
        return await _handleAthkarRenewal();
      case 'renewPrayerNotifications':
        return await _handlePrayerNotificationsRenewal();
      case 'updateHomeWidget':
        return await _handleWidgetUpdate();
      default:
        debugPrint('Unknown background task: $task');
        return Future.value(false);
    }
  });
}

Future<bool> _handleAthkarRenewal() async {
  try {
    debugPrint('🔄 Background athkar renewal started');

    final cacheHelper = CacheHelper();
    await cacheHelper.init();

    final notificationHelper = NotificationPageHelper();
    await notificationHelper.init();

    final isEnabled = cacheHelper.getData(key: 'randomAthkar') ?? false;
    if (!isEnabled) {
      debugPrint('🔄 Random athkar disabled - skipping renewal');
      return true;
    }

    final frequency = cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60;

    await notificationHelper.scheduleRandomAthkar(true, frequency);

    debugPrint('✅ Background athkar renewal completed successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Error in background athkar renewal: $e');
    return false;
  }
}

Future<bool> _handleWidgetUpdate() async {
  try {
    debugPrint('🔄 Background widget update started at ${DateTime.now()}');

    final cacheHelper = CacheHelper();
    await cacheHelper.init();

    await WidgetService.initialize();

    debugPrint('📱 Force updating widget with new verse...');
    await WidgetService.forceUpdateWidget();

    await WidgetBackgroundService.updateLastUpdateTime();

    debugPrint('✅ Widget updated successfully at ${DateTime.now()}');
  } catch (e) {
    debugPrint('❌ Error in background widget update: $e');

    try {
      debugPrint('🔄 Attempting fallback widget update...');
      await WidgetService.updateWidget();
      debugPrint('✅ Fallback widget update successful');
    } catch (fallbackError) {
      debugPrint('❌ Fallback widget update also failed: $fallbackError');
    }
  }

  return true;
}

Future<bool> _handlePrayerNotificationsRenewal() async {
  try {
    debugPrint('🔄 Background prayer notifications renewal started');

    final cacheHelper = CacheHelper();
    await cacheHelper.init();

    final notificationServices = NotificationServices();
    await notificationServices.initialize();

    final coordinates =
        PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates == null) {
      debugPrint(
          '❌ Location not available for prayer notifications renewal');
      return false;
    }

    await notificationServices.cancelAllPrayerNotifications();

    final offsets = PrayerTimesCalculator.offsetsFromCache(cacheHelper);
    final now = DateTime.now();
    int totalScheduled = 0;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final prayerTimes =
          PrayerTimesCalculator.compute(coordinates, targetDate);
      final adjusted =
          PrayerTimesCalculator.dailyAdjustedTimes(prayerTimes, offsets);

      for (final entry in adjusted.entries) {
        final prayer = entry.key;
        final time = entry.value;
        final title = _prayerTitle(prayer);

        if (time.isAfter(now)) {
          await notificationServices.schedulePrayerNotificationWithDate(
            prayer: prayer,
            title: '🕌 $title Prayer Time',
            body:
                'It\'s time for $title prayer. May Allah accept your prayers.',
            scheduledTime: time,
            dayOffset: dayOffset,
          );
          totalScheduled++;
        }
      }
    }

    debugPrint(
        '✅ Background prayer notifications renewal completed: $totalScheduled notifications scheduled');
    return true;
  } catch (e) {
    debugPrint('❌ Error in background prayer notifications renewal: $e');
    return false;
  }
}

String _prayerTitle(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr:
      return 'Fajr';
    case Prayer.dhuhr:
      return 'Dhuhr';
    case Prayer.asr:
      return 'Asr';
    case Prayer.maghrib:
      return 'Maghrib';
    case Prayer.isha:
      return 'Isha';
    default:
      return prayer.name;
  }
}
