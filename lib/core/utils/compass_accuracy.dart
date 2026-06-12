import 'package:flutter_compass_v2/flutter_compass_v2.dart';

enum CompassAccuracy {
  high,
  medium,
  low,
  unknown;

  bool get needsCalibration =>
      this == CompassAccuracy.low || this == CompassAccuracy.unknown;

  static CompassAccuracy fromEvent(CompassEvent event) {
    final accuracy = event.accuracy;
    if (accuracy == null || accuracy < 0) return CompassAccuracy.unknown;
    if (accuracy <= 20) return CompassAccuracy.high;
    if (accuracy <= 35) return CompassAccuracy.medium;
    return CompassAccuracy.low;
  }
}
