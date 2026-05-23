import 'package:adhan/adhan.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesCalculator {
  PrayerTimesCalculator._();

  static const String latKey = 'latitude';
  static const String lonKey = 'longitude';

  static const String fajrOffsetKey = 'prayer_offset_fajr';
  static const String sunriseOffsetKey = 'prayer_offset_sunrise';
  static const String dhuhrOffsetKey = 'prayer_offset_dhuhr';
  static const String asrOffsetKey = 'prayer_offset_asr';
  static const String maghribOffsetKey = 'prayer_offset_maghrib';
  static const String ishaOffsetKey = 'prayer_offset_isha';

  static const List<String> offsetPrayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static String offsetKeyFor(String prayerKey) => 'prayer_offset_$prayerKey';

  static CalculationParameters defaultParameters() {
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    return params;
  }

  static PrayerTimes compute(Coordinates coordinates, DateTime date) {
    return PrayerTimes(
      coordinates,
      DateComponents.from(date),
      defaultParameters(),
    );
  }

  static Coordinates? coordinatesFromStrings(String? latStr, String? lonStr) {
    if (latStr == null || lonStr == null) return null;
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) return null;
    return Coordinates(lat, lon);
  }

  static Coordinates? coordinatesFromCache(CacheHelper cache) {
    return coordinatesFromStrings(
      cache.getDataString(key: latKey),
      cache.getDataString(key: lonKey),
    );
  }

  static Coordinates? coordinatesFromPrefs(SharedPreferences prefs) {
    return coordinatesFromStrings(
      prefs.getString(latKey),
      prefs.getString(lonKey),
    );
  }

  static Map<String, int> zeroOffsets() => {
        for (final k in offsetPrayerKeys) k: 0,
      };

  static Map<String, int> offsetsFromCache(CacheHelper cache) {
    return {
      for (final k in offsetPrayerKeys)
        k: (cache.getData(key: offsetKeyFor(k)) as int?) ?? 0,
    };
  }

  static Map<String, int> offsetsFromPrefs(SharedPreferences prefs) {
    return {
      for (final k in offsetPrayerKeys) k: prefs.getInt(offsetKeyFor(k)) ?? 0,
    };
  }

  static String keyOf(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.sunrise:
        return 'sunrise';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
      default:
        return prayer.name.toLowerCase();
    }
  }

  static DateTime? adjustedTimeFor(
    PrayerTimes prayerTimes,
    Prayer prayer,
    Map<String, int> offsets,
  ) {
    final base = prayerTimes.timeForPrayer(prayer);
    if (base == null) return null;
    final offset = offsets[keyOf(prayer)] ?? 0;
    return base.add(Duration(minutes: offset));
  }

  static Map<Prayer, DateTime> dailyAdjustedTimes(
    PrayerTimes prayerTimes,
    Map<String, int> offsets,
  ) {
    final result = <Prayer, DateTime>{};
    for (final p in const [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ]) {
      final t = adjustedTimeFor(prayerTimes, p, offsets);
      if (t != null) result[p] = t;
    }
    return result;
  }
}
