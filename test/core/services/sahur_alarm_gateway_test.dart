import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/ios_prayer_experience.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/services/sahur_alarm_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const gateway = NativeSahurAlarmGateway();
  setUp(() => SharedPreferences.setMockInitialValues({'app_locale': 'ar'}));
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(NativeSahurAlarmGateway.channel, null);
    messenger.setMockMethodCallHandler(IOSPrayerBridge.channel, null);
  });

  test(
    'Android publishes both modes and localized Stop without Flutter playback',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <Map>[];
      messenger.setMockMethodCallHandler(NativeSahurAlarmGateway.channel, (
        call,
      ) async {
        expect(call.method, 'configure');
        calls.add(call.arguments as Map);
        return {'accepted': true, 'supportsAlarms': true};
      });
      expect(
        (await gateway.configure(
          const SahurAlarmSettings(enabled: true),
        )).accepted,
        isTrue,
      );
      await gateway.configure(
        const SahurAlarmSettings(enabled: true, type: 1, minutesBeforeFajr: 75),
      );
      expect(calls[0], containsPair('hour', 4));
      expect(calls[1], containsPair('minutesBeforeFajr', 75));
      expect(calls[1], containsPair('type', 1));
      expect(calls[1], containsPair('locale', 'ar'));
      expect(calls[1]['stop'], isNot('Stop'));
      expect(calls[1].keys, isNot(contains('snooze')));
      await gateway.configure(const SahurAlarmSettings());
      expect(calls.last['enabled'], isFalse);
    },
  );

  test(
    'platform errors and a rejected registration are visible to the caller',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(
        NativeSahurAlarmGateway.channel,
        (_) async => {'accepted': false},
      );
      expect(
        (await gateway.configure(
          const SahurAlarmSettings(enabled: true),
        )).accepted,
        isFalse,
      );
      messenger.setMockMethodCallHandler(NativeSahurAlarmGateway.channel, (
        _,
      ) async {
        throw PlatformException(code: 'storageUnavailable');
      });
      await expectLater(
        gateway.configure(const SahurAlarmSettings(enabled: true)),
        throwsA(isA<NotificationNotScheduledException>()),
      );
    },
  );

  test('iOS shares AlarmKit permission and serial native revision', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var revision = 3;
    var authorized = false;
    var supports = true;
    var scheduled = false;
    final calls = <String>[];
    Map<String, Object?> receipt() => {
      'schemaVersion': 1,
      'revision': revision,
      'policyRevision': 1,
      'configurationSignature': '',
      'experience': const IOSPrayerExperience().toMap(),
      'notificationAuthorization': 'authorized',
      'alarmAuthorization': authorized ? 'authorized' : 'notDetermined',
      'supportsAlarms': supports,
      'notificationCount': 0,
      'otherNotificationCount': 0,
      'alarmCount': 0,
      'migration': 'uninitialized',
      'policies': {},
      'events': [],
      'sahurScheduled': scheduled,
    };
    messenger.setMockMethodCallHandler(IOSPrayerBridge.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'requestAlarms') {
        authorized = true;
        revision++;
      }
      if (call.method == 'setSahur') {
        expect((call.arguments as Map)['expectedRevision'], revision);
        scheduled =
            ((call.arguments as Map)['sahur'] as Map)['enabled'] == true;
        revision++;
      }
      return receipt();
    });
    final alarm = await gateway.configure(
      const SahurAlarmSettings(enabled: true),
      requestPermission: true,
    );
    expect(alarm.accepted, isTrue);
    expect(alarm.notificationOnly, isFalse);
    expect(calls, ['status', 'requestAlarms', 'setSahur']);
    expect(
      await NativeSahurAlarmGateway.requiresNotificationPermission(),
      isFalse,
    );
    calls.clear();
    supports = false;
    final fallback = await gateway.configure(
      const SahurAlarmSettings(enabled: true),
      requestPermission: true,
    );
    expect(fallback.notificationOnly, isTrue);
    expect(calls, ['status', 'setSahur']);
    expect(
      await NativeSahurAlarmGateway.requiresNotificationPermission(),
      isTrue,
    );

    // Restoring an enabled package-era setting is also an explicit request
    // for the shared permission on the first foreground launch after update.
    calls.clear();
    supports = true;
    authorized = false;
    final cache = CacheHelper();
    await cache.init();
    await cache.saveData(key: 'sahurAlarmEnabled', value: true);
    await NativeSahurAlarmGateway.sync(cache, requestPermission: true);
    expect(calls, ['status', 'requestAlarms', 'setSahur']);
  });

  test(
    'saved settings sanitize malformed times and clamp the before-Fajr lead',
    () async {
      SharedPreferences.setMockInitialValues({
        'sahurAlarmEnabled': true,
        'sahurExactTime': 'bad',
        'sahurMinutesBeforeFajr': 999,
      });
      final cache = CacheHelper();
      await cache.init();
      final settings = SahurAlarmSettings.fromCache(cache);
      expect(
        (settings.hour, settings.minute, settings.minutesBeforeFajr),
        (4, 0, 150),
      );
      expect(settings.enabled, isTrue);
    },
  );
}
