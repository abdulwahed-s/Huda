import 'package:flutter/foundation.dart';
import 'package:huda/core/services/mac_prayer_bridge.dart';
import 'package:huda/core/services/mac_prayer_experience.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_common.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:uuid/uuid.dart';

/// macOS: the native service saves its settings and rebuilds its queue.
class MacPrayerAlertPlatform extends PrayerAlertPlatform<MacPrayerExperience> {
  MacPrayerAlertPlatform() {
    MacPrayerBridge.status.addListener(_sync);
    _sync();
  }

  final _applied = ValueNotifier<MacPrayerExperience?>(null);
  final _test = DelayedPrayerTest();
  String? _testSession;
  MacPrayerStatus? _receipt;

  void _sync() {
    final status = MacPrayerBridge.status.value;
    if (status.revision > 0) _applied.value = status.experience;
  }

  @override
  ValueListenable<MacPrayerExperience?> get applied => _applied;

  @override
  Future<void> refresh() async {
    await MacPrayerBridge.refresh();
    _sync();
  }

  @override
  PrayerAlertCapabilities capabilities(MacPrayerExperience settings) =>
      PrayerAlertCapabilities(
        perPrayer: true,
        perPrayerReciter: true,
        beforeMinutes: const [5, 10, 15, 30],
        // Here the two really differ: the notification's own sound (up to
        // 30 s, even with Huda closed) or Huda playing the whole adhan.
        styleNames: const {
          PrayerAlertStyle.short: 'prayerAlertStyleNotificationAdhan',
        },
        styleHints: const {
          PrayerAlertStyle.short: 'prayerAlertStyleNotificationAdhanHint',
          PrayerAlertStyle.full: 'prayerAlertStyleLiveAdhanHint',
        },
        styles: const [
          PrayerAlertStyle.silent,
          PrayerAlertStyle.short,
          PrayerAlertStyle.full,
          PrayerAlertStyle.focus,
        ],
        volume: true,
        length: true,
        focusStyle: true,
        toggles: [
          if (MacPrayerBridge.status.value.supportsTimeSensitive)
            const PrayerAlertToggle('timeSensitive'),
          const PrayerAlertToggle('allowLockedAudio'),
          const PrayerAlertToggle('quiet'),
          const PrayerAlertToggle('backgroundEnabled'),
          if (settings.backgroundEnabled)
            const PrayerAlertToggle('startAtLogin'),
        ],
      );

  static PrayerAlertStyle _style(MacPrayerExperience settings) =>
      switch (settings.mode) {
        MacPrayerReminderMode.silent => PrayerAlertStyle.silent,
        MacPrayerReminderMode.focus => PrayerAlertStyle.focus,
        MacPrayerReminderMode.adhan =>
          settings.delivery == MacPrayerAdhanDelivery.short
              ? PrayerAlertStyle.short
              : PrayerAlertStyle.full,
      };

  @override
  PrayerAlertSettings view(MacPrayerExperience settings) {
    final style = _style(settings);
    return PrayerAlertSettings(
      enabled: settings.enabled,
      style: style,
      reciterId: settings.reciterId,
      audioVersion: settings.audioVersion,
      volume: settings.volume,
      stopAfterSeconds: settings.stopAfterSeconds,
      focusDurationSeconds: settings.focusDurationSeconds,
      focusAudio: settings.focusAudio,
      focusCommitment: settings.focusCommitment,
      focusImmersive: settings.focusStyle == MacPrayerFocusStyle.immersive,
      toggles: {
        'timeSensitive': settings.timeSensitive,
        'allowLockedAudio': settings.allowLockedAudio,
        'quiet': settings.quiet,
        'backgroundEnabled': settings.backgroundEnabled,
        'startAtLogin': settings.startAtLogin,
      },
      beforeMinutes: settings.advanceMinutes,
      prayers: {
        for (final prayer in prayerAlertPrayers)
          prayer: _prayer(settings, prayer),
      },
    );
  }

  PrayerAlertPrayer _prayer(MacPrayerExperience settings, String prayer) {
    final own = settings.overrides[prayer];
    final effective = settings.forPrayer(prayer);
    return PrayerAlertPrayer(
      style: effective.enabled ? _style(effective) : PrayerAlertStyle.off,
      reciterId: effective.reciterId,
      beforeMinutes: effective.advanceMinutes,
      ownStyle: own != null && (own.off || own.mode != null),
      ownReciter: own?.reciterId != null,
      ownBefore: own?.advanceMinutes != null,
    );
  }

  MacPrayerExperience _own(
    MacPrayerExperience settings,
    String prayer,
    MacPrayerOverride Function(MacPrayerOverride own) update,
  ) {
    final next = update(
      settings.overrides[prayer] ?? const MacPrayerOverride(),
    );
    final overrides = {...settings.overrides};
    if (next.isEmpty) {
      overrides.remove(prayer);
    } else {
      overrides[prayer] = next;
    }
    return settings.copyWith(configured: true, overrides: overrides);
  }

