import 'package:flutter/widgets.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

class PrayerNotificationPlanner {
  const PrayerNotificationPlanner(this.cacheHelper);

  static const int configurationVersion = 2;

  final CacheHelper cacheHelper;

  PrayerNotificationPlan? build({
    required DateTime now,
    required int maxEvents,
    required Duration horizon,
    required String timeZoneName,
  }) {
    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates == null || maxEvents <= 0 || horizon <= Duration.zero) {
      return null;
    }

    final localeCode = _localeCode();
    final localizations = _localizations(localeCode);
    final offsets = PrayerTimesCalculator.offsetsFromCache(cacheHelper);
    final requestedThrough = now.add(horizon);
    final events = <PrayerNotificationEvent>[];

    for (var dayOffset = 0;
        dayOffset <= horizon.inDays && events.length < maxEvents;
        dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final times = PrayerTimesCalculator.computeFromCache(
        cacheHelper,
        coordinates,
        date,
      );
      final adjusted = PrayerTimesCalculator.dailyAdjustedTimes(times, offsets);

      for (final prayer in const [
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        final scheduledTime = adjusted[prayer];
        if (scheduledTime == null ||
            !scheduledTime.isAfter(now) ||
            scheduledTime.isAfter(requestedThrough)) {
          continue;
        }

        final prayerName = _prayerName(prayer, localizations);
        events.add(PrayerNotificationEvent(
          id: PrayerNotificationEvent.idFor(scheduledTime, prayer),
          prayer: prayer,
          scheduledTime: scheduledTime,
          title: localizations.notificationPrayerTimeTitle(prayerName),
          body: localizations.notificationPrayerTimeBody(prayerName),
        ));
        if (events.length == maxEvents) break;
      }
    }

    return PrayerNotificationPlan(
      events: List.unmodifiable(events),
      configurationSignature: _configurationSignature(
        localeCode: localeCode,
        timeZoneName: timeZoneName,
        offsets: offsets,
      ),
      requestedThrough: requestedThrough,
    );
  }

  String _localeCode() =>
      cacheHelper.getDataString(key: 'app_locale') ??
      cacheHelper.getDataString(key: 'locale') ??
      'en';

  AppLocalizations _localizations(String localeCode) {
    try {
      return lookupAppLocalizations(Locale(localeCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  String _prayerName(Prayer prayer, AppLocalizations localizations) {
    switch (prayer) {
      case Prayer.fajr:
        return localizations.fajr;
      case Prayer.dhuhr:
        return localizations.dhuhr;
      case Prayer.asr:
        return localizations.asr;
      case Prayer.maghrib:
        return localizations.maghrib;
      case Prayer.isha:
        return localizations.isha;
      case Prayer.sunrise:
      case Prayer.none:
        return prayer.name;
    }
  }

  String _configurationSignature({
    required String localeCode,
    required String timeZoneName,
    required Map<String, int> offsets,
  }) {
    final parts = <String>[
      'v$configurationVersion',
      cacheHelper.getDataString(key: PrayerTimesCalculator.latKey) ?? '',
      cacheHelper.getDataString(key: PrayerTimesCalculator.lonKey) ?? '',
      PrayerTimesCalculator.countryCodeFromCache(cacheHelper),
      PrayerTimesCalculator.methodTokenFromCache(cacheHelper),
      cacheHelper.getDataString(key: PrayerTimesCalculator.madhabKey) ?? '',
      cacheHelper.getDataString(
              key: PrayerTimesCalculator.highLatitudeRuleKey) ??
          '',
      localeCode,
      timeZoneName,
      for (final key in PrayerTimesCalculator.offsetPrayerKeys)
        '$key:${offsets[key] ?? 0}',
    ];
    return parts.join('|');
  }
}
