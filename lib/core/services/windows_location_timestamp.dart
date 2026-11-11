import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

Position normalizeWindowsLocationTimestamp(Position position) {
  final timestamp = position.timestamp.millisecondsSinceEpoch;
  // geolocator_windows 0.2.5 sends clock::to_time_t() (Unix seconds), but
  // Position.fromMap reads milliseconds. Only convert seconds in 2000-2100;
  // correctly encoded milliseconds from a fixed plugin pass through unchanged.
  if (timestamp < 946684800 || timestamp >= 4102444800) return position;
  return Position.fromMap({
    ...position.toJson(),
    'timestamp': timestamp * Duration.millisecondsPerSecond,
  });
}
