import 'dart:async';
import 'dart:math' as math;

import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates;
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_location_coordinator.dart'
    show PrayerLocationMetadata;
import 'package:precise_compass/precise_compass.dart';

const double kQiblahAlignmentToleranceDeg = 5.0;

const double _kaabaLat = 21.422487;
const double _kaabaLng = 39.826206;

/// How sure the location behind the bearing is.
enum QiblahFixState {
  /// A fix from the last minute.
  fresh,

  /// An older fix is in use while a fresh one is on its way.
  refining,

  /// A fresh fix failed; an older one is still in use.
  stale,
}

class QiblahReading {
  const QiblahReading({
    required this.heading,
    required this.qiblahBearing,
    required this.hasHeading,
    required this.accuracy,
    required this.confidence,
    required this.shouldCalibrate,
    this.fieldMicroTesla,
    this.pitch,
    this.roll,
    this.distanceKm,
    this.fix = QiblahFixState.fresh,
    this.place,
  });

  final double heading;

  final double qiblahBearing;

  final bool hasHeading;

  final CompassAccuracy accuracy;

  final double confidence;

  final bool shouldCalibrate;

  /// The ambient magnetic field (µT), when measured.
  final double? fieldMicroTesla;

  /// The phone's tilt in degrees, when reported.
  final double? pitch;
  final double? roll;

  /// Great-circle distance to the Kaaba.
  final double? distanceKm;

  final QiblahFixState fix;

  /// The place of the fix ("Istanbul"), when the lookup found one.
  final String? place;

  double get delta {
    var d = (qiblahBearing - heading) % 360.0;
    if (d > 180.0) d -= 360.0;
    if (d < -180.0) d += 360.0;
    return d;
  }

  double get needleAngle => delta * math.pi / 180.0;

  bool get isAligned => delta.abs() <= kQiblahAlignmentToleranceDeg;

  /// Earth's field is about 25–65 µT; well outside that, something nearby
  /// (metal, magnets, electronics) is bending the reading.
  bool get hasInterference {
    final field = fieldMicroTesla;
    return field != null && (field < 18 || field > 75);
  }

  /// Held well away from flat, where the compass and the dial disagree.
  bool get isTilted {
    final p = pitch, r = roll;
    return (p != null && p.abs() > 35) || (r != null && r.abs() > 35);
  }
}

class QiblahService {
  const QiblahService._();

  static double bearingToKaaba(double lat, double lng) {
    final phi1 = _radians(lat);
    final phi2 = _radians(_kaabaLat);
    final deltaLambda = _radians(_kaabaLng - lng);
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    return (_degrees(math.atan2(y, x)) + 360.0) % 360.0;
  }

  /// Great-circle (haversine) distance to the Kaaba in kilometres.
  static double distanceToKaabaKm(double lat, double lng) =>
      _distanceKm(lat, lng, _kaabaLat, _kaabaLng);

  static double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0088;
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// A last-known fix younger than this is used as it is.
  static const Duration freshFixAge = Duration(minutes: 1);

  /// How long a fresh fix may take before the older one stays in use.
  static const Duration fixTimeLimit = Duration(seconds: 20);

  /// Compass readings with the bearing from the best location available:
  /// the last known fix at once (so the dial starts immediately), then a
  /// fresh fix whenever the last one is older than [freshFixAge], or always
  /// when [refresh]. Errors only when there is no fix at all.
  static Stream<QiblahReading> qiblahStream({bool refresh = false}) {
    late final StreamController<QiblahReading> controller;
    StreamSubscription<CompassReading>? compass;
    CompassReading? lastHeading;
    Position? fix;
    var state = QiblahFixState.fresh;
    String? place;

    void emit() {
      final heading = lastHeading, position = fix;
      if (heading == null || position == null || controller.isClosed) return;
      controller.add(
        QiblahReading(
          heading: heading.heading,
          qiblahBearing: bearingToKaaba(position.latitude, position.longitude),
          hasHeading: heading.hasHeading,
          accuracy: heading.accuracy,
          confidence: heading.confidence,
          shouldCalibrate: heading.shouldCalibrate,
          fieldMicroTesla: heading.magneticFieldMagnitude,
          pitch: heading.pitch,
          roll: heading.roll,
          distanceKm: distanceToKaabaKm(position.latitude, position.longitude),
          fix: state,
          place: place,
        ),
      );
    }

    void use(Position position, QiblahFixState fixState) {
      final previous = fix;
      // Keep the name while the place is the same town.
      if (previous == null ||
          _distanceKm(
                previous.latitude,
                previous.longitude,
                position.latitude,
                position.longitude,
              ) >
              10) {
        place = null;
      }
      fix = position;
      state = fixState;
      emit();
      compass ??= PreciseCompass.heading.listen((reading) {
        lastHeading = reading;
        emit();
      }, onError: controller.addError);
      // The place's name is a courtesy: no name, no problem.
      placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 8))
          .then((placemarks) {
            if (fix != position) return;
            place = PrayerLocationMetadata.fromPlacemarks(placemarks).locality;
            emit();
          })
          .catchError((Object _) {});
    }

    Future<void> start() async {
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {
        lastKnown = null;
      }
      final recent =
          lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp).abs() < freshFixAge;
      if (lastKnown != null) {
        use(
          lastKnown,
          recent && !refresh ? QiblahFixState.fresh : QiblahFixState.refining,
        );
        if (recent && !refresh) return;
      }
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: fixTimeLimit,
          ),
        );
        if (!controller.isClosed) use(current, QiblahFixState.fresh);
      } catch (error) {
        if (controller.isClosed) return;
        if (fix == null) {
          controller.addError(error);
        } else {
          state = QiblahFixState.stale;
          emit();
        }
      }
    }

    controller = StreamController<QiblahReading>(
      onListen: start,
      onCancel: () async {
        await compass?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  static double _radians(double deg) => deg * math.pi / 180.0;
  static double _degrees(double rad) => rad * 180.0 / math.pi;
}
