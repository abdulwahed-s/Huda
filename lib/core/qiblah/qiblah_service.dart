import 'dart:math' as math;

import 'package:huda/core/services/geolocator.dart';
import 'package:precise_compass/precise_compass.dart';

const double kQiblahAlignmentToleranceDeg = 5.0;

const double _kaabaLat = 21.422487;
const double _kaabaLng = 39.826206;

class QiblahReading {
  const QiblahReading({
    required this.heading,
    required this.qiblahBearing,
    required this.hasHeading,
    required this.accuracy,
    required this.confidence,
    required this.shouldCalibrate,
  });

  final double heading;

  final double qiblahBearing;

  final bool hasHeading;

  final CompassAccuracy accuracy;

  final double confidence;

  final bool shouldCalibrate;

  double get delta {
    var d = (qiblahBearing - heading) % 360.0;
    if (d > 180.0) d -= 360.0;
    if (d < -180.0) d += 360.0;
    return d;
  }

  double get needleAngle => delta * math.pi / 180.0;

  bool get isAligned => delta.abs() <= kQiblahAlignmentToleranceDeg;
}

class QiblahService {
  const QiblahService._();

  static double bearingToKaaba(double lat, double lng) {
    final phi1 = _radians(lat);
    final phi2 = _radians(_kaabaLat);
    final deltaLambda = _radians(_kaabaLng - lng);
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    return (_degrees(math.atan2(y, x)) + 360.0) % 360.0;
  }

  static Stream<QiblahReading> qiblahStream() async* {
    final position = await _currentPosition();
    final bearing = bearingToKaaba(position.latitude, position.longitude);

    yield* PreciseCompass.heading.map(
      (reading) => QiblahReading(
        heading: reading.heading,
        qiblahBearing: bearing,
        hasHeading: reading.hasHeading,
        accuracy: reading.accuracy,
        confidence: reading.confidence,
        shouldCalibrate: reading.shouldCalibrate,
      ),
    );
  }

  static Future<Position> _currentPosition() async {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;
    return Geolocator.getCurrentPosition();
  }

  static double _radians(double deg) => deg * math.pi / 180.0;
  static double _degrees(double rad) => rad * 180.0 / math.pi;
}
