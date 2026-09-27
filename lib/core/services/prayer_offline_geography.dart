import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_zone_countries.dart';
import 'package:timezone_finder/timezone_finder.dart' as finder;
import 'package:timezone_finder/src/index/boundary_store.dart' show sharedIndex;

class PrayerGeographicResult {
  const PrayerGeographicResult({
    this.value,
    required this.source,
    this.reason,
    this.candidates = const {},
  });
  final String? value;
  final String source;
  final String? reason;

  final Set<String> candidates;
  bool get verified => value != null && reason == null;
}

class PrayerBoundaryRing {
  PrayerBoundaryRing(List<double> values)
    : points = Float64List.fromList(values) {
    for (var i = 2; i < points.length; i += 2) {
      while (points[i] - points[i - 2] > 180) {
        points[i] -= 360;
      }
      while (points[i] - points[i - 2] < -180) {
        points[i] += 360;
      }
    }
    for (var i = 0; i + 1 < points.length; i += 2) {
      _minX = math.min(_minX, points[i]);
      _maxX = math.max(_maxX, points[i]);
      _minY = math.min(_minY, points[i + 1]);
      _maxY = math.max(_maxY, points[i + 1]);
    }
  }
  final Float64List points;
  double _minX = double.infinity, _maxX = double.negativeInfinity;
  double _minY = double.infinity, _maxY = double.negativeInfinity;

  ({bool contains, bool intersects}) inspect(
    double lat,
    double lon,
    double radius,
  ) {
    if (points.length < 6) return (contains: false, intersects: true);
    var x = lon;
    while (x - points[0] > 180) {
      x -= 360;
    }
    while (x - points[0] < -180) {
      x += 360;
    }
    final dy = radius / 110000;
    final dx = dy / math.cos((lat.abs() + dy) * math.pi / 180);
    if (lat + dy < _minY ||
        lat - dy > _maxY ||
        x + dx < _minX ||
        x - dx > _maxX) {
      return (contains: false, intersects: false);
    }
    var inside = false;
    var intersects = false;
    for (var i = 0, j = points.length - 2; i < points.length; j = i, i += 2) {
      final ax = points[j], ay = points[j + 1];
      final bx = points[i], by = points[i + 1];
      if ((ay > lat) != (by > lat) &&
          x < (bx - ax) * (lat - ay) / (by - ay) + ax) {
        inside = !inside;
      }
      if (math.min(ax, bx) <= x + dx &&
          math.max(ax, bx) >= x - dx &&
          math.min(ay, by) <= lat + dy &&
          math.max(ay, by) >= lat - dy) {
        intersects = true;
      }
    }
    return (contains: inside, intersects: intersects);
  }
}

abstract final class PrayerOfflineGeography {
  static const countryMarginMeters = 5000.0;
  static const timeZoneMarginMeters = 500.0;
  static List<PrayerBoundaryRing>? _zoneRings;
  static Future<List<({String? code, List<PrayerBoundaryRing> rings})>>?
  _countries;

  static String? _accuracyReason(
    double latitude,
    double? accuracy,
    bool manual,
  ) {
    if (latitude.abs() > 85) return 'polarBoundary';
    if (accuracy == null && !manual) return 'accuracyUnknown';
    if (accuracy != null &&
        (!accuracy.isFinite || accuracy < 0 || accuracy > 100000)) {
      return 'accuracyUnresolved';
    }
    return null;
  }

  static PrayerGeographicResult timeZone(
    double lat,
    double lon, {
    double? accuracyMeters,
    bool manual = false,
  }) {
    final zone = finder.findLocation(lon, lat)?.name;
    final source =
        'timezone_finder-0.2.0/${finder.boundaryDataVersion}/policy-1';
    if (zone == null) {
      return PrayerGeographicResult(source: source, reason: 'noBoundary');
    }
    final reason = _accuracyReason(lat, accuracyMeters, manual);
    if (reason != null) {
      return PrayerGeographicResult(
        value: zone,
        source: source,
        reason: reason,
      );
    }
    _zoneRings ??= sharedIndex.decodeAllRings
        .map(
          (ring) => PrayerBoundaryRing([
            for (final coordinate in ring) coordinate / 1000000,
          ]),
        )
        .toList(growable: false);
    var containing = 0;
    for (final ring in _zoneRings!) {
      final result = ring.inspect(
        lat,
        lon,
        (accuracyMeters ?? 0) + timeZoneMarginMeters,
      );
      if (result.intersects) {
        return PrayerGeographicResult(
          value: zone,
          source: source,
          reason: 'boundaryUncertain',
        );
      }
      if (result.contains) containing++;
    }
    return PrayerGeographicResult(
      value: zone,
      source: source,
      reason: containing > 0 ? null : 'noBoundary',
    );
  }

