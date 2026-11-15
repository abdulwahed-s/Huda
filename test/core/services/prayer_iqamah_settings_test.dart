import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_iqamah_settings.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/core/services/prayer_reliability_storage.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingScheduler extends PrayerNotificationScheduler {
  _RecordingScheduler(CacheHelper cache) : super(cacheHelper: cache);
  int calls = 0;
  @override
  Future<PrayerScheduleResult> reconcile({
    String reason = 'unspecified',
    bool force = false,
  }) async {
    calls++;
    return const PrayerScheduleResult(status: PrayerScheduleStatus.upToDate);
  }
}

class _IqamahCubit extends PrayerTimesCubit {
  _IqamahCubit(super.cacheHelper, PrayerNotificationScheduler scheduler)
    : super(
        notificationScheduler: scheduler,
        connectivityChanges: const Stream.empty(),
        connectivityCheck: () async => [],
      );

  void load(DailyPrayerTimes times) => emit(PrayerTimesLoaded(times, const []));

  @override
  Future<NextPrayerInfo> getCurrentOrNextPrayerTime(DateTime now) async {
    final elapsed = iqamahSettings.windowFor(Prayer.maghrib) > Duration.zero;
    return NextPrayerInfo(
      name: elapsed ? 'Maghrib' : 'Isha',
      time: elapsed
          ? now.subtract(const Duration(minutes: 3))
          : now.add(const Duration(hours: 1)),
      isPastPrayer: elapsed,
      prayer: elapsed ? Prayer.maghrib : Prayer.isha,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'defaults, invalid input, clamping, unknown prayers and cache round trip',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = CacheHelper();
      await cache.init();
      expect(
        PrayerIqamahSettings.fromCache(cache).toMap(),
        PrayerIqamahSettings.defaults,
      );
      final settings = PrayerIqamahSettings.sanitize({
        'fajr': 100,
        'dhuhr': -1,
        'asr': 'bad',
        'maghrib': 0,
        'isha': double.nan,
        'sunrise': 15,
      });
      expect(settings.toMap(), {
        'fajr': 60,
        'dhuhr': 0,
        'asr': 20,
        'maghrib': 0,
        'isha': 20,
      });
      expect(settings.windowFor(Prayer.sunrise), Duration.zero);
      expect(settings.windowFor(Prayer.none), Duration.zero);
      await settings.save(cache);
      expect(PrayerIqamahSettings.fromCache(cache).toMap(), settings.toMap());
      await cache.saveData(key: PrayerIqamahSettings.cacheKey, value: '{');
      expect(
        PrayerIqamahSettings.fromCache(cache).toMap(),
        PrayerIqamahSettings.defaults,
      );
    },
  );

  test(
    'desktop preference maps restore defaults and sanitize partial values',
    () {
      for (final raw in [
        null,
        false,
        <String, Object?>{},
        {'maghrib': 0, 'fajr': 90, 'isha': 'invalid'},
      ]) {
        final expected = PrayerIqamahSettings.sanitize(raw).toMap();
        expect(
          WindowsPrayerTaskbarPreferences.fromMap({
            'iqamahMinutes': raw,
          }).toMap()['iqamahMinutes'],
          expected,
        );
        expect(
          LinuxPrayerTrayPreferences.fromMap({
            'iqamahMinutes': raw,
          }).toMap()['iqamahMinutes'],
          expected,
        );
      }
    },
  );

  test(
    'each window is half open, zero skips start, sunrise never becomes a target',
    () {
      final start = DateTime.utc(2026, 10, 2, 5);
      for (final entry in PrayerIqamahSettings.defaults.entries) {
        final prayer = Prayer.values.byName(entry.key);
        final transitions = [
          PrayerTransition(prayer: prayer, instant: start),
          PrayerTransition(
            prayer: Prayer.sunrise,
            instant: start.add(const Duration(minutes: 1)),
          ),
          PrayerTransition(
            prayer: Prayer.fajr,
            instant: start.add(const Duration(hours: 2)),
          ),
        ];
        PrayerMoment resolve(
          DateTime now, [
          PrayerIqamahSettings iqamah = const PrayerIqamahSettings(),
        ]) => PrayerMomentResolver.resolve(
          now: now,
          transitions: transitions,
          iqamah: iqamah,
        )!;
        expect(resolve(start).isElapsed, true);
        expect(
          resolve(
            start
                .add(Duration(minutes: entry.value))
                .subtract(const Duration(milliseconds: 1)),
          ).isElapsed,
          true,
        );
        expect(
          resolve(start.add(Duration(minutes: entry.value))).isElapsed,
          false,
        );
        final off = resolve(
          start,
          PrayerIqamahSettings.sanitize({entry.key: 0}),
        );
        expect(off.isElapsed, false);
        expect(off.prayerInstant, start.add(const Duration(hours: 2)));
      }
    },
  );

