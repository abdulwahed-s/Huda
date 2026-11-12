import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';

enum LinuxPrayerReminderMode { silent, adhan, focus }

enum LinuxPrayerFocusStyle { compact, immersive }

const linuxPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const linuxPrayerAdvanceMinutes = [0, 5, 10, 15, 30];

/// One prayer's own settings; anything null follows the defaults.
class LinuxPrayerOverride {
  const LinuxPrayerOverride({
    this.off = false,
    this.mode,
    this.reciterId,
    this.audioVersion,
    this.advanceMinutes,
  });

  /// No alert for this prayer.
  final bool off;
  final LinuxPrayerReminderMode? mode;
  final String? reciterId, audioVersion;
  final int? advanceMinutes;

  bool get isEmpty =>
      !off && mode == null && reciterId == null && advanceMinutes == null;

  Map<String, Object?> toMap() => {
    if (off) 'mode': 'off' else if (mode != null) 'mode': mode!.name,
    if (reciterId != null) 'reciterId': reciterId,
    if (reciterId != null) 'audioVersion': audioVersion,
    if (advanceMinutes != null) 'advanceMinutes': advanceMinutes,
  };

  static LinuxPrayerOverride fromMap(Map<Object?, Object?> value) {
    final mode = value['mode'] as String?;
    return LinuxPrayerOverride(
      off: mode == 'off',
      mode: mode == null || mode == 'off'
          ? null
          : LinuxPrayerReminderMode.values.byName(mode),
      reciterId: value['reciterId'] as String?,
      audioVersion: value['audioVersion'] as String?,
      advanceMinutes: value['advanceMinutes'] as int?,
    );
  }
}

/// The native service is the authority for these preferences, including startup.
class LinuxPrayerExperience {
  const LinuxPrayerExperience({
    this.configured = false,
    this.enabled = true,
    this.mode = LinuxPrayerReminderMode.silent,
    this.backgroundEnabled = true,
    this.reciterId = 'huda-default',
    this.audioVersion = 'v1',
    this.volume = .7,
    this.stopAfterSeconds,
    this.focusStyle = LinuxPrayerFocusStyle.compact,
    this.focusDurationSeconds = 600,
    this.focusAudio = false,
    this.focusCommitment = false,
    this.focusDisplay = 'current',
    this.allowLockedAudio = false,
    this.quiet = false,
    this.advanceMinutes = 0,
    this.overrides = const {},
  });

  final bool configured, enabled, backgroundEnabled;
  final LinuxPrayerReminderMode mode;
  final String reciterId, audioVersion, focusDisplay;
  final LinuxPrayerFocusStyle focusStyle;
  final double volume;
  final int? stopAfterSeconds;
  final int focusDurationSeconds;
  final bool focusAudio, focusCommitment;
  final bool allowLockedAudio, quiet;

  /// Minutes before each prayer for a quiet reminder; 0 for none.
  final int advanceMinutes;
  final Map<String, LinuxPrayerOverride> overrides;

  /// The settings [prayer] uses: its own where set, otherwise these.
  LinuxPrayerExperience forPrayer(String prayer) {
    final own = overrides[prayer];
    if (own == null) return this;
    return LinuxPrayerExperience(
      configured: configured,
      enabled: enabled && !own.off,
      mode: own.mode ?? mode,
      backgroundEnabled: backgroundEnabled,
      reciterId: own.reciterId ?? reciterId,
      audioVersion: own.reciterId == null
          ? audioVersion
          : own.audioVersion ?? audioVersion,
      volume: volume,
      stopAfterSeconds: stopAfterSeconds,
      focusStyle: focusStyle,
      focusDurationSeconds: focusDurationSeconds,
      focusAudio: focusAudio,
      focusCommitment: focusCommitment,
      focusDisplay: focusDisplay,
      allowLockedAudio: allowLockedAudio,
      quiet: quiet,
      advanceMinutes: own.advanceMinutes ?? advanceMinutes,
    );
  }

  bool get needsAudio =>
      mode == LinuxPrayerReminderMode.adhan ||
      mode == LinuxPrayerReminderMode.focus && focusAudio;
  String get deliverySignature => configured
      ? 'linux-reminders-v2:${enabled ? 1 : 0}:${mode.name}:${backgroundEnabled ? 1 : 0}:${quiet ? 1 : 0}'
            '${mode == LinuxPrayerReminderMode.focus ? ':${focusStyle.name}:$focusDurationSeconds:${focusCommitment ? 1 : 0}:$focusDisplay' : ''}'
            '${overrides.isEmpty && advanceMinutes == 0 ? '' : ':$_perPrayerSignature'}'
      : 'legacy';

  String get _perPrayerSignature => [
    'a$advanceMinutes',
    for (final prayer in linuxPrayerKeys)
      if (overrides[prayer] case final own?)
        '$prayer=${own.off ? 'off' : own.mode?.name ?? ''}'
            '/${own.reciterId ?? ''}/${own.advanceMinutes ?? ''}',
  ].join(',');

