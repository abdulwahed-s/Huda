import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

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
  }) =>
      GeolocatorPlatform.instance.getLastKnownPosition(
        forceLocationManager: forceAndroidLocationManager,
      );

  static Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) =>
      GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: locationSettings,
      );

  static Future<bool> openAppSettings() =>
      GeolocatorPlatform.instance.openAppSettings();

  static Future<bool> openLocationSettings() =>
      GeolocatorPlatform.instance.openLocationSettings();
}
