import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_audio_library.dart';
import 'package:huda/l10n/app_localizations.dart';

/// Words and icons for the prayer alert settings, in one place.
extension PrayerAlertLabels on AppLocalizations {
  String prayerName(String prayer) => switch (prayer) {
    'fajr' => fajr,
    'dhuhr' => dhuhr,
    'asr' => asr,
    'maghrib' => maghrib,
    _ => isha,
  };

  String alertStyle(PrayerAlertStyle style) => switch (style) {
    PrayerAlertStyle.off => prayerAlertStyleOff,
    PrayerAlertStyle.silent => prayerAlertStyleSilent,
    PrayerAlertStyle.short => prayerAlertStyleShort,
    PrayerAlertStyle.full => prayerAlertStyleFull,
    PrayerAlertStyle.alarm => prayerAlertStyleAlarm,
    PrayerAlertStyle.focus => prayerAlertStyleFocus,
  };

  /// The style's name on this platform ([PrayerAlertCapabilities.styleNames]).
  String alertStyleOn(PrayerAlertStyle style, PrayerAlertCapabilities? on) =>
      _named(on?.styleNames[style]) ?? alertStyle(style);

  String alertStyleHintOn(
    PrayerAlertStyle style,
    PrayerAlertCapabilities? on,
  ) => _named(on?.styleHints[style]) ?? alertStyleHint(style);

  String? _named(String? key) => switch (key) {
    'prayerAlertStyleAdhan' => prayerAlertStyleAdhan,
    'prayerAlertStyleAdhanHint' => prayerAlertStyleAdhanHint,
    'prayerAlertStyleNotificationAdhan' => prayerAlertStyleNotificationAdhan,
    'prayerAlertStyleNotificationAdhanHint' =>
      prayerAlertStyleNotificationAdhanHint,
    'prayerAlertStyleMacFullHint' => prayerAlertStyleMacFullHint,
    'prayerAlertStyleMacFocusHint' => prayerAlertStyleMacFocusHint,
    _ => null,
  };

  /// "Adhan · Opening only" (Android) or "Prayer alarm · Opening only"
  /// (iOS), otherwise the style's name.
  String alertStyleSummary(
    PrayerAlertStyle style,
    PrayerAlertCapabilities? on, {
    bool opening = false,
  }) => [
    alertStyleOn(style, on),
    if (opening &&
        (style == PrayerAlertStyle.full || style == PrayerAlertStyle.alarm))
      prayerAlertLengthOpening,
  ].join(' · ');

  String alertStyleHint(PrayerAlertStyle style) => switch (style) {
    PrayerAlertStyle.off => prayerAlertStyleOffHint,
    PrayerAlertStyle.silent => prayerAlertStyleSilentHint,
    PrayerAlertStyle.short => prayerAlertStyleShortHint,
    PrayerAlertStyle.full => prayerAlertStyleFullHint,
    PrayerAlertStyle.alarm => prayerAlertStyleAlarmHint,
    PrayerAlertStyle.focus => prayerAlertStyleFocusHint,
  };

  /// Title and optional hint of a platform switch.
  (String, String?) alertToggle(String key) => switch (key) {
    'alarmScreenEnabled' => (
      prayerAlertToggleAlarmScreen,
      prayerAlertToggleAlarmScreenHint,
    ),
    'flipToStopEnabled' => (prayerAlertToggleFlip, prayerAlertToggleFlipHint),
    'vibrate' => (prayerAlertToggleVibrate, null),
    'respectRingerMode' => (
      prayerAlertToggleRinger,
      prayerAlertToggleRingerHint,
    ),
    'stopOnHeadsetDisconnect' => (prayerAlertToggleHeadset, null),
    'showMissedSummary' => (prayerAlertToggleMissed, null),
    'timeSensitive' => (
      prayerAlertToggleTimeSensitive,
      prayerAlertToggleTimeSensitiveHint,
    ),
    'allowLockedAudio' => (prayerAlertToggleLockedAudio, null),
    'quiet' => (prayerAlertToggleQuiet, prayerAlertToggleQuietHint),
    'backgroundEnabled' => (
      prayerAlertToggleBackground,
      prayerAlertToggleBackgroundHint,
    ),
    'startAtLogin' => (prayerAlertToggleStartAtLogin, null),
    _ => (key, null),
  };

