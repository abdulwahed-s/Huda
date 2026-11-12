import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda/core/services/android_prayer_experience_service.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';

/// Android: the native policy saves at once; each prayer can differ in
/// everything, including volume, length and the alarm screen.
class AndroidPrayerAlertPlatform
    extends PrayerAlertPlatform<AndroidPrayerExperience> {
  AndroidPrayerAlertPlatform({required this.settings, required this.state}) {
    settings.addListener(_sync);
    _sync();
  }

  final AndroidPrayerExperienceService settings;
  final AndroidPrayerNotificationStateService state;
  final _applied = ValueNotifier<AndroidPrayerExperience?>(null);

  void _sync() => _applied.value = settings.policy;

  static const _styles = {
    'silent': PrayerAlertStyle.silent,
    'short': PrayerAlertStyle.full,
    'full': PrayerAlertStyle.full,
    'off': PrayerAlertStyle.off,
  };
  static const _perPrayerToggles = [
    'alarmScreenEnabled',
    'flipToStopEnabled',
    'vibrate',
  ];
  static const _tuningKeys = {
    'volumeGain',
    'fadeInSeconds',
    'stopAfterSeconds',
    ..._perPrayerToggles,
  };

  @override
  ValueListenable<AndroidPrayerExperience?> get applied => _applied;

  @override
  Future<void> refresh() async {
    await state.initialize();
    await settings.refresh();
  }

  @override
  PrayerAlertCapabilities capabilities(AndroidPrayerExperience settings) {
    final flip = state.snapshot?.capabilities.flipSensor ?? false;
    return PrayerAlertCapabilities(
      // "Short" is not a separate style here: it is the "Opening only"
      // length of the one Adhan style (the short recording).
      styles: const [PrayerAlertStyle.silent, PrayerAlertStyle.full],
      lengthOpening: true,
      styleNames: const {PrayerAlertStyle.full: 'prayerAlertStyleAdhan'},
      styleHints: const {PrayerAlertStyle.full: 'prayerAlertStyleAdhanHint'},
      perPrayer: true,
      perPrayerReciter: true,
      perPrayerTuning: true,
      volume: true,
      length: true,
      fadeIn: true,
      // Delivered natively like the prayers, on the "Before prayer" channel,
      // whose sound the user sets in Android's settings.
      beforeMinutes: AndroidPrayerExperience.advanceMinuteOptions
          .where((minutes) => minutes > 0)
          .toList(),
      toggles: [
        const PrayerAlertToggle('alarmScreenEnabled', perPrayer: true),
        if (flip) const PrayerAlertToggle('flipToStopEnabled', perPrayer: true),
        const PrayerAlertToggle('vibrate', perPrayer: true),
        const PrayerAlertToggle('respectRingerMode'),
        const PrayerAlertToggle('stopOnHeadsetDisconnect'),
        const PrayerAlertToggle('showMissedSummary'),
      ],
    );
  }

  @override
  PrayerAlertSettings view(AndroidPrayerExperience settings) {
    final values = settings.values;
    return PrayerAlertSettings(
      enabled: settings.enabled,
      style: _styles[values['defaultMode']] ?? PrayerAlertStyle.full,
      reciterId: values['reciterId'] as String,
      audioVersion: values['audioVersion'] as String,
      volume: (values['volumeGain'] as num).toDouble(),
      stopAfterSeconds: (values['stopAfterSeconds'] as num?)?.toInt(),
      fadeInSeconds: (values['fadeInSeconds'] as num).toInt(),
      openingOnly: values['defaultMode'] == 'short',
      beforeMinutes: (values['advanceMinutes'] as num).toInt(),
      toggles: {
        for (final entry in values.entries)
          if (entry.value is bool) entry.key: entry.value as bool,
      },
      prayers: {
        for (final prayer in AndroidPrayerExperience.prayers)
          prayer: _prayer(settings, prayer),
      },
    );
  }

  PrayerAlertPrayer _prayer(AndroidPrayerExperience settings, String prayer) {
    final own = settings.overrideFor(prayer);
    final effective = settings.effective(prayer);
    return PrayerAlertPrayer(
      style: _styles[effective['mode']] ?? PrayerAlertStyle.full,
      reciterId: effective['reciterId'] as String,
      beforeMinutes: (effective['advanceMinutes'] as num).toInt(),
      ownStyle: own.containsKey('mode'),
      ownReciter: own.containsKey('reciterId'),
      ownBefore: own.containsKey('advanceMinutes'),
      ownTuning: own.keys.any(_tuningKeys.contains),
      tuning: {
        for (final entry in own.entries)
          if (_tuningKeys.contains(entry.key)) entry.key: entry.value,
        // The opening is this prayer's own length when its mode is short.
        if (own['mode'] == 'short') 'opening': true,
      },
      openingOnly: effective['mode'] == 'short',
    );
  }

  @override
  AndroidPrayerExperience change(
    AndroidPrayerExperience settings,
    PrayerAlertChange change,
  ) {
    final prayer = change.prayer;
    Map<String, Object?> values = switch (change) {
      SetPrayerAlertsEnabled(:final enabled) => {'enabled': enabled},
      // Choosing Adhan again keeps "Opening only" if it was chosen.
      SetPrayerAlertStyle(:final style) when prayer == null => {
        'defaultMode':
            style == PrayerAlertStyle.full &&
                settings.values['defaultMode'] == 'short'
            ? 'short'
            : style!.name,
      },
      SetPrayerAlertStyle(:final style) => {
        'mode':
            style == PrayerAlertStyle.full &&
                settings.overrideFor(prayer!)['mode'] == 'short'
            ? 'short'
            : style?.name,
      },
      SetPrayerAlertLength(opening: true) when prayer == null => {
        'defaultMode': 'short',
      },
      SetPrayerAlertLength(opening: true) => {'mode': 'short'},
      SetPrayerAlertReciter(:final reciterId, :final audioVersion) => {
        'reciterId': reciterId,
        'audioVersion': reciterId == null ? null : audioVersion,
      },
      SetPrayerAlertVolume(:final volume) => {'volumeGain': volume},
      SetPrayerAlertLength(:final seconds, :final inherit) => {
        // A length other than the opening plays the full recording.
        if (prayer == null && settings.values['defaultMode'] == 'short')
          'defaultMode': 'full',
        if (prayer != null && settings.overrideFor(prayer)['mode'] == 'short')
          'mode': inherit ? null : 'full',
        // A prayer can't store "the whole recording" as empty; an hour is
        // longer than any adhan.
        'stopAfterSeconds': inherit
            ? null
            : prayer != null
            ? seconds ?? 3600
            : seconds,
      },
      SetPrayerAlertFadeIn(:final seconds) => {'fadeInSeconds': seconds},
      // For a prayer, null follows the default again.
      SetPrayerAlertBefore(:final minutes) => {
        'advanceMinutes': prayer == null ? minutes ?? 0 : minutes,
      },
      SetPrayerAlertToggle(:final key, :final value) => {key: value},
      ResetPrayerAlert() => {
        for (final key in AndroidPrayerExperience.overrideKeys) key: null,
      },
      _ => const {},
    };
    if (values.isEmpty) return settings;
    return settings.edit(values, prayer: prayer);
  }

  @override
  Future<AndroidPrayerExperience> apply(
    AndroidPrayerExperience previous,
    AndroidPrayerExperience next,
  ) => settings.update({...next.values});

  @override
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    AndroidPrayerExperience settings, {
    required String title,
    required String body,
  }) async {
    try {
      await state.platform.host.runDeliveryTest(prayer, 10);
      return PrayerTestOutcome.scheduled;
    } on PlatformException catch (error) {
      final reason = '${error.code} ${error.message}';
      if (reason.contains('prayerDisabled')) return PrayerTestOutcome.prayerOff;
      if (reason.contains('notificationsBlocked')) {
        return PrayerTestOutcome.notificationsOff;
      }
      if (reason.contains('exactAccessDenied')) {
        return PrayerTestOutcome.exactAlarmsOff;
      }
      return PrayerTestOutcome.failed;
    } catch (_) {
      return PrayerTestOutcome.failed;
    }
  }

  @override
  Future<void> stopTest() => state.stop();
}