  static Future<PrayerGeographicResult> country(
    double lat,
    double lon, {
    double? accuracyMeters,
    bool manual = false,
  }) async {
    const source = 'NaturalEarth-5.1.1-50m/ISO_A2/policy-2';
    final reason = _accuracyReason(lat, accuracyMeters, manual);
    _countries ??= _loadCountries();
    final countries = await _countries!;
    final radius =
        (reason == null ? accuracyMeters ?? 0 : 0) + countryMarginMeters;
    final candidates = <String>{};
    var unidentifiedNearby = false;
    String? containing;
    var containingCount = 0;
    for (final country in countries) {
      var inside = false;
      var near = false;
      for (final ring in country.rings) {
        final result = ring.inspect(lat, lon, radius);
        if (result.intersects) near = true;
        if (result.contains) inside = !inside;
      }
      if (inside) {
        containingCount++;
        containing = country.code;
      }
      if (inside || near) {
        if (country.code == null) {
          unidentifiedNearby = true;
        } else {
          candidates.add(country.code!);
        }
      }
    }
    final candidateSet = Set<String>.unmodifiable(candidates);
    if (reason != null) {
      return PrayerGeographicResult(
        source: source,
        reason: reason,
        candidates: lat.abs() > 85 ? const {} : candidateSet,
      );
    }
    if (containingCount == 1 &&
        containing != null &&
        candidates.length == 1 &&
        !unidentifiedNearby) {
      return PrayerGeographicResult(
        value: containing,
        source: source,
        candidates: candidateSet,
      );
    }
    return PrayerGeographicResult(
      source: source,
      reason: candidates.length > 1 || unidentifiedNearby
          ? 'countryBoundaryUncertain'
          : 'countryUnknown',
      candidates: candidateSet,
    );
  }

  static Future<PrayerGeographicResult> resolveCountry(
    double lat,
    double lon, {
    double? accuracyMeters,
    bool manual = false,
    PrayerGeographicResult? zone,
  }) async {
    final dataset = await country(
      lat,
      lon,
      accuracyMeters: accuracyMeters,
      manual: manual,
    );
    final zoneName = zone?.value;
    final own =
        zoneName == null ||
            PrayerZoneCountries.dataVersion != finder.boundaryDataVersion
        ? null
        : PrayerZoneCountries.country[zoneName];
    if (own == null) return dataset;
    final candidates = Set<String>.unmodifiable({own, ...dataset.candidates});
    PrayerGeographicResult unresolved(String reason) => PrayerGeographicResult(
      source: dataset.source,
      reason: reason,
      candidates: candidates,
    );
    if (dataset.verified && dataset.value != own) {
      return unresolved('countrySourcesDisagree');
    }
    if (zone?.verified != true) {
      return dataset.verified
          ? dataset
          : unresolved(dataset.reason ?? 'countryUnknown');
    }
    final enclaves = PrayerZoneCountries.sharedWith[zoneName] ?? const [];
    if (enclaves.any(dataset.candidates.contains)) {
      return unresolved('countryBoundaryUncertain');
    }
    return PrayerGeographicResult(
      value: own,
      source: 'zone.tab-${PrayerZoneCountries.dataVersion}/policy-1',
      candidates: candidates,
    );
  }

  static String? soleZoneForCountry(String countryCode) {
    if (PrayerZoneCountries.dataVersion != finder.boundaryDataVersion) {
      return null;
    }
    String? found;
    for (final entry in PrayerZoneCountries.country.entries) {
      if (entry.value != countryCode) continue;
      if (found != null) return null;
      found = entry.key;
    }
    return found;
  }

  static Future<List<({String? code, List<PrayerBoundaryRing> rings})>>
  _loadCountries() async {
    try {
      final data =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/geography/countries_50m.json',
                ),
              )
              as Map;
      return (data['features'] as List)
          .map(
            (feature) => (
              code: feature['code'] as String?,
              rings: (feature['rings'] as List)
                  .map(
                    (ring) => PrayerBoundaryRing([
                      for (final point in ring as List) ...[
                        (point[0] as num).toDouble(),
                        (point[1] as num).toDouble(),
                      ],
                    ]),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      _countries = null;
      rethrow;
    }
  }
}