  String alertSaveFailure(PrayerAlertSaveFailure? failure) => switch (failure) {
    PrayerAlertSaveFailure.companionUnavailable => prayerAlertFailureCompanion,
    PrayerAlertSaveFailure.serviceUnavailable => prayerAlertFailureService,
    PrayerAlertSaveFailure.scheduleFailed => prayerAlertFailureSchedule,
    _ => prayerAlertFailureUnknown,
  };

  String downloadFailure(PrayerAudioDownloadFailure? failure) =>
      switch (failure) {
        PrayerAudioDownloadFailure.server => prayerAlertDownloadServer,
        PrayerAudioDownloadFailure.integrity => prayerAlertDownloadIntegrity,
        PrayerAudioDownloadFailure.storage => prayerAlertDownloadStorage,
        _ => prayerAlertDownloadNetwork,
      };

  String testOutcome(PrayerTestOutcome outcome, {required bool delayed}) =>
      switch (outcome) {
        PrayerTestOutcome.scheduled =>
          delayed ? prayerAlertTestShown : prayerAlertTestScheduled,
        PrayerTestOutcome.notificationsOff => prayerAlertTestNotificationsOff,
        PrayerTestOutcome.exactAlarmsOff => prayerAlertTestExactOff,
        PrayerTestOutcome.prayerOff => prayerAlertTestPrayerOff,
        PrayerTestOutcome.alarmPermission => prayerAlertTestAlarmPermission,
        PrayerTestOutcome.serviceNotRunning => prayerAlertTestServiceOff,
        PrayerTestOutcome.audioMissing => prayerAlertTestAudioMissing,
        PrayerTestOutcome.failed => prayerAlertTestFailed,
      };

  /// "Whole adhan", "30 s" or "2 min".
  String alertLength(int? seconds, String Function(int) number) {
    if (seconds == null || seconds >= 3600) return prayerAlertLengthWhole;
    if (seconds % 60 == 0) {
      return prayerAlertLengthMinutes(number(seconds ~/ 60));
    }
    return prayerAlertLengthSeconds(number(seconds));
  }

  /// A named warning key from the platform layer.
  String alertWarning(String key) => switch (key) {
    'prayerAlertStartupWarning' => prayerAlertStartupWarning,
    _ => key,
  };
}

IconData prayerAlertStyleIcon(PrayerAlertStyle style) => switch (style) {
  PrayerAlertStyle.off => Icons.notifications_off_outlined,
  PrayerAlertStyle.silent => Icons.notifications_none_rounded,
  PrayerAlertStyle.short => Icons.music_note_rounded,
  PrayerAlertStyle.full => Icons.volume_up_rounded,
  PrayerAlertStyle.alarm => Icons.alarm_rounded,
  PrayerAlertStyle.focus => Icons.self_improvement_rounded,
};

/// Digits in the user's numerals, for minute and second values.
String prayerAlertNumber(BuildContext context, int value) {
  final language = Localizations.localeOf(context).languageCode;
  final digits = switch (language) {
    'ar' => '٠١٢٣٤٥٦٧٨٩',
    'ur' => '۰۱۲۳۴۵۶۷۸۹',
    'bn' => '০১২৩৪৫৬৭৮৯',
    _ => null,
  };
  final text = '$value';
  if (digits == null) return text;
  return String.fromCharCodes(
    text.codeUnits.map((unit) => digits.codeUnitAt(unit - 0x30)),
  );
}

/// "3.4 MB", with the user's numerals.
String prayerAlertSize(BuildContext context, int bytes) {
  final megabytes = bytes / (1024 * 1024);
  final text = megabytes < 10
      ? megabytes.toStringAsFixed(1)
      : megabytes.round().toString();
  final language = Localizations.localeOf(context).languageCode;
  final digits = switch (language) {
    'ar' => '٠١٢٣٤٥٦٧٨٩',
    'ur' => '۰۱۲۳۴۵۶۷۸۹',
    'bn' => '০১২৩৪৫৬৭৮৯',
    _ => null,
  };
  final localized = digits == null
      ? text
      : text.replaceAllMapped(
          RegExp(r'[0-9]'),
          (match) => digits[int.parse(match[0]!)],
        );
  return '$localized MB';
}
