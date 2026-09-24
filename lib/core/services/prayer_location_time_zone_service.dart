import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:timezone_finder/timezone_finder.dart' as timezone_finder;

typedef PrayerTimeZoneResolver =
    Future<String> Function(
      double latitude,
      double longitude,
      String countryCode,
    );

abstract final class PrayerLocationTimeZoneService {
  static const MethodChannel _channel = MethodChannel(
    'com.aw.huda/prayer_location',
  );

  static Future<String> resolveExact(
    double latitude,
    double longitude,
    String countryCode,
  ) async {
    if (PlatformUtils.isWindows) {
      return resolveOfflineExact(latitude, longitude);
    }
    if (!PlatformUtils.isAndroid &&
        !PlatformUtils.isIOS &&
        !PlatformUtils.isMacOS) {
      throw UnsupportedError(
        'Coordinate timezone lookup is unavailable on this platform',
      );
    }
    final identifier = await _channel.invokeMethod<String>(
      'resolveTimeZone',
      <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'countryCode': countryCode,
      },
    );
    final normalized = identifier?.trim() ?? '';
    if (normalized.isEmpty) {
      throw StateError('No IANA timezone found for the coordinates');
    }
    PrayerTimeZoneService.location(normalized);
    return normalized;
  }

  static String resolveOfflineExact(double latitude, double longitude) {
    PrayerTimeZoneService.initializeDatabase();
    final location = timezone_finder.findLocation(longitude, latitude);
    if (location == null || location.name.trim().isEmpty) {
      throw StateError('No IANA timezone boundary covers the coordinates');
    }
    PrayerTimeZoneService.location(location.name);
    return location.name;
  }

  static Future<String> resolve(
    double latitude,
    double longitude,
    String countryCode,
  ) async {
    try {
      return await resolveExact(latitude, longitude, countryCode);
    } on PlatformException {
      return legacyFallback(countryCode);
    } on MissingPluginException {
      return legacyFallback(countryCode);
    } on UnsupportedError {
      return legacyFallback(countryCode);
    }
  }

  static String legacyFallback(String countryCode) {
    final mapped = PrayerTimesCalculator.timeZoneNameForCountry(countryCode);
    if (mapped != null) return mapped;
    return PrayerTimeZoneService.configuredLocalTimeZoneName ?? 'UTC';
  }
}
