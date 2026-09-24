import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/linux_prayer_notification_scheduler.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_location_coordinator.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:synchronized/synchronized.dart';

typedef PrayerWidgetPublisher =
    Future<void> Function({
      required PrayerLocationGeneration generation,
      required int scheduleRevision,
      required int publicationRevision,
      required String configurationSignature,
    });

class PrayerNotificationScheduler implements PrayerLocationActivator {
  PrayerNotificationScheduler({
    required this.cacheHelper,
    PrayerNotificationGateway? notifications,
    NotificationCapacityPolicy? capacityPolicy,
    LinuxPrayerScheduleWriter? linuxScheduler,
    PrayerPushSynchronizer? pushSynchronizer,
    PrayerLocationRepository? locationRepository,
    PrayerWidgetPublisher? widgetPublisher,
    DateTime Function()? now,
  }) : notifications = notifications ?? NotificationServices(),
       capacityPolicy = capacityPolicy ?? NotificationCapacityPolicy.current,
       linuxScheduler = linuxScheduler ?? LinuxPrayerNotificationScheduler(),
       pushSynchronizer =
           pushSynchronizer ??
           PrayerPushService(cacheHelper: cacheHelper, now: now),
       locationRepository =
           locationRepository ??
           PrayerLocationRepository(cacheHelper: cacheHelper),
       widgetPublisher =
           widgetPublisher ??
           (({
             required PrayerLocationGeneration generation,
             required int scheduleRevision,
             required int publicationRevision,
             required String configurationSignature,
           }) => _publishWidget(
             cacheHelper,
             generation: generation,
             scheduleRevision: scheduleRevision,
             publicationRevision: publicationRevision,
             configurationSignature: configurationSignature,
           )),
       _now = now ?? DateTime.now;

  static const signatureKey = 'prayer_notification_plan_signature';
  static const coverageKey = 'prayer_notification_coverage_until';
  static const lastSuccessKey = 'prayer_notification_last_success';
  static const lastReasonKey = 'prayer_notification_last_reason';
  static const pendingCountKey = 'prayer_notification_pending_count';
  static const eventIdsKey = 'prayer_notification_event_ids';
  static const Duration occurrenceRetention = Duration(days: 400);

  static final Lock _isolateLock = Lock();

  final CacheHelper cacheHelper;
  final PrayerNotificationGateway notifications;
  final NotificationCapacityPolicy capacityPolicy;
  final LinuxPrayerScheduleWriter linuxScheduler;
  final PrayerPushSynchronizer pushSynchronizer;
  final PrayerLocationRepository locationRepository;
  final PrayerWidgetPublisher widgetPublisher;
  final DateTime Function() _now;

