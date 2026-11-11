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