  test(
    'latest prayer wins across midnight and overlapping windows, even when off',
    () {
      final start = DateTime.utc(2026, 10, 2, 23, 55);
      final transitions = [
        PrayerTransition(prayer: Prayer.isha, instant: start),
        PrayerTransition(
          prayer: Prayer.fajr,
          instant: start.add(const Duration(minutes: 10)),
        ),
        PrayerTransition(
          prayer: Prayer.dhuhr,
          instant: start.add(const Duration(hours: 12)),
        ),
      ];
      expect(
        PrayerMomentResolver.resolve(
          now: start.add(const Duration(minutes: 6)),
          transitions: transitions,
        )!.prayer,
        Prayer.isha,
      );
      final now = start.add(const Duration(minutes: 10));
      expect(
        PrayerMomentResolver.resolve(
          now: now,
          transitions: transitions,
        )!.prayer,
        Prayer.fajr,
      );
      expect(
        PrayerMomentResolver.resolve(
          now: now,
          transitions: transitions,
          iqamah: PrayerIqamahSettings.sanitize({'fajr': 0}),
        )!.prayer,
        Prayer.dhuhr,
      );
    },
  );

  test(
    'macOS widget patch and cubit save preserve calculation identity without scheduling',
    () async {
      final prior = {
        'version': 4,
        'revision': 42,
        'locationRevision': 7,
        'scheduleRevision': 9,
        'configurationSignature': 'unchanged',
        'precomputedDays': {
          'day': {'fajr': 123},
        },
      };
      SharedPreferences.setMockInitialValues({
        PrayerWidgetService.displayPayloadKey: jsonEncode(prior),
        'prayer_widget_settings_v2': jsonEncode(prior),
      });
      final cache = CacheHelper();
      await cache.init();
      final repository = PrayerLocationRepository(
        cacheHelper: cache,
        storage: InMemoryPrayerReliabilityStorage(),
      );
      getIt.registerSingleton<CacheHelper>(cache);
      getIt.registerSingleton<PrayerLocationRepository>(repository);
      final calls = <MethodCall>[];
      const channel = MethodChannel('com.aw.huda/mac_widgets');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await getIt.reset();
      });
      final settings = PrayerIqamahSettings.sanitize({'maghrib': 0});
      await PrayerWidgetService.publishIqamah(settings);
      for (final key in [
        PrayerWidgetService.displayPayloadKey,
        'prayer_widget_settings_v2',
      ]) {
        final payload = jsonDecode(cache.getDataString(key: key)!) as Map;
        expect(payload.remove('iqamahMinutes'), settings.toMap());
        expect(payload, prior);
      }
      expect(calls.single.method, 'publish');
      final scheduler = _RecordingScheduler(cache);
      final cubit = _IqamahCubit(cache, scheduler);
      final times = PrayerTimesCalculator.compute(
        Coordinates(23.588, 58.3829),
        DateTime(2026, 10, 2),
        timeZoneName: 'Asia/Muscat',
      );
      cubit.load(times);
      final iterator = StreamIterator(cubit.getNextPrayerCountdown());
      expect(await iterator.moveNext(), true);
      expect(iterator.current.isPastPrayer, true);
      final next = iterator.moveNext();
      await cubit.saveIqamahSettings(
        PrayerIqamahSettings.sanitize({'maghrib': 0}),
      );
      expect(await next.timeout(const Duration(milliseconds: 500)), true);
      expect(iterator.current.isPastPrayer, false);
      expect(
        (cubit.state as PrayerTimesLoaded).iqamahSettings.toMap()['maghrib'],
        0,
      );
      expect((cubit.state as PrayerTimesLoaded).prayerTimes, same(times));
      expect(scheduler.calls, 0);
      await iterator.cancel();
      await cubit.close();
    },
    skip: !PlatformUtils.isMacOS,
  );
}
