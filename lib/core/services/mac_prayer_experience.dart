enum MacPrayerReminderMode { silent, adhan, focus }

enum MacPrayerAdhanDelivery { short, full }

enum MacPrayerFocusStyle { compact, immersive }

const macPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const macPrayerAdvanceMinutes = [0, 5, 10, 15, 30];

/// One prayer's own settings; anything null follows the defaults.
class MacPrayerOverride {
  const MacPrayerOverride({
    this.off = false,
    this.mode,
    this.delivery,
    this.reciterId,
    this.audioVersion,
    this.advanceMinutes,
  });

  /// No alert for this prayer.
  final bool off;
  final MacPrayerReminderMode? mode;
  final MacPrayerAdhanDelivery? delivery;
  final String? reciterId, audioVersion;
  final int? advanceMinutes;

  bool get isEmpty =>
      !off &&
      mode == null &&
      delivery == null &&
      reciterId == null &&
      advanceMinutes == null;

  Map<String, Object?> toMap() => {
    if (off) 'mode': 'off' else if (mode != null) 'mode': mode!.name,
    if (delivery != null) 'delivery': delivery!.name,
    if (reciterId != null) 'reciterId': reciterId,
    if (reciterId != null) 'audioVersion': audioVersion,
    if (advanceMinutes != null) 'advanceMinutes': advanceMinutes,
  };

  static MacPrayerOverride fromMap(Map<Object?, Object?> value) {
    final mode = value['mode'] as String?;
    return MacPrayerOverride(
      off: mode == 'off',
      mode: mode == null || mode == 'off'
          ? null
          : MacPrayerReminderMode.values.byName(mode),
      delivery: value['delivery'] == null
          ? null
          : MacPrayerAdhanDelivery.values.byName(value['delivery'] as String),
      reciterId: value['reciterId'] as String?,
      audioVersion: value['audioVersion'] as String?,
      advanceMinutes: value['advanceMinutes'] as int?,
    );
  }
}

/// The native service is the authority for these preferences, including startup.
class MacPrayerExperience {
  const MacPrayerExperience({
    this.configured = false,
    this.enabled = true,
    this.mode = MacPrayerReminderMode.silent,
    this.backgroundEnabled = false,
    this.startAtLogin = false,
    this.reciterId = 'huda-default',
    this.audioVersion = 'v1',
    this.delivery = MacPrayerAdhanDelivery.full,
    this.volume = .7,
    this.stopAfterSeconds,
    this.focusStyle = MacPrayerFocusStyle.compact,
    this.focusDurationSeconds = 600,
    this.focusAudio = false,
    this.focusCommitment = false,
    this.focusDisplay = 'current',
    this.timeSensitive = false,
    this.allowLockedAudio = false,
    this.quiet = false,
    this.advanceMinutes = 0,
    this.overrides = const {},
  });

  final bool configured, enabled, backgroundEnabled, startAtLogin;

  /// Minutes before each prayer for a reminder; 0 for none.
  final int advanceMinutes;
  final Map<String, MacPrayerOverride> overrides;

  /// The settings [prayer] uses: its own where set, otherwise these.
  MacPrayerExperience forPrayer(String prayer) {
    final own = overrides[prayer];
    return copyWith(
      enabled: own?.off == true ? false : null,
      mode: own?.mode,
      delivery: own?.delivery,
      reciterId: own?.reciterId,
      audioVersion: own?.reciterId == null ? null : own!.audioVersion,
      advanceMinutes: own?.advanceMinutes,
      overrides: const {},
    );
  }
  final MacPrayerReminderMode mode;
  final String reciterId, audioVersion, focusDisplay;
  final MacPrayerAdhanDelivery delivery;
  final MacPrayerFocusStyle focusStyle;
  final double volume;
  final int? stopAfterSeconds;
  final int focusDurationSeconds;
  final bool focusAudio, focusCommitment;
  final bool timeSensitive, allowLockedAudio, quiet;

