import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CustomPrayerAngles', () {
    test('parses localized digits and decimal separators', () {
      expect(CustomPrayerAngles.tryParseLocalized('١٨٫٥'), 18.5);
      expect(CustomPrayerAngles.tryParseLocalized('۱۷,۵'), 17.5);
      expect(CustomPrayerAngles.tryParseLocalized(double.nan), isNull);
    });

    test('falls back per field for missing or invalid stored values', () {
      final angles = CustomPrayerAngles.fromStoredValues(
        fajr: '-1',
        maghrib: '4.5',
        isha: 'not-a-number',
      );

      expect(angles.fajr, CustomPrayerAngles.defaultFajr);
      expect(angles.maghrib, 4.5);
      expect(angles.isha, CustomPrayerAngles.defaultIsha);
    });

    test(
      'reads legacy numeric and canonical string preference values',
      () async {
        SharedPreferences.setMockInitialValues({
          PrayerTimesCalculator.customFajrAngleKey: 18.5,
          PrayerTimesCalculator.customMaghribAngleKey: '4',
          PrayerTimesCalculator.customIshaAngleKey: '16.5',
        });
        final cache = CacheHelper();
        await cache.init();

        expect(
          PrayerTimesCalculator.customAnglesFromCache(cache),
          const CustomPrayerAngles(fajr: 18.5, maghrib: 4, isha: 16.5),
        );
      },
    );
  });

  group('PrayerTimesCalculator custom parameters', () {
    test('uses all three angles and disables interval modes for Custom', () {
      final parameters = PrayerTimesCalculator.buildParameters(
        methodToken: 'other',
        customAngles: const CustomPrayerAngles(
          fajr: 18.5,
          maghrib: 4,
          isha: 16.5,
        ),
      );

      expect(parameters.fajrAngle, 18.5);
      expect(parameters.maghribIsInterval, isFalse);
      expect(parameters.maghribValue, 4);
      expect(parameters.ishaIsInterval, isFalse);
      expect(parameters.ishaValue, 16.5);
    });

    test('named methods ignore custom values', () {
      final expected = CalculationMethod.oman.getParameters();
      final parameters = PrayerTimesCalculator.buildParameters(
        methodToken: 'oman',
        customAngles: const CustomPrayerAngles(fajr: 10, maghrib: 4, isha: 11),
      );

      expect(parameters.fajrAngle, expected.fajrAngle);
      expect(parameters.maghribIsInterval, expected.maghribIsInterval);
      expect(parameters.maghribValue, expected.maghribValue);
      expect(parameters.ishaIsInterval, expected.ishaIsInterval);
      expect(parameters.ishaValue, expected.ishaValue);
    });

    test('a positive custom Maghrib angle is after sunset and before Isha', () {
      final parameters = PrayerTimesCalculator.buildParameters(
        methodToken: 'other',
        customAngles: const CustomPrayerAngles(fajr: 18, maghrib: 4, isha: 17),
      );
      final times = PrayerTimes(
        Coordinates(24.3486, 56.6953),
        const DateComponents(2026, 6, 28),
        parameters,
        utcOffset: const Duration(hours: 4),
        countryCode: 'OM',
      );

      expect(times.maghrib, isNotNull);
      expect(times.sunset, isNotNull);
      expect(times.isha, isNotNull);
      expect(times.maghrib!.isAfter(times.sunset!), isTrue);
      expect(times.maghrib!.isBefore(times.isha!), isTrue);
    });
  });

  test(
    'notification configuration changes when a custom angle changes',
    () async {
      SharedPreferences.setMockInitialValues({
        PrayerTimesCalculator.latKey: '24.3486',
        PrayerTimesCalculator.lonKey: '56.6953',
        PrayerTimesCalculator.countryCodeKey: 'OM',
        PrayerTimesCalculator.methodKey: 'other',
        PrayerTimesCalculator.customFajrAngleKey: '18',
        PrayerTimesCalculator.customMaghribAngleKey: '0',
        PrayerTimesCalculator.customIshaAngleKey: '17',
      });
      final cache = CacheHelper();
      await cache.init();
      PrayerTimeZoneService.initializeDatabase();
      final planner = PrayerNotificationPlanner(cache);
      final initial = planner.build(
        now: DateTime.utc(2026, 6, 27, 20),
        maxEvents: 5,
        horizon: const Duration(days: 1),
        timeZoneName: 'Asia/Muscat',
      );

      await cache.saveData(
        key: PrayerTimesCalculator.customMaghribAngleKey,
        value: '4',
      );
      final changed = planner.build(
        now: DateTime.utc(2026, 6, 27, 20),
        maxEvents: 5,
        horizon: const Duration(days: 1),
        timeZoneName: 'Asia/Muscat',
      );

      expect(initial, isNotNull);
      expect(changed, isNotNull);
      expect(
        changed!.configurationSignature,
        isNot(initial!.configurationSignature),
      );
      expect(changed.configurationSignature, contains('custom-maghrib:4'));
      expect(changed.configurationSignature, startsWith('v4|'));
    },
  );

  test('PrayerTimesCubit persists canonical custom-angle strings', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheHelper();
    await cache.init();
    final cubit = PrayerTimesCubit(cache);

    await cubit.savePrayerSettings(
      methodToken: 'other',
      madhabToken: PrayerTimesCalculator.defaultMadhabToken,
      highLatToken: PrayerTimesCalculator.defaultHighLatitudeToken,
      offsets: PrayerTimesCalculator.zeroOffsets(),
      customAngles: const CustomPrayerAngles(
        fajr: 18.5,
        maghrib: 4,
        isha: 16.5,
      ),
    );

    expect(
      cache.getDataString(key: PrayerTimesCalculator.customFajrAngleKey),
      '18.5',
    );
    expect(
      cache.getDataString(key: PrayerTimesCalculator.customMaghribAngleKey),
      '4',
    );
    expect(
      cache.getDataString(key: PrayerTimesCalculator.customIshaAngleKey),
      '16.5',
    );
    expect(
      cubit.customPrayerAngles,
      const CustomPrayerAngles(fajr: 18.5, maghrib: 4, isha: 16.5),
    );
    await cubit.close();
  });
}
