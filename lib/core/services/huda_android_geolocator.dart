import 'package:flutter/services.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class HudaAndroidGeolocator extends GeolocatorPlatform {
  static const MethodChannel _channel = MethodChannel('com.aw.huda/location');

  @override
  Future<bool> isLocationServiceEnabled() async {
    final enabled =
        await _channel.invokeMethod<bool>('isLocationServiceEnabled');
    return enabled ?? false;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    final status = await ph.Permission.locationWhenInUse.status;
    return _mapPermission(status);
  }

  @override
  Future<LocationPermission> requestPermission() async {
    final status = await ph.Permission.locationWhenInUse.request();
    return _mapPermission(status);
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'getLastKnownPosition',
    );
    return map == null ? null : _positionFromMap(map);
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'getCurrentPosition',
    );
    if (map == null) {
      throw const LocationServiceDisabledException();
    }
    return _positionFromMap(map);
  }

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();

  @override
  Future<bool> openLocationSettings() async {
    final opened = await _channel.invokeMethod<bool>('openLocationSettings');
    return opened ?? false;
  }

  LocationPermission _mapPermission(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
      case ph.PermissionStatus.provisional:
        return LocationPermission.whileInUse;
      case ph.PermissionStatus.permanentlyDenied:
      case ph.PermissionStatus.restricted:
        return LocationPermission.deniedForever;
      case ph.PermissionStatus.denied:
        return LocationPermission.denied;
    }
  }

  Position _positionFromMap(Map<String, dynamic> map) {
    double d(String key) => (map[key] as num?)?.toDouble() ?? 0.0;
    return Position(
      latitude: d('latitude'),
      longitude: d('longitude'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      accuracy: d('accuracy'),
      altitude: d('altitude'),
      altitudeAccuracy: d('altitudeAccuracy'),
      heading: d('heading'),
      headingAccuracy: d('headingAccuracy'),
      speed: d('speed'),
      speedAccuracy: d('speedAccuracy'),
    );
  }
}
