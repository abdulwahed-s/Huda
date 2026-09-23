import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

void main() {
  setUpAll(PrayerTimeZoneService.initializeDatabase);

  test('Umm al-Qura uses 120m Isha in Ramadan and 90m otherwise', () {
    final coordinates = Coordinates(21.3891, 39.8579);
    final ramadan = PrayerTimesCalculator.compute(
      coordinates,
      DateTime(2026, 3, 1),
      methodToken: 'ummAlQura',
      countryCode: 'OM',
      timeZoneName: 'Asia/Muscat',
    );
    final normal = PrayerTimesCalculator.compute(
      coordinates,
      DateTime(2026, 5, 1),
      methodToken: 'ummAlQura',
      countryCode: 'OM',
      timeZoneName: 'Asia/Muscat',
    );
    expect(
      ramadan.ishaInstantUtc!.difference(ramadan.maghribInstantUtc!),
      const Duration(minutes: 120),
    );
    expect(
      normal.ishaInstantUtc!.difference(normal.maghribInstantUtc!),
      const Duration(minutes: 90),
    );
  });

  test('manual offsets preserve both directions of day rollover', () {
    final times = DailyPrayerTimes(
      fajrInstantUtc: DateTime.utc(2026, 1, 2, 0, 5),
      ishaInstantUtc: DateTime.utc(2026, 1, 1, 23, 55),
    );
    expect(
      PrayerTimesCalculator.adjustedInstantFor(times, Prayer.isha, {
        'isha': 10,
      }),
      DateTime.utc(2026, 1, 2, 0, 5),
    );
    expect(
      PrayerTimesCalculator.adjustedInstantFor(times, Prayer.fajr, {
        'fajr': -10,
      }),
      DateTime.utc(2026, 1, 1, 23, 55),
    );
  });

  test('manual offset validation is identical and bounded', () {
    expect(
      PrayerTimesCalculator.sanitizeOffsets({'fajr': -999999, 'isha': 999999}),
      containsPair('fajr', -PrayerTimesCalculator.maxManualOffsetMinutes),
    );
    expect(
      PrayerTimesCalculator.sanitizeOffsets({'fajr': -999999, 'isha': 999999}),
      containsPair('isha', PrayerTimesCalculator.maxManualOffsetMinutes),
    );
  });

  test('selection compares absolute instants across different zones', () {
    final coordinates = Coordinates(23.5880, 58.3829);
    final times = PrayerTimesCalculator.compute(
      coordinates,
      DateTime(2026, 6, 28),
      countryCode: 'OM',
      timeZoneName: 'Asia/Muscat',
    );
    final transitions =
        PrayerTimesCalculator.dailyAdjustedInstants(
          times,
          PrayerTimesCalculator.zeroOffsets(),
        ).entries.map(
          (entry) => PrayerTransition(prayer: entry.key, instant: entry.value),
        );
    final nowInNewYorkZone = PrayerTimeZoneService.atInstant(
      times.fajrInstantUtc!.add(const Duration(minutes: 30)),
      'America/New_York',
    );
    final moment = PrayerMomentResolver.resolve(
      now: nowInNewYorkZone,
      transitions: transitions,
    )!;
    expect(moment.prayer, Prayer.dhuhr);
    expect(moment.mode, PrayerMomentMode.countdown);
    expect(moment.prayerInstant.isUtc, isTrue);
  });
}
