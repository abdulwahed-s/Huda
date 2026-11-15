import 'dart:convert';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

class PrayerIqamahSettings {
  const PrayerIqamahSettings() : _minutes = defaults;

  PrayerIqamahSettings.sanitize(Object? value)
    : _minutes = Map.unmodifiable({
        for (final entry in defaults.entries)
          entry.key: _sanitize(
            value is Map ? value[entry.key] : null,
            entry.value,
          ),
      });

  static const cacheKey = 'prayer_iqamah_minutes';
  static const maxMinutes = 60;
  static const defaults = {
    'fajr': 25,
    'dhuhr': 20,
    'asr': 20,
    'maghrib': 5,
    'isha': 20,
  };

  final Map<String, int> _minutes;

  static int _sanitize(Object? value, int fallback) =>
      value is num && value.isFinite
      ? value.clamp(0, maxMinutes).toInt()
      : fallback;

  Duration windowFor(Prayer prayer) =>
      Duration(minutes: _minutes[prayer.name] ?? 0);

  Map<String, int> toMap() => Map.of(_minutes);

  factory PrayerIqamahSettings.fromCache(CacheHelper cache) {
    try {
      return PrayerIqamahSettings.sanitize(
        jsonDecode(cache.getDataString(key: cacheKey) ?? 'null'),
      );
    } on FormatException {
      return const PrayerIqamahSettings();
    } on TypeError {
      return const PrayerIqamahSettings();
    }
  }

  Future<void> save(CacheHelper cache) async {
    if (!await cache.saveData(key: cacheKey, value: jsonEncode(_minutes))) {
      throw StateError('Iqamah settings could not be saved.');
    }
  }
}