  MacPrayerExperience _changePrayer(
    MacPrayerExperience settings,
    String prayer,
    PrayerAlertChange change,
  ) => switch (change) {
    SetPrayerAlertStyle(:final style) => _own(
      settings,
      prayer,
      (own) => MacPrayerOverride(
        off: style == PrayerAlertStyle.off,
        mode: switch (style) {
          null || PrayerAlertStyle.off => null,
          PrayerAlertStyle.silent => MacPrayerReminderMode.silent,
          PrayerAlertStyle.focus => MacPrayerReminderMode.focus,
          _ => MacPrayerReminderMode.adhan,
        },
        delivery: switch (style) {
          PrayerAlertStyle.short => MacPrayerAdhanDelivery.short,
          PrayerAlertStyle.full => MacPrayerAdhanDelivery.full,
          _ => null,
        },
        reciterId: own.reciterId,
        audioVersion: own.audioVersion,
        advanceMinutes: own.advanceMinutes,
      ),
    ),
    SetPrayerAlertReciter(:final reciterId, :final audioVersion) => _own(
      settings,
      prayer,
      (own) => MacPrayerOverride(
        off: own.off,
        mode: own.mode,
        delivery: own.delivery,
        reciterId: reciterId,
        audioVersion: reciterId == null ? null : audioVersion,
        advanceMinutes: own.advanceMinutes,
      ),
    ),
    SetPrayerAlertBefore(:final minutes) => _own(
      settings,
      prayer,
      (own) => MacPrayerOverride(
        off: own.off,
        mode: own.mode,
        delivery: own.delivery,
        reciterId: own.reciterId,
        audioVersion: own.audioVersion,
        advanceMinutes: minutes,
      ),
    ),
    ResetPrayerAlert() => settings.copyWith(
      configured: true,
      overrides: {...settings.overrides}..remove(prayer),
    ),
    _ => settings,
  };

  @override
  MacPrayerExperience change(
    MacPrayerExperience settings,
    PrayerAlertChange change,
  ) {
    if (change.prayer case final prayer?) {
      return _changePrayer(settings, prayer, change);
    }
    final next = switch (change) {
      SetPrayerAlertsEnabled(:final enabled) => settings.copyWith(
        enabled: enabled,
      ),
      SetPrayerAlertStyle(style: PrayerAlertStyle.silent) => settings.copyWith(
        mode: MacPrayerReminderMode.silent,
      ),
      SetPrayerAlertStyle(style: PrayerAlertStyle.focus) => settings.copyWith(
        mode: MacPrayerReminderMode.focus,
      ),
      SetPrayerAlertStyle(:final style) => settings.copyWith(
        mode: MacPrayerReminderMode.adhan,
        delivery: style == PrayerAlertStyle.short
            ? MacPrayerAdhanDelivery.short
            : MacPrayerAdhanDelivery.full,
      ),
      SetPrayerAlertReciter(:final reciterId, :final audioVersion) =>
        settings.copyWith(reciterId: reciterId, audioVersion: audioVersion),
      SetPrayerAlertBefore(:final minutes) => settings.copyWith(
        advanceMinutes: minutes ?? 0,
      ),
      SetPrayerAlertVolume(:final volume) => settings.copyWith(volume: volume),
      SetPrayerAlertLength(:final seconds) => settings.copyWith(
        stopAfterSeconds: seconds,
        clearCutoff: seconds == null,
      ),
      SetPrayerAlertFocus(
        :final durationSeconds,
        :final audio,
        :final commitment,
        :final immersive,
      ) =>
        settings.copyWith(
          focusDurationSeconds: durationSeconds,
          focusAudio: audio,
          focusCommitment: commitment,
          focusStyle: immersive == null
              ? null
              : immersive
              ? MacPrayerFocusStyle.immersive
              : MacPrayerFocusStyle.compact,
        ),
      SetPrayerAlertToggle(:final key, :final value) => switch (key) {
        'timeSensitive' => settings.copyWith(timeSensitive: value),
        'allowLockedAudio' => settings.copyWith(allowLockedAudio: value),
        'quiet' => settings.copyWith(quiet: value),
        // Starting at login needs Huda to keep running in the menu bar.
        'backgroundEnabled' => settings.copyWith(
          backgroundEnabled: value,
          startAtLogin: value == true ? null : false,
        ),
        'startAtLogin' => settings.copyWith(
          startAtLogin: value,
          backgroundEnabled: value == true ? true : null,
        ),
        _ => settings,
      },
      _ => settings,
    };
    return next.copyWith(configured: true);
  }

  @override
  Future<MacPrayerExperience> apply(
    MacPrayerExperience previous,
    MacPrayerExperience next,
  ) async {
    try {
      _receipt = await MacPrayerBridge.applyExperience(
        next.copyWith(configured: true),
      );
    } catch (error) {
      throw PrayerAlertApplyException(PrayerAlertSaveFailure.unknown, error);
    }
    await reconcilePrayerAlerts('mac-prayer-settings');
    return _receipt!.experience;
  }

  @override
  String? warning(MacPrayerExperience requested, MacPrayerExperience _) {
    final receipt = _receipt;
    return requested.startAtLogin &&
            receipt != null &&
            receipt.startupState != 'enabled'
        ? 'prayerAlertStartupWarning'
        : null;
  }

  @override
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    MacPrayerExperience settings, {
    required String title,
    required String body,
  }) async {
    final status = MacPrayerBridge.status.value;
    if (status.authorization != 'authorized' &&
        status.authorization != 'provisional') {
      return PrayerTestOutcome.notificationsOff;
    }
    final effective = settings.forPrayer(prayer);
    if (!effective.enabled) return PrayerTestOutcome.prayerOff;
    if (!await _test.wait()) return PrayerTestOutcome.scheduled;
    try {
      final session = _testSession = 'preview:${const Uuid().v4()}';
      final result = await MacPrayerBridge.command(
        'previewNotification',
        sessionId: session,
        settings: effective.copyWith(configured: true),
        prayer: prayer,
      );
      return result.audioError != null && effective.needsAudio
          ? PrayerTestOutcome.audioMissing
          : PrayerTestOutcome.scheduled;
    } catch (_) {
      return PrayerTestOutcome.failed;
    }
  }

  @override
  Future<void> stopTest() async {
    _test.cancel();
    final session = _testSession;
    _testSession = null;
    if (session == null) return;
    try {
      await MacPrayerBridge.command('stopPreview', sessionId: session);
    } catch (_) {}
  }
}
