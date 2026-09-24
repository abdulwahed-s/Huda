import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';

class PrayerScheduleConfiguration {
  PrayerScheduleConfiguration({
    required this.location,
    required this.deviceTimeZoneId,
    required this.methodToken,
    required this.madhabToken,
    required this.highLatitudeRuleToken,
    required this.customAngles,
    required Map<String, int> offsets,
    required this.localeCode,
    this.schedulingCapability = 'default',
  }) : offsets = Map.unmodifiable(
         PrayerTimesCalculator.sanitizeOffsets(offsets),
       );

  static const int signatureVersion = 4;

  final PrayerLocationGeneration location;
  final String deviceTimeZoneId;
  final String methodToken;
  final String madhabToken;
  final String highLatitudeRuleToken;
  final CustomPrayerAngles customAngles;
  final Map<String, int> offsets;
  final String localeCode;
  final String schedulingCapability;

  factory PrayerScheduleConfiguration.fromCache({
    required CacheHelper cache,
    required PrayerLocationGeneration location,
    required String deviceTimeZoneId,
  }) {
    return PrayerScheduleConfiguration(
      location: location,
      deviceTimeZoneId: deviceTimeZoneId,
      methodToken: PrayerTimesCalculator.methodTokenFromCache(cache),
      madhabToken:
          cache.getDataString(key: PrayerTimesCalculator.madhabKey) ??
          PrayerTimesCalculator.defaultMadhabToken,
      highLatitudeRuleToken:
          cache.getDataString(key: PrayerTimesCalculator.highLatitudeRuleKey) ??
          PrayerTimesCalculator.defaultHighLatitudeToken,
      customAngles: PrayerTimesCalculator.customAnglesFromCache(cache),
      offsets: PrayerTimesCalculator.offsetsFromCache(cache),
      localeCode:
          cache.getDataString(key: 'app_locale') ??
          cache.getDataString(key: 'locale') ??
          'en',
    );
  }

  PrayerScheduleConfiguration forLocation(
    PrayerLocationGeneration nextLocation,
  ) {
    return PrayerScheduleConfiguration(
      location: nextLocation,
      deviceTimeZoneId: deviceTimeZoneId,
      methodToken: methodToken,
      madhabToken: madhabToken,
      highLatitudeRuleToken: highLatitudeRuleToken,
      customAngles: customAngles,
      offsets: offsets,
      localeCode: localeCode,
      schedulingCapability: schedulingCapability,
    );
  }

  PrayerScheduleConfiguration forSchedulingCapability(String capability) {
    final normalized = capability.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        capability,
        'capability',
        'Scheduling capability cannot be empty.',
      );
    }
    return PrayerScheduleConfiguration(
      location: location,
      deviceTimeZoneId: deviceTimeZoneId,
      methodToken: methodToken,
      madhabToken: madhabToken,
      highLatitudeRuleToken: highLatitudeRuleToken,
      customAngles: customAngles,
      offsets: offsets,
      localeCode: localeCode,
      schedulingCapability: normalized,
    );
  }

  String get signature {
    final parts = <String>[
      'v$signatureVersion',
      'location:${location.revision}',
      'lat:${location.latitude}',
      'lon:${location.longitude}',
      'country:${location.countryCode ?? ''}',
      'zone:${location.timeZoneId}',
      'zone-provenance:${location.timeZoneProvenance.name}',
      'device-zone:$deviceTimeZoneId',
      'method:$methodToken',
      'madhab:$madhabToken',
      'high-latitude:$highLatitudeRuleToken',
      'custom-fajr:${CustomPrayerAngles.canonical(customAngles.fajr)}',
      'custom-maghrib:${CustomPrayerAngles.canonical(customAngles.maghrib)}',
      'custom-isha:${CustomPrayerAngles.canonical(customAngles.isha)}',
      'locale:$localeCode',
      'scheduling-capability:$schedulingCapability',
      for (final key in PrayerTimesCalculator.offsetPrayerKeys)
        '$key:${offsets[key] ?? 0}',
    ];
    return parts.join('|');
  }
}
