import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_offline_geography.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'dart:math' as math;

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';

class PrayerLocationFix {
  const PrayerLocationFix({
    required this.latitude,
    required this.longitude,
    required this.capturedAtUtc,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAtUtc;
  final double? accuracyMeters;
}

class PrayerLocationMetadata {
  const PrayerLocationMetadata({
    this.countryCode,
    this.locality,
    this.countryName,
  });

  final String? countryCode;
  final String? locality;
  final String? countryName;
}

abstract interface class PrayerLocationActivator {
  Future<PrayerScheduleResult> activateCandidate({
    required PrayerLocationGeneration candidate,
    required String reason,
  });
}

enum PrayerLocationUpdateStatus {
  activated,
  ignoredManualMode,
  ignoredInsignificant,
  rejectedInvalid,
  rejectedStale,
  rejectedInaccurate,
  deferredCountry,
  timeZoneUnavailable,
  superseded,
  degraded,
  failed,
}

class PrayerLocationUpdateResult {
  const PrayerLocationUpdateResult(
    this.status, {
    this.generation,
    this.scheduleResult,
    this.message,
  });

  final PrayerLocationUpdateStatus status;
  final PrayerLocationGeneration? generation;
  final PrayerScheduleResult? scheduleResult;
  final String? message;

  bool get activated => status == PrayerLocationUpdateStatus.activated;
}

typedef PrayerCoordinateTimeZoneResolver =
    Future<String> Function(
      double latitude,
      double longitude,
      String countryCode,
    );
typedef PrayerLocationMetadataResolver =
    Future<PrayerLocationMetadata> Function(double latitude, double longitude);

class PrayerLocationCoordinator {
  PrayerLocationCoordinator({
    required this.cacheHelper,
    required this.repository,
    required this.activator,
    required PrayerCoordinateTimeZoneResolver timeZoneResolver,
    required PrayerLocationMetadataResolver metadataResolver,
    this.onDisplay,
    DateTime Function()? now,
  }) : _timeZoneResolver = timeZoneResolver,
       _metadataResolver = metadataResolver,
       _now = now ?? DateTime.now;

  static const Duration maximumAutomaticFixAge = Duration(minutes: 30);
  static const Duration futureFixTolerance = Duration(minutes: 2);
  static const double maximumAutomaticAccuracyMeters = 5000;
  static const double significantDistanceMeters = 10000;
  static const Duration significantPrayerDelta = Duration(minutes: 1);

  static const double countryChoiceRadiusMeters = 25000;

  final Future<void> Function(PrayerDisplaySnapshot)? onDisplay;
  final CacheHelper cacheHelper;
  final PrayerLocationRepository repository;
  final PrayerLocationActivator activator;
  final PrayerCoordinateTimeZoneResolver _timeZoneResolver;
  final PrayerLocationMetadataResolver _metadataResolver;
  final DateTime Function() _now;

  Future<PrayerLocationUpdateResult> submit({
    required PrayerLocationFix fix,
    required PrayerLocationMode mode,
    required PrayerLocationSource source,
    required String reason,
    bool explicitUserAction = false,
    PrayerLocationMetadata? suppliedMetadata,
    bool enrich = false,
    PrayerDisplaySnapshot? calculationSettings,
    bool Function()? isCurrent,
  }) async {
    final now = _now().toUtc();
    if (!_validFix(fix)) {
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.rejectedInvalid,
      );
    }
    final isAutomaticMonitor =
        mode == PrayerLocationMode.automatic && !explicitUserAction;
    if (isAutomaticMonitor) {
      final captured = fix.capturedAtUtc.toUtc();
      if (captured.isAfter(now.add(futureFixTolerance)) ||
          now.difference(captured) > maximumAutomaticFixAge) {
        return const PrayerLocationUpdateResult(
          PrayerLocationUpdateStatus.rejectedStale,
        );
      }
      if (fix.accuracyMeters == null ||
          fix.accuracyMeters! > maximumAutomaticAccuracyMeters) {
        return const PrayerLocationUpdateResult(
          PrayerLocationUpdateStatus.rejectedInaccurate,
        );
      }
    }

    var storageUnavailable = false;
    int? revision;
    try {
      revision = await repository.beginIntent(
        mode,
        allowModeChange:
            explicitUserAction || mode == PrayerLocationMode.manual,
        automaticFixCapturedAtUtc: mode == PrayerLocationMode.automatic
            ? fix.capturedAtUtc
            : null,
      );
    } catch (_) {
      storageUnavailable = true;
      revision = now.microsecondsSinceEpoch;
    }
    if (revision == null) {
      final current = await repository.readState();
      final active = current.activeLocation;
      if (isAutomaticMonitor &&
          active != null &&
          active.mode == PrayerLocationMode.automatic &&
          active.source != PrayerLocationSource.migration &&
          active.capturedAtUtc.isAfter(fix.capturedAtUtc.toUtc())) {
        return const PrayerLocationUpdateResult(
          PrayerLocationUpdateStatus.superseded,
        );
      }
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.ignoredManualMode,
      );
    }

    var metadata = suppliedMetadata ?? const PrayerLocationMetadata();
    final issues = <PrayerWorkflowIssue>{
      if (storageUnavailable) PrayerWorkflowIssue.storage,
    };
    var countryChoices = const <PrayerCountryChoice>[];
    if (!storageUnavailable) {
      try {
        final stored = await repository.readState();
        calculationSettings ??= stored.displaySnapshot;
        countryChoices = stored.countryChoices;
      } catch (_) {}
    }
    PrayerTimeZoneService.initializeDatabase();
    PrayerGeographicResult? zoneResult;
    PrayerGeographicResult? countryResult;
    try {
      zoneResult = PrayerOfflineGeography.timeZone(
        fix.latitude,
        fix.longitude,
        accuracyMeters: fix.accuracyMeters,
        manual: mode == PrayerLocationMode.manual,
      );
      countryResult = await PrayerOfflineGeography.resolveCountry(
        fix.latitude,
        fix.longitude,
        accuracyMeters: fix.accuracyMeters,
        manual: mode == PrayerLocationMode.manual,
        zone: zoneResult,
      );
    } catch (_) {
    }
    var countryCode = countryResult?.verified == true
        ? countryResult!.value
        : null;
    String? chosenZone;
    if (countryCode == null) {
      final choice = _countryChoiceFor(
        fix,
        countryResult?.candidates ?? const {},
        countryChoices,
      );
      if (choice != null) {
        countryCode = choice.countryCode;
        chosenZone = PrayerOfflineGeography.soleZoneForCountry(countryCode);
      }
    }
    String timeZoneId;
    try {
      timeZoneId =
          chosenZone ??
          zoneResult?.value ??
          await _timeZoneResolver(
            fix.latitude,
            fix.longitude,
            countryCode ?? '',
          ).timeout(const Duration(seconds: 5));
      PrayerTimeZoneService.location(timeZoneId);
    } catch (_) {
      try {
        await repository.updateIssues(add: {PrayerWorkflowIssue.location});
      } catch (_) {}
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.timeZoneUnavailable,
      );
    }
    if (enrich && suppliedMetadata == null) {
      try {
        metadata = await _metadataResolver(
          fix.latitude,
          fix.longitude,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        issues.add(PrayerWorkflowIssue.locality);
      }
    }
    if (_normalize(metadata.locality) == null) {
      issues.add(PrayerWorkflowIssue.locality);
    }
    final reasons = <String>[
      if (chosenZone == null && zoneResult?.verified != true)
        zoneResult?.reason ?? 'timezoneUnverified',
      if (countryCode == null &&
          PrayerTimesCalculator.requiresCountry(
            calculationSettings?.method ??
                PrayerTimesCalculator.methodTokenFromCache(cacheHelper),
          ))
        countryResult?.reason ?? 'countryUnknown',
    ];
    if (reasons.isNotEmpty) issues.add(PrayerWorkflowIssue.verification);

    final candidate = PrayerLocationGeneration(
      verificationReasons: reasons,
      resolutionSource: zoneResult?.source,
      countryCandidates: countryCode == null
          ? List.unmodifiable(countryResult?.candidates ?? const <String>{})
          : const [],
      revision: revision,
      mode: mode,
      latitude: fix.latitude,
      longitude: fix.longitude,
      timeZoneId: timeZoneId,
      timeZoneProvenance: PrayerTimeZoneProvenance.coordinateResolved,
      countryCode: countryCode,
      locality: _normalize(metadata.locality),
      countryName: _verifiedCountryName(countryCode, metadata),
      capturedAtUtc: fix.capturedAtUtc.toUtc(),
      committedAtUtc: now,
      accuracyMeters: fix.accuracyMeters,
      source: source,
    );
    if (!candidate.isValid) {
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.rejectedInvalid,
      );
    }

