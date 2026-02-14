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
