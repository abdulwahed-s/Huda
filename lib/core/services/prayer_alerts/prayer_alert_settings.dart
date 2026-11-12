import 'package:flutter/foundation.dart';

/// The five prayers that alerts can be set for, in order.
const prayerAlertPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

/// How a prayer alerts. Each platform supports some of them
/// ([PrayerAlertCapabilities.styles]); [off] is only used per prayer.
enum PrayerAlertStyle {
  off,

  /// A notification with no adhan.
  silent,

  /// A notification that plays a short part of the adhan.
  short,

  /// The adhan, played in full (or until the chosen length).
  full,

  /// iOS: an alarm that rings even in silent mode, with the short adhan.
  alarm,

  /// iOS 26.1+: an alarm with the whole built-in adhan.
  fullAlarm,

  /// Desktop: a quiet full-screen moment for the prayer.
  focus,
}

/// One prayer's effective settings, and which of them are its own.
@immutable
class PrayerAlertPrayer {
  const PrayerAlertPrayer({
    required this.style,
    required this.reciterId,
    this.beforeMinutes = 0,
    this.ownStyle = false,
    this.ownReciter = false,
    this.ownBefore = false,
    this.ownTuning = false,
    this.tuning = const {},
    this.openingOnly = false,
  });

  final PrayerAlertStyle style;
  final String reciterId;
  final int beforeMinutes;
  final bool ownStyle, ownReciter, ownBefore;

  /// Android: volume, length, fade-in or alarm options differ from the rest.
  final bool ownTuning;

  /// Android: this prayer's own values by setting key (absent = default).
  final Map<String, Object?> tuning;

  /// Android: plays only the opening of the adhan (the short recording).
  final bool openingOnly;

  bool get custom => ownStyle || ownReciter || ownBefore || ownTuning;
}

/// What the shared settings sheet shows, read from a platform's own model.
@immutable
class PrayerAlertSettings {
  const PrayerAlertSettings({
    required this.enabled,
    required this.style,
    required this.reciterId,
    required this.audioVersion,
    required this.prayers,
    this.volume = 1,
    this.stopAfterSeconds,
    this.fadeInSeconds = 0,
    this.beforeMinutes = 0,
    this.beforeStyle = PrayerAlertStyle.silent,
    this.fallbackStyle = PrayerAlertStyle.short,
    this.focusDurationSeconds = 600,
    this.focusAudio = false,
    this.focusCommitment = false,
    this.focusImmersive = false,
    this.toggles = const {},
    this.openingOnly = false,
  });

  final bool enabled;

  /// Android: the adhan plays only its opening (the short recording).
  final bool openingOnly;
  final PrayerAlertStyle style;
  final String reciterId, audioVersion;
  final Map<String, PrayerAlertPrayer> prayers;
  final double volume;

  /// Null plays the whole recording.
  final int? stopAfterSeconds;
  final int fadeInSeconds;
  final int beforeMinutes;

  /// iOS: whether a before-prayer reminder is silent or plays a short sound.
  final PrayerAlertStyle beforeStyle;

  /// iOS: used when an alarm can't be set.
  final PrayerAlertStyle fallbackStyle;
  final int focusDurationSeconds;
  final bool focusAudio, focusCommitment, focusImmersive;

  /// Platform switches by [PrayerAlertToggle.key].
  final Map<String, bool> toggles;

  bool get usesAudio =>
      const {
        PrayerAlertStyle.short,
        PrayerAlertStyle.full,
        PrayerAlertStyle.alarm,
        PrayerAlertStyle.fullAlarm,
      }.contains(style) ||
      style == PrayerAlertStyle.focus && focusAudio;

  /// Every prayer that alerts, with the recording it uses.
  Set<String> get reciters => {
    for (final prayer in prayers.values)
      if (prayer.style != PrayerAlertStyle.off &&
          prayer.style != PrayerAlertStyle.silent)
        prayer.reciterId,
  };
}

/// One edit from the sheet. Each platform turns it into its own model.
sealed class PrayerAlertChange {
  const PrayerAlertChange({this.prayer});

  /// Null changes every prayer's default; otherwise only this prayer.
  final String? prayer;
}

class SetPrayerAlertsEnabled extends PrayerAlertChange {
  const SetPrayerAlertsEnabled(this.enabled);
  final bool enabled;
}

class SetPrayerAlertStyle extends PrayerAlertChange {
  /// For a prayer, null [style] follows the default again.
  const SetPrayerAlertStyle(this.style, {super.prayer});
  final PrayerAlertStyle? style;
}

class SetPrayerAlertReciter extends PrayerAlertChange {
  /// For a prayer, null [reciterId] follows the default again.
  const SetPrayerAlertReciter(
    this.reciterId,
    this.audioVersion, {
    super.prayer,
  });
  final String? reciterId;
  final String audioVersion;
}

