import 'dart:convert';

import 'package:huda/core/cache/cache_helper.dart';

enum WindowsPrayerReminderMode { silent, adhan, focus }

const windowsPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const windowsPrayerAdvanceMinutes = [0, 5, 10, 15, 30];

/// One prayer's own settings; anything null follows the defaults.
class WindowsPrayerOverride {
  const WindowsPrayerOverride({
    this.off = false,
    this.mode,
    this.reciterId,
    this.audioVersion,
    this.advanceMinutes,
  });

  /// No alert and no toast for this prayer.
  final bool off;
  final WindowsPrayerReminderMode? mode;
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

  static WindowsPrayerOverride fromMap(Map<Object?, Object?> value) {
    final mode = value['mode'] as String?;
    return WindowsPrayerOverride(
      off: mode == 'off',
      mode: mode == null || mode == 'off'
          ? null
          : WindowsPrayerReminderMode.values.byName(mode),
      reciterId: value['reciterId'] as String?,
      audioVersion: value['audioVersion'] as String?,
      advanceMinutes: value['advanceMinutes'] as int?,
    );
  }
}

/// One global Windows policy. Missing preferences preserve legacy toast behavior.
class WindowsPrayerExperience {
  const WindowsPrayerExperience({
    this.configured = false,
    this.enabled = true,
    this.mode = WindowsPrayerReminderMode.silent,
    this.reciterId = bundledReciterId,
    this.audioVersion = 'v1',
    this.volume = 0.7,
    this.stopAfterSeconds,
    this.focusDurationSeconds = 600,
    this.focusAudio = false,
    this.focusPreventEarlyExit = false,
    this.advanceMinutes = 0,
    this.overrides = const {},
  });

  static const preferencesKey = 'windows_prayer_experience_v1';
  static const bundledReciterId = 'huda-default';
  static final idPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final versionPattern = RegExp(r'^v[1-9][0-9]*$');
  final bool configured, enabled, focusAudio, focusPreventEarlyExit;
  final WindowsPrayerReminderMode mode;
  final String reciterId, audioVersion;
  final double volume;
  final int? stopAfterSeconds;
  final int focusDurationSeconds;

  /// Minutes before each prayer for a reminder while Huda runs; 0 for none.
  final int advanceMinutes;
  final Map<String, WindowsPrayerOverride> overrides;

  /// The settings [prayer] uses: its own where set, otherwise these.
  WindowsPrayerExperience forPrayer(String prayer) {
    final own = overrides[prayer];
    if (own == null) return copyWith(overrides: const {});
    return WindowsPrayerExperience(
      configured: configured,
      enabled: enabled && !own.off,
      mode: own.mode ?? mode,
      reciterId: own.reciterId ?? reciterId,
      audioVersion: own.reciterId == null
          ? audioVersion
          : own.audioVersion ?? audioVersion,
      volume: volume,
      stopAfterSeconds: stopAfterSeconds,
      focusDurationSeconds: focusDurationSeconds,
      focusAudio: focusAudio,
      focusPreventEarlyExit: focusPreventEarlyExit,
      advanceMinutes: own.advanceMinutes ?? advanceMinutes,
    );
  }

  bool get playsAudio =>
      configured &&
      enabled &&
      (mode == WindowsPrayerReminderMode.adhan ||
          (mode == WindowsPrayerReminderMode.focus && focusAudio));

  /// Audio changes do not replace hundreds of otherwise identical silent toasts.
  /// v2: toasts no longer carry a next-prayer line. Only prayers that are off
  /// change which toasts exist. Must match the companion's DeliverySignature.
  String get deliverySignature {
    if (!configured) return 'legacy';
    final off = [
      for (final prayer in windowsPrayerKeys)
        if (overrides[prayer]?.off == true) prayer,
    ];
    return 'windows-reminders-v2:${enabled ? 1 : 0}:${mode.name}'
        '${off.isEmpty ? '' : ':off=${off.join(',')}'}';
  }

