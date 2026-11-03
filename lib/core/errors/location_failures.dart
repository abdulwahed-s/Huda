import 'package:flutter/services.dart';

abstract class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);
}

class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure()
    : super('Location services are disabled.');
}

class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure()
    : super('Location permissions are denied.');
}

class LocationPermissionPermanentlyDeniedFailure extends LocationFailure {
  const LocationPermissionPermanentlyDeniedFailure()
    : super('Location permissions are permanently denied.');
}

/// No new fix arrived in time and the device has no earlier one.
class LocationUnavailableFailure extends LocationFailure {
  const LocationUnavailableFailure()
    : super(
        'Your location could not be determined. '
        'Try again, or search for your city.',
      );

  @override
  String toString() => message;
}

/// This platform has no location provider (Linux).
class LocationNotSupportedFailure extends LocationFailure {
  const LocationNotSupportedFailure()
    : super('This device cannot share its location.');
}

/// Why Huda has no place to calculate prayer times for, or why a place the
/// user asked for wasn't used. Each one has its own message and fix in the
/// UI; none of them is shown as raw error text.
enum PrayerLocationProblem {
  /// The user declined the location prompt (it can be asked again).
  denied,

  /// Location access is off for Huda; only Settings can turn it back on.
  blocked,

  /// Location services are off on the device.
  servicesOff,

  /// This device or platform has no way to share its location.
  noDeviceLocation,

  /// Location is allowed, but no fix arrived in time.
  noFix,

  /// The place was found, but its time zone couldn't be worked out.
  timeZone,

  /// The place's coordinates weren't usable.
  placeInvalid,

  /// The place couldn't be saved on this device.
  saveFailed,

  /// Prayer times couldn't be calculated for the saved place.
  calculation,

  /// Anything else; the message stays general but still offers a next step.
  unknown;

  /// The user can fix it by asking for permission again.
  bool get canAsk => this == denied;

  /// Turning something on in the system settings fixes it.
  bool get needsSettings => this == blocked || this == servicesOff;
}

/// One place that turns location errors into a [PrayerLocationProblem].
PrayerLocationProblem prayerLocationProblemOf(Object error) {
  if (error is LocationServiceDisabledFailure) {
    return PrayerLocationProblem.servicesOff;
  }
  if (error is LocationPermissionDeniedFailure) {
    return PrayerLocationProblem.denied;
  }
  if (error is LocationPermissionPermanentlyDeniedFailure) {
    return PrayerLocationProblem.blocked;
  }
  if (error is LocationUnavailableFailure) return PrayerLocationProblem.noFix;
  if (error is LocationNotSupportedFailure) {
    return PrayerLocationProblem.noDeviceLocation;
  }
  if (error is MissingPluginException) {
    return PrayerLocationProblem.noDeviceLocation;
  }
  if (error is PlatformException) {
    return switch (error.code) {
      'UNAVAILABLE' || 'TIMEOUT' => PrayerLocationProblem.noFix,
      'PERMISSION_DENIED' => PrayerLocationProblem.denied,
      'LOCATION_SERVICES_DISABLED' => PrayerLocationProblem.servicesOff,
      _ => PrayerLocationProblem.unknown,
    };
  }
  // Older geolocator-style exceptions carried only a message.
  return switch (error.toString()) {
    'Exception: Location services are disabled.' =>
      PrayerLocationProblem.servicesOff,
    'Exception: Location permissions are denied.' ||
    'Exception: Location permissions are denied' =>
      PrayerLocationProblem.denied,
    'Exception: Location permissions are permanently denied.' =>
      PrayerLocationProblem.blocked,
    _ => PrayerLocationProblem.unknown,
  };
}
