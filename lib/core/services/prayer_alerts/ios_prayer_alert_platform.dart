import 'package:flutter/foundation.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/ios_prayer_experience.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_common.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';

/// iOS: native settings apply, then the schedule is rebuilt. Prayers can each
/// differ, and can have a reminder before the prayer.
class IOSPrayerAlertPlatform extends PrayerAlertPlatform<IOSPrayerExperience> {
  IOSPrayerAlertPlatform() {
    IOSPrayerBridge.status.addListener(_sync);
    _sync();
  }

  final _applied = ValueNotifier<IOSPrayerExperience?>(null);
  bool _loaded = false;

  void _sync() {
    if (_loaded || IOSPrayerBridge.status.value.revision > 0) {
      _applied.value = IOSPrayerBridge.status.value.experience;
    }
  }

  static const _styles = {
    IOSPrayerMode.off: PrayerAlertStyle.off,
    IOSPrayerMode.silent: PrayerAlertStyle.silent,
    IOSPrayerMode.short: PrayerAlertStyle.short,
    IOSPrayerMode.alarm: PrayerAlertStyle.alarm,
    IOSPrayerMode.fullAlarm: PrayerAlertStyle.fullAlarm,
  };
  static IOSPrayerMode _mode(PrayerAlertStyle style) =>
      _styles.entries.firstWhere((entry) => entry.value == style).key;

  @override
  ValueListenable<IOSPrayerExperience?> get applied => _applied;

  @override
  Duration get debounce => const Duration(milliseconds: 700);

  @override
  Future<void> refresh() async {
    await IOSPrayerBridge.refresh();
    _loaded = true;
    _sync();
  }

  @override
  PrayerAlertCapabilities capabilities(IOSPrayerExperience settings) {
    final status = IOSPrayerBridge.status.value;
    return PrayerAlertCapabilities(
      styles: [
        PrayerAlertStyle.silent,
        PrayerAlertStyle.short,
        if (status.supportsAlarms) PrayerAlertStyle.alarm,
        if (status.supportsAlarms) PrayerAlertStyle.fullAlarm,
      ],
      // The whole adhan as the alarm sound plays from iOS 26.1 (custom alarm
      // sounds); before that iOS uses the short Prayer alarm instead.
      unavailable: {
        if (status.supportsAlarms && !status.fullAlarmAvailable)
          PrayerAlertStyle.fullAlarm: 'prayerAlertFullAlarmUnavailable',
      },
      perPrayer: true,
      perPrayerReciter: true,
      beforeMinutes: iosPrayerAdvanceMinutes.where((m) => m > 0).toList(),
      beforeStyle: true,
      fallback: status.supportsAlarms,
      toggles: const [PrayerAlertToggle('timeSensitive')],
    );
  }

  @override
  PrayerAlertSettings view(IOSPrayerExperience settings) => PrayerAlertSettings(
    enabled: settings.enabled,
    style: _styles[settings.mode]!,
    reciterId: settings.reciterId,
    audioVersion: settings.audioVersion,
    beforeMinutes: settings.advanceMinutes,
    beforeStyle: _styles[settings.advanceMode]!,
    fallbackStyle: _styles[settings.fallback]!,
    toggles: {'timeSensitive': settings.timeSensitive},
    prayers: {
      for (final prayer in iosPrayerKeys)
        prayer: PrayerAlertPrayer(
          style: _styles[settings.policyFor(prayer).mode]!,
          reciterId: settings.policyFor(prayer).reciterId!,
          beforeMinutes: settings.policyFor(prayer).advanceMinutes!,
          ownStyle: settings.overrides[prayer]?.mode != null,
          ownReciter: settings.overrides[prayer]?.reciterId != null,
          ownBefore: settings.overrides[prayer]?.advanceMinutes != null,
        ),
    },
  );

  IOSPrayerExperience _override(
    IOSPrayerExperience settings,
    String prayer,
    IOSPrayerOverride Function(IOSPrayerOverride current) update,
  ) {
    final next = update(
      settings.overrides[prayer] ?? const IOSPrayerOverride(),
    );
    final overrides = {...settings.overrides};
    if (next.toMap().isEmpty) {
      overrides.remove(prayer);
    } else {
      overrides[prayer] = next;
    }
    return settings.copyWith(overrides: overrides);
  }

