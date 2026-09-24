import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

enum PrayerLocationMode {
  automatic,
  manual;

  static PrayerLocationMode? tryParse(Object? value) {
    if (value is! String) return null;
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  static PrayerLocationMode fromStorage(String? value) =>
      tryParse(value) ?? manual;
}

enum PrayerTimeZoneProvenance {
  coordinateResolved,
  legacyApproximate;

  static PrayerTimeZoneProvenance? tryParse(Object? value) {
    if (value is! String) return null;
    for (final provenance in values) {
      if (provenance.name == value) return provenance;
    }
    return null;
  }
}

enum PrayerLocationSource {
  explicit,
  foreground,
  androidBackground,
  iosSignificantChange,
  migration;

  static PrayerLocationSource? tryParse(Object? value) {
    if (value is! String) return null;
    for (final source in values) {
      if (source.name == value) return source;
    }
    return null;
  }
}

@immutable
class PrayerLocationGeneration {
  const PrayerLocationGeneration({
    required this.revision,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    required this.timeZoneProvenance,
    required this.capturedAtUtc,
    required this.committedAtUtc,
    required this.source,
    this.countryCode,
    this.locality,
    this.countryName,
    this.accuracyMeters,
  });

  static const int schemaVersion = 1;
  static const int maxSafeRevision = 9007199254740991;

  final int revision;
  final PrayerLocationMode mode;
  final double latitude;
  final double longitude;
  final String timeZoneId;
  final PrayerTimeZoneProvenance timeZoneProvenance;
  final String? countryCode;
  final String? locality;
  final String? countryName;
  final DateTime capturedAtUtc;
  final DateTime committedAtUtc;
  final double? accuracyMeters;
  final PrayerLocationSource source;

  bool get isValid =>
      revision > 0 &&
      revision <= maxSafeRevision &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      _validTimeZone(timeZoneId) &&
      capturedAtUtc.isUtc &&
      committedAtUtc.isUtc &&
      (accuracyMeters == null ||
          (accuracyMeters!.isFinite && accuracyMeters! >= 0));

  PrayerLocationGeneration copyWith({
    int? revision,
    PrayerLocationMode? mode,
    double? latitude,
    double? longitude,
    String? timeZoneId,
    PrayerTimeZoneProvenance? timeZoneProvenance,
    Object? countryCode = _unset,
    Object? locality = _unset,
    Object? countryName = _unset,
    DateTime? capturedAtUtc,
    DateTime? committedAtUtc,
    Object? accuracyMeters = _unset,
    PrayerLocationSource? source,
  }) {
    return PrayerLocationGeneration(
      revision: revision ?? this.revision,
      mode: mode ?? this.mode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      timeZoneProvenance: timeZoneProvenance ?? this.timeZoneProvenance,
      countryCode: identical(countryCode, _unset)
          ? this.countryCode
          : _normalizeOptional(countryCode as String?),
      locality: identical(locality, _unset)
          ? this.locality
          : _normalizeOptional(locality as String?),
      countryName: identical(countryName, _unset)
          ? this.countryName
          : _normalizeOptional(countryName as String?),
      capturedAtUtc: (capturedAtUtc ?? this.capturedAtUtc).toUtc(),
      committedAtUtc: (committedAtUtc ?? this.committedAtUtc).toUtc(),
      accuracyMeters: identical(accuracyMeters, _unset)
          ? this.accuracyMeters
          : accuracyMeters as double?,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'revision': revision,
    'mode': mode.name,
    'latitude': latitude,
    'longitude': longitude,
    'timeZoneId': timeZoneId,
    'timeZoneProvenance': timeZoneProvenance.name,
    'countryCode': countryCode,
    'locality': locality,
    'countryName': countryName,
    'capturedAtUtc': capturedAtUtc.toUtc().toIso8601String(),
    'committedAtUtc': committedAtUtc.toUtc().toIso8601String(),
    'accuracyMeters': accuracyMeters,
    'source': source.name,
  };

  static PrayerLocationGeneration? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    if (_integer(json['schemaVersion']) != schemaVersion) return null;
    final revision = _integer(json['revision']);
    final latitude = _finiteDouble(json['latitude']);
    final longitude = _finiteDouble(json['longitude']);
    final accuracy = json['accuracyMeters'] == null
        ? null
        : _finiteDouble(json['accuracyMeters']);
    final mode = PrayerLocationMode.tryParse(json['mode']);
    final provenance = PrayerTimeZoneProvenance.tryParse(
      json['timeZoneProvenance'],
    );
    final source = PrayerLocationSource.tryParse(json['source']);
    final capturedAt = _utcDate(json['capturedAtUtc']);
    final committedAt = _utcDate(json['committedAtUtc']);
    final zone = json['timeZoneId'] is String
        ? (json['timeZoneId']! as String).trim()
        : '';
    if (revision == null ||
        latitude == null ||
        longitude == null ||
        (json['accuracyMeters'] != null && accuracy == null) ||
        mode == null ||
        provenance == null ||
        source == null ||
        capturedAt == null ||
        committedAt == null ||
        !_validTimeZone(zone)) {
      return null;
    }
    final generation = PrayerLocationGeneration(
      revision: revision,
      mode: mode,
      latitude: latitude,
      longitude: longitude,
      timeZoneId: zone,
      timeZoneProvenance: provenance,
      countryCode: _optionalString(json['countryCode'])?.toUpperCase(),
      locality: _optionalString(json['locality']),
      countryName: _optionalString(json['countryName']),
      capturedAtUtc: capturedAt,
      committedAtUtc: committedAt,
      accuracyMeters: accuracy,
      source: source,
    );
    return generation.isValid ? generation : null;
  }

  static bool _validTimeZone(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.toLowerCase() == 'unknown' ||
        normalized.toLowerCase() == 'null') {
      return false;
    }
    try {
      tz.getLocation(normalized);
      return true;
    } catch (_) {
      return false;
    }
  }

  static int? _integer(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  static double? _finiteDouble(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }

  static DateTime? _utcDate(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !value.endsWith('Z')) return null;
    return parsed.toUtc();
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    return _normalizeOptional(value);
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerLocationGeneration &&
      other.revision == revision &&
      other.mode == mode &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.timeZoneId == timeZoneId &&
      other.timeZoneProvenance == timeZoneProvenance &&
      other.countryCode == countryCode &&
      other.locality == locality &&
      other.countryName == countryName &&
      other.capturedAtUtc == capturedAtUtc &&
      other.committedAtUtc == committedAtUtc &&
      other.accuracyMeters == accuracyMeters &&
      other.source == source;

  @override
  int get hashCode => Object.hash(
    revision,
    mode,
    latitude,
    longitude,
    timeZoneId,
    timeZoneProvenance,
    countryCode,
    locality,
    countryName,
    capturedAtUtc,
    committedAtUtc,
    accuracyMeters,
    source,
  );
}

const Object _unset = Object();