  void validate() {
    if (!idPattern.hasMatch(reciterId) ||
        !versionPattern.hasMatch(audioVersion) ||
        !volume.isFinite ||
        volume < 0 ||
        volume > 1 ||
        focusDurationSeconds < 60 ||
        focusDurationSeconds > 3600 ||
        (stopAfterSeconds != null &&
            (stopAfterSeconds! < 1 || stopAfterSeconds! > 3600)) ||
        !windowsPrayerAdvanceMinutes.contains(advanceMinutes) ||
        overrides.entries.any(
          (entry) =>
              !windowsPrayerKeys.contains(entry.key) ||
              entry.value.reciterId != null &&
                  (!idPattern.hasMatch(entry.value.reciterId!) ||
                      !versionPattern.hasMatch(entry.value.audioVersion ?? '')) ||
              entry.value.advanceMinutes != null &&
                  !windowsPrayerAdvanceMinutes.contains(
                    entry.value.advanceMinutes,
                  ),
        )) {
      throw const FormatException('Invalid Windows prayer reminder settings.');
    }
  }

  Map<String, Object?> toMap() {
    validate();
    return {
      'version': 1,
      'configured': configured,
      'enabled': enabled,
      'mode': mode.name,
      'reciterId': reciterId,
      'audioVersion': audioVersion,
      'volume': volume,
      'stopAfterSeconds': stopAfterSeconds,
      'focusDurationSeconds': focusDurationSeconds,
      'focusAudio': focusAudio,
      'focusPreventEarlyExit': focusPreventEarlyExit,
      if (advanceMinutes != 0) 'advanceMinutes': advanceMinutes,
      if (overrides.isNotEmpty)
        'overrides': {
          for (final entry in overrides.entries) entry.key: entry.value.toMap(),
        },
    };
  }

  static WindowsPrayerExperience? tryParse(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    try {
      final result = WindowsPrayerExperience(
        configured: value['configured'] as bool,
        enabled: value['enabled'] as bool,
        mode: WindowsPrayerReminderMode.values.byName(value['mode'] as String),
        // The former built-in choice follows the corrected mobile default.
        // A newly selected downloadable Mishary recording has no legacy length.
        reciterId:
            value['reciterId'] == 'mishary-rashid-alafasy' &&
                value['audioVersion'] == 'v1' &&
                value.containsKey('length')
            ? bundledReciterId
            : value['reciterId'] as String,
        audioVersion: value['audioVersion'] as String,
        volume: (value['volume'] as num).toDouble(),
        // Preserve the bounded intent of the previous short recording choice.
        stopAfterSeconds:
            value['stopAfterSeconds'] as int? ??
            (value['length'] == 'short' ? 30 : null),
        focusDurationSeconds: value['focusDurationSeconds'] as int,
        focusAudio: value['focusAudio'] as bool,
        focusPreventEarlyExit: value['focusPreventEarlyExit'] == true,
        advanceMinutes: value['advanceMinutes'] as int? ?? 0,
        overrides: {
          for (final entry
              in (value['overrides'] as Map? ?? const {}).entries)
            entry.key as String: WindowsPrayerOverride.fromMap(
              (entry.value as Map).cast<Object?, Object?>(),
            ),
        },
      );
      result.validate();
      return result;
    } catch (_) {
      return null;
    }
  }

  static WindowsPrayerExperience read(CacheHelper cache) {
    try {
      final raw = cache.getDataString(key: preferencesKey);
      return raw == null
          ? const WindowsPrayerExperience()
          : tryParse(jsonDecode(raw)) ?? const WindowsPrayerExperience();
    } catch (_) {
      return const WindowsPrayerExperience();
    }
  }

  WindowsPrayerExperience copyWith({
    bool? configured,
    bool? enabled,
    WindowsPrayerReminderMode? mode,
    String? reciterId,
    String? audioVersion,
    double? volume,
    int? stopAfterSeconds,
    bool clearCutoff = false,
    int? focusDurationSeconds,
    bool? focusAudio,
    bool? focusPreventEarlyExit,
    int? advanceMinutes,
    Map<String, WindowsPrayerOverride>? overrides,
  }) => WindowsPrayerExperience(
    configured: configured ?? this.configured,
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    reciterId: reciterId ?? this.reciterId,
    audioVersion: audioVersion ?? this.audioVersion,
    volume: volume ?? this.volume,
    stopAfterSeconds: clearCutoff
        ? null
        : stopAfterSeconds ?? this.stopAfterSeconds,
    focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
    focusAudio: focusAudio ?? this.focusAudio,
    focusPreventEarlyExit: focusPreventEarlyExit ?? this.focusPreventEarlyExit,
    advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    overrides: overrides ?? this.overrides,
  );
}
