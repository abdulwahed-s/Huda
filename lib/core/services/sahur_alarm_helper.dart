import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/presentation/screens/sahur_alarm_ring_screen.dart';
import 'package:huda/l10n/app_localizations.dart';
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
        stopButton: "Stop",
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

    String localizedTitle = 'Sahur Alarm';
    String localizedBody = 'Time to wake up for Sahur';
    String killTitle = 'Your alarms may not ring';
    String killBody =
        'You killed the app. Please reopen so your alarms can be rescheduled.';

    try {
      final context = App.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          localizedTitle = l10n.sahurAlarmRinging;
          localizedBody = l10n.sahurAlarmNotificationBody;
          killTitle = l10n.alarmKilledTitle;
          killBody = l10n.alarmKilledBody;
        }
      }
    } catch (_) {}

    await Alarm.setWarningNotificationOnKill(killTitle, killBody);

    if (!isEnabled) {
      await stopAlarm();
      return;
    }

    final alarmType = cacheHelper.getData(key: 'sahurAlarmType') ?? 0;

    Coordinates? coordinates;
    int fajrOffsetMinutes = 0;
    int minutesBefore =
        cacheHelper.getData(key: 'sahurMinutesBeforeFajr') ?? 30;

    if (alarmType == 1) {
      coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
      final offsets = PrayerTimesCalculator.offsetsFromCache(cacheHelper);
      fajrOffsetMinutes = offsets['fajr'] ?? 0;
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
        if (coordinates != null) {
          try {
            final prayerTimes =
                PrayerTimesCalculator.compute(coordinates, targetDate);
            nextFajrTime = prayerTimes.fajr
                .add(Duration(minutes: fajrOffsetMinutes));
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
        title: localizedTitle,
        body: localizedBody,
        alarmId: alarmId,
      );
    }
    debugPrint('⏰ Scheduled Sahur alarms for the next $_batchDays days.');
  }

  static bool _isRingScreenShowing = false;

  static void initListeners() {
    Alarm.ringing.listen((alarmSet) async {
      for (final alarmSettings in alarmSet.alarms) {
        if (alarmSettings.id >= sahurAlarmId &&
            alarmSettings.id < sahurAlarmId + _batchDays) {
          if (_isRingScreenShowing) continue;
          _isRingScreenShowing = true;

          final navigator = App.navigatorKey.currentState;
          if (navigator != null) {
            await navigator.push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SahurAlarmRingScreen(alarmSettings: alarmSettings),
              ),
            );

            _isRingScreenShowing = false;
            await updateSahurAlarmSchedule();
          } else {
            _isRingScreenShowing = false;
          }
        }
      }
    });
  }
}