class SetPrayerAlertVolume extends PrayerAlertChange {
  const SetPrayerAlertVolume(this.volume, {super.prayer});
  final double? volume;
}

class SetPrayerAlertLength extends PrayerAlertChange {
  /// Null [seconds] plays the whole recording.
  const SetPrayerAlertLength(
    this.seconds, {
    super.prayer,
    this.inherit = false,
    this.opening = false,
  });
  final int? seconds;

  /// Android: only the opening of the adhan (the short recording).
  final bool opening;

  /// For a prayer: follow the default length again.
  final bool inherit;
}

class SetPrayerAlertFadeIn extends PrayerAlertChange {
  const SetPrayerAlertFadeIn(this.seconds, {super.prayer});
  final int? seconds;
}

class SetPrayerAlertBefore extends PrayerAlertChange {
  /// 0 turns the reminder off; for a prayer, null follows the default.
  const SetPrayerAlertBefore(this.minutes, {super.prayer});
  final int? minutes;
}

class SetPrayerAlertBeforeStyle extends PrayerAlertChange {
  const SetPrayerAlertBeforeStyle(this.style);
  final PrayerAlertStyle style;
}

class SetPrayerAlertFallback extends PrayerAlertChange {
  const SetPrayerAlertFallback(this.style);
  final PrayerAlertStyle style;
}

class SetPrayerAlertToggle extends PrayerAlertChange {
  /// For a prayer, null [value] follows the default again.
  const SetPrayerAlertToggle(this.key, this.value, {super.prayer});
  final String key;
  final bool? value;
}

class SetPrayerAlertFocus extends PrayerAlertChange {
  const SetPrayerAlertFocus({
    this.durationSeconds,
    this.audio,
    this.commitment,
    this.immersive,
  });
  final int? durationSeconds;
  final bool? audio, commitment, immersive;
}

class ResetPrayerAlert extends PrayerAlertChange {
  const ResetPrayerAlert(String prayer) : super(prayer: prayer);
}

/// A platform switch shown under "More options".
@immutable
class PrayerAlertToggle {
  const PrayerAlertToggle(this.key, {this.perPrayer = false});

  /// Names the setting; the sheet looks up its title and hint by it.
  final String key;

  /// Android: can be set per prayer.
  final bool perPrayer;
}

/// What this device can do, so the sheet only offers what works.
@immutable
class PrayerAlertCapabilities {
  const PrayerAlertCapabilities({
    required this.styles,
    this.unavailable = const {},
    this.perPrayer = false,
    this.perPrayerReciter = false,
    this.perPrayerTuning = false,
    this.volume = false,
    this.length = false,
    this.fadeIn = false,
    this.beforeMinutes = const [],
    this.beforeStyle = false,
    this.fallback = false,
    this.focusStyle = false,
    this.toggles = const [],
    this.needsCompanion = false,
    this.lengthOpening = false,
    this.styleNames = const {},
    this.styleHints = const {},
  });

  /// "Plays for" offers "Opening only" (Android's short recording).
  final bool lengthOpening;

  /// l10n keys naming a style differently on this platform.
  final Map<PrayerAlertStyle, String> styleNames, styleHints;

  /// Offered default styles, in order.
  final List<PrayerAlertStyle> styles;

  /// Styles shown but not usable yet, with why (an l10n key).
  final Map<PrayerAlertStyle, String> unavailable;
  final bool perPrayer, perPrayerReciter, perPrayerTuning;
  final bool volume, length, fadeIn;

  /// Minutes offered for a before-prayer reminder; empty when unsupported.
  final List<int> beforeMinutes;
  final bool beforeStyle, fallback;

  /// Focus can be compact or fill the screen (macOS, Linux).
  final bool focusStyle;
  final List<PrayerAlertToggle> toggles;

  /// Windows: the reminder before a prayer needs Huda running.
  final bool needsCompanion;

  bool get beforePrayer => beforeMinutes.isNotEmpty;
}

/// What happened to "Send a test", in words the user can act on.
enum PrayerTestOutcome {
  scheduled,
  notificationsOff,
  exactAlarmsOff,
  prayerOff,
  alarmPermission,
  serviceNotRunning,
  audioMissing,
  failed,
}

/// Why saving didn't work.
enum PrayerAlertSaveFailure {
  companionUnavailable,
  serviceUnavailable,
  scheduleFailed,
  unknown,
}

class PrayerAlertApplyException implements Exception {
  const PrayerAlertApplyException(this.failure, [this.cause]);
  final PrayerAlertSaveFailure failure;
  final Object? cause;

  @override
  String toString() => 'PrayerAlertApplyException($failure, $cause)';
}
