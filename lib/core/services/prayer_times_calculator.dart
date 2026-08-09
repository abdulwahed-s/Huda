import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyPrayerTimes {
  const DailyPrayerTimes({
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
    this.fajrInstantUtc,
    this.sunriseInstantUtc,
    this.dhuhrInstantUtc,
    this.asrInstantUtc,
    this.maghribInstantUtc,
    this.ishaInstantUtc,
  });

  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;
  final DateTime? fajrInstantUtc;
  final DateTime? sunriseInstantUtc;
  final DateTime? dhuhrInstantUtc;
  final DateTime? asrInstantUtc;
  final DateTime? maghribInstantUtc;
  final DateTime? ishaInstantUtc;

  DateTime? timeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
      case Prayer.none:
        return null;
    }
  }

  DateTime? instantForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajrInstantUtc;
      case Prayer.sunrise:
        return sunriseInstantUtc;
      case Prayer.dhuhr:
        return dhuhrInstantUtc;
      case Prayer.asr:
        return asrInstantUtc;
      case Prayer.maghrib:
        return maghribInstantUtc;
      case Prayer.isha:
        return ishaInstantUtc;
      case Prayer.none:
        return null;
    }
  }
}

class PrayerTimesCalculator {
  PrayerTimesCalculator._();

  static const String latKey = 'latitude';
  static const String lonKey = 'longitude';
  static const String countryCodeKey = 'country_code';

  static const String methodKey = 'calculation_method';
  static const String madhabKey = 'madhab';
  static const String highLatitudeRuleKey = 'high_latitude_rule';

  static const String autoMethodToken = 'auto';
  static const String defaultMethodToken = autoMethodToken;
  static const String defaultMadhabToken = 'shafi';
  static const String defaultHighLatitudeToken = 'automatic';

  static const Map<String, String> _countryTimeZoneIds = {
    'AE': 'Asia/Dubai',
    'BH': 'Asia/Bahrain',
    'DE': 'Europe/Berlin',
    'EG': 'Africa/Cairo',
    'ES': 'Europe/Madrid',
    'FR': 'Europe/Paris',
    'GB': 'Europe/London',
    'ID': 'Asia/Jakarta',
    'IN': 'Asia/Kolkata',
    'JP': 'Asia/Tokyo',
    'KW': 'Asia/Kuwait',
    'MY': 'Asia/Kuala_Lumpur',
    'NP': 'Asia/Kathmandu',
    'OM': 'Asia/Muscat',
    'PK': 'Asia/Karachi',
    'QA': 'Asia/Qatar',
    'SA': 'Asia/Riyadh',
    'TR': 'Europe/Istanbul',
    'UK': 'Europe/London',
  };

  static final List<String> pickerMethodTokens = [
    autoMethodToken,
    for (final method in CalculationMethod.values) method.name,
  ];

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

