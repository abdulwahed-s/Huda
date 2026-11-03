import 'dart:async';

import 'package:flutter/services.dart';

import 'package:huda/core/errors/location_failures.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/utils/platform_utils.dart';

/// Prayer times only need the city, so a fix this recent is used as is.
const recentLocationAge = Duration(minutes: 10);

/// How long to wait for a new fix before settling for the last known one.
const locationFixTimeLimit = Duration(seconds: 30);

/// Whether this platform has a location provider at all. Linux has none
/// (there is no geolocator implementation for it), so a city is the only way.
bool get deviceLocationSupported => !PlatformUtils.isLinux;

/// Whether a location can be read now without showing a system prompt:
/// services on and permission already granted.
Future<bool> canLocateWithoutAsking() async {
  if (!deviceLocationSupported) return false;
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  } catch (_) {
    return false;
  }
}

Future<Position> getCurrentLocation({
  Duration timeLimit = locationFixTimeLimit,
  DateTime Function() now = DateTime.now,
}) async {
  if (!deviceLocationSupported) throw const LocationNotSupportedFailure();

  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationServiceDisabledFailure();
  }

  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedFailure();
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionPermanentlyDeniedFailure();
  }

  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    throw const LocationPermissionDeniedFailure();
  }

  final recent = await _lastKnownPosition();
  if (recent != null &&
      now().difference(recent.timestamp) <= recentLocationAge) {
    return recent;
  }
  Future<Position> lastKnownOrFail() async {
    final last = recent ?? await _lastKnownPosition();
    if (last != null) return last;
    throw const LocationUnavailableFailure();
  }

  try {
    return await Geolocator.getCurrentPosition().timeout(timeLimit);
  } on TimeoutException {
    // A new fix may never come: Apple's plugin skips fixes more than five
    // seconds old, and a Mac that isn't moving may only have a cached one.
    return lastKnownOrFail();
  } on LocationUnavailableFailure {
    return lastKnownOrFail();
  } on PlatformException catch (error) {
    // Android's own location layer reports a missed fix this way.
    if (error.code == 'UNAVAILABLE' || error.code == 'TIMEOUT') {
      return lastKnownOrFail();
    }
    rethrow;
  } on PermissionDeniedException {
    throw const LocationPermissionDeniedFailure();
  } on LocationServiceDisabledException {
    throw const LocationServiceDisabledFailure();
  }
}

Future<Position?> _lastKnownPosition() async {
  try {
    return await Geolocator.getLastKnownPosition();
  } catch (_) {
    // Not every platform keeps one.
    return null;
  }
}

Future<Position?> getCurrentLocationForTravelValidation() async {
  if (!deviceLocationSupported) return null;
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  final permission = await Geolocator.checkPermission();
  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    return null;
  }
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
  } on PermissionDeniedException {
    return null;
  } on LocationServiceDisabledException {
    return null;
  }
}
