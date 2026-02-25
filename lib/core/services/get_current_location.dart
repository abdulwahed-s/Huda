import 'package:geolocator/geolocator.dart';
import 'package:huda/core/errors/location_failures.dart';

Future<Position> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationServiceDisabledFailure();
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedFailure();
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionPermanentlyDeniedFailure();
  }

  return await Geolocator.getCurrentPosition();
}