    if (isCurrent != null && !isCurrent()) {
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.superseded,
      );
    }
    PrayerLocationUpdateStatus? rejection;
    try {
      rejection = await repository.synchronized((session) async {
        await cacheHelper.reload();
        final state = session.state;
        if (state.journal != null &&
            state.revisionCounter == revision &&
            state.latestIntentRevision != revision) {
          return PrayerLocationUpdateStatus.degraded;
        }
        if (state.latestIntentRevision != revision ||
            state.latestIntentMode != mode) {
          return PrayerLocationUpdateStatus.superseded;
        }
        final active = state.activeLocation;
        if (isAutomaticMonitor &&
            active != null &&
            !_isSignificant(active, candidate, now)) {
          return PrayerLocationUpdateStatus.ignoredInsignificant;
        }
        return await session.stageCandidate(candidate)
            ? null
            : PrayerLocationUpdateStatus.superseded;
      });
    } catch (_) {
      storageUnavailable = true;
      issues.add(PrayerWorkflowIssue.storage);
    }
    if (rejection != null && rejection != PrayerLocationUpdateStatus.degraded) {
      return PrayerLocationUpdateResult(
        rejection,
        message: rejection == PrayerLocationUpdateStatus.deferredCountry
            ? 'Country is required for automatic calculation method.'
            : null,
      );
    }

    if (rejection == PrayerLocationUpdateStatus.degraded) {
      issues.add(PrayerWorkflowIssue.notifications);
    }
    var display = calculationSettings == null
        ? PrayerDisplaySnapshot.fromCache(
            cacheHelper,
            candidate,
            issues: issues,
          )
        : PrayerDisplaySnapshot(
            location: candidate,
            method: calculationSettings.method,
            madhab: calculationSettings.madhab,
            highLatitude: calculationSettings.highLatitude,
            angles: calculationSettings.angles,
            offsets: calculationSettings.offsets,
            revision: PrayerDisplaySnapshot.nextRevision(
              calculationSettings.revision,
            ),
            issues: issues,
          );
    try {
      final accepted = await repository.saveDisplay(display);
      if (!accepted) {
        return const PrayerLocationUpdateResult(
          PrayerLocationUpdateStatus.superseded,
        );
      }
    } catch (_) {
      storageUnavailable = true;
      display = display.withIssues({
        ...display.issues,
        PrayerWorkflowIssue.storage,
      });
    }
    if (isCurrent != null && !isCurrent()) {
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.superseded,
      );
    }
    await _publishDisplay(display);
    if (isCurrent != null && !isCurrent()) {
      return const PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.superseded,
      );
    }
    if (storageUnavailable) {
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.failed,
        generation: candidate,
      );
    }
    if (rejection == PrayerLocationUpdateStatus.degraded) {
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.degraded,
        generation: candidate,
        scheduleResult: const PrayerScheduleResult(
          status: PrayerScheduleStatus.deferred,
          message: 'ownershipRecoveryPending',
        ),
      );
    }
    if (!candidate.calculationVerified) {
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.deferredCountry,
        generation: candidate,
      );
    }
    try {
      final schedule = await activator.activateCandidate(
        candidate: candidate,
        reason: reason,
      );
      if (schedule.status == PrayerScheduleStatus.degraded ||
          schedule.status == PrayerScheduleStatus.deferred ||
          schedule.status == PrayerScheduleStatus.failed) {
        display = display.withIssues({
          ...display.issues,
          PrayerWorkflowIssue.notifications,
        });
        try {
          await repository.saveDisplay(display);
        } catch (_) {}
        await _publishDisplay(display);
        return PrayerLocationUpdateResult(
          PrayerLocationUpdateStatus.degraded,
          generation: candidate,
          scheduleResult: schedule,
          message: schedule.message,
        );
      }
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.activated,
        generation: candidate,
        scheduleResult: schedule,
      );
    } catch (error) {
      display = display.withIssues({
        ...display.issues,
        PrayerWorkflowIssue.notifications,
      });
      try {
        await repository.saveDisplay(display);
      } catch (_) {}
      await _publishDisplay(display);
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.failed,
        generation: candidate,
        scheduleResult: PrayerScheduleResult(
          status: PrayerScheduleStatus.failed,
          message: error.toString(),
        ),
        message: error.toString(),
      );
    }
  }

  Future<void> _publishDisplay(PrayerDisplaySnapshot display) async {
    if (onDisplay != null) {
      await onDisplay!(display);
      return;
    }
    try {
      await PrayerWidgetService.publishDisplay(
        display,
        cacheHelper: cacheHelper,
      );
    } catch (_) {
      await repository.saveDisplay(
        display.withIssues({...display.issues, PrayerWorkflowIssue.widget}),
      );
    }
  }

  Future<PrayerDisplaySnapshot> enrichDisplay(
    PrayerDisplaySnapshot display, {
    bool Function()? isCurrent,
  }) async {
    final metadata = await _metadataResolver(
      display.location.latitude,
      display.location.longitude,
    ).timeout(const Duration(seconds: 5));
    if (isCurrent != null && !isCurrent()) return display;
    final locality = _normalize(metadata.locality);
    if (locality == null) throw StateError('Location details unavailable');
    final location = display.location.copyWith(
      locality: locality,
      countryName: _verifiedCountryName(display.location.countryCode, metadata),
    );
    final updated = PrayerDisplaySnapshot(
      location: location,
      method: display.method,
      madhab: display.madhab,
      highLatitude: display.highLatitude,
      angles: display.angles,
      offsets: display.offsets,
      revision: PrayerDisplaySnapshot.nextRevision(display.revision),
      issues: {...display.issues}..remove(PrayerWorkflowIssue.locality),
    );
    final accepted = await repository.saveDisplay(
      updated,
      expectedDisplayRevision: display.revision,
    );
    return accepted ? updated : display;
  }

  static PrayerCountryChoice? _countryChoiceFor(
    PrayerLocationFix fix,
    Set<String> candidates,
    List<PrayerCountryChoice> choices,
  ) {
    PrayerCountryChoice? nearest;
    var nearestDistance = double.infinity;
    for (final choice in choices) {
      if (!candidates.contains(choice.countryCode)) continue;
      final distance = distanceMeters(
        fix.latitude,
        fix.longitude,
        choice.latitude,
        choice.longitude,
      );
      if (distance <= countryChoiceRadiusMeters && distance < nearestDistance) {
        nearest = choice;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  bool _validFix(PrayerLocationFix fix) =>
      fix.latitude.isFinite &&
      fix.longitude.isFinite &&
      fix.latitude >= -90 &&
      fix.latitude <= 90 &&
      fix.longitude >= -180 &&
      fix.longitude <= 180 &&
      (fix.accuracyMeters == null ||
          (fix.accuracyMeters!.isFinite && fix.accuracyMeters! >= 0));

  bool _isSignificant(
    PrayerLocationGeneration active,
    PrayerLocationGeneration candidate,
    DateTime now,
  ) {
    if (active.mode != PrayerLocationMode.automatic) return false;
    final distance = distanceMeters(
      active.latitude,
      active.longitude,
      candidate.latitude,
      candidate.longitude,
    );
    final combinedAccuracy =
        (active.accuracyMeters ?? 0) + (candidate.accuracyMeters ?? 0);
    final confidentDistance = math.max(0.0, distance - combinedAccuracy);

    if (distance <= combinedAccuracy) return false;
    if (active.timeZoneId != candidate.timeZoneId) return true;
    if (confidentDistance >= significantDistanceMeters) {
      return true;
    }

    final deviceZone = candidate.timeZoneId;
    final planner = PrayerNotificationPlanner(cacheHelper);
    final activeConfiguration = PrayerScheduleConfiguration.fromCache(
      cache: cacheHelper,
      location: active,
      deviceTimeZoneId: deviceZone,
    );
    final activePlan = planner.buildFromConfiguration(
      now: now,
      maxEvents: 20,
      horizon: const Duration(hours: 48),
      configuration: activeConfiguration,
    );
    final candidatePlan = planner.buildFromConfiguration(
      now: now,
      maxEvents: 20,
      horizon: const Duration(hours: 48),
      configuration: activeConfiguration.forLocation(candidate),
    );
    if (activePlan == null || candidatePlan == null) return false;
    final oldById = <int, DateTime>{
      for (final event in activePlan.events)
        event.id: event.scheduledInstantUtc,
    };
    for (final event in candidatePlan.events) {
      final old = oldById[event.id];
      if (old == null) continue;
      if (event.scheduledInstantUtc.difference(old).abs() >=
          significantPrayerDelta) {
        return true;
      }
    }
    return false;
  }

  static double distanceMeters(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusMeters = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(latitudeB - latitudeA);
    final dLon = radians(longitudeB - longitudeA);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(latitudeA)) *
            math.cos(radians(latitudeB)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String? _verifiedCountryName(
    String? countryCode,
    PrayerLocationMetadata metadata,
  ) {
    if (countryCode == null) return null;
    return metadata.countryCode?.trim().toUpperCase() == countryCode
        ? _normalize(metadata.countryName) ?? countryCode
        : countryCode;
  }
}
