import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:adhan/adhan.dart';

class SahurAlarmHelper {
  static const int sahurAlarmId = 114;

  static const int _batchDays = 30;

  static Future<void> scheduleAlarm({
    required TimeOfDay alarmTime,
    required DateTime scheduleDate,
    required String title,
    required String body,
    required int alarmId,
  }) async {
    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      return;
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledDateTime,
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        icon: 'huda_icon',
        iconColor: Colors.blue,
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> stopAlarm() async {
    for (int i = 0; i < _batchDays; i++) {
      await Alarm.stop(sahurAlarmId + i);
    }
    debugPrint('🛑 Sahur alarm batch stopped/disabled');
  }

  static Future<void> updateSahurAlarmSchedule() async {
    final cacheHelper = getIt<CacheHelper>();
    final isEnabled = cacheHelper.getData(key: 'sahurAlarmEnabled') ?? false;

    if (!isEnabled) {
      await stopAlarm();
      return;
    }

    final alarmType = cacheHelper.getData(key: 'sahurAlarmType') ?? 0;

    Coordinates? coordinates;
    CalculationParameters? params;
    int minutesBefore =
        cacheHelper.getData(key: 'sahurMinutesBeforeFajr') ?? 30;

    if (alarmType == 1) {
      final latString = cacheHelper.getDataString(key: 'latitude');
      final lonString = cacheHelper.getDataString(key: 'longitude');
      if (latString != null && lonString != null) {
        final lat = double.tryParse(latString);
        final lon = double.tryParse(lonString);
        if (lat != null && lon != null) {
          coordinates = Coordinates(lat, lon);
          params = CalculationMethod.karachi.getParameters();
          params.madhab = Madhab.shafi;
        }
      }
    }

    final now = DateTime.now();

    for (int i = 0; i < _batchDays; i++) {
      final targetDate = now.add(Duration(days: i));
      TimeOfDay alarmTime;

      if (alarmType == 0) {
        final timeStr = cacheHelper.getData(key: 'sahurExactTime') ?? '04:00';
        final parts = timeStr.toString().split(':');
        alarmTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        DateTime? nextFajrTime;
        if (coordinates != null && params != null) {
          try {
            final dateComponents = DateComponents.from(targetDate);
            final prayerTimes =
                PrayerTimes(coordinates, dateComponents, params);
            nextFajrTime = prayerTimes.fajr;
          } catch (e) {
            debugPrint('Error calculating Fajr time for $targetDate: $e');
          }
        }

        if (nextFajrTime != null) {
          final targetTime =
              nextFajrTime.subtract(Duration(minutes: minutesBefore));
          alarmTime = TimeOfDay.fromDateTime(targetTime);
        } else {
          alarmTime = const TimeOfDay(hour: 04, minute: 00);
        }
      }

      final alarmId = sahurAlarmId + i;
      await scheduleAlarm(
        alarmTime: alarmTime,
        scheduleDate: targetDate,
        title: 'Sahur Alarm',
        body: 'Time to wake up for Sahur',
        alarmId: alarmId,
      );
    }
    debugPrint('⏰ Scheduled Sahur alarms for the next $_batchDays days.');
  }

  static void initListeners() {
    Alarm.ringStream.stream.listen((alarmSettings) async {
      if (alarmSettings.id >= sahurAlarmId &&
          alarmSettings.id < sahurAlarmId + _batchDays) {
        await Future.delayed(const Duration(minutes: 5));
        await updateSahurAlarmSchedule();
      }
    });
  }
}
