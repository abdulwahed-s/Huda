import 'package:flutter/foundation.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_common.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:uuid/uuid.dart';

/// Windows: toasts are silent; Huda's companion plays the adhan or shows
/// Focus. Saving replaces the queued toasts only when their text changes.
class WindowsPrayerAlertPlatform
    extends PrayerAlertPlatform<WindowsPrayerExperience> {
  final _test = DelayedPrayerTest();
  String? _testSession;

  @override
  ValueListenable<WindowsPrayerExperience?> get applied =>
      WindowsPrayerTaskbarBridge.experience;

  @override
  Duration get debounce => const Duration(milliseconds: 700);

  @override
  Future<void> refresh() => WindowsPrayerTaskbarBridge.refreshStatus();

  /// Per-prayer settings need a companion that knows them (version 3).
  static bool get _perPrayer =>
      WindowsPrayerTaskbarBridge.status.value.prayerExperienceVersion >= 3;

  @override
  PrayerAlertCapabilities capabilities(WindowsPrayerExperience settings) =>
      PrayerAlertCapabilities(
        perPrayer: _perPrayer,
        perPrayerReciter: _perPrayer,
        beforeMinutes: _perPrayer ? const [5, 10, 15, 30] : const [],
        // Reminders before prayers are shown by Huda's companion.
        needsCompanion: true,
        styles: const [
          PrayerAlertStyle.silent,
          PrayerAlertStyle.full,
          PrayerAlertStyle.focus,
        ],
        volume: true,
        length: true,
      );

  static PrayerAlertStyle _style(WindowsPrayerExperience settings) =>
      switch (settings.mode) {
        WindowsPrayerReminderMode.silent => PrayerAlertStyle.silent,
        WindowsPrayerReminderMode.adhan => PrayerAlertStyle.full,
        WindowsPrayerReminderMode.focus => PrayerAlertStyle.focus,
      };

  @override
  PrayerAlertSettings view(WindowsPrayerExperience settings) {
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
      focusCommitment: settings.focusPreventEarlyExit,
      beforeMinutes: settings.advanceMinutes,
      prayers: {
        for (final prayer in prayerAlertPrayers)
          prayer: _prayer(settings, prayer),
      },
    );
  }

  PrayerAlertPrayer _prayer(WindowsPrayerExperience settings, String prayer) {
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

  static WindowsPrayerReminderMode _mode(PrayerAlertStyle style) =>
      switch (style) {
        PrayerAlertStyle.focus => WindowsPrayerReminderMode.focus,
        PrayerAlertStyle.silent => WindowsPrayerReminderMode.silent,
        _ => WindowsPrayerReminderMode.adhan,
      };

  WindowsPrayerExperience _own(
    WindowsPrayerExperience settings,
    String prayer,
    WindowsPrayerOverride Function(WindowsPrayerOverride own) update,
  ) {
    final next = update(
      settings.overrides[prayer] ?? const WindowsPrayerOverride(),
    );
    final overrides = {...settings.overrides};
    if (next.isEmpty) {
      overrides.remove(prayer);
    } else {
      overrides[prayer] = next;
    }
    return settings.copyWith(configured: true, overrides: overrides);
  }

  WindowsPrayerExperience _changePrayer(
    WindowsPrayerExperience settings,
    String prayer,
    PrayerAlertChange change,
  ) => switch (change) {
    SetPrayerAlertStyle(:final style) => _own(
      settings,
      prayer,
      (own) => WindowsPrayerOverride(
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
      (own) => WindowsPrayerOverride(
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
      (own) => WindowsPrayerOverride(
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
  WindowsPrayerExperience change(
    WindowsPrayerExperience settings,
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
      ) =>
        settings.copyWith(
          focusDurationSeconds: durationSeconds,
          focusAudio: audio,
          focusPreventEarlyExit: commitment,
        ),
      _ => settings,
    };
    return next.copyWith(configured: true);
  }

  @override
  Future<WindowsPrayerExperience> apply(
    WindowsPrayerExperience previous,
    WindowsPrayerExperience next,
  ) async {
    final settings = next.copyWith(configured: true);
    if (!WindowsPrayerTaskbarBridge.status.value.helperAvailable &&
        settings.enabled &&
        settings.mode != WindowsPrayerReminderMode.silent) {
      throw const PrayerAlertApplyException(
        PrayerAlertSaveFailure.companionUnavailable,
      );
    }
    try {
      await WindowsPrayerTaskbarBridge.applyExperience(
        settings,
        reconcile: () async {
          await reconcilePrayerAlerts('windows-prayer-experience-changed');
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.scheduled,
          );
        },
      );
    } on PrayerAlertApplyException {
      rethrow;
    } catch (error) {
      throw PrayerAlertApplyException(PrayerAlertSaveFailure.unknown, error);
    }
    return WindowsPrayerTaskbarBridge.experience.value;
  }

  @override
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    WindowsPrayerExperience settings, {
    required String title,
    required String body,
  }) async {
    final status = WindowsPrayerTaskbarBridge.status.value;
    final effective = settings.forPrayer(prayer);
    if (!effective.enabled) return PrayerTestOutcome.prayerOff;
    if (!status.helperAvailable) return PrayerTestOutcome.serviceNotRunning;
    if (!await _test.wait()) return PrayerTestOutcome.scheduled;
    try {
      final session = _testSession = 'preview:${const Uuid().v4()}';
      final result = await WindowsPrayerTaskbarBridge.experienceCommand(
        'previewNotification',
        sessionId: session,
        settings: effective.copyWith(configured: true),
      );
      return result.prayerAudioError != null && effective.playsAudio
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
    for (final command in [
      'clearPreviewNotification',
      'dismissFocus',
      'stopAdhan',
    ]) {
      try {
        await WindowsPrayerTaskbarBridge.experienceCommand(
          command,
          sessionId: session,
        );
      } catch (_) {}
    }
  }
}