  Future<PrayerScheduleResult> reconcile({
    String reason = 'unspecified',
    bool force = false,
  }) {
    final effectiveReason = force ? '$reason-force' : reason;
    return _guarded(() {
      return locationRepository.synchronized((session) async {
        final state = session.state;
        final candidate = state.pendingCandidate;
        final target = candidate ?? state.activeLocation;
        if (target == null) {
          await pushSynchronizer.disable(
            reason: 'location-unavailable',
            locationRevision: state.activeLocation?.revision ?? 0,
            scheduleRevision: state.scheduleRevision,
          );
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.locationUnavailable,
            message: 'A complete prayer location is required.',
          );
        }
        return _reconcileLocked(
          session: session,
          target: target,
          activatesCandidate: candidate != null,
          reason: effectiveReason,
        );
      });
    });
  }

  @override
  Future<PrayerScheduleResult> activateCandidate({
    required PrayerLocationGeneration candidate,
    required String reason,
  }) {
    return _guarded(() {
      return locationRepository.synchronized((session) async {
        final newest = session.state.pendingCandidate;
        if (newest == null) {
          final active = session.state.activeLocation;
          if (active?.revision == candidate.revision) {
            final events = session.state.committedEvents;
            return PrayerScheduleResult(
              status: PrayerScheduleStatus.upToDate,
              pendingCount: events.length,
              coverageUntil: events.isEmpty ? null : events.last.scheduledTime,
            );
          }
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.deferred,
            message: 'The location request was superseded.',
          );
        }
        if (newest.revision != candidate.revision ||
            session.state.latestIntentRevision != candidate.revision) {
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.deferred,
            message: 'The location request was superseded.',
          );
        }
        return _reconcileLocked(
          session: session,
          target: newest,
          activatesCandidate: true,
          reason: reason,
        );
      });
    });
  }

  Future<PrayerScheduleResult> _guarded(
    Future<PrayerScheduleResult> Function() action,
  ) {
    return _isolateLock.synchronized(() async {
      try {
        return await action();
      } catch (error, stackTrace) {
        debugPrint('Prayer notification reconciliation failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        return PrayerScheduleResult(
          status: PrayerScheduleStatus.failed,
          message: error.toString(),
        );
      }
    });
  }

  Future<PrayerScheduleResult> _reconcileLocked({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required String reason,
  }) async {
    await cacheHelper.reload();
    final now = _now().toUtc();
    var history = _recordElapsedOccurrences(
      session.state.occurrenceHistory,
      session.state.committedEvents,
      now,
    );
    history = _recordElapsedOccurrences(
      history,
      session.state.journal?.desiredEvents ?? const <PrayerNotificationEvent>[],
      now,
      disposition: PrayerOccurrenceDisposition.deliveryUncertain,
    );

    if (PrayerTimesCalculator.methodTokenFromCache(cacheHelper) ==
            PrayerTimesCalculator.autoMethodToken &&
        (target.countryCode == null || target.countryCode!.trim().isEmpty)) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        message: 'Country is required for automatic calculation method.',
      );
    }

    if (capacityPolicy.platform == HudaNotificationPlatform.web ||
        capacityPolicy.platform == HudaNotificationPlatform.unsupported) {
      final scheduleRevision = _nextScheduleRevision(
        _highestKnownScheduleRevision(session.state),
      );
      final signature = 'unsupported|location:${target.revision}';
      await _commit(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        scheduleRevision: scheduleRevision,
        configurationSignature: signature,
        digest: _digest(target.revision, signature, const []),
        events: const [],
        history: history,
        activatedAt: now,
        publishWidget: true,
      );
      await _publishCommittedWidget(session, target, signature);
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.unsupported,
        message: 'Scheduled prayer notifications are unavailable.',
      );
    }

    await notifications.initialize();
    final deviceTimeZone = await notifications.refreshTimeZone();
    final configuration =
        PrayerScheduleConfiguration.fromCache(
          cache: cacheHelper,
          location: target,
          deviceTimeZoneId: deviceTimeZone,
        ).forSchedulingCapability(
          await notifications.schedulingCapabilitySignature(),
        );

    if (capacityPolicy.platform == HudaNotificationPlatform.linux) {
      return _reconcileLinux(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        configuration: configuration,
        history: history,
        reason: reason,
        now: now,
      );
    }

    final allPending = await notifications.pendingNotificationRequests();
    final pendingPrayerById = {
      for (final request in allPending)
        if (PrayerNotificationEvent.isPrayerId(request.id)) request.id: request,
    };
    final otherPendingCount = allPending.length - pendingPrayerById.length;
    final available = math.max(
      0,
      math.min(
        capacityPolicy.prayerPendingLimit,
        capacityPolicy.totalPendingLimit - otherPendingCount,
      ),
    );

    final provisional = PrayerNotificationPlanner(cacheHelper)
        .buildFromConfiguration(
          now: now,
          maxEvents: math.max(available, 1),
          horizon: capacityPolicy.prayerHorizon,
          configuration: configuration,
        );
    if (provisional == null) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.locationUnavailable,
      );
    }

    final suppressedIds = history.map((record) => record.occurrenceId).toSet();
    var desired = provisional.events
        .where((event) => !suppressedIds.contains(event.id))
        .take(available)
        .toList(growable: false);
    var digest = _digest(target.revision, configuration.signature, desired);
    final existingJournal = session.state.journal;
    final remoteScheduleRevision =
        session.state.remoteOwnershipAcknowledgement?.scheduleRevision ?? 0;
    int scheduleRevision;
    var continuesExistingAttempt =
        existingJournal != null &&
        existingJournal.scheduleRevision >= remoteScheduleRevision &&
        existingJournal.candidateLocationRevision == target.revision &&
        existingJournal.configurationSignature == configuration.signature &&
        existingJournal.desiredEventDigest == digest;
    if (continuesExistingAttempt) {
      scheduleRevision = existingJournal.scheduleRevision;
      desired = existingJournal.desiredEvents
          .where(
            (event) =>
                event.scheduledInstantUtc.isAfter(now) &&
                !suppressedIds.contains(event.id),
          )
          .toList(growable: false);
      final resumedDigest = _digest(
        target.revision,
        configuration.signature,
        desired,
      );
      if (resumedDigest != digest) {
        digest = resumedDigest;
        scheduleRevision = _nextScheduleRevision(
          _highestKnownScheduleRevision(session.state),
        );
        continuesExistingAttempt = false;
      }
    } else if (session.state.committedDesiredEventDigest == digest &&
        session.state.committedConfigurationSignature ==
            configuration.signature) {
      final highestKnown = _highestKnownScheduleRevision(session.state);
      scheduleRevision = highestKnown == session.state.scheduleRevision
          ? math.max(1, session.state.scheduleRevision)
          : _nextScheduleRevision(highestKnown);
    } else {
      scheduleRevision = _nextScheduleRevision(
        _highestKnownScheduleRevision(session.state),
      );
    }
    desired = desired
        .map((event) => event.copyWith(scheduleRevision: scheduleRevision))
        .toList(growable: false);

    var journal = PrayerScheduleJournal(
      candidateLocationRevision: target.revision,
      previousLocationRevision: session.state.activeLocation?.revision,
      scheduleRevision: scheduleRevision,
      configurationSignature: configuration.signature,
      cutoverInstantUtc: continuesExistingAttempt
          ? existingJournal!.cutoverInstantUtc
          : now,
      phase: PrayerReconciliationPhase.preparing,
      desiredEvents: List.unmodifiable(desired),
      desiredEventDigest: digest,
      completedOrUncertainOperations: continuesExistingAttempt
          ? existingJournal!.completedOrUncertainOperations
          : const [],
      attemptCount: continuesExistingAttempt
          ? existingJournal!.attemptCount + 1
          : 1,
    );
    await session.save(
      session.state.copyWith(occurrenceHistory: history, journal: journal),
    );

    final notificationsAllowed = await notifications.areNotificationsAllowed();
    if (!notificationsAllowed) {
      return _reconcileDisabledNotifications(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        journal: journal,
        pendingPrayerIds: pendingPrayerById.keys.toSet(),
        history: history,
        now: now,
        reason: reason,
      );
    }

    if (available == 0 &&
        capacityPolicy.platform != HudaNotificationPlatform.ios) {
      journal = journal.copyWith(
        phase: PrayerReconciliationPhase.degraded,
        lastErrorCategory: 'zero-local-capacity',
      );
      await session.save(session.state.copyWith(journal: journal));
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        message: 'No prayer notification capacity is currently available.',
      );
    }

    journal = journal.copyWith(
      phase: PrayerReconciliationPhase.transferringOwnership,
    );
    await session.save(session.state.copyWith(journal: journal));
    final desiredById = {for (final event in desired) event.id: event};
    final desiredIds = desiredById.keys.toSet();
    var currentAllPending = allPending;
    var currentPendingPrayerById = pendingPrayerById;

    if (capacityPolicy.platform == HudaNotificationPlatform.ios) {
      final localReleases = currentPendingPrayerById.keys.toSet().difference(
        desiredIds,
      );
      if (!await _cancelIds(session, localReleases)) {
        return _degradedResult(session, 'remote-handoff-release-failed');
      }
      if (localReleases.isNotEmpty) {
        currentAllPending = await notifications.pendingNotificationRequests();
        currentPendingPrayerById = {
          for (final request in currentAllPending)
            if (PrayerNotificationEvent.isPrayerId(request.id))
              request.id: request,
        };
        if (localReleases.any(currentPendingPrayerById.containsKey)) {
          return _degradedResult(
            session,
            'remote-handoff-release-verification-failed',
          );
        }
      }
      journal = session.state.journal ?? journal;
    }
    final coverage = desired.isEmpty ? null : desired.last.scheduledInstantUtc;
    final remote = await pushSynchronizer.syncFallback(
      localCoverageUntil: coverage,
      timeZoneName: target.timeZoneId,
      reason: reason,
      locationRevision: target.revision,
      scheduleRevision: scheduleRevision,
      configurationSignature: configuration.signature,
      configuration: configuration,
      suppressedOccurrenceIds: suppressedIds,
    );
    final remoteAcceptedRequestedRevision =
        remote.acknowledged &&
        (remote.acceptedScheduleRevision ?? scheduleRevision) ==
            scheduleRevision &&
        (remote.acceptedLocationRevision ?? target.revision) == target.revision;
    final remoteAcceptedRequestedBoundary = _sameInstant(
      remote.ownershipUntilUtc,
      coverage,
    );
    final remoteAcknowledged =
        remoteAcceptedRequestedRevision && remoteAcceptedRequestedBoundary;
    if (capacityPolicy.platform == HudaNotificationPlatform.ios &&
        !remoteAcknowledged) {
      await _rebaseJournalAboveServerRevision(
        session,
        remote.acceptedScheduleRevision,
        'remote-${remote.status.name}',
        acceptedLocationRevision: remote.acceptedLocationRevision,
        candidateLocationRevision: target.revision,
      );
      journal = (session.state.journal ?? journal).copyWith(
        phase: PrayerReconciliationPhase.degraded,
        lastErrorCategory: 'remote-${remote.status.name}',
      );
      if (session.state.journal?.scheduleRevision == journal.scheduleRevision) {
        await session.save(session.state.copyWith(journal: journal));
      }
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        pendingCount: currentPendingPrayerById.length,
        message:
            remote.message ??
            'APNs ownership was not acknowledged; the partial handoff is journaled for recovery.',
      );
    }
    if (remoteAcknowledged) {
      journal = (session.state.journal ?? journal).copyWith(
        acknowledgedRemoteScheduleRevision:
            remote.acceptedScheduleRevision ?? scheduleRevision,
        acknowledgedRemoteOwnershipUntilUtc: remote.ownershipUntilUtc,
      );
      await session.save(
        session.state.copyWith(
          journal: journal,
          remoteOwnershipAcknowledgement:
              capacityPolicy.platform == HudaNotificationPlatform.ios
              ? PrayerRemoteOwnershipAcknowledgement(
                  locationRevision: target.revision,
                  scheduleRevision: scheduleRevision,
                  enabled: true,
                  localCoverageUntilUtc: coverage,
                  acknowledgedAtUtc: _now().toUtc(),
                )
              : session.state.remoteOwnershipAcknowledgement,
        ),
      );
    }

    journal = (session.state.journal ?? journal).copyWith(
      phase: PrayerReconciliationPhase.applyingLocal,
    );
    await session.save(session.state.copyWith(journal: journal));
    final pendingIds = currentPendingPrayerById.keys.toSet();
    final staleIds = pendingIds.difference(desiredIds);
    final mismatchedIds = pendingIds.intersection(desiredIds).where((id) {
      return !desiredById[id]!.matchesPendingPayload(
        currentPendingPrayerById[id]?.payload,
      );
    }).toSet();
    final newIds = desiredIds.difference(pendingIds);
    final retainedIds = desiredIds
        .intersection(pendingIds)
        .difference(mismatchedIds);

    if (mismatchedIds.isEmpty &&
        newIds.isEmpty &&
        staleIds.isEmpty &&
        retainedIds.length == desiredIds.length &&
        session.state.committedDesiredEventDigest == digest &&
        session.state.committedConfigurationSignature ==
            configuration.signature &&
        !activatesCandidate) {
      await session.save(
        session.state.copyWith(journal: null, occurrenceHistory: history),
      );
      await _publishCommittedWidget(session, target, configuration.signature);
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.upToDate,
        pendingCount: desired.length,
        coverageUntil: desired.isEmpty ? null : desired.last.scheduledTime,
      );
    }

    final earlyCancel = <int>{};
    final replacementNeedsSlot =
        capacityPolicy.platform == HudaNotificationPlatform.windows
        ? mismatchedIds.length
        : 0;
    final freeSlots = math.max(
      0,
      capacityPolicy.totalPendingLimit - currentAllPending.length,
    );
    final slotsNeeded = math.max(
      0,
      newIds.length + replacementNeedsSlot - freeSlots,
    );
    if (slotsNeeded > staleIds.length) {
      await _markDegraded(session, 'insufficient-safe-capacity');
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.degraded,
        pendingCount: pendingIds.length,
        message:
            'The existing plan was retained because replacement capacity is insufficient.',
      );
    }
    earlyCancel.addAll(staleIds.take(slotsNeeded));
    if (capacityPolicy.platform == HudaNotificationPlatform.windows) {
      earlyCancel.addAll(mismatchedIds);
    }
    if (!await _cancelIds(session, earlyCancel)) {
      return _degradedResult(session, 'early-cancellation-failed');
    }

    var scheduledCount = 0;
    final toSchedule = desired
        .where(
          (event) =>
              newIds.contains(event.id) || mismatchedIds.contains(event.id),
        )
        .toList(growable: false);
    for (final event in toSchedule) {
      final mutationNow = _now().toUtc();
      if (!event.scheduledInstantUtc.isAfter(mutationNow)) {
        history = _upsertHistory(
          history,
          PrayerOccurrenceRecord(
            occurrenceId: event.id,
            scheduledInstantUtc: event.scheduledInstantUtc,
            locationRevision: event.locationRevision,
            scheduleRevision: event.scheduleRevision,
            disposition: PrayerOccurrenceDisposition.deliveryUncertain,
            recordedAtUtc: mutationNow,
          ),
          mutationNow,
        );
        await session.save(
          session.state.copyWith(
            occurrenceHistory: history,
            journal: session.state.journal?.copyWith(
              phase: PrayerReconciliationPhase.degraded,
              lastErrorCategory: 'deadline-passed-during-apply',
            ),
          ),
        );
        return const PrayerScheduleResult(
          status: PrayerScheduleStatus.degraded,
          message:
              'A prayer became due during reconciliation; recovery will suppress replay.',
        );
      }
      await _recordOperation(session, 'schedule-uncertain:${event.id}');
      if (!await notifications.schedulePrayerEvent(event)) {
        return _degradedResult(session, 'schedule-failed:${event.id}');
      }
      scheduledCount++;
      await _recordOperation(session, 'schedule-complete:${event.id}');
    }

    var verified = await notifications.pendingNotificationRequests();
    var verifiedById = {
      for (final request in verified)
        if (PrayerNotificationEvent.isPrayerId(request.id)) request.id: request,
    };
    final missingOrInvalid = desired
        .where((event) {
          return !event.matchesPendingPayload(verifiedById[event.id]?.payload);
        })
        .toList(growable: false);
    if (missingOrInvalid.isNotEmpty) {
      return _degradedResult(session, 'verification-incomplete');
    }

    final remainingStale = verifiedById.keys.toSet().difference(desiredIds);
    if (!await _cancelIds(session, remainingStale)) {
      return _degradedResult(session, 'stale-cancellation-failed');
    }
    verified = await notifications.pendingNotificationRequests();
    verifiedById = {
      for (final request in verified)
        if (PrayerNotificationEvent.isPrayerId(request.id)) request.id: request,
    };
    final finalPrayerIds = verifiedById.keys.toSet();
    final finalMatches = desired.every(
      (event) => event.matchesPendingPayload(verifiedById[event.id]?.payload),
    );
    if (!finalMatches ||
        finalPrayerIds.difference(desiredIds).isNotEmpty ||
        desiredIds.difference(finalPrayerIds).isNotEmpty) {
      return _degradedResult(session, 'final-verification-incomplete');
    }
    final verifiedSchedulingCapability = await notifications
        .schedulingCapabilitySignature();
    if (verifiedSchedulingCapability != configuration.schedulingCapability) {
      return _degradedResult(session, 'scheduling-capability-changed');
    }

    await _commit(
      session: session,
      target: target,
      activatesCandidate: activatesCandidate,
      scheduleRevision: scheduleRevision,
      configurationSignature: configuration.signature,
      digest: digest,
      events: desired,
      history: history,
      activatedAt: _now().toUtc(),
      publishWidget: true,
    );
    await _persistSuccess(configuration.signature, desired, reason);
    await _publishCommittedWidget(session, target, configuration.signature);
    return PrayerScheduleResult(
      status: scheduledCount == 0
          ? PrayerScheduleStatus.upToDate
          : PrayerScheduleStatus.scheduled,
      scheduledCount: scheduledCount,
      pendingCount: desired.length,
      coverageUntil: desired.isEmpty ? null : desired.last.scheduledTime,
    );
  }

  Future<PrayerScheduleResult> _reconcileLinux({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required PrayerScheduleConfiguration configuration,
    required List<PrayerOccurrenceRecord> history,
    required String reason,
    required DateTime now,
  }) async {
    final plan = PrayerNotificationPlanner(cacheHelper).buildFromConfiguration(
      now: now,
      maxEvents: capacityPolicy.prayerPendingLimit,
      horizon: capacityPolicy.prayerHorizon,
      configuration: configuration,
    );
    if (plan == null) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.locationUnavailable,
      );
    }
    final suppressed = history.map((record) => record.occurrenceId).toSet();
    var events = plan.events
        .where((event) => !suppressed.contains(event.id))
        .toList(growable: false);
    final digest = _digest(target.revision, configuration.signature, events);
    final highestKnown = _highestKnownScheduleRevision(session.state);
    final revision =
        session.state.committedDesiredEventDigest == digest &&
            highestKnown == session.state.scheduleRevision
        ? math.max(1, session.state.scheduleRevision)
        : _nextScheduleRevision(highestKnown);
    events = events
        .map((event) => event.copyWith(scheduleRevision: revision))
        .toList(growable: false);
    final journal = PrayerScheduleJournal(
      candidateLocationRevision: target.revision,
      previousLocationRevision: session.state.activeLocation?.revision,
      scheduleRevision: revision,
      configurationSignature: configuration.signature,
      cutoverInstantUtc: now,
      phase: PrayerReconciliationPhase.applyingLocal,
      desiredEvents: events,
      desiredEventDigest: digest,
      attemptCount: (session.state.journal?.attemptCount ?? 0) + 1,
    );
    await session.save(
      session.state.copyWith(journal: journal, occurrenceHistory: history),
    );
    final applied = await linuxScheduler.apply(
      PrayerNotificationPlan(
        events: events,
        configurationSignature: configuration.signature,
        requestedThrough: now.add(capacityPolicy.prayerHorizon),
        locationRevision: target.revision,
        scheduleRevision: revision,
      ),
    );
    if (!applied) return _degradedResult(session, 'linux-apply-failed');
    await _commit(
      session: session,
      target: target,
      activatesCandidate: activatesCandidate,
      scheduleRevision: revision,
      configurationSignature: configuration.signature,
      digest: digest,
      events: events,
      history: history,
      activatedAt: _now().toUtc(),
      publishWidget: false,
    );
    await _persistSuccess(configuration.signature, events, reason);
    return PrayerScheduleResult(
      status: PrayerScheduleStatus.scheduled,
      scheduledCount: events.length,
      pendingCount: events.length,
      coverageUntil: events.isEmpty ? null : events.last.scheduledTime,
    );
  }

  Future<PrayerScheduleResult> _reconcileDisabledNotifications({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required PrayerScheduleJournal journal,
    required Set<int> pendingPrayerIds,
    required List<PrayerOccurrenceRecord> history,
    required DateTime now,
    required String reason,
  }) async {
    journal = journal.copyWith(
      phase: PrayerReconciliationPhase.transferringOwnership,
    );
    await session.save(session.state.copyWith(journal: journal));
    final remote = await pushSynchronizer.disable(
      reason: '$reason-notification-permission-denied',
      locationRevision: target.revision,
      scheduleRevision: journal.scheduleRevision,
    );
    final remoteAcknowledged =
        remote.acknowledged &&
        (remote.acceptedScheduleRevision ?? journal.scheduleRevision) ==
            journal.scheduleRevision &&
        (remote.acceptedLocationRevision ?? target.revision) == target.revision;
    if (capacityPolicy.platform == HudaNotificationPlatform.ios &&
        !remoteAcknowledged) {
      await _rebaseJournalAboveServerRevision(
        session,
        remote.acceptedScheduleRevision,
        'remote-disable-${remote.status.name}',
        acceptedLocationRevision: remote.acceptedLocationRevision,
        candidateLocationRevision: target.revision,
      );
      await _markDegraded(session, 'remote-disable-${remote.status.name}');
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        pendingCount: pendingPrayerIds.length,
        message: remote.message,
      );
    }
    if (remoteAcknowledged &&
        capacityPolicy.platform == HudaNotificationPlatform.ios) {
      journal = (session.state.journal ?? journal).copyWith(
        acknowledgedRemoteScheduleRevision:
            remote.acceptedScheduleRevision ?? journal.scheduleRevision,
        acknowledgedRemoteOwnershipUntilUtc: null,
      );
      await session.save(
        session.state.copyWith(
          journal: journal,
          remoteOwnershipAcknowledgement: PrayerRemoteOwnershipAcknowledgement(
            locationRevision: target.revision,
            scheduleRevision: journal.scheduleRevision,
            enabled: false,
            acknowledgedAtUtc: _now().toUtc(),
          ),
        ),
      );
    }
    if (!await _cancelIds(session, pendingPrayerIds)) {
      return _degradedResult(session, 'disabled-local-cancellation-failed');
    }
    final remaining = await notifications.pendingNotificationRequests();
    if (remaining.any(
      (request) => PrayerNotificationEvent.isPrayerId(request.id),
    )) {
      return _degradedResult(session, 'disabled-local-verification-failed');
    }
    final digest = _digest(
      target.revision,
      journal.configurationSignature,
      const [],
    );
    await _commit(
      session: session,
      target: target,
      activatesCandidate: activatesCandidate,
      scheduleRevision: journal.scheduleRevision,
      configurationSignature: journal.configurationSignature,
      digest: digest,
      events: const [],
      history: history,
      activatedAt: now,
      publishWidget: true,
    );
    await _persistSuccess(journal.configurationSignature, const [], reason);
    await _publishCommittedWidget(
      session,
      target,
      journal.configurationSignature,
    );
    return const PrayerScheduleResult(
      status: PrayerScheduleStatus.permissionDenied,
      message: 'Notification permission is disabled.',
    );
  }

  Future<void> _commit({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required int scheduleRevision,
    required String configurationSignature,
    required String digest,
    required List<PrayerNotificationEvent> events,
    required List<PrayerOccurrenceRecord> history,
    required DateTime activatedAt,
    required bool publishWidget,
  }) async {
    final current = session.state;
    if (activatesCandidate) {
      if (current.pendingCandidate?.revision != target.revision ||
          current.latestIntentRevision != target.revision) {
        throw StateError('Candidate changed before activation commit');
      }
      await session.commitActive(
        generation: target,
        scheduleRevision: scheduleRevision,
        configurationSignature: configurationSignature,
        desiredEventDigest: digest,
        events: events,
        occurrenceHistory: history,
        activatedAtUtc: activatedAt,
      );
    } else {
      await session.commitScheduleForActive(
        generation: target,
        scheduleRevision: scheduleRevision,
        configurationSignature: configurationSignature,
        desiredEventDigest: digest,
        events: events,
        occurrenceHistory: history,
        activatedAtUtc: activatedAt,
        publishWidget: publishWidget,
      );
    }
  }

  Future<void> _publishCommittedWidget(
    PrayerLocationRepositorySession session,
    PrayerLocationGeneration target,
    String configurationSignature,
  ) async {
    final state = session.state;
    if (!state.widgetPublicationPending) return;
    try {
      await widgetPublisher(
        generation: state.activeLocation ?? target,
        scheduleRevision: state.scheduleRevision,
        publicationRevision: state.widgetPublicationRevision,
        configurationSignature: configurationSignature,
      );
      await session.markWidgetPublished(state.widgetPublicationRevision);
    } catch (error) {
      debugPrint('Prayer widget publication deferred: $error');
    }
  }

  static Future<void> _publishWidget(
    CacheHelper cacheHelper, {
    required PrayerLocationGeneration generation,
    required int scheduleRevision,
    required int publicationRevision,
    required String configurationSignature,
  }) async {
    await PrayerWidgetService.pushSettings(
      cacheHelper: cacheHelper,
      activeGeneration: generation,
      scheduleRevision: scheduleRevision,
      publicationRevision: publicationRevision,
      configurationSignature: configurationSignature,
    );
  }

  Future<bool> _cancelIds(
    PrayerLocationRepositorySession session,
    Iterable<int> ids,
  ) async {
    for (final id in ids.toSet()) {
      if (!PrayerNotificationEvent.isPrayerId(id)) continue;
      try {
        await _recordOperation(session, 'cancel-uncertain:$id');
        await notifications.cancelNotifications([id]);
        await _recordOperation(session, 'cancel-complete:$id');
      } catch (_) {
        await _markDegraded(session, 'cancel-failed:$id');
        return false;
      }
    }
    return true;
  }

  Future<void> _recordOperation(
    PrayerLocationRepositorySession session,
    String operation,
  ) async {
    final journal = session.state.journal;
    if (journal == null) return;
    final operations = <String>[
      ...journal.completedOrUncertainOperations,
      operation,
    ];
    await session.save(
      session.state.copyWith(
        journal: journal.copyWith(
          completedOrUncertainOperations: List.unmodifiable(operations),
        ),
      ),
    );
  }

  Future<void> _markDegraded(
    PrayerLocationRepositorySession session,
    String category,
  ) async {
    final journal = session.state.journal;
    if (journal == null) return;
    await session.save(
      session.state.copyWith(
        journal: journal.copyWith(
          phase: PrayerReconciliationPhase.degraded,
          lastErrorCategory: category,
        ),
      ),
    );
  }

  Future<void> _rebaseJournalAboveServerRevision(
    PrayerLocationRepositorySession session,
    int? acceptedScheduleRevision,
    String category, {
    int? acceptedLocationRevision,
    required int candidateLocationRevision,
  }) async {
    final journal = session.state.journal;
    if (journal == null) return;
    if ((acceptedLocationRevision != null &&
            (acceptedLocationRevision < 0 ||
                acceptedLocationRevision >
                    PrayerLocationGeneration.maxSafeRevision)) ||
        (acceptedScheduleRevision != null &&
            (acceptedScheduleRevision < 0 ||
                acceptedScheduleRevision >
                    PrayerLocationGeneration.maxSafeRevision))) {
      await _markDegraded(session, '$category-invalid-server-revision');
      return;
    }
    if (acceptedLocationRevision != null &&
        acceptedLocationRevision > candidateLocationRevision) {
      await session.save(
        session.state.copyWith(
          revisionCounter: math.max(
            session.state.revisionCounter,
            acceptedLocationRevision,
          ),
          journal: journal.copyWith(
            phase: PrayerReconciliationPhase.degraded,
            lastErrorCategory: '$category-server-location-newer',
          ),
        ),
      );
      return;
    }
    if (acceptedScheduleRevision == null ||
        acceptedScheduleRevision <= journal.scheduleRevision) {
      return;
    }
    if (acceptedScheduleRevision >= PrayerLocationGeneration.maxSafeRevision) {
      await _markDegraded(session, '$category-revision-space-exhausted');
      return;
    }
    final rebasedRevision = acceptedScheduleRevision + 1;
    final rebasedEvents = journal.desiredEvents
        .map((event) => event.copyWith(scheduleRevision: rebasedRevision))
        .toList(growable: false);
    await session.save(
      session.state.copyWith(
        journal: PrayerScheduleJournal(
          candidateLocationRevision: journal.candidateLocationRevision,
          previousLocationRevision: journal.previousLocationRevision,
          scheduleRevision: rebasedRevision,
          configurationSignature: journal.configurationSignature,
          cutoverInstantUtc: _now().toUtc(),
          phase: PrayerReconciliationPhase.degraded,
          desiredEvents: List.unmodifiable(rebasedEvents),
          desiredEventDigest: journal.desiredEventDigest,
          completedOrUncertainOperations: const [],
          attemptCount: journal.attemptCount,
          lastErrorCategory: '$category-server-newer-rebased',
        ),
      ),
    );
  }

  Future<PrayerScheduleResult> _degradedResult(
    PrayerLocationRepositorySession session,
    String category,
  ) async {
    await _markDegraded(session, category);
    return PrayerScheduleResult(
      status: PrayerScheduleStatus.degraded,
      message: category,
    );
  }

  List<PrayerOccurrenceRecord> _recordElapsedOccurrences(
    List<PrayerOccurrenceRecord> current,
    List<PrayerNotificationEvent> committedEvents,
    DateTime now, {
    PrayerOccurrenceDisposition disposition = PrayerOccurrenceDisposition.due,
  }) {
    var result = current;
    final known = result.map((record) => record.occurrenceId).toSet();
    for (final event in committedEvents) {
      if (known.contains(event.id) || event.scheduledInstantUtc.isAfter(now)) {
        continue;
      }
      result = _upsertHistory(
        result,
        PrayerOccurrenceRecord(
          occurrenceId: event.id,
          scheduledInstantUtc: event.scheduledInstantUtc,
          locationRevision: event.locationRevision,
          scheduleRevision: event.scheduleRevision,
          disposition: disposition,
          recordedAtUtc: now,
        ),
        now,
      );
      known.add(event.id);
    }
    return result;
  }

  List<PrayerOccurrenceRecord> _upsertHistory(
    List<PrayerOccurrenceRecord> current,
    PrayerOccurrenceRecord next,
    DateTime now,
  ) {
    final newestRecordedAt = current.fold<DateTime?>(null, (latest, item) {
      if (latest == null || item.recordedAtUtc.isAfter(latest)) {
        return item.recordedAtUtc;
      }
      return latest;
    });
    final clockIsTrusted =
        newestRecordedAt == null ||
        !now.isBefore(newestRecordedAt.subtract(const Duration(minutes: 2)));
    final cutoff = now.subtract(occurrenceRetention);
    final byId = <int, PrayerOccurrenceRecord>{
      for (final record in current)
        if (!clockIsTrusted || !record.recordedAtUtc.isBefore(cutoff))
          record.occurrenceId: record,
      next.occurrenceId: next,
    };
    final values = byId.values.toList()
      ..sort((a, b) => a.recordedAtUtc.compareTo(b.recordedAtUtc));
    return List.unmodifiable(values);
  }

  String _digest(
    int locationRevision,
    String configurationSignature,
    Iterable<PrayerNotificationEvent> events,
  ) {
    final encoded = jsonEncode(<String, Object?>{
      'locationRevision': locationRevision,
      'configurationSignature': configurationSignature,
      'events': [
        for (final event in events)
          <Object?>[
            event.id,
            event.prayer.name,
            event.scheduledInstantUtc.toIso8601String(),
            event.scheduledTime.toIso8601String(),
            event.timeZoneName,
            event.title,
            event.body,
          ],
      ],
    });
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  static int _nextScheduleRevision(int current, {int? otherRevision}) {
    final highest = math.max(current, otherRevision ?? 0);
    if (highest < 0 || highest >= PrayerLocationGeneration.maxSafeRevision) {
      throw StateError('Prayer schedule revision space exhausted');
    }
    return math.max(1, highest + 1);
  }

  static int _highestKnownScheduleRevision(PrayerReliabilityState state) {
    return <int>[
      state.scheduleRevision,
      state.journal?.scheduleRevision ?? 0,
      state.remoteOwnershipAcknowledgement?.scheduleRevision ?? 0,
    ].reduce(math.max);
  }

  static bool _sameInstant(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == null && second == null;
    return first.toUtc().isAtSameMomentAs(second.toUtc());
  }

  Future<void> _persistSuccess(
    String signature,
    List<PrayerNotificationEvent> retainedEvents,
    String reason,
  ) async {
    final coverage = retainedEvents.isEmpty
        ? null
        : retainedEvents.last.scheduledInstantUtc.toIso8601String();
    try {
      await cacheHelper.saveData(key: signatureKey, value: signature);
      if (coverage == null) {
        await cacheHelper.removeData(key: coverageKey);
      } else {
        await cacheHelper.saveData(key: coverageKey, value: coverage);
      }
      await cacheHelper.saveData(
        key: lastSuccessKey,
        value: _now().toUtc().toIso8601String(),
      );
      await cacheHelper.saveData(key: lastReasonKey, value: reason);
      await cacheHelper.saveData(
        key: pendingCountKey,
        value: retainedEvents.length,
      );
      await cacheHelper.saveData(
        key: eventIdsKey,
        value: retainedEvents.map((event) => event.id).toList(),
      );
    } catch (error) {
      debugPrint('Prayer notification projection update deferred: $error');
    }
  }
}