  @override
  IOSPrayerExperience change(
    IOSPrayerExperience settings,
    PrayerAlertChange change,
  ) {
    final prayer = change.prayer;
    if (prayer != null) {
      return switch (change) {
        SetPrayerAlertStyle(:final style) => _override(
          settings,
          prayer,
          (own) => IOSPrayerOverride(
            mode: style == null ? null : _mode(style),
            reciterId: own.reciterId,
            advanceMinutes: own.advanceMinutes,
            advanceMode: own.advanceMode,
          ),
        ),
        SetPrayerAlertReciter(:final reciterId) => _override(
          settings,
          prayer,
          (own) => IOSPrayerOverride(
            mode: own.mode,
            reciterId: reciterId,
            advanceMinutes: own.advanceMinutes,
            advanceMode: own.advanceMode,
          ),
        ),
        SetPrayerAlertBefore(:final minutes) => _override(
          settings,
          prayer,
          (own) => IOSPrayerOverride(
            mode: own.mode,
            reciterId: own.reciterId,
            advanceMinutes: minutes,
            advanceMode: own.advanceMode,
          ),
        ),
        ResetPrayerAlert() => settings.copyWith(
          overrides: {...settings.overrides}..remove(prayer),
        ),
        _ => settings,
      };
    }
    return switch (change) {
      SetPrayerAlertsEnabled(:final enabled) => settings.copyWith(
        enabled: enabled,
      ),
      SetPrayerAlertStyle(:final style) => settings.copyWith(
        mode: _mode(style!),
      ),
      SetPrayerAlertReciter(:final reciterId, :final audioVersion) =>
        settings.copyWith(reciterId: reciterId, audioVersion: audioVersion),
      SetPrayerAlertBefore(:final minutes) => settings.copyWith(
        advanceMinutes: minutes ?? 0,
      ),
      SetPrayerAlertBeforeStyle(:final style) => settings.copyWith(
        advanceMode: _mode(style),
      ),
      SetPrayerAlertFallback(:final style) => settings.copyWith(
        fallback: _mode(style),
      ),
      SetPrayerAlertToggle(key: 'timeSensitive', :final value) =>
        settings.copyWith(timeSensitive: value),
      _ => settings,
    };
  }

  @override
  Future<IOSPrayerExperience> apply(
    IOSPrayerExperience previous,
    IOSPrayerExperience next,
  ) async {
    try {
      await IOSPrayerBridge.applyExperience(next);
    } catch (error) {
      throw PrayerAlertApplyException(PrayerAlertSaveFailure.unknown, error);
    }
    await reconcilePrayerAlerts('ios-prayer-settings');
    return IOSPrayerBridge.status.value.experience;
  }

  @override
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    IOSPrayerExperience settings, {
    required String title,
    required String body,
  }) async {
    final status = IOSPrayerBridge.status.value;
    final policy = settings.policyFor(prayer);
    final mode = policy.mode!;
    if (mode == IOSPrayerMode.off) return PrayerTestOutcome.prayerOff;
    final alarm =
        mode == IOSPrayerMode.alarm || mode == IOSPrayerMode.fullAlarm;
    if (alarm && status.alarmAuthorization != 'authorized') {
      return PrayerTestOutcome.alarmPermission;
    }
    if (!alarm &&
        status.notificationAuthorization != 'authorized' &&
        status.notificationAuthorization != 'provisional') {
      return PrayerTestOutcome.notificationsOff;
    }
    try {
      final result = await IOSPrayerBridge.testDelivery(
        mode,
        reciterId: policy.reciterId!,
        audioVersion: settings.audioVersion,
        title: title,
        body: body,
      );
      final error = result.error ?? '';
      if (error.contains('audioMissing')) return PrayerTestOutcome.audioMissing;
      if (error.contains('alarmPermission')) {
        return PrayerTestOutcome.alarmPermission;
      }
      return PrayerTestOutcome.scheduled;
    } catch (error) {
      final text = '$error';
      if (text.contains('audioMissing')) return PrayerTestOutcome.audioMissing;
      if (text.contains('alarmPermission')) {
        return PrayerTestOutcome.alarmPermission;
      }
      return PrayerTestOutcome.failed;
    }
  }

  @override
  Future<void> stopTest() async {
    await IOSPrayerBridge.stopPreview();
    await IOSPrayerBridge.cancelTests();
  }
}
