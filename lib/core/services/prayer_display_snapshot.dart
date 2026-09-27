import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

enum PrayerWorkflowIssue {
  verification,
  locality,
  location,
  calculation,
  storage,
  nativeCandidate,
  notifications,
  widget,
}

class PrayerDisplaySnapshot {
  const PrayerDisplaySnapshot({
    required this.location,
    required this.method,
    required this.madhab,
    required this.highLatitude,
    required this.angles,
    required this.offsets,
    required this.revision,
    this.issues = const {},
  });
  final PrayerLocationGeneration location;
  final String method, madhab, highLatitude;
  final CustomPrayerAngles angles;
  final Map<String, int> offsets;
  final int revision;
  final Set<PrayerWorkflowIssue> issues;
  bool get provisional =>
      !location.calculationVerified ||
      (location.countryCode == null &&
          PrayerTimesCalculator.requiresCountry(method));

  PrayerDisplaySnapshot withSettings({
    String? method,
    String? madhab,
    String? highLatitude,
    CustomPrayerAngles? angles,
    Map<String, int>? offsets,
  }) {
    final nextMethod = method ?? this.method;
    final reasons = location.verificationReasons
        .where((reason) => !reason.startsWith('country'))
        .toList();
    if (location.countryCode == null &&
        PrayerTimesCalculator.requiresCountry(nextMethod)) {
      reasons.add('countryUnknown');
    }
    final nextLocation = location.copyWith(verificationReasons: reasons);
    final nextIssues = {...issues}..remove(PrayerWorkflowIssue.verification);
    if (!nextLocation.calculationVerified) {
      nextIssues.add(PrayerWorkflowIssue.verification);
    }
    return PrayerDisplaySnapshot(
      location: nextLocation,
      method: nextMethod,
      madhab: madhab ?? this.madhab,
      highLatitude: highLatitude ?? this.highLatitude,
      angles: angles ?? this.angles,
      offsets: Map.unmodifiable(offsets ?? this.offsets),
      revision: nextRevision(revision),
      issues: Set.unmodifiable(nextIssues),
    );
  }

  static int nextRevision(int previous) {
    final clock = DateTime.now().microsecondsSinceEpoch;
    return clock > previous ? clock : previous + 1;
  }

  factory PrayerDisplaySnapshot.fromCache(
    CacheHelper cache,
    PrayerLocationGeneration location, {
    Set<PrayerWorkflowIssue> issues = const {},
  }) => PrayerDisplaySnapshot(
    location: location,
    method: PrayerTimesCalculator.methodTokenFromCache(cache),
    madhab:
        cache.getDataString(key: PrayerTimesCalculator.madhabKey) ??
        PrayerTimesCalculator.defaultMadhabToken,
    highLatitude:
        cache.getDataString(key: PrayerTimesCalculator.highLatitudeRuleKey) ??
        PrayerTimesCalculator.defaultHighLatitudeToken,
    angles: PrayerTimesCalculator.customAnglesFromCache(cache),
    offsets: PrayerTimesCalculator.offsetsFromCache(cache),
    revision: DateTime.now().microsecondsSinceEpoch,
    issues: issues,
  );

  PrayerDisplaySnapshot withIssues(
    Set<PrayerWorkflowIssue> next, {
    bool advanceRevision = false,
  }) => PrayerDisplaySnapshot(
    location: location,
    method: method,
    madhab: madhab,
    highLatitude: highLatitude,
    angles: angles,
    offsets: offsets,
    revision: advanceRevision ? nextRevision(revision) : revision,
    issues: Set.unmodifiable(next),
  );

  DailyPrayerTimes compute(DateTime instant) {
    final day = PrayerTimeZoneService.wallClockAtInstant(
      instant,
      location.timeZoneId,
    );
    return computeDate(day);
  }

  DailyPrayerTimes computeDate(DateTime day) => PrayerTimesCalculator.compute(
    Coordinates(location.latitude, location.longitude),
    day,
    methodToken: method,
    countryCode: location.countryCode ?? '',
    timeZoneName: location.timeZoneId,
    madhab: PrayerTimesCalculator.madhabFromToken(madhab),
    highLatitudeRule: PrayerTimesCalculator.highLatitudeRuleFromToken(
      highLatitude,
    ),
    customAngles: angles,
  );
  Map<String, Object?> toJson() => {
    'version': 1,
    'revision': revision,
    'location': location.toJson(),
    'method': method,
    'effectiveMethod': PrayerTimesCalculator.resolveMethod(
      method,
      location.countryCode ?? '',
    ).name,
    'madhab': madhab,
    'highLatitude': highLatitude,
    'angles': {
      'fajr': angles.fajr,
      'maghrib': angles.maghrib,
      'isha': angles.isha,
    },
    'offsets': offsets,
    'issues': issues.map((e) => e.name).toList(),
  };
  static PrayerDisplaySnapshot? tryParse(Object? raw) {
    if (raw is! Map || raw['version'] != 1) return null;
    try {
      final location = PrayerLocationGeneration.tryParse(raw['location']);
      if (location == null) return null;
      final angles = raw['angles'] as Map;
      return PrayerDisplaySnapshot(
        location: location,
        revision: raw['revision'] as int,
        method: raw['method'] as String,
        madhab: raw['madhab'] as String,
        highLatitude: raw['highLatitude'] as String,
        angles: CustomPrayerAngles.fromStoredValues(
          fajr: angles['fajr'],
          maghrib: angles['maghrib'],
          isha: angles['isha'],
        ),
        offsets: Map<String, int>.from(raw['offsets'] as Map),
        issues: {
          for (final name in raw['issues'] as List)
            PrayerWorkflowIssue.values.byName(name as String),
        },
      );
    } catch (_) {
      return null;
    }
  }
}
