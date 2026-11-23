import 'package:flutter/foundation.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';
import 'package:huda/core/services/linux_prayer_notification_gateway.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_common.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:uuid/uuid.dart';

/// Linux: Huda's background service saves the settings and delivers alerts.
class LinuxPrayerAlertPlatform
    extends PrayerAlertPlatform<LinuxPrayerExperience> {
  LinuxPrayerAlertPlatform() {
    LinuxPrayerNotificationGateway.status.addListener(_sync);
    _sync();
  }

  final _applied = ValueNotifier<LinuxPrayerExperience?>(null);
  final _test = DelayedPrayerTest();
  String? _testSession;

  void _sync() =>
      _applied.value = LinuxPrayerNotificationGateway.status.value.experience;

  @override
  ValueListenable<LinuxPrayerExperience?> get applied => _applied;

  @override
  Future<void> refresh() async {
    await LinuxPrayerNotificationGateway.refresh();
    _sync();
  }

  /// Per-prayer settings need a companion that knows them (version 2).
  static bool get _perPrayer =>
      LinuxPrayerNotificationGateway.status.value.experienceVersion >= 2;

  @override
  PrayerAlertCapabilities capabilities(LinuxPrayerExperience settings) =>
      PrayerAlertCapabilities(
        perPrayer: _perPrayer,
        perPrayerReciter: _perPrayer,
        // The legacy helper (Plasma, XFCE) delivers prayers from Huda's
        // plan and has no reminders before them.
        beforeMinutes:
            _perPrayer &&
                LinuxPrayerNotificationGateway.status.value.deliveryOwner ==
                    'native'
            ? const [5, 10, 15, 30]
            : const [],
        styles: const [
          PrayerAlertStyle.silent,
          PrayerAlertStyle.full,
          PrayerAlertStyle.focus,
        ],
        volume: true,
        length: true,
        focusStyle: true,
        toggles: [
          if (LinuxPrayerNotificationGateway.status.value.supportsLockedAudio)
            const PrayerAlertToggle('allowLockedAudio'),
          const PrayerAlertToggle('quiet'),
          const PrayerAlertToggle('backgroundEnabled'),
        ],
      );

  static PrayerAlertStyle _style(LinuxPrayerExperience settings) =>
      switch (settings.mode) {
        LinuxPrayerReminderMode.silent => PrayerAlertStyle.silent,
        LinuxPrayerReminderMode.adhan => PrayerAlertStyle.full,
        LinuxPrayerReminderMode.focus => PrayerAlertStyle.focus,
      };

  @override
  PrayerAlertSettings view(LinuxPrayerExperience settings) {
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
      focusImmersive: settings.focusStyle == LinuxPrayerFocusStyle.immersive,
      toggles: {
        'allowLockedAudio': settings.allowLockedAudio,
        'quiet': settings.quiet,
        'backgroundEnabled': settings.backgroundEnabled,
      },
      beforeMinutes: settings.advanceMinutes,
      prayers: {
        for (final prayer in prayerAlertPrayers)
          prayer: _prayer(settings, prayer),
      },
    );
  }

  PrayerAlertPrayer _prayer(LinuxPrayerExperience settings, String prayer) {
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

  static LinuxPrayerReminderMode _mode(PrayerAlertStyle style) =>
      switch (style) {
        PrayerAlertStyle.focus => LinuxPrayerReminderMode.focus,
        PrayerAlertStyle.silent => LinuxPrayerReminderMode.silent,
        _ => LinuxPrayerReminderMode.adhan,
      };

  LinuxPrayerExperience _own(
    LinuxPrayerExperience settings,
    String prayer,
    LinuxPrayerOverride Function(LinuxPrayerOverride own) update,
  ) {
    final next = update(
      settings.overrides[prayer] ?? const LinuxPrayerOverride(),
    );
    final overrides = {...settings.overrides};
    if (next.isEmpty) {
      overrides.remove(prayer);
    } else {
      overrides[prayer] = next;
    }
    return settings.copyWith(configured: true, overrides: overrides);
  }

  LinuxPrayerExperience _changePrayer(
    LinuxPrayerExperience settings,
    String prayer,
    PrayerAlertChange change,
  ) => switch (change) {
    SetPrayerAlertStyle(:final style) => _own(
      settings,
      prayer,
      (own) => LinuxPrayerOverride(
        off: style == PrayerAlertStyle.off,
        mode: style == null || style == PrayerAlertStyle.off
            ? null
            : _mode(style),
        reciterId: own.reciterId,
        audioVersion: own.audioVersion,
        advanceMinutes: own.advanceMinutes,
      ),
    ),
    SetPrayerAlertReciter(:final reciterId, :final audioVersion) => _own(
      settings,
      prayer,
      (own) => LinuxPrayerOverride(
        off: own.off,
        mode: own.mode,
        reciterId: reciterId,
        audioVersion: reciterId == null ? null : audioVersion,
        advanceMinutes: own.advanceMinutes,
      ),
    ),
    SetPrayerAlertBefore(:final minutes) => _own(
      settings,
      prayer,
      (own) => LinuxPrayerOverride(
        off: own.off,
        mode: own.mode,
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
  LinuxPrayerExperience change(
    LinuxPrayerExperience settings,
    PrayerAlertChange change,
  ) {
    if (change.prayer case final prayer?) {
      return _changePrayer(settings, prayer, change);
    }
    final next = switch (change) {
      SetPrayerAlertsEnabled(:final enabled) => settings.copyWith(
        enabled: enabled,
      ),
      SetPrayerAlertStyle(:final style) => settings.copyWith(
        mode: _mode(style!),
      ),
      SetPrayerAlertBefore(:final minutes) => settings.copyWith(
        advanceMinutes: minutes ?? 0,
      ),
      SetPrayerAlertReciter(:final reciterId, :final audioVersion) =>
        settings.copyWith(reciterId: reciterId, audioVersion: audioVersion),
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
              ? LinuxPrayerFocusStyle.immersive
              : LinuxPrayerFocusStyle.compact,
        ),
      SetPrayerAlertToggle(:final key, :final value) => switch (key) {
        'allowLockedAudio' => settings.copyWith(allowLockedAudio: value),
        'quiet' => settings.copyWith(quiet: value),
        'backgroundEnabled' => settings.copyWith(backgroundEnabled: value),
        _ => settings,
      },
      _ => settings,
    };
    return next.copyWith(configured: true);
  }

  @override
  Future<LinuxPrayerExperience> apply(
    LinuxPrayerExperience previous,
    LinuxPrayerExperience next,
  ) async {
    final LinuxPrayerStatus receipt;
    try {
      receipt = await LinuxPrayerNotificationGateway.applyExperience(
        next.copyWith(configured: true),
        startAtLogin: LinuxPrayerTrayBridge.preferences.value.startAtLogin,
      );
    } catch (error) {
      throw PrayerAlertApplyException(
        PrayerAlertSaveFailure.serviceUnavailable,
        error,
      );
    }
    await reconcilePrayerAlerts('linux-prayer-settings');
    return receipt.experience;
  }

  @override
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    LinuxPrayerExperience settings, {
    required String title,
    required String body,
  }) async {
    final effective = settings.forPrayer(prayer);
    if (!effective.enabled) return PrayerTestOutcome.prayerOff;
    if (!LinuxPrayerTrayBridge.status.value.serviceAvailable) {
      return PrayerTestOutcome.serviceNotRunning;
    }
    if (!await _test.wait()) return PrayerTestOutcome.scheduled;
    try {
      final session = _testSession = 'preview:${const Uuid().v4()}';
      final result = await LinuxPrayerNotificationGateway.command(
        'previewNotification',
        sessionId: session,
        settings: effective.copyWith(configured: true, overrides: const {}),
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
      await LinuxPrayerNotificationGateway.command(
        'stopPreview',
        sessionId: session,
      );
    } catch (_) {}
  }
}
