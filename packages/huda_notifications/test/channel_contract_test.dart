import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda_notifications/huda_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = PrayerHostApi.pigeonChannelCodec;
  const snapshotChannel =
      'dev.flutter.pigeon.huda_notifications.PrayerHostApi.getSnapshot';
  tearDown(() => messenger.setMockMessageHandler(snapshotChannel, null));
  test(
    'generated wire codec roundtrips integer identities, inherited policy and optional values',
    () {
      final event = EventData(
        id: 326100091,
        prayer: 'fajr',
        utcMillis: 1791540000000,
        timeZone: 'Asia/Muscat',
        localDate: '2026-10-09',
        title: 'الفجر',
        body: 'حان وقت الصلاة',
      );
      final registration = RegistrationData(
        event: event,
        token: 'immutable-token',
        precision: 'exact',
        outcome: 'registered',
      );
      final decoded =
          codec.decodeMessage(codec.encodeMessage(registration))!
              as RegistrationData;
      expect(decoded.event.utcMillis, event.utcMillis);
      expect(decoded.event.title, event.title);
      expect(decoded.event.compatiblePayload, isNull);
      final asset = AudioAssetData(
        reciterId: 'example-reciter',
        version: 'v1',
        variant: 'short',
        path: '/private/staging/short.wav',
        bytes: 999,
        sha256: 'a' * 64,
        durationMillis: 18025,
        nameEnglish: 'Example',
        nameArabic: 'مثال',
      );
      final decodedAsset =
          codec.decodeMessage(codec.encodeMessage(asset))! as AudioAssetData;
      expect(decodedAsset.durationMillis, 18025);
      expect(decodedAsset.nameArabic, 'مثال');
      final policy = PolicyData(
        schemaVersion: 1,
        revision: 47,
        values: {
          'perPrayer': {
            'fajr': {'mode': 'off'},
          },
          'stopAfterSeconds': null,
        },
      );
      expect(
        (codec.decodeMessage(codec.encodeMessage(policy))! as PolicyData)
            .values,
        policy.values,
      );
    },
  );
  test('typed host errors retain the recovery code and details', () async {
    messenger.setMockMessageHandler(
      snapshotChannel,
      (message) async => codec.encodeMessage([
        'stalePolicy',
        'Policy changed.',
        {'recoverable': true},
      ]),
    );
    await expectLater(
      PrayerHostApi(binaryMessenger: messenger).getSnapshot(),
      throwsA(
        isA<PlatformException>()
            .having((error) => error.code, 'code', 'stalePolicy')
            .having((error) => error.details, 'details', {'recoverable': true}),
      ),
    );
  });
  test(
    'non-Android initialization explicitly reports unsupportedPlatform',
    () async {
      if (HudaPrayerNotifications.isSupported) return;
      await expectLater(
        HudaPrayerNotifications().initialize(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'unsupportedPlatform',
          ),
        ),
      );
    },
  );
}