  bool get needsAudio =>
      mode == MacPrayerReminderMode.adhan ||
      mode == MacPrayerReminderMode.focus && focusAudio;
  bool get playerAudio =>
      mode == MacPrayerReminderMode.adhan &&
          delivery == MacPrayerAdhanDelivery.full ||
      mode == MacPrayerReminderMode.focus && focusAudio;

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
            RegExp(r'^display:[0-9]+$').hasMatch(focusDisplay)) ||
        startAtLogin && !backgroundEnabled ||
        !macPrayerAdvanceMinutes.contains(advanceMinutes) ||
        overrides.entries.any(
          (entry) =>
              !macPrayerKeys.contains(entry.key) ||
              entry.value.reciterId != null &&
                  (!RegExp(
                        r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
                      ).hasMatch(entry.value.reciterId!) ||
                      !RegExp(
                        r'^v[1-9][0-9]*$',
                      ).hasMatch(entry.value.audioVersion ?? '')) ||
              entry.value.advanceMinutes != null &&
                  !macPrayerAdvanceMinutes.contains(entry.value.advanceMinutes),
        )) {
      throw const FormatException('Invalid macOS prayer settings.');
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
      'startAtLogin': startAtLogin,
      'reciterId': reciterId,
      'audioVersion': audioVersion,
      'delivery': delivery.name,
      'volume': volume,
      'stopAfterSeconds': stopAfterSeconds,
      'focusStyle': focusStyle.name,
      'focusDurationSeconds': focusDurationSeconds,
      'focusAudio': focusAudio,
      'focusCommitment': focusCommitment,
      'focusDisplay': focusDisplay,
      'timeSensitive': timeSensitive,
      'allowLockedAudio': allowLockedAudio,
      'quiet': quiet,
      if (advanceMinutes != 0) 'advanceMinutes': advanceMinutes,
      if (overrides.isNotEmpty)
        'overrides': {
          for (final entry in overrides.entries) entry.key: entry.value.toMap(),
        },
    };
  }

  static MacPrayerExperience fromMap(Map<Object?, Object?> value) {
    if (value['version'] != 1) {
      throw const FormatException('Unsupported macOS prayer settings.');
    }
    final result = MacPrayerExperience(
      configured: value['configured'] as bool,
      enabled: value['enabled'] as bool,
      mode: MacPrayerReminderMode.values.byName(value['mode'] as String),
      backgroundEnabled: value['backgroundEnabled'] as bool,
      startAtLogin: value['startAtLogin'] as bool,
      reciterId: value['reciterId'] as String,
      audioVersion: value['audioVersion'] as String,
      delivery: MacPrayerAdhanDelivery.values.byName(
        value['delivery'] as String,
      ),
      volume: (value['volume'] as num).toDouble(),
      stopAfterSeconds: value['stopAfterSeconds'] as int?,
      focusStyle: MacPrayerFocusStyle.values.byName(
        value['focusStyle'] as String,
      ),
      focusDurationSeconds: value['focusDurationSeconds'] as int,
      focusAudio: value['focusAudio'] as bool,
      focusCommitment: value['focusCommitment'] as bool,
      focusDisplay: value['focusDisplay'] as String,
      timeSensitive: value['timeSensitive'] as bool,
      allowLockedAudio: value['allowLockedAudio'] as bool,
      quiet: value['quiet'] as bool,
      advanceMinutes: value['advanceMinutes'] as int? ?? 0,
      overrides: {
        for (final entry
            in (value['overrides'] as Map? ?? const {}).entries)
          entry.key as String: MacPrayerOverride.fromMap(
            (entry.value as Map).cast<Object?, Object?>(),
          ),
      },
    );
    result.validate();
    return result;
  }

  MacPrayerExperience copyWith({
    bool? configured,
    bool? enabled,
    MacPrayerReminderMode? mode,
    bool? backgroundEnabled,
    bool? startAtLogin,
    String? reciterId,
    String? audioVersion,
    MacPrayerAdhanDelivery? delivery,
    double? volume,
    int? stopAfterSeconds,
    bool clearCutoff = false,
    MacPrayerFocusStyle? focusStyle,
    int? focusDurationSeconds,
    bool? focusAudio,
    bool? focusCommitment,
    String? focusDisplay,
    bool? timeSensitive,
    bool? allowLockedAudio,
    bool? quiet,
    int? advanceMinutes,
    Map<String, MacPrayerOverride>? overrides,
  }) => MacPrayerExperience(
    configured: configured ?? this.configured,
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
    startAtLogin: startAtLogin ?? this.startAtLogin,
    reciterId: reciterId ?? this.reciterId,
    audioVersion: audioVersion ?? this.audioVersion,
    delivery: delivery ?? this.delivery,
    volume: volume ?? this.volume,
    stopAfterSeconds: clearCutoff
        ? null
        : stopAfterSeconds ?? this.stopAfterSeconds,
    focusStyle: focusStyle ?? this.focusStyle,
    focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
    focusAudio: focusAudio ?? this.focusAudio,
    focusCommitment: focusCommitment ?? this.focusCommitment,
    focusDisplay: focusDisplay ?? this.focusDisplay,
    timeSensitive: timeSensitive ?? this.timeSensitive,
    allowLockedAudio: allowLockedAudio ?? this.allowLockedAudio,
    quiet: quiet ?? this.quiet,
    advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    overrides: overrides ?? this.overrides,
  );
}
