import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/utils/platform_utils.dart';

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
    if (!PlatformUtils.isAndroid && !PlatformUtils.isIOS) {
      throw UnsupportedError('Coordinate timezone lookup requires Android/iOS');
    }
    final identifier = await _channel.invokeMethod<String>(
      'resolveTimeZone',
      <String, double>{'latitude': latitude, 'longitude': longitude},
    );
    final normalized = identifier?.trim() ?? '';
    if (normalized.isEmpty) {
      throw StateError('No IANA timezone found for the coordinates');
    }
    PrayerTimeZoneService.location(normalized);
    return normalized;
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
