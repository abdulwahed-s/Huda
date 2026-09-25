import 'dart:math' as math;

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
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
    DateTime Function()? now,
  }) : _timeZoneResolver = timeZoneResolver,
       _metadataResolver = metadataResolver,
       _now = now ?? DateTime.now;

  static const Duration maximumAutomaticFixAge = Duration(minutes: 30);
  static const Duration futureFixTolerance = Duration(minutes: 2);
  static const double maximumAutomaticAccuracyMeters = 5000;
  static const double significantDistanceMeters = 10000;
  static const Duration significantPrayerDelta = Duration(minutes: 1);

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

    final revision = await repository.beginIntent(
      mode,
      allowModeChange: explicitUserAction || mode == PrayerLocationMode.manual,
      automaticFixCapturedAtUtc: isAutomaticMonitor ? fix.capturedAtUtc : null,
    );
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

    PrayerLocationMetadata metadata =
        suppliedMetadata ?? const PrayerLocationMetadata();
    if (suppliedMetadata == null) {
      try {
        metadata = await _metadataResolver(fix.latitude, fix.longitude);
      } catch (_) {}
    }
    final countryCode = _normalize(metadata.countryCode)?.toUpperCase();

    late final String timeZoneId;
    try {
      timeZoneId = (await _timeZoneResolver(
        fix.latitude,
        fix.longitude,
        countryCode ?? '',
      )).trim();
      if (timeZoneId.isEmpty) throw StateError('empty timezone');
    } catch (error) {
      return PrayerLocationUpdateResult(
        PrayerLocationUpdateStatus.timeZoneUnavailable,
        message: error.toString(),
      );
    }

    final candidate = PrayerLocationGeneration(
      revision: revision,
      mode: mode,
      latitude: fix.latitude,
      longitude: fix.longitude,
      timeZoneId: timeZoneId,
      timeZoneProvenance: PrayerTimeZoneProvenance.coordinateResolved,
      countryCode: countryCode,
      locality: _normalize(metadata.locality),
      countryName: _normalize(metadata.countryName),
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

    final rejection = await repository.synchronized((session) async {
      await cacheHelper.reload();
      final state = session.state;
      if (state.latestIntentRevision != revision ||
          state.latestIntentMode != mode) {
        return PrayerLocationUpdateStatus.superseded;
      }
      if (PrayerTimesCalculator.methodTokenFromCache(cacheHelper) ==
              PrayerTimesCalculator.autoMethodToken &&
          countryCode == null) {
        return PrayerLocationUpdateStatus.deferredCountry;
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
    if (rejection != null) {
      return PrayerLocationUpdateResult(
        rejection,
        message: rejection == PrayerLocationUpdateStatus.deferredCountry
            ? 'Country is required for automatic calculation method.'
            : null,
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
}