  void validate() {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(reciterId) ||
        !RegExp(r'^v[1-9][0-9]*$').hasMatch(audioVersion) ||
        !volume.isFinite ||
        volume < 0 ||
        volume > 1 ||
        focusDurationSeconds < 60 ||
        focusDurationSeconds > 3600 ||
        (stopAfterSeconds != null &&
            (stopAfterSeconds! < 1 || stopAfterSeconds! > 3600)) ||
        !(focusDisplay == 'current' ||
            focusDisplay == 'all' ||
            RegExp(r'^monitor-[0-9]+$').hasMatch(focusDisplay)) ||
        !linuxPrayerAdvanceMinutes.contains(advanceMinutes) ||
        overrides.entries.any(
          (entry) =>
              !linuxPrayerKeys.contains(entry.key) ||
              entry.value.reciterId != null &&
                  (!RegExp(
                        r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
                      ).hasMatch(entry.value.reciterId!) ||
                      !RegExp(
                        r'^v[1-9][0-9]*$',
                      ).hasMatch(entry.value.audioVersion ?? '')) ||
              entry.value.advanceMinutes != null &&
                  !linuxPrayerAdvanceMinutes.contains(
                    entry.value.advanceMinutes,
                  ),
        )) {
      throw const FormatException('Invalid Linux prayer settings.');
    }
  }

  Map<String, Object?> toMap() {
    validate();
    return {
      'version': 1,
      'configured': configured,
      'enabled': enabled,
      'mode': mode.name,
      'backgroundEnabled': backgroundEnabled,
      'reciterId': reciterId,
      'audioVersion': audioVersion,
      'volume': volume,
      'stopAfterSeconds': stopAfterSeconds,
      'focusStyle': focusStyle.name,
      'focusDurationSeconds': focusDurationSeconds,
      'focusAudio': focusAudio,
      'focusCommitment': focusCommitment,
      'focusDisplay': focusDisplay,
      'allowLockedAudio': allowLockedAudio,
      'quiet': quiet,
      if (advanceMinutes != 0) 'advanceMinutes': advanceMinutes,
      if (overrides.isNotEmpty)
        'overrides': {
          for (final entry in overrides.entries) entry.key: entry.value.toMap(),
        },
    };
  }

  static LinuxPrayerExperience fromMap(Map<Object?, Object?> value) {
    if (value['version'] != 1) {
      throw const FormatException('Unsupported Linux prayer settings.');
    }
    final result = LinuxPrayerExperience(
      configured: value['configured'] as bool,
      enabled: value['enabled'] as bool,
      mode: LinuxPrayerReminderMode.values.byName(value['mode'] as String),
      backgroundEnabled: value['backgroundEnabled'] != false,
      reciterId: value['reciterId'] as String,
      audioVersion: value['audioVersion'] as String,
      volume: (value['volume'] as num).toDouble(),
      stopAfterSeconds: value['stopAfterSeconds'] as int?,
      focusStyle: LinuxPrayerFocusStyle.values.byName(
        value['focusStyle'] as String,
      ),
      focusDurationSeconds: value['focusDurationSeconds'] as int,
      focusAudio: value['focusAudio'] as bool,
      focusCommitment: value['focusCommitment'] as bool,
      focusDisplay: value['focusDisplay'] as String,
      allowLockedAudio: value['allowLockedAudio'] as bool,
      quiet: value['quiet'] as bool,
      advanceMinutes: value['advanceMinutes'] as int? ?? 0,
      overrides: {
        for (final entry
            in (value['overrides'] as Map? ?? const {}).entries)
          entry.key as String: LinuxPrayerOverride.fromMap(
            (entry.value as Map).cast<Object?, Object?>(),
          ),
      },
    );
    result.validate();
    return result;
  }

  static const preferencesKey = 'linux_prayer_experience_v1';
  static LinuxPrayerExperience? tryParse(Object? value) {
    try {
      return value is Map ? fromMap(value.cast<Object?, Object?>()) : null;
    } catch (_) {
      return null;
    }
  }

  static LinuxPrayerExperience read(CacheHelper cache) {
    try {
      final raw = cache.getDataString(key: preferencesKey);
      return raw == null
          ? const LinuxPrayerExperience()
          : tryParse(jsonDecode(raw)) ?? const LinuxPrayerExperience();
    } catch (_) {
      return const LinuxPrayerExperience();
    }
  }

  LinuxPrayerExperience copyWith({
    bool? configured,
    bool? enabled,
    LinuxPrayerReminderMode? mode,
    bool? backgroundEnabled,
    String? reciterId,
    String? audioVersion,
    double? volume,
    int? stopAfterSeconds,
    bool clearCutoff = false,
    LinuxPrayerFocusStyle? focusStyle,
    int? focusDurationSeconds,
    bool? focusAudio,
    bool? focusCommitment,
    String? focusDisplay,
    bool? allowLockedAudio,
    bool? quiet,
    int? advanceMinutes,
    Map<String, LinuxPrayerOverride>? overrides,
  }) => LinuxPrayerExperience(
    configured: configured ?? this.configured,
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
    reciterId: reciterId ?? this.reciterId,
    audioVersion: audioVersion ?? this.audioVersion,
    volume: volume ?? this.volume,
    stopAfterSeconds: clearCutoff
        ? null
        : stopAfterSeconds ?? this.stopAfterSeconds,
    focusStyle: focusStyle ?? this.focusStyle,
    focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
    focusAudio: focusAudio ?? this.focusAudio,
    focusCommitment: focusCommitment ?? this.focusCommitment,
    focusDisplay: focusDisplay ?? this.focusDisplay,
    allowLockedAudio: allowLockedAudio ?? this.allowLockedAudio,
    quiet: quiet ?? this.quiet,
    advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    overrides: overrides ?? this.overrides,
  );
}