  static Madhab madhabFromToken(String? token) {
    return token == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  static HighLatitudeRule highLatitudeRuleFromToken(String? token) {
    switch (token) {
      case 'automatic':
        return HighLatitudeRule.automatic;
      case 'middleOfTheNight':
        return HighLatitudeRule.middleOfTheNight;
      case 'seventhOfTheNight':
        return HighLatitudeRule.seventhOfTheNight;
      case 'twilightAngle':
        return HighLatitudeRule.twilightAngle;
      case 'none':
        return HighLatitudeRule.none;
      default:
        return HighLatitudeRule.automatic;
    }
  }

  static CalculationMethod _methodFromToken(String token) {
    for (final method in CalculationMethod.values) {
      if (method.name == token) return method;
    }
    return CalculationMethod.ummAlQura;
  }

  static CalculationMethod resolveMethod(
      String methodToken, String countryCode) {
    if (methodToken == autoMethodToken) {
      if (countryCode.trim().isEmpty) return CalculationMethod.ummAlQura;
      return AutoMethod.forCountry(countryCode.trim());
    }
    return _methodFromToken(methodToken);
  }

  static CalculationParameters buildParameters({
    String methodToken = defaultMethodToken,
    String countryCode = '',
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.automatic,
  }) {
    final params = resolveMethod(methodToken, countryCode).getParameters()
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule;
    return params;
  }

  static DateTime? _localWallClock(DateTime? t) {
    if (t == null) return null;
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  static DateTime? _instantUtc(DateTime? wallClock, Duration offset) {
    return wallClock?.subtract(offset).toUtc();
  }

  static DateTime? _wallClockAtInstant(
    DateTime? instantUtc,
    String? timeZoneName,
    DateTime? fixedOffsetWallClock,
  ) {
    if (instantUtc == null) return null;
    if (timeZoneName == null) return _localWallClock(fixedOffsetWallClock);
    return PrayerTimeZoneService.wallClockAtInstant(
      instantUtc,
      timeZoneName,
    );
  }

  static String? timeZoneNameForCountry(String countryCode) =>
      _countryTimeZoneIds[countryCode.trim().toUpperCase()];

  static String resolveTimeZoneName({
    required String countryCode,
    required String fallbackTimeZoneName,
  }) {
    return timeZoneNameForCountry(countryCode) ?? fallbackTimeZoneName;
  }

  static Duration offsetForTimeZone(String timeZoneName, DateTime date) {
    final midday = DateTime(
      date.year,
      date.month,
      date.day,
      12,
    );
    return PrayerTimeZoneService.fromWallClock(midday, timeZoneName)
        .timeZoneOffset;
  }

  static Duration _calculationOffset({
    required String countryCode,
    required DateTime date,
    String? timeZoneName,
  }) {
    final zoneId = timeZoneName ?? timeZoneNameForCountry(countryCode);
    if (zoneId == null) return date.timeZoneOffset;
    try {
      return offsetForTimeZone(zoneId, date);
    } catch (_) {
      if (timeZoneName != null) rethrow;
      return date.timeZoneOffset;
    }
  }

  static DailyPrayerTimes compute(
    Coordinates coordinates,
    DateTime date, {
    String methodToken = defaultMethodToken,
    String countryCode = '',
    String? timeZoneName,
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.automatic,
  }) {
    final params = buildParameters(
      methodToken: methodToken,
      countryCode: countryCode,
      madhab: madhab,
      highLatitudeRule: highLatitudeRule,
    );
    final calculationOffset = _calculationOffset(
      countryCode: countryCode,
      date: date,
      timeZoneName: timeZoneName,
    );
    final times = PrayerTimes(
      coordinates,
      DateComponents(date.year, date.month, date.day),
      params,
      utcOffset: calculationOffset,
      countryCode: countryCode.trim(),
    );
    final calculationTimeZoneName =
        timeZoneName ?? timeZoneNameForCountry(countryCode);
    final fajrInstant = _instantUtc(times.fajr, calculationOffset);
    final sunriseInstant = _instantUtc(times.sunrise, calculationOffset);
    final dhuhrInstant = _instantUtc(times.dhuhr, calculationOffset);
    final asrInstant = _instantUtc(times.asr, calculationOffset);
    final maghribInstant = _instantUtc(times.maghrib, calculationOffset);
    final ishaInstant = _instantUtc(times.isha, calculationOffset);
    return DailyPrayerTimes(
      fajr: _wallClockAtInstant(
        fajrInstant,
        calculationTimeZoneName,
        times.fajr,
      ),
      sunrise: _wallClockAtInstant(
        sunriseInstant,
        calculationTimeZoneName,
        times.sunrise,
      ),
      dhuhr: _wallClockAtInstant(
        dhuhrInstant,
        calculationTimeZoneName,
        times.dhuhr,
      ),
      asr: _wallClockAtInstant(
        asrInstant,
        calculationTimeZoneName,
        times.asr,
      ),
      maghrib: _wallClockAtInstant(
        maghribInstant,
        calculationTimeZoneName,
        times.maghrib,
      ),
      isha: _wallClockAtInstant(
        ishaInstant,
        calculationTimeZoneName,
        times.isha,
      ),
      fajrInstantUtc: fajrInstant,
      sunriseInstantUtc: sunriseInstant,
      dhuhrInstantUtc: dhuhrInstant,
      asrInstantUtc: asrInstant,
      maghribInstantUtc: maghribInstant,
      ishaInstantUtc: ishaInstant,
    );
  }

  static DailyPrayerTimes computeFromCache(
    CacheHelper cache,
    Coordinates coordinates,
    DateTime date, {
    String? timeZoneName,
  }) {
    return compute(
      coordinates,
      date,
      methodToken: methodTokenFromCache(cache),
      countryCode: countryCodeFromCache(cache),
      timeZoneName: timeZoneName,
      madhab: madhabFromToken(cache.getDataString(key: madhabKey)),
      highLatitudeRule: highLatitudeRuleFromToken(
          cache.getDataString(key: highLatitudeRuleKey)),
    );
  }

  static DailyPrayerTimes computeFromPrefs(
    SharedPreferences prefs,
    Coordinates coordinates,
    DateTime date, {
    String? timeZoneName,
  }) {
    return compute(
      coordinates,
      date,
      methodToken: methodTokenFromPrefs(prefs),
      countryCode: countryCodeFromPrefs(prefs),
      timeZoneName: timeZoneName,
      madhab: madhabFromToken(prefs.getString(madhabKey)),
      highLatitudeRule:
          highLatitudeRuleFromToken(prefs.getString(highLatitudeRuleKey)),
    );
  }

  static Coordinates? coordinatesFromStrings(String? latStr, String? lonStr) {
    if (latStr == null || lonStr == null) return null;
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) return null;
    if (!lat.isFinite || !lon.isFinite) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
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

  static String countryCodeFromCache(CacheHelper cache) =>
      cache.getDataString(key: countryCodeKey) ?? '';

  static String countryCodeFromPrefs(SharedPreferences prefs) =>
      prefs.getString(countryCodeKey) ?? '';

  static String methodTokenFromCache(CacheHelper cache) =>
      cache.getDataString(key: methodKey) ?? defaultMethodToken;

  static String methodTokenFromPrefs(SharedPreferences prefs) =>
      prefs.getString(methodKey) ?? defaultMethodToken;

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
      case Prayer.none:
        return 'none';
    }
  }

  static DateTime? adjustedTimeFor(
    DailyPrayerTimes prayerTimes,
    Prayer prayer,
    Map<String, int> offsets,
  ) {
    final base = prayerTimes.timeForPrayer(prayer);
    if (base == null) return null;
    final offset = offsets[keyOf(prayer)] ?? 0;
    return base.add(Duration(minutes: offset));
  }

  static DateTime? adjustedInstantFor(
    DailyPrayerTimes prayerTimes,
    Prayer prayer,
    Map<String, int> offsets,
  ) {
    final base = prayerTimes.instantForPrayer(prayer);
    if (base == null) return null;
    final offset = offsets[keyOf(prayer)] ?? 0;
    return base.add(Duration(minutes: offset)).toUtc();
  }

  static Map<Prayer, DateTime> dailyAdjustedTimes(
    DailyPrayerTimes prayerTimes,
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

  static Map<Prayer, DateTime> dailyAdjustedInstants(
    DailyPrayerTimes prayerTimes,
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
      final instant = adjustedInstantFor(prayerTimes, p, offsets);
      if (instant != null) result[p] = instant;
    }
    return result;
  }
}
