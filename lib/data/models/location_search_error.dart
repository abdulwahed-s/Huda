enum LocationSearchErrorType {
  noConnection,
  rateLimit,
  server,
  unknown,
}

class LocationSearchException implements Exception {
  final LocationSearchErrorType type;

  const LocationSearchException(this.type);

  @override
  String toString() => 'LocationSearchException($type)';
}
