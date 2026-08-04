import 'package:flutter/widgets.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

class PrayerNotificationPlanner {
  const PrayerNotificationPlanner(this.cacheHelper);

  static const int configurationVersion = 3;

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
    final countryCode = PrayerTimesCalculator.countryCodeFromCache(cacheHelper);
    final scheduleTimeZoneName = PrayerTimesCalculator.resolveTimeZoneName(
      countryCode: countryCode,
      fallbackTimeZoneName: timeZoneName,
    );
    final nowUtc = now.toUtc();
    final zonedNow = PrayerTimeZoneService.atInstant(
      nowUtc,
      scheduleTimeZoneName,
    );
    final requestedThrough = nowUtc.add(horizon);
    final zonedRequestedThrough = PrayerTimeZoneService.atInstant(
      requestedThrough,
      scheduleTimeZoneName,
    );
    final candidates = <PrayerNotificationEvent>[];

    for (var dayOffset = 0;; dayOffset++) {
      final date = DateTime(
        zonedNow.year,
        zonedNow.month,
        zonedNow.day + dayOffset,
      );
      if (_isAfterCalendarDate(date, zonedRequestedThrough)) break;
      final times = PrayerTimesCalculator.computeFromCache(
        cacheHelper,
        coordinates,
        date,
        timeZoneName: scheduleTimeZoneName,
      );
      final adjustedInstants =
          PrayerTimesCalculator.dailyAdjustedInstants(times, offsets);

      for (final prayer in const [
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        final scheduledInstantUtc = adjustedInstants[prayer];
        if (scheduledInstantUtc == null) continue;
        final scheduledTime = PrayerTimeZoneService.wallClockAtInstant(
          scheduledInstantUtc,
          scheduleTimeZoneName,
        );

        final prayerName = _prayerName(prayer, localizations);
        final event = PrayerNotificationEvent(
          id: PrayerNotificationEvent.idFor(scheduledTime, prayer),
          prayer: prayer,
          scheduledTime: scheduledTime,
          scheduledInstantUtc: scheduledInstantUtc,
          timeZoneName: scheduleTimeZoneName,
          title: localizations.notificationPrayerTimeTitle(prayerName),
          body: localizations.notificationPrayerTimeBody(prayerName),
        );
        if (!event.scheduledInstantUtc.isAfter(nowUtc) ||
            event.scheduledInstantUtc.isAfter(requestedThrough)) {
          continue;
        }
        candidates.add(event);
      }
    }

    candidates.sort(
      (first, second) => first.scheduledInstantUtc.compareTo(
        second.scheduledInstantUtc,
      ),
    );
    final selectedIds = <int>{};
    final events = <PrayerNotificationEvent>[];
    for (final candidate in candidates) {
      if (!selectedIds.add(candidate.id)) continue;
      events.add(candidate);
      if (events.length == maxEvents) break;
    }

    return PrayerNotificationPlan(
      events: List.unmodifiable(events),
      configurationSignature: _configurationSignature(
        localeCode: localeCode,
        deviceTimeZoneName: timeZoneName,
        scheduleTimeZoneName: scheduleTimeZoneName,
        offsets: offsets,
      ),
      requestedThrough: requestedThrough,
    );
  }

  bool _isAfterCalendarDate(DateTime date, DateTime other) {
    if (date.year != other.year) return date.year > other.year;
    if (date.month != other.month) return date.month > other.month;
    return date.day > other.day;
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
    required String deviceTimeZoneName,
    required String scheduleTimeZoneName,
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
      'device-zone:$deviceTimeZoneName',
      'schedule-zone:$scheduleTimeZoneName',
      for (final key in PrayerTimesCalculator.offsetPrayerKeys)
        '$key:${offsets[key] ?? 0}',
    ];
    return parts.join('|');
  }
}
