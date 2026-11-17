import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda/core/services/android_prayer_experience_service.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/ios_prayer_experience.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';
import 'package:huda/core/services/mac_prayer_experience.dart';
import 'package:huda/core/services/prayer_alerts/android_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/ios_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/linux_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/mac_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:huda/core/services/prayer_alerts/windows_prayer_alert_platform.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda_notifications/huda_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Host extends PrayerHostApi {
  final tests = <String>[];
  String? refuse;

  @override
  Future<EventData> runDeliveryTest(String prayer, int delaySeconds) async {
    tests.add('$prayer:$delaySeconds');
    if (refuse != null) {
      throw PlatformException(
        code: 'IllegalArgumentException',
        message: refuse,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android', () {
    late AndroidPrayerAlertPlatform platform;
    late _Host host;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final cache = CacheHelper();
      await cache.init();
      host = _Host();
      final settings = AndroidPrayerExperienceService(cache: cache, api: host);
      platform = AndroidPrayerAlertPlatform(
        settings: settings,
        state: AndroidPrayerNotificationStateService(
          platform: HudaPrayerNotifications(host: host),
          settings: settings,
          audioCoordinator: AudioCoordinator(),
        ),
      );
    });
    final base = AndroidPrayerExperience.fromMap({});

    test('whole numbers the native policy sends as doubles still read', () {
      final native = AndroidPrayerExperience.fromMap({
        'stopAfterSeconds': 30.0,
        'fadeInSeconds': 5.0,
        'perPrayer': {
          'fajr': {'stopAfterSeconds': 3600.0, 'volumeGain': 1},
        },
      });
      final view = platform.view(native);
      expect(view.stopAfterSeconds, 30);
      expect(view.fadeInSeconds, 5);
      expect(view.prayers['fajr']!.tuning['stopAfterSeconds'], 3600.0);
    });

    test('the short recording is the Adhan style\'s "Opening only"', () {
      final short = platform.change(
        base,
        const SetPrayerAlertLength(null, opening: true),
      );
      expect(short.values['defaultMode'], 'short');
      var view = platform.view(short);
      expect(view.style, PrayerAlertStyle.full);
      expect(view.openingOnly, isTrue);
      expect(
        platform.capabilities(short).styles,
        isNot(contains(PrayerAlertStyle.short)),
      );
      // Choosing Adhan again keeps the opening; another length plays it all.
      expect(
        platform
            .change(short, const SetPrayerAlertStyle(PrayerAlertStyle.full))
            .values['defaultMode'],
        'short',
      );
      final minute = platform.change(short, const SetPrayerAlertLength(60));
      expect(minute.values['defaultMode'], 'full');
      expect(minute.values['stopAfterSeconds'], 60);

      final fajr = platform.change(
        minute,
        const SetPrayerAlertLength(null, prayer: 'fajr', opening: true),
      );
      view = platform.view(fajr);
      expect(view.prayers['fajr']!.openingOnly, isTrue);
      expect(view.prayers['fajr']!.tuning['opening'], isTrue);
      expect(view.prayers['dhuhr']!.openingOnly, isFalse);
      final back = platform.change(
        fajr,
        const SetPrayerAlertLength(null, prayer: 'fajr', inherit: true),
      );
      expect(back.overrideFor('fajr'), isEmpty);
    });

    test('a prayer follows the default until it gets its own', () {
      var next = platform.change(
        base,
        const SetPrayerAlertStyle(PrayerAlertStyle.off, prayer: 'isha'),
      );
      expect(platform.view(next).prayers['isha']!.style, PrayerAlertStyle.off);
      expect(platform.view(next).prayers['isha']!.ownStyle, isTrue);
      next = platform.change(
        next,
        const SetPrayerAlertStyle(null, prayer: 'isha'),
      );
      expect(next.overrideFor('isha'), isEmpty);
    });

    test('"the whole adhan" for one prayer is stored as an hour', () {
      final next = platform.change(
        platform.change(base, const SetPrayerAlertLength(30)),
        const SetPrayerAlertLength(null, prayer: 'fajr'),
      );
      expect(next.values['stopAfterSeconds'], 30);
      expect(next.overrideFor('fajr')['stopAfterSeconds'], 3600);
      expect(
        platform.view(next).prayers['fajr']!.tuning['stopAfterSeconds'],
        3600,
      );
      final inherited = platform.change(
        next,
        const SetPrayerAlertLength(null, prayer: 'fajr', inherit: true),
      );
      expect(inherited.overrideFor('fajr'), isEmpty);
    });

    test('reset clears everything a prayer had of its own', () {
      final custom = platform.change(
        platform.change(
          base,
          const SetPrayerAlertToggle('vibrate', false, prayer: 'asr'),
        ),
        const SetPrayerAlertReciter('mishary', 'v1', prayer: 'asr'),
      );
      expect(platform.view(custom).prayers['asr']!.custom, isTrue);
      final reset = platform.change(custom, const ResetPrayerAlert('asr'));
      expect(platform.view(reset).prayers['asr']!.custom, isFalse);
    });

    test('a reminder before the prayer: default, per prayer and reset', () {
      expect(platform.capabilities(base).beforeMinutes, [5, 10, 15, 30]);
      expect(platform.view(base).beforeMinutes, 0);
      var next = platform.change(base, const SetPrayerAlertBefore(10));
      expect(next.values['advanceMinutes'], 10);
      next = platform.change(
        next,
        const SetPrayerAlertBefore(5, prayer: 'fajr'),
      );
      next = platform.change(
        next,
        const SetPrayerAlertBefore(0, prayer: 'isha'),
      );
      var view = platform.view(next);
      expect(view.beforeMinutes, 10);
      expect(view.prayers['fajr']!.beforeMinutes, 5);
      expect(view.prayers['fajr']!.ownBefore, isTrue);
      expect(view.prayers['isha']!.beforeMinutes, 0);
      expect(view.prayers['isha']!.ownBefore, isTrue);
      expect(view.prayers['asr']!.beforeMinutes, 10);
      expect(view.prayers['asr']!.ownBefore, isFalse);
      expect(next.advanceActive, isTrue);

      // Null follows the default again; reset clears it with the rest.
      next = platform.change(
        next,
        const SetPrayerAlertBefore(null, prayer: 'isha'),
      );
      expect(next.overrideFor('isha'), isEmpty);
      next = platform.change(next, const ResetPrayerAlert('fajr'));
      expect(next.overrideFor('fajr'), isEmpty);
      view = platform.view(next);
      expect(view.prayers['fajr']!.beforeMinutes, 10);
      expect(view.prayers['fajr']!.custom, isFalse);

      // "None" globally is stored as 0, never removed.
      next = platform.change(next, const SetPrayerAlertBefore(null));
      expect(next.values['advanceMinutes'], 0);
      expect(next.advanceActive, isFalse);
    });

    test('a refused test says why', () async {
      host.refuse = 'exactAccessDenied';
      expect(
        await platform.sendTest('dhuhr', base, title: '', body: ''),
        PrayerTestOutcome.exactAlarmsOff,
      );
      host.refuse = 'prayerDisabled';
      expect(
        await platform.sendTest('dhuhr', base, title: '', body: ''),
        PrayerTestOutcome.prayerOff,
      );
      expect(host.tests, ['dhuhr:10', 'dhuhr:10']);
    });
  });

  group('iOS', () {
    final platform = IOSPrayerAlertPlatform();
    tearDown(() => IOSPrayerBridge.status.value = const IOSPrayerStatus());

    test('one Prayer alarm; the whole adhan needs iOS 26.1', () {
      IOSPrayerBridge.status.value = const IOSPrayerStatus(
        supportsAlarms: true,
      );
      final older = platform.capabilities(const IOSPrayerExperience());
      expect(older.styles, [
        PrayerAlertStyle.silent,
        PrayerAlertStyle.short,
        PrayerAlertStyle.alarm,
      ]);
      // Before 26.1 an alarm plays only the opening, so there is no choice.
      expect(older.length, isFalse);
      var next = platform.change(
        const IOSPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.alarm),
      );
      expect(next.mode, IOSPrayerMode.alarm);
      expect(platform.view(next).openingOnly, isTrue);

      IOSPrayerBridge.status.value = const IOSPrayerStatus(
        supportsAlarms: true,
        fullAlarmAvailable: true,
      );
      final newer = platform.capabilities(const IOSPrayerExperience());
      expect(newer.length, isTrue);
      expect(newer.lengthOpening, isTrue);
      expect(newer.lengths, [null]);
      // The whole adhan is the default length.
      next = platform.change(
        const IOSPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.alarm),
      );
      expect(next.mode, IOSPrayerMode.fullAlarm);
      expect(platform.view(next).style, PrayerAlertStyle.alarm);
      expect(platform.view(next).openingOnly, isFalse);
      next = platform.change(
        next,
        const SetPrayerAlertLength(null, opening: true),
      );
      expect(next.mode, IOSPrayerMode.alarm);
      // Choosing the style again keeps the chosen length.
      next = platform.change(
        next,
        const SetPrayerAlertStyle(PrayerAlertStyle.alarm),
      );
      expect(next.mode, IOSPrayerMode.alarm);
      next = platform.change(next, const SetPrayerAlertLength(null));
      expect(next.mode, IOSPrayerMode.fullAlarm);
      // A length doesn't turn a notification into an alarm.
      final notification = platform.change(
        const IOSPrayerExperience(),
        const SetPrayerAlertLength(null, opening: true),
      );
      expect(notification.mode, IOSPrayerMode.short);
    });

    test('each prayer can have its own alarm length', () {
      IOSPrayerBridge.status.value = const IOSPrayerStatus(
        supportsAlarms: true,
        fullAlarmAvailable: true,
      );
      var next = platform.change(
        const IOSPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.alarm, prayer: 'fajr'),
      );
      expect(next.overrides['fajr']!.mode, IOSPrayerMode.fullAlarm);
      next = platform.change(
        next,
        const SetPrayerAlertLength(null, prayer: 'fajr', opening: true),
      );
      var fajr = platform.view(next).prayers['fajr']!;
      expect(next.overrides['fajr']!.mode, IOSPrayerMode.alarm);
      expect(fajr.openingOnly, isTrue);
      expect(fajr.tuning, {'opening': true});
      // The others are notifications, so the default length is the whole adhan.
      next = platform.change(
        next,
        const SetPrayerAlertLength(null, prayer: 'fajr', inherit: true),
      );
      expect(next.overrides['fajr']!.mode, IOSPrayerMode.fullAlarm);
      // When every prayer alarms, the default follows theirs.
      next = platform.change(
        next.copyWith(mode: IOSPrayerMode.alarm),
        const SetPrayerAlertLength(null, prayer: 'fajr', inherit: true),
      );
      fajr = platform.view(next).prayers['fajr']!;
      expect(next.overrides['fajr']?.mode, isNull);
      expect(fajr.openingOnly, isTrue);
      expect(fajr.tuning, isEmpty);
      next.validate();
    });

    test('before-prayer reminders can differ per prayer', () {
      var next = platform.change(
        const IOSPrayerExperience(),
        const SetPrayerAlertBefore(10),
      );
      next = platform.change(
        next,
        const SetPrayerAlertBefore(0, prayer: 'fajr'),
      );
      final view = platform.view(next);
      expect(view.prayers['dhuhr']!.beforeMinutes, 10);
      expect(view.prayers['fajr']!.beforeMinutes, 0);
      expect(view.prayers['fajr']!.ownBefore, isTrue);
      next.validate();
    });
  });

  group('macOS', () {
    final platform = MacPrayerAlertPlatform();

    test('short and full adhan map to the adhan delivery', () {
      final short = platform.change(
        const MacPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.short),
      );
      expect(short.mode, MacPrayerReminderMode.adhan);
      expect(short.delivery, MacPrayerAdhanDelivery.short);
      expect(short.configured, isTrue);
      expect(platform.view(short).style, PrayerAlertStyle.short);
    });

    test('a prayer can have its own delivery, recording and reminder', () {
      var next = platform.change(
        const MacPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.full),
      );
      next = platform.change(
        next,
        const SetPrayerAlertStyle(PrayerAlertStyle.short, prayer: 'fajr'),
      );
      next = platform.change(
        next,
        const SetPrayerAlertBefore(15, prayer: 'maghrib'),
      );
      next.validate();
      final read = MacPrayerExperience.fromMap(next.toMap());
      expect(read.forPrayer('fajr').delivery, MacPrayerAdhanDelivery.short);
      expect(read.forPrayer('dhuhr').delivery, MacPrayerAdhanDelivery.full);
      expect(read.forPrayer('maghrib').advanceMinutes, 15);
      expect(
        platform.view(read).prayers['fajr']!.style,
        PrayerAlertStyle.short,
      );
      // Settings saved by older versions have neither field.
      expect(const MacPrayerExperience().toMap(), isNot(contains('overrides')));
    });

    test('Full adhan or Focus turns on the menu bar and login, once', () {
      final full = platform.change(
        const MacPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.full),
      );
      expect(full.backgroundEnabled, isTrue);
      expect(full.startAtLogin, isTrue);
      full.validate();
      // The notification styles don't need Huda running.
      final short = platform.change(
        const MacPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.short),
      );
      expect(short.backgroundEnabled, isFalse);
      expect(short.startAtLogin, isFalse);
      // A user who turned them off keeps that until a live style is chosen.
      final off = platform.change(
        full,
        const SetPrayerAlertToggle('backgroundEnabled', false),
      );
      expect(off.startAtLogin, isFalse);
      expect(
        platform
            .change(off, const SetPrayerAlertToggle('quiet', true))
            .backgroundEnabled,
        isFalse,
      );
      final focus = platform.change(
        off,
        const SetPrayerAlertStyle(PrayerAlertStyle.focus, prayer: 'isha'),
      );
      expect(focus.backgroundEnabled, isTrue);
      expect(focus.startAtLogin, isTrue);
    });

    test('starting at login keeps Huda running in the background', () {
      final login = platform.change(
        const MacPrayerExperience(),
        const SetPrayerAlertToggle('startAtLogin', true),
      );
      expect(login.backgroundEnabled, isTrue);
      login.validate();
      final off = platform.change(
        login,
        const SetPrayerAlertToggle('backgroundEnabled', false),
      );
      expect(off.startAtLogin, isFalse);
      off.validate();
    });
  });

  group('Windows', () {
    final platform = WindowsPrayerAlertPlatform();

    test('the adhan needs the companion, so saving says so', () async {
      WindowsPrayerTaskbarBridge.status.value =
          const WindowsPrayerTaskbarStatus();
      final adhan = platform.change(
        const WindowsPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.full),
      );
      expect(adhan.mode, WindowsPrayerReminderMode.adhan);
      await expectLater(
        platform.apply(const WindowsPrayerExperience(), adhan),
        throwsA(
          isA<PrayerAlertApplyException>().having(
            (error) => error.failure,
            'failure',
            PrayerAlertSaveFailure.companionUnavailable,
          ),
        ),
      );
    });

    test(
      'prayers that are off change the toast signature like the companion',
      () {
        var next = platform.change(
          const WindowsPrayerExperience(),
          const SetPrayerAlertStyle(PrayerAlertStyle.silent),
        );
        next = platform.change(
          next,
          const SetPrayerAlertStyle(PrayerAlertStyle.off, prayer: 'isha'),
        );
        next = platform.change(
          next,
          const SetPrayerAlertStyle(PrayerAlertStyle.off, prayer: 'fajr'),
        );
        next = platform.change(
          next,
          const SetPrayerAlertStyle(PrayerAlertStyle.full, prayer: 'dhuhr'),
        );
        next = platform.change(next, const SetPrayerAlertBefore(5));
        // The same string as PrayerExperienceTests in the companion.
        expect(
          next.deliverySignature,
          'windows-reminders-v2:1:silent:off=fajr,isha',
        );
        final read = WindowsPrayerExperience.tryParse(next.toMap())!;
        expect(read.forPrayer('dhuhr').mode, WindowsPrayerReminderMode.adhan);
        expect(read.forPrayer('asr').advanceMinutes, 5);
        expect(
          platform.view(read).prayers['isha']!.style,
          PrayerAlertStyle.off,
        );
      },
    );

    test('Focus options map to the companion settings', () {
      final focus = platform.change(
        const WindowsPrayerExperience(),
        const SetPrayerAlertFocus(durationSeconds: 900, commitment: true),
      );
      expect(focus.focusDurationSeconds, 900);
      expect(focus.focusPreventEarlyExit, isTrue);
      expect(platform.view(focus).focusCommitment, isTrue);
    });
  });

  group('Linux', () {
    final platform = LinuxPrayerAlertPlatform();

    test('each prayer can differ, and the settings survive a round trip', () {
      var next = platform.change(
        const LinuxPrayerExperience(),
        const SetPrayerAlertStyle(PrayerAlertStyle.full),
      );
      next = platform.change(
        next,
        const SetPrayerAlertStyle(PrayerAlertStyle.off, prayer: 'isha'),
      );
      next = platform.change(
        next,
        const SetPrayerAlertReciter('mishary', 'v2', prayer: 'fajr'),
      );
      next = platform.change(next, const SetPrayerAlertBefore(10));
      next.validate();
      final view = platform.view(next);
      expect(view.prayers['isha']!.style, PrayerAlertStyle.off);
      expect(view.prayers['fajr']!.reciterId, 'mishary');
      expect(view.prayers['dhuhr']!.beforeMinutes, 10);
      final read = LinuxPrayerExperience.fromMap(next.toMap());
      expect(read.deliverySignature, next.deliverySignature);
      expect(read.forPrayer('fajr').audioVersion, 'v2');
      expect(read.forPrayer('isha').enabled, isFalse);
      // Older settings without these fields keep their signature.
      expect(
        const LinuxPrayerExperience(configured: true).deliverySignature,
        isNot(contains(':a')),
      );
      final reset = platform.change(next, const ResetPrayerAlert('fajr'));
      expect(reset.overrides.containsKey('fajr'), isFalse);
    });

    test('the whole adhan clears the length', () {
      final short = platform.change(
        const LinuxPrayerExperience(),
        const SetPrayerAlertLength(60),
      );
      expect(short.stopAfterSeconds, 60);
      final whole = platform.change(short, const SetPrayerAlertLength(null));
      expect(whole.stopAfterSeconds, isNull);
      expect(
        platform
            .change(whole, const SetPrayerAlertFocus(immersive: true))
            .focusStyle,
        LinuxPrayerFocusStyle.immersive,
      );
    });
  });
}
