import 'package:huda/core/services/prayer_audio_catalog.dart';
import 'package:huda_notifications/huda_notifications.dart';

enum AndroidPrayerMode { off, silent, short, full }

/// Native policy is authoritative. Sparse overrides inherit the global value.
class AndroidPrayerExperience {
  AndroidPrayerExperience._(this.policyRevision, this.values);
  static const schemaVersion = 1;
  static const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const preferenceKey = 'android_prayer_experience_v1';
  static const defaults = <String, Object?>{
    'enabled': true,
    'defaultMode': 'full',
    'reciterId': 'huda-default',
    'audioVersion': 'v1',
    'volumeGain': 1.0,
    'fadeInSeconds': 0,
    'stopAfterSeconds': null,
    'alarmScreenEnabled': true,
    // On by default; it does nothing on phones without the sensors.
    'flipToStopEnabled': true,
    'respectRingerMode': false,
    'respectDoNotDisturb': true,
    'vibrate': true,
    'stopOnHeadsetDisconnect': true,
    // Ignored since notifications became one prayer each; kept because the
    // native policy validator rejects unknown or missing keys.
    'showNextPrayer': true,
    'showMissedSummary': false,
    // Ignored since "Remind me in 5 minutes" was removed (one Stop on every
    // platform); kept for the same reason as showNextPrayer.
    'followUpEnabled': false,
    'localeCode': 'en',
    // Minutes of the reminder before each prayer; 0 is none.
    'advanceMinutes': 0,
    'perPrayer': <String, Object?>{},
  };
  static const advanceMinuteOptions = [0, 5, 10, 15, 30];
  static const overrideKeys = {
    'mode',
    'reciterId',
    'audioVersion',
    'volumeGain',
    'fadeInSeconds',
    'stopAfterSeconds',
    'alarmScreenEnabled',
    'flipToStopEnabled',
    'vibrate',
    'advanceMinutes',
  };
  final int policyRevision;
  final Map<String, Object?> values;

  factory AndroidPrayerExperience.fromPolicy(PolicyData data) {
    if (data.schemaVersion != schemaVersion) {
      throw const FormatException('Unsupported Android prayer policy.');
    }
    return AndroidPrayerExperience.fromMap(
      data.values,
      revision: data.revision,
    );
  }
  factory AndroidPrayerExperience.fromMap(
    Map<String, Object?> input, {
    int revision = 0,
  }) {
    if (revision < 0 || input.keys.any((key) => !defaults.containsKey(key))) {
      throw const FormatException('Invalid Android prayer policy.');
    }
    final normalized = {...defaults, ...input};
    for (final entry in defaults.entries) {
      if (entry.value is bool && normalized[entry.key] is! bool) {
        throw const FormatException('Invalid boolean setting.');
      }
    }
    if (normalized['respectDoNotDisturb'] != true ||
        !['silent', 'short', 'full'].contains(normalized['defaultMode']) ||
        normalized['localeCode'] is! String ||
        (normalized['localeCode'] as String).length < 2 ||
        (normalized['localeCode'] as String).length > 16) {
      throw const FormatException('Invalid Android prayer policy.');
    }
    final rawOverrides = normalized['perPrayer'];
    if (rawOverrides is! Map ||
        rawOverrides.keys.any((key) => !prayers.contains(key))) {
      throw const FormatException('Invalid prayer overrides.');
    }
    final overrides = <String, Object?>{};
    for (final entry in rawOverrides.entries) {
      if (entry.value is! Map) {
        throw const FormatException('Invalid prayer override.');
      }
      final fields = Map<String, Object?>.from(entry.value as Map);
      if (fields.keys.any((key) => !overrideKeys.contains(key)) ||
          fields.values.any((value) => value == null) ||
          fields.containsKey('mode') &&
              !AndroidPrayerMode.values.any(
                (mode) => mode.name == fields['mode'],
              )) {
        throw const FormatException('Invalid prayer override.');
      }
      for (final key in [
        'alarmScreenEnabled',
        'flipToStopEnabled',
        'vibrate',
      ]) {
        if (fields.containsKey(key) && fields[key] is! bool) {
          throw const FormatException('Invalid boolean override.');
        }
      }
      overrides[entry.key as String] = Map<String, Object?>.unmodifiable(
        fields,
      );
    }
    normalized['perPrayer'] = Map<String, Object?>.unmodifiable(overrides);
    final result = AndroidPrayerExperience._(
      revision,
      Map.unmodifiable(normalized),
    );
    for (final prayer in prayers) {
      result.effective(prayer);
    }
    return result;
  }
  Map<String, Object?> overrideFor(String prayer) {
    if (!prayers.contains(prayer)) throw ArgumentError.value(prayer);
    return Map<String, Object?>.from(
      (values['perPrayer'] as Map)[prayer] as Map? ?? const {},
    );
  }

  Map<String, Object?> effective(String prayer) {
    final result = {...values, ...overrideFor(prayer)};
    result['mode'] = enabled
        ? overrideFor(prayer)['mode'] ?? values['defaultMode']
        : 'off';
    void number(String key, num min, num max, {bool integer = false}) {
      final value = result[key];
      if (value is! num ||
          !value.isFinite ||
          value < min ||
          value > max ||
          integer && value % 1 != 0) {
        throw FormatException('Invalid $key.');
      }
    }

    number('volumeGain', 0, 1);
    number('fadeInSeconds', 0, 30, integer: true);
    if (result['stopAfterSeconds'] != null) {
      number('stopAfterSeconds', 1, 3600, integer: true);
    }
    number('advanceMinutes', 0, 30, integer: true);
    if (!advanceMinuteOptions.contains(
      (result['advanceMinutes'] as num).toInt(),
    )) {
      throw const FormatException('Invalid advanceMinutes.');
    }
    if (result['reciterId'] is! String ||
        !PrayerAudioCatalogRules.idPattern.hasMatch(
          result['reciterId'] as String,
        ) ||
        result['audioVersion'] is! String ||
        !PrayerAudioCatalogRules.versionPattern.hasMatch(
          result['audioVersion'] as String,
        )) {
      throw const FormatException('Invalid audio identity.');
    }
    return Map.unmodifiable(result);
  }

  bool get enabled => values['enabled'] as bool;
  Set<String> get enabledPrayers =>
      prayers.where((prayer) => effective(prayer)['mode'] != 'off').toSet();

  /// Whether a prayer that alerts has a reminder before it. Native then
  /// reserves part of the alarm budget for reminders, so fewer prayers fit.
  bool get advanceActive => prayers.any((prayer) {
    final resolved = effective(prayer);
    return resolved['mode'] != 'off' && (resolved['advanceMinutes'] as num) > 0;
  });
  String get eligibilitySignature => prayers
      .map((prayer) => '$prayer:${enabledPrayers.contains(prayer) ? 1 : 0}')
      .join(',');
  PolicyData toPolicy() => PolicyData(
    schemaVersion: schemaVersion,
    revision: policyRevision,
    values: values,
  );
  AndroidPrayerExperience edit(Map<String, Object?> changes, {String? prayer}) {
    if (prayer == null) {
      return AndroidPrayerExperience.fromMap({
        ...values,
        ...changes,
      }, revision: policyRevision);
    }
    final override = {...overrideFor(prayer), ...changes}
      ..removeWhere((key, value) => value == null);
    return AndroidPrayerExperience.fromMap({
      ...values,
      'perPrayer': {...values['perPrayer'] as Map, prayer: override},
    }, revision: policyRevision);
  }
}
