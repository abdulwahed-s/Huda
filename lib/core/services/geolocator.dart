import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:huda/core/services/windows_location_timestamp.dart';
import 'package:huda/core/utils/platform_utils.dart';

export 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class Geolocator {
  const Geolocator._();

  static Future<bool> isLocationServiceEnabled() =>
      GeolocatorPlatform.instance.isLocationServiceEnabled();

  static Future<LocationPermission> checkPermission() =>
      GeolocatorPlatform.instance.checkPermission();

  static Future<LocationPermission> requestPermission() =>
      GeolocatorPlatform.instance.requestPermission();

  static Future<Position?> getLastKnownPosition({
    bool forceAndroidLocationManager = false,
  }) => GeolocatorPlatform.instance
      .getLastKnownPosition(forceLocationManager: forceAndroidLocationManager)
      .then(
        (position) => position == null ? null : _normalizePosition(position),
      );

  static Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) => GeolocatorPlatform.instance
      .getCurrentPosition(locationSettings: locationSettings)
      .then(_normalizePosition);

  static Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) => GeolocatorPlatform.instance
      .getPositionStream(locationSettings: locationSettings)
      .map(_normalizePosition);

  static Position _normalizePosition(Position position) =>
      PlatformUtils.isWindows
      ? normalizeWindowsLocationTimestamp(position)
      : position;

  static Future<bool> openAppSettings() =>
      GeolocatorPlatform.instance.openAppSettings();

  static Future<bool> openLocationSettings() =>
      GeolocatorPlatform.instance.openLocationSettings();
}
