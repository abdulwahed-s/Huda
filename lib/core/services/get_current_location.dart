import 'package:huda/core/errors/location_failures.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/utils/platform_utils.dart';

Future<Position> getCurrentLocation() async {
  bool serviceEnabled = true;
  if (!PlatformUtils.isLinux) {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
  }

  if (!serviceEnabled) {
    throw const LocationServiceDisabledFailure();
  }

  LocationPermission permission = LocationPermission.always;
  if (!PlatformUtils.isLinux) {
    permission = await Geolocator.checkPermission();
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedFailure();
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionPermanentlyDeniedFailure();
  }

  try {
    return await Geolocator.getCurrentPosition();
  } catch (e) {
    throw const LocationServiceDisabledFailure();
  }
}
