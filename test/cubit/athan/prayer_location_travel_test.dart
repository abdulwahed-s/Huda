import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(PrayerTimeZoneService.initializeDatabase);

  Position position(double latitude, double longitude) => Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026, 9, 5),
    accuracy: 100,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  Future<CacheHelper> cacheWithMode(String mode) async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesCalculator.latKey: '23.5880',
      PrayerTimesCalculator.lonKey: '58.3829',
      PrayerTimesCalculator.countryCodeKey: 'OM',
      PrayerTimesCalculator.timeZoneIdKey: 'Asia/Muscat',
      PrayerTimesCalculator.locationModeKey: mode,
    });
    final cache = CacheHelper();
    await cache.init();
    return cache;
  }

  test(
    'automatic mode follows meaningful travel into another timezone',
    () async {
      final cache = await cacheWithMode('automatic');
      var resolvedZone = '';
      final cubit = PrayerTimesCubit(
        cache,
        travelLocationProvider: () async => position(35.6762, 139.6503),
        placemarkProvider: (_, _) async => const [
          Placemark(locality: 'Tokyo', country: 'Japan', isoCountryCode: 'JP'),
        ],
        timeZoneResolver: (latitude, longitude, countryCode) async {
          resolvedZone = 'Asia/Tokyo';
          return resolvedZone;
        },
      );

      await cubit.refreshAutomaticLocationIfNeeded(
        now: DateTime.utc(2026, 9, 5),
        force: true,
      );

      expect(cache.getDataString(key: PrayerTimesCalculator.latKey), '35.6762');
      expect(
        cache.getDataString(key: PrayerTimesCalculator.lonKey),
        '139.6503',
      );
      expect(
        cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
        'Asia/Tokyo',
      );
      expect(resolvedZone, 'Asia/Tokyo');
      expect(cubit.locationMode, PrayerLocationMode.automatic);
      expect(cubit.state, isA<PrayerTimesLoaded>());
      await cubit.close();
    },
  );

  test('automatic mode follows Muscat travel vectors', () async {
    final vectors = <(double, double, String, String)>[
      (25.2048, 55.2708, 'AE', 'Asia/Dubai'),
      (51.5074, -0.1278, 'GB', 'Europe/London'),
      (19.0760, 72.8777, 'IN', 'Asia/Kolkata'),
    ];
    for (final (latitude, longitude, country, zone) in vectors) {
      final cache = await cacheWithMode('automatic');
      final cubit = PrayerTimesCubit(
        cache,
        travelLocationProvider: () async => position(latitude, longitude),
        placemarkProvider: (_, _) async => [Placemark(isoCountryCode: country)],
        timeZoneResolver: (_, _, _) async => zone,
      );

      await cubit.refreshAutomaticLocationIfNeeded(
        now: DateTime.utc(2026, 9, 5),
        force: true,
      );

      expect(
        cache.getDataString(key: PrayerTimesCalculator.latKey),
        latitude.toString(),
      );
      expect(
        cache.getDataString(key: PrayerTimesCalculator.lonKey),
        longitude.toString(),
      );
      expect(
        cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
        zone,
      );
      expect(cubit.prayerTimeZoneId, zone);
      expect(cubit.state, isA<PrayerTimesLoaded>());
      await cubit.close();
    }
  });

  test('manual mode is never replaced by travel validation', () async {
    final cache = await cacheWithMode('manual');
    var locationRequests = 0;
    final cubit = PrayerTimesCubit(
      cache,
      travelLocationProvider: () async {
        locationRequests++;
        return position(35.6762, 139.6503);
      },
      timeZoneResolver: (_, _, _) async => 'Asia/Tokyo',
    );

    await cubit.refreshAutomaticLocationIfNeeded(force: true);

    expect(locationRequests, 0);
    expect(cache.getDataString(key: PrayerTimesCalculator.latKey), '23.5880');
    expect(
      cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
      'Asia/Muscat',
    );
    expect(cubit.locationMode, PrayerLocationMode.manual);
    await cubit.close();
  });

  test(
    'a nearby move is significant when its coordinate timezone changed',
    () async {
      final cache = await cacheWithMode('automatic');
      final cubit = PrayerTimesCubit(
        cache,
        travelLocationProvider: () async => position(23.5900, 58.3900),
        placemarkProvider: (_, _) async => const [
          Placemark(locality: 'Border', country: 'Test', isoCountryCode: 'XX'),
        ],
        timeZoneResolver: (_, _, _) async => 'Asia/Dubai',
      );

      await cubit.refreshAutomaticLocationIfNeeded(
        now: DateTime.utc(2026, 9, 5),
        force: true,
      );

      expect(
        cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
        'Asia/Dubai',
      );
      expect(cache.getDataString(key: PrayerTimesCalculator.latKey), '23.59');
      expect(cubit.state, isA<PrayerTimesLoaded>());
      await cubit.close();
    },
  );

  test('legacy coordinates with no provenance migrate as fixed/manual', () {
    expect(PrayerLocationMode.fromStorage(null), PrayerLocationMode.manual);
    expect(
      PrayerLocationMode.fromStorage('unexpected'),
      PrayerLocationMode.manual,
    );
  });

  test(
    'failed timezone lookup does not commit a half-updated location',
    () async {
      final cache = await cacheWithMode('automatic');
      final cubit = PrayerTimesCubit(
        cache,
        placemarkProvider: (_, _) async => const [
          Placemark(locality: 'Tokyo', country: 'Japan', isoCountryCode: 'JP'),
        ],
        timeZoneResolver: (_, _, _) async => throw StateError('lookup failed'),
      );

      await cubit.setManualLocation(35.6762, 139.6503);

      expect(cache.getDataString(key: PrayerTimesCalculator.latKey), '23.5880');
      expect(cache.getDataString(key: PrayerTimesCalculator.lonKey), '58.3829');
      expect(
        cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
        'Asia/Muscat',
      );
      expect(cubit.locationMode, PrayerLocationMode.automatic);
      expect(cubit.state, isA<PrayerTimesError>());
      await cubit.close();
    },
  );

  test(
    'automatic travel keeps the previous generation when exact timezone lookup fails',
    () async {
      final cache = await cacheWithMode('automatic');
      final cubit = PrayerTimesCubit(
        cache,
        travelLocationProvider: () async => position(51.5074, -0.1278),
        placemarkProvider: (_, _) async => const [
          Placemark(
            locality: 'London',
            country: 'United Kingdom',
            isoCountryCode: 'GB',
          ),
        ],
        timeZoneResolver: (_, _, _) async =>
            throw StateError('boundary lookup failed'),
      );

      await cubit.refreshAutomaticLocationIfNeeded(
        now: DateTime.utc(2026, 9, 5),
        force: true,
      );

      expect(cache.getDataString(key: PrayerTimesCalculator.latKey), '23.5880');
      expect(cache.getDataString(key: PrayerTimesCalculator.lonKey), '58.3829');
      expect(
        cache.getDataString(key: PrayerTimesCalculator.timeZoneIdKey),
        'Asia/Muscat',
      );
      expect(cubit.locationMode, PrayerLocationMode.automatic);
      await cubit.close();
    },
  );

  test('missing coordinates remain an explicit setup state', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheHelper();
    await cache.init();
    final cubit = PrayerTimesCubit(cache);
    cubit.loadCachedPrayerTimes();
    expect(cubit.state, isA<PrayerTimesNeedsSetup>());
    await cubit.close();
  });
}
