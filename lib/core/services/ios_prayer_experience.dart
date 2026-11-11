/// `fullAlarm`: the whole built-in adhan as the alarm sound (iOS 26.1+);
/// earlier it runs as `alarm`.
enum IOSPrayerMode { off, silent, short, alarm, fullAlarm }

const iosPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const iosPrayerAdvanceMinutes = [0, 5, 10, 15, 30];

class IOSPrayerOverride {
  const IOSPrayerOverride({
    this.mode,
    this.reciterId,
    this.advanceMinutes,
    this.advanceMode,
  });
  final IOSPrayerMode? mode, advanceMode;
  final String? reciterId;
  final int? advanceMinutes;
  Map<String, Object?> toMap() => {
    if (mode != null) 'mode': mode!.name,
    if (reciterId != null) 'reciterId': reciterId,
    if (advanceMinutes != null) 'advanceMinutes': advanceMinutes,
    if (advanceMode != null) 'advanceMode': advanceMode!.name,
  };
  factory IOSPrayerOverride.fromMap(Map value) => IOSPrayerOverride(
    mode: value['mode'] == null
        ? null
        : IOSPrayerMode.values.byName(value['mode'] as String),
    reciterId: value['reciterId'] as String?,
    advanceMinutes: value['advanceMinutes'] as int?,
    advanceMode: value['advanceMode'] == null
        ? null
        : IOSPrayerMode.values.byName(value['advanceMode'] as String),
  );
}

/// Native acknowledged settings are authoritative. Sparse prayer overrides
/// inherit global defaults, so changing a default does not erase an override.
class IOSPrayerExperience {
  const IOSPrayerExperience({
    this.enabled = true,
    this.mode = IOSPrayerMode.short,
    this.reciterId = 'huda-default',
    this.audioVersion = 'v1',
    this.fallback = IOSPrayerMode.short,
    // Matches the native default: prayers break through Focus, as in 4.3.0.
    this.timeSensitive = true,
    this.advanceMinutes = 0,
    this.advanceMode = IOSPrayerMode.silent,
    this.overrides = const {},
  });
  final bool enabled, timeSensitive;
  final IOSPrayerMode mode, fallback, advanceMode;
  final String reciterId, audioVersion;
  final int advanceMinutes;
  final Map<String, IOSPrayerOverride> overrides;
  IOSPrayerOverride policyFor(String prayer) {
    final value = overrides[prayer];
    return IOSPrayerOverride(
      mode: enabled ? value?.mode ?? mode : IOSPrayerMode.off,
      reciterId: value?.reciterId ?? reciterId,
      advanceMinutes: value?.advanceMinutes ?? advanceMinutes,
      advanceMode: value?.advanceMode ?? advanceMode,
    );
  }

  void validate() {
    bool reciter(String value) =>
        value.length <= 100 &&
        RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value);
    if (!reciter(reciterId) ||
        !RegExp(r'^v[1-9][0-9]*$').hasMatch(audioVersion) ||
        ![IOSPrayerMode.silent, IOSPrayerMode.short].contains(fallback) ||
        ![IOSPrayerMode.silent, IOSPrayerMode.short].contains(advanceMode) ||
        !iosPrayerAdvanceMinutes.contains(advanceMinutes) ||
        overrides.length > 5 ||
        overrides.entries.any(
          (e) =>
              !iosPrayerKeys.contains(e.key) ||
              e.value.reciterId != null && !reciter(e.value.reciterId!) ||
              e.value.advanceMinutes != null &&
                  !iosPrayerAdvanceMinutes.contains(e.value.advanceMinutes) ||
              e.value.advanceMode != null &&
                  ![
                    IOSPrayerMode.silent,
                    IOSPrayerMode.short,
                  ].contains(e.value.advanceMode),
        )) {
      throw const FormatException('Invalid iOS prayer settings.');
    }
  }

  Map<String, Object?> toMap() {
    validate();
    return {
      'version': 1,
      'enabled': enabled,
      'mode': mode.name,
      'reciterId': reciterId,
      'audioVersion': audioVersion,
      'fallback': fallback.name,
      'timeSensitive': timeSensitive,
      'advanceMinutes': advanceMinutes,
      'advanceMode': advanceMode.name,
      'overrides': overrides.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory IOSPrayerExperience.fromMap(Map value) {
    if (value['version'] != 1) {
      throw const FormatException('Unsupported iOS prayer settings.');
    }
    final result = IOSPrayerExperience(
      enabled: value['enabled'] as bool,
      mode: IOSPrayerMode.values.byName(value['mode'] as String),
      reciterId: value['reciterId'] as String,
      audioVersion: value['audioVersion'] as String,
      fallback: IOSPrayerMode.values.byName(value['fallback'] as String),
      timeSensitive: value['timeSensitive'] as bool,
      advanceMinutes: value['advanceMinutes'] as int,
      advanceMode: IOSPrayerMode.values.byName(value['advanceMode'] as String),
      overrides: Map<String, IOSPrayerOverride>.unmodifiable(
        (value['overrides'] as Map).map(
          (key, value) =>
              MapEntry(key as String, IOSPrayerOverride.fromMap(value as Map)),
        ),
      ),
    );
    result.validate();
    return result;
  }
  IOSPrayerExperience copyWith({
    bool? enabled,
    IOSPrayerMode? mode,
    String? reciterId,
    String? audioVersion,
    IOSPrayerMode? fallback,
    bool? timeSensitive,
    int? advanceMinutes,
    IOSPrayerMode? advanceMode,
    Map<String, IOSPrayerOverride>? overrides,
  }) => IOSPrayerExperience(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    reciterId: reciterId ?? this.reciterId,
    audioVersion: audioVersion ?? this.audioVersion,
    fallback: fallback ?? this.fallback,
    timeSensitive: timeSensitive ?? this.timeSensitive,
    advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    advanceMode: advanceMode ?? this.advanceMode,
    overrides: Map.unmodifiable(overrides ?? this.overrides),
  );
}
