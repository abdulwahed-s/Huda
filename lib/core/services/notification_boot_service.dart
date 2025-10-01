import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:flutter/material.dart';

class NotificationBootService {
  static final NotificationBootService _instance =
      NotificationBootService._internal();
  factory NotificationBootService() => _instance;
  NotificationBootService._internal();

  static Future<void> rescheduleAfterBoot() async {
    try {
      debugPrint('🔄 Rescheduling Islamic notifications after boot...');

      final cacheHelper = getIt<CacheHelper>();
      final notificationHelper = NotificationPageHelper();

      await notificationHelper.init();

      final kahfFriday = cacheHelper.getData(key: 'kahfFriday') ?? false;
      final sabahMasaa = cacheHelper.getData(key: 'sabahMasaa') ?? false;
      final randomAthkar = cacheHelper.getData(key: 'randomAthkar') ?? false;
      final randomAthkarFrequency =
          cacheHelper.getData(key: 'randomAthkarFrequency') ?? 60;
      final quranReminder = cacheHelper.getData(key: 'quranReminder') ?? false;
      final quranReminderTimeStr =
          cacheHelper.getData(key: 'quranReminderTime') ?? '19:30';

      final kahfFridayTimeStr =
          cacheHelper.getData(key: 'kahfFridayTime') ?? '09:00';
      final morningAthkarTimeStr =
          cacheHelper.getData(key: 'morningAthkarTime') ?? '07:00';
      final eveningAthkarTimeStr =
          cacheHelper.getData(key: 'eveningAthkarTime') ?? '18:00';

      TimeOfDay? quranTime;
      if (quranReminder) {
        final parts = quranReminderTimeStr.split(':');
        quranTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      TimeOfDay? kahfTime;
      if (kahfFriday) {
        final parts = kahfFridayTimeStr.split(':');
        kahfTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      TimeOfDay? morningTime;
      TimeOfDay? eveningTime;
      if (sabahMasaa) {
        final morningParts = morningAthkarTimeStr.split(':');
        morningTime = TimeOfDay(
          hour: int.parse(morningParts[0]),
          minute: int.parse(morningParts[1]),
        );

        final eveningParts = eveningAthkarTimeStr.split(':');
        eveningTime = TimeOfDay(
          hour: int.parse(eveningParts[0]),
          minute: int.parse(eveningParts[1]),
        );
      }

      await notificationHelper.rescheduleAllNotifications(
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

      debugPrint('✅ Islamic notifications rescheduled after boot successfully');
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications after boot: $e');
    }
  }
}
