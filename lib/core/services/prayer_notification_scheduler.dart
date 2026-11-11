import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/mac_prayer_notification_gateway.dart';
import 'package:huda/core/services/ios_prayer_notification_gateway.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/pending_notification.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/linux_prayer_notification_scheduler.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';
import 'package:huda/core/services/linux_prayer_notification_gateway.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/notification_ids.dart';
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
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/windows_prayer_scheduling_controller.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter/services.dart' show PlatformException;
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
    this.deferWidgetPublication = false,
    this.macGateway,
    this.iosGateway,
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
  static const verificationPendingMessage = 'locationVerificationPending';
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
  final bool deferWidgetPublication;
  final MacPrayerNotificationGateway? macGateway;
  final IOSPrayerNotificationGateway? iosGateway;
  WindowsPrayerSchedulingController? _windowsController;
  final DateTime Function() _now;

  bool get _useWindowsWorker =>
      !kIsWeb &&
      capacityPolicy.platform == HudaNotificationPlatform.windows &&
      notifications is NotificationServices;

  WindowsPrayerSchedulingController get _windowsWorker =>
      _windowsController ??= WindowsPrayerSchedulingController(
        cache: cacheHelper,
        initializeNotifications: notifications.initialize,
        resolveDeviceTimeZone: notifications.refreshTimeZone,
        publishWidget: widgetPublisher,
      );

  bool get _supportsSafeReplacement =>
      notifications is VerifiedPrayerNotificationGateway &&
      (notifications as VerifiedPrayerNotificationGateway)
          .supportsSafeReplacement;

  bool _matchesPending(
    PrayerNotificationEvent event,
    PendingNotification? pending,
  ) => notifications is VerifiedPrayerNotificationGateway
      ? (notifications as VerifiedPrayerNotificationGateway)
            .matchesPendingEvent(event, pending)
      : event.matchesPendingPayload(pending?.payload);

  Future<PrayerScheduleResult> reconcile({
    String reason = 'unspecified',
    bool force = false,
  }) {
    if (_useWindowsWorker) {
      return _windowsWorker.reconcile(reason: reason, force: force);
    }
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
    if (_useWindowsWorker) {
      return _windowsWorker.activateCandidate(
        candidate: candidate,
        reason: reason,
      );
    }
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
        final result = await action();
        final notificationsReady =
            (result.isSuccess &&
                result.status != PrayerScheduleStatus.permissionDenied) ||
            result.message == verificationPendingMessage;
        await locationRepository.updateIssues(
          add: notificationsReady ? {} : {PrayerWorkflowIssue.notifications},
          remove: notificationsReady ? {PrayerWorkflowIssue.notifications} : {},
        );
        return result;
      } catch (error, stackTrace) {
        debugPrint('Prayer notification reconciliation failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        DateTime? coverage;
        try {
          coverage = (await locationRepository.readState())
              .acknowledgedCoverageUntilUtc;
          await locationRepository.updateIssues(
            add: {PrayerWorkflowIssue.notifications},
          );
        } catch (_) {}
        return PrayerScheduleResult(
          status: PrayerScheduleStatus.failed,
          coverageUntil: coverage,
          message: PrayerPushErrorCode.unavailable,
        );
      }
    });
  }

  Future<PrayerScheduleResult> _reconcileLocked({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required String reason,
    bool allowRemoteRevisionRetry = true,
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

    final display = session.state.displaySnapshot;
    final inputConfiguration =
        session.state.journal?.configuration ??
        (display?.location.revision == target.revision
            ? PrayerScheduleConfiguration.fromDisplay(
                display!,
                deviceTimeZoneId: target.timeZoneId,
                localeCode: cacheHelper.getDataString(key: 'locale') ?? 'en',
              )
            : session.state.committedConfiguration?.forLocation(target)) ??
        PrayerScheduleConfiguration.fromCache(
          cache: cacheHelper,
          location: target,
          deviceTimeZoneId: target.timeZoneId,
        );
    if (!inputConfiguration.location.calculationVerified ||
        (PrayerTimesCalculator.requiresCountry(
              inputConfiguration.methodToken,
            ) &&
            (target.countryCode == null || target.countryCode!.isEmpty))) {
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        coverageUntil:
            session.state.acknowledgedCoverageUntilUtc ??
            DateTime.tryParse(
              cacheHelper.getDataString(key: coverageKey) ?? '',
            ),
        message: verificationPendingMessage,
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
        fallbackConfiguration: inputConfiguration,
      );
      await _publishCommittedWidget(session, target, signature);
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.unsupported,
        message: 'Scheduled prayer notifications are unavailable.',
      );
    }

    if (capacityPolicy.platform == HudaNotificationPlatform.linux) {
      var applied = LinuxPrayerTrayBridge.experience.value.configured
          ? LinuxPrayerTrayBridge.experience.value
          : LinuxPrayerExperience.read(cacheHelper);
      // Prayers move to the companion by themselves, with the default (Silent)
      // reminders, once it can take them; the editor only changes them. Until
      // then the legacy helper keeps delivering.
      if (!applied.configured &&
          await LinuxPrayerNotificationGateway.canAdoptDefault()) {
        await LinuxPrayerTrayBridge.enableStartupOnce();
        applied = const LinuxPrayerExperience(configured: true);
      }
      if (applied.configured) {
        return _reconcileLinux(
          session: session,
          target: target,
          activatesCandidate: activatesCandidate,
          configuration: inputConfiguration
              .forLocation(target)
              .withLinuxExperience(applied),
          history: history,
          reason: reason,
          now: now,
        );
      }
    }
    await notifications.initialize();
    if (capacityPolicy.platform == HudaNotificationPlatform.ios &&
        (notifications is NotificationServices || iosGateway != null)) {
      return _reconcileIOSNative(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        configuration: inputConfiguration,
        history: history,
        reason: reason,
        now: now,
      );
    }
    if (capacityPolicy.platform == HudaNotificationPlatform.macos &&
        (notifications is NotificationServices || macGateway != null)) {
      return _reconcileMacNative(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        configuration: inputConfiguration,
        history: history,
        reason: reason,
        now: now,
      );
    }
    final transaction = notifications is TransactionalPrayerGatewayProvider
        ? await (notifications as TransactionalPrayerGatewayProvider)
              .transactionalPrayerBackend()
        : notifications is TransactionalPrayerNotificationGateway &&
              await (notifications as TransactionalPrayerNotificationGateway)
                  .isEnabled()
        ? notifications as TransactionalPrayerNotificationGateway
        : null;
    if (transaction != null) {
      return _reconcileAndroidNative(
        session: session,
        target: target,
        activatesCandidate: activatesCandidate,
        inputConfiguration: inputConfiguration,
        gateway: transaction,
        history: history,
        reason: reason,
        now: now,
      );
    }
    final deviceTimeZone = await notifications.refreshTimeZone();
    final windowsExperience =
        capacityPolicy.platform == HudaNotificationPlatform.windows
        ? WindowsPrayerExperience.read(cacheHelper)
        : null;
    final linuxExperience =
        capacityPolicy.platform == HudaNotificationPlatform.linux
        ? LinuxPrayerExperience.read(cacheHelper)
        : null;
    final resumableConfiguration = session.state.journal?.configuration;
    final configuration =
        (resumableConfiguration?.windowsExperience?.deliverySignature ==
                    windowsExperience?.deliverySignature &&
                resumableConfiguration?.linuxExperience?.deliverySignature ==
                    linuxExperience?.deliverySignature
            ? resumableConfiguration
            : null) ??
        PrayerScheduleConfiguration(
          location: target,
          deviceTimeZoneId: deviceTimeZone,
          methodToken: inputConfiguration.methodToken,
          madhabToken: inputConfiguration.madhabToken,
          highLatitudeRuleToken: inputConfiguration.highLatitudeRuleToken,
          customAngles: inputConfiguration.customAngles,
          offsets: inputConfiguration.offsets,
          localeCode: inputConfiguration.localeCode,
          schedulingCapability: await notifications
              .schedulingCapabilitySignature(),
          windowsExperience: windowsExperience,
          linuxExperience: linuxExperience,
        );
    // Resolved once per reconcile; the final capability check degrades the
    // result if the permission changes while events are being scheduled.
    final allowExact = await notifications.canScheduleExactNotifications();

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
      configuration: configuration,
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
      remoteOwnershipFloorUtc: existingJournal?.remoteOwnershipFloorUtc,
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
        allowRemoteRevisionRetry: allowRemoteRevisionRetry,
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

    final coverage = desired.isEmpty ? null : desired.last.scheduledInstantUtc;
    final isIos = capacityPolicy.platform == HudaNotificationPlatform.ios;
    final priorOwnershipFloor = journal.remoteOwnershipFloorUtc;
    journal = journal.copyWith(
      phase: PrayerReconciliationPhase.transferringOwnership,
      remoteOwnershipFloorUtc: isIos
          ? _earlier(
              priorOwnershipFloor,
              coverage ?? PrayerScheduleJournal.serverOwnsAll,
            )
          : priorOwnershipFloor,
    );
    await session.save(session.state.copyWith(journal: journal));
    final desiredById = {for (final event in desired) event.id: event};
    final desiredIds = desiredById.keys.toSet();
    var currentAllPending = allPending;
    var currentPendingPrayerById = pendingPrayerById;

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
    if (isIos && !remoteAcknowledged) {
      final outcomeFloor = remote.acknowledged
          ? _earlier(
              journal.remoteOwnershipFloorUtc,
              remote.ownershipUntilUtc ?? PrayerScheduleJournal.serverOwnsAll,
            )
          : remote.status == PrayerPushSyncStatus.failed
          ? journal.remoteOwnershipFloorUtc
          : priorOwnershipFloor;
      final current = session.state.journal;
      if (current != null && current.remoteOwnershipFloorUtc != outcomeFloor) {
        await session.save(
          session.state.copyWith(
            journal: current.copyWith(remoteOwnershipFloorUtc: outcomeFloor),
          ),
        );
      }
      final rebasedForRetry = await _rebaseJournalAboveServerRevision(
        session,
        remote.acceptedScheduleRevision,
        'remote-${remote.status.name}',
        acceptedLocationRevision: remote.acceptedLocationRevision,
        candidateLocationRevision: target.revision,
      );
      if (rebasedForRetry && allowRemoteRevisionRetry) {
        return _reconcileLocked(
          session: session,
          target: target,
          activatesCandidate: activatesCandidate,
          reason: reason,
          allowRemoteRevisionRetry: false,
        );
      }
      journal = (session.state.journal ?? journal).copyWith(
        phase: PrayerReconciliationPhase.degraded,
        lastErrorCategory: 'remote-${remote.status.name}',
      );
      if (session.state.journal?.scheduleRevision == journal.scheduleRevision) {
        await session.save(session.state.copyWith(journal: journal));
      }
      final bridgedThrough = await _bridgeLocalAlerts(
        session: session,
        desired: desired,
        pendingById: currentPendingPrayerById,
        pendingCount: currentAllPending.length,
        allowExact: allowExact,
      );
      if (bridgedThrough != null) {
        return PrayerScheduleResult(
          status: PrayerScheduleStatus.deferred,
          pendingCount: desired
              .where(
                (event) => !event.scheduledInstantUtc.isAfter(bridgedThrough),
              )
              .length,
          coverageUntil: bridgedThrough,
          message: PrayerScheduleResult.localBridgeMessage,
        );
      }
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        pendingCount: currentPendingPrayerById.length,
        coverageUntil:
            session.state.acknowledgedCoverageUntilUtc ??
            DateTime.tryParse(
              cacheHelper.getDataString(key: coverageKey) ?? '',
            ),
        message:
            remote.message ??
            'APNs ownership was not acknowledged; the partial handoff is journaled for recovery.',
      );
    }
    final notificationCoverageUntil = _notificationCoverageUntil(
      target: target,
      localEvents: desired,
      remote: remote,
    );
    final notificationCoverageUntilInstant = _notificationCoverageUntilInstant(
      localEvents: desired,
      remote: remote,
    );
    if (remoteAcknowledged) {
      journal = (session.state.journal ?? journal).copyWith(
        acknowledgedRemoteScheduleRevision:
            remote.acceptedScheduleRevision ?? scheduleRevision,
        acknowledgedRemoteOwnershipUntilUtc: remote.ownershipUntilUtc,
        remoteOwnershipFloorUtc: null,
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
      return !_matchesPending(desiredById[id]!, currentPendingPrayerById[id]);
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
      await _persistSuccess(
        configuration.signature,
        desired,
        reason,
        coverageUntilInstant: notificationCoverageUntilInstant,
      );
      await _publishCommittedWidget(session, target, configuration.signature);
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.upToDate,
        pendingCount: desired.length,
        coverageUntil: notificationCoverageUntil,
      );
    }

    final earlyCancel = <int>{};
    final replacementNeedsSlot =
        capacityPolicy.platform == HudaNotificationPlatform.windows &&
            !_supportsSafeReplacement
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
    if (capacityPolicy.platform == HudaNotificationPlatform.windows &&
        !_supportsSafeReplacement) {
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
      // Recovery diffs the OS pending list against the journaled desired
      // events, so only uncertain outcomes are persisted, not every step.
      try {
        if (!await notifications.schedulePrayerEvent(
          event,
          allowExact: allowExact,
        )) {
          return await _degradedResult(session, 'schedule-failed:${event.id}');
        }
      } catch (_) {
        await _recordOperation(session, 'schedule-uncertain:${event.id}');
        return _degradedResult(session, 'schedule-uncertain:${event.id}');
      }
      scheduledCount++;
    }

    var verified = await notifications.pendingNotificationRequests();
    var verifiedById = {
      for (final request in verified)
        if (PrayerNotificationEvent.isPrayerId(request.id)) request.id: request,
    };
    final missingOrInvalid = desired
        .where((event) {
          return !_matchesPending(event, verifiedById[event.id]);
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
      (event) => _matchesPending(event, verifiedById[event.id]),
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
      coverageUntilUtc: notificationCoverageUntilInstant,
      publishWidget: true,
    );
    await _persistSuccess(
      configuration.signature,
      desired,
      reason,
      coverageUntilInstant: notificationCoverageUntilInstant,
    );
    await _publishCommittedWidget(session, target, configuration.signature);
    return PrayerScheduleResult(
      status: scheduledCount == 0
          ? PrayerScheduleStatus.upToDate
          : PrayerScheduleStatus.scheduled,
      scheduledCount: scheduledCount,
      pendingCount: desired.length,
      coverageUntil: notificationCoverageUntil,
    );
  }

  Future<PrayerScheduleResult> _reconcileAndroidNative({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required PrayerScheduleConfiguration inputConfiguration,
    required TransactionalPrayerNotificationGateway gateway,
    required List<PrayerOccurrenceRecord> history,
    required String reason,
    required DateTime now,
  }) async {
    // Import durable native attempts while holding the existing file mutation lock.
    var cursor = 0;
    while (true) {
      final page = await gateway.deliveryHistory(cursor);
      for (final record in page.records) {
        history = _upsertHistory(
          history,
          PrayerOccurrenceRecord(
            occurrenceId: record.id,
            scheduledInstantUtc: DateTime.fromMillisecondsSinceEpoch(
              record.utcMillis,
              isUtc: true,
            ),
            locationRevision: record.locationRevision,
            scheduleRevision: record.scheduleRevision,
            disposition: record.outcome == 'displayed'
                ? PrayerOccurrenceDisposition.confirmedDelivered
                : PrayerOccurrenceDisposition.automaticAttempt,
            recordedAtUtc: DateTime.fromMillisecondsSinceEpoch(
              record.receivedMillis,
              isUtc: true,
            ),
          ),
          now,
        );
      }
      cursor = page.nextCursor;
      if (page.records.length < 1000) break;
    }
    await session.save(session.state.copyWith(occurrenceHistory: history));
    await gateway.acknowledgeHistory(cursor);
    var state = await gateway.executionSnapshot();
    var activateTarget = activatesCandidate;
    final interrupted = session.state.journal;
    final accepted = state.plan;
    if (interrupted != null &&
        accepted != null &&
        accepted.locationRevision == target.revision &&
        accepted.scheduleRevision == interrupted.scheduleRevision &&
        accepted.eventDigest == interrupted.desiredEventDigest &&
        accepted.configurationDigest ==
            sha256
                .convert(utf8.encode(interrupted.configurationSignature))
                .toString() &&
        (accepted.state == 'activated' || accepted.state == 'finalized')) {
      // Native activation is an execution fact even if the Dart commit/reply was interrupted.
      await _commit(
        session: session,
        target: target,
        activatesCandidate: activateTarget,
        scheduleRevision: interrupted.scheduleRevision,
        configurationSignature: interrupted.configurationSignature,
        digest: interrupted.desiredEventDigest,
        events: interrupted.desiredEvents,
        history: history,
        activatedAt: now,
        publishWidget: true,
        fallbackConfiguration: interrupted.configuration,
      );
      if (accepted.state != 'finalized' && interrupted.configuration != null) {
        await gateway.finalizeNativePlan(
          accepted,
          interrupted.configuration!,
          interrupted.desiredEventDigest,
          _androidPrayerLabels(interrupted.configuration!.localeCode),
        );
      }
      activateTarget = false;
      state = await gateway.executionSnapshot();
    }
    final committed = session.state.committedConfiguration;
    final committedPlan = state.plan;
    if (session.state.journal == null &&
        committed != null &&
        committedPlan?.state == 'activated' &&
        committedPlan!.locationRevision ==
            session.state.activeLocation?.revision &&
        committedPlan.scheduleRevision == session.state.scheduleRevision &&
        committedPlan.eventDigest ==
            session.state.committedDesiredEventDigest &&
        committedPlan.configurationDigest ==
            sha256.convert(utf8.encode(committed.signature)).toString()) {
      // A failed CE write/reply after Dart commit must finish the same operation.
      await gateway.finalizeNativePlan(
        committedPlan,
        committed,
        session.state.committedDesiredEventDigest!,
        _androidPrayerLabels(committed.localeCode),
      );
      state = await gateway.executionSnapshot();
    }
    final policy = await gateway.acknowledgedPolicy();
    final capability = await gateway.schedulingCapabilitySignature();
    final configuration = PrayerScheduleConfiguration(
      location: target,
      deviceTimeZoneId: await gateway.refreshTimeZone(),
      methodToken: inputConfiguration.methodToken,
      madhabToken: inputConfiguration.madhabToken,
      highLatitudeRuleToken: inputConfiguration.highLatitudeRuleToken,
      customAngles: inputConfiguration.customAngles,
      offsets: inputConfiguration.offsets,
      localeCode: inputConfiguration.localeCode,
      schedulingCapability: capability,
      androidEnabledPrayers: policy.enabledPrayers,
    );
    final allPending = await notifications.pendingNotificationRequests();
    // Reminders before prayers have their own native reservation.
    final standardCount = allPending
        .where(
          (request) =>
              !PrayerNotificationEvent.isPrayerId(request.id) &&
              !NotificationIds.isPrayerAdvance(request.id),
        )
        .length;
    final budget = await gateway.reserveQuota(standardCount);
    if (budget == 0 && policy.enabledPrayers.isNotEmpty) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        message: 'No prayer alarm capacity is available.',
      );
    }
    final provisional = PrayerNotificationPlanner(cacheHelper)
        .buildFromConfiguration(
          now: now,
          maxEvents: math.max(budget, 1),
          horizon: capacityPolicy.prayerHorizon,
          configuration: configuration,
        );
    if (provisional == null) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.locationUnavailable,
      );
    }
    final suppressed = history.map((record) => record.occurrenceId).toSet();
    var desired = provisional.events
        .where((event) => !suppressed.contains(event.id))
        .take(budget)
        .toList();
    final digest = _digest(target.revision, configuration.signature, desired);
    final configurationDigest = sha256
        .convert(utf8.encode(configuration.signature))
        .toString();
    final installed = {
      for (final registration in state.pending)
        if (PrayerNotificationEvent.isPrayerId(registration.event.id))
          registration.event.id: registration,
    };
    final plan = state.plan;
    if (plan != null &&
        plan.state == 'finalized' &&
        plan.configurationDigest == configurationDigest &&
        plan.locationRevision == target.revision &&
        installed.length == desired.length &&
        desired.every(
          (event) =>
              installed[event.id]?.event.utcMillis ==
                  event.scheduledInstantUtc.millisecondsSinceEpoch &&
              installed[event.id]?.outcome == 'registered',
        ) &&
        !activateTarget) {
      // Adopt native coverage extensions with their accepted source revision.
      desired = desired
          .map(
            (event) => event.copyWith(scheduleRevision: plan.scheduleRevision),
          )
          .toList();
      await _commit(
        session: session,
        target: target,
        activatesCandidate: false,
        scheduleRevision: plan.scheduleRevision,
        configurationSignature: configuration.signature,
        digest: digest,
        events: desired,
        history: history,
        activatedAt: now,
        publishWidget: true,
        fallbackConfiguration: configuration,
      );
      await _persistSuccess(configuration.signature, desired, reason);
      await _publishCommittedWidget(session, target, configuration.signature);
      return PrayerScheduleResult(
        status: state.capabilities.notifications
            ? state.capabilities.exactAlarms
                  ? PrayerScheduleStatus.upToDate
                  : PrayerScheduleStatus.degraded
            : PrayerScheduleStatus.permissionDenied,
        pendingCount: desired.length,
        coverageUntil: desired.isEmpty
            ? null
            : desired.last.scheduledInstantUtc,
      );
    }
    final existing = session.state.journal;
    final resumes =
        existing?.desiredEventDigest == digest &&
        existing?.configurationSignature == configuration.signature;
    final revision = resumes
        ? existing!.scheduleRevision
        : _nextScheduleRevision(
            math.max(
              _highestKnownScheduleRevision(session.state),
              plan?.scheduleRevision ?? 0,
            ),
          );
    desired = desired
        .map((event) => event.copyWith(scheduleRevision: revision))
        .toList();
    final journal = PrayerScheduleJournal(
      configuration: configuration,
      candidateLocationRevision: target.revision,
      previousLocationRevision: session.state.activeLocation?.revision,
      scheduleRevision: revision,
      configurationSignature: configuration.signature,
      cutoverInstantUtc: now,
      phase: PrayerReconciliationPhase.preparing,
      desiredEvents: desired,
      desiredEventDigest: digest,
      attemptCount: resumes ? existing!.attemptCount + 1 : 1,
    );
    await session.save(
      session.state.copyWith(journal: journal, occurrenceHistory: history),
    );
    final operationId =
        'dart-${target.revision}-$revision-${digest.substring(0, 24)}';
    final expectedGeneration = state.plan?.generation ?? 0;
    try {
      final prepared = await gateway.prepareNativePlan(
        operationId: operationId,
        expectedGeneration: expectedGeneration,
        policy: policy,
        configuration: configuration,
        scheduleRevision: revision,
        eventDigest: digest,
        events: desired,
        history: history,
        quota: budget,
      );
      final acceptedReceipt =
          prepared.state == 'activated' || prepared.state == 'finalized'
          ? prepared
          : await gateway.activateNativePlan(operationId, expectedGeneration);
      await _commit(
        session: session,
        target: target,
        activatesCandidate: activateTarget,
        scheduleRevision: revision,
        configurationSignature: configuration.signature,
        digest: digest,
        events: desired,
        history: history,
        activatedAt: _now().toUtc(),
        publishWidget: true,
        fallbackConfiguration: configuration,
      );
      if (acceptedReceipt.state != 'finalized') {
        await gateway.finalizeNativePlan(
          acceptedReceipt,
          configuration,
          digest,
          _androidPrayerLabels(configuration.localeCode),
        );
      }
      await _persistSuccess(configuration.signature, desired, reason);
      await _publishCommittedWidget(session, target, configuration.signature);
      final capabilities = (await gateway.executionSnapshot()).capabilities;
      return PrayerScheduleResult(
        status: !capabilities.notifications
            ? PrayerScheduleStatus.permissionDenied
            : capabilities.exactAlarms
            ? PrayerScheduleStatus.scheduled
            : PrayerScheduleStatus.degraded,
        scheduledCount: desired.length,
        pendingCount: desired.length,
        coverageUntil: desired.isEmpty
            ? null
            : desired.last.scheduledInstantUtc,
        message: capabilities.exactAlarms ? null : 'inexactNotificationOnly',
      );
    } on PlatformException catch (error) {
      await _markDegraded(session, error.code);
      return PrayerScheduleResult(
        status: error.code == 'deadlineProtected'
            ? PrayerScheduleStatus.deferred
            : PrayerScheduleStatus.degraded,
        pendingCount: installed.length,
        coverageUntil: state.plan?.coverageUtcMillis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                state.plan!.coverageUtcMillis!,
                isUtc: true,
              ),
        message: error.code,
      );
    }
  }

  Map<String, Object?> _androidPrayerLabels(String localeCode) {
    AppLocalizations l10n;
    try {
      l10n = lookupAppLocalizations(Locale(localeCode));
    } catch (_) {
      l10n = lookupAppLocalizations(const Locale('en'));
    }
    final names = {
      'fajr': l10n.fajr,
      'dhuhr': l10n.dhuhr,
      'asr': l10n.asr,
      'maghrib': l10n.maghrib,
      'isha': l10n.isha,
    };
    return {
      for (final entry in names.entries)
        entry.key: {
          'title': l10n.notificationPrayerTimeTitle(entry.value),
          'body': l10n.notificationPrayerTimeBody(entry.value),
        },
    };
  }

  Future<PrayerScheduleResult> _reconcileIOSNative({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required PrayerScheduleConfiguration configuration,
    required List<PrayerOccurrenceRecord> history,
    required String reason,
    required DateTime now,
    bool rebasedNativeCandidate = false,
  }) async {
    final gateway =
        iosGateway ??
        IOSPrayerNotificationGateway(
          cache: cacheHelper,
          retirement: pushSynchronizer is PrayerPushRetirer
              ? pushSynchronizer as PrayerPushRetirer
              : PrayerPushService(cacheHelper: cacheHelper),
        );
    final receipt = await gateway.apply(
      configuration,
      legacyRevision: _highestKnownScheduleRevision(session.state),
      locationRevisionFloor: session.state.revisionCounter,
    );
    if (!receipt.ownsSchedule) {
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.deferred,
        pendingCount: receipt.notificationCount,
        coverageUntil: session.state.acknowledgedCoverageUntilUtc,
        message: 'migrationPending',
      );
    }
    final acceptedConfiguration = receipt.schedule ?? configuration;
    final nativeLocation = acceptedConfiguration.location;
    var acceptedTarget = target;
    var acceptsCandidate = activatesCandidate;
    final adoptNative = nativeLocation.revision > target.revision;
    if (adoptNative) {
      if (!await session.stageNativeIOSCandidate(acceptedConfiguration)) {
        throw StateError('Invalid native iOS location generation.');
      }
      acceptedTarget = nativeLocation;
      acceptsCandidate = true;
    }
    final signature =
        '${receipt.configurationSignature}|ios:${receipt.revision}:${receipt.policyRevision}';
    final events = gateway
        .acknowledgedEvents(receipt)
        .map(
          (event) => event.copyWith(
            locationRevision: acceptedTarget.revision,
            scheduleRevision: receipt.revision,
            configurationSignature: signature,
          ),
        )
        .toList(growable: false);
    await _commit(
      session: session,
      target: acceptedTarget,
      activatesCandidate: acceptsCandidate,
      scheduleRevision: receipt.revision,
      configurationSignature: signature,
      digest: _digest(acceptedTarget.revision, signature, events),
      events: events,
      history: history,
      activatedAt: now,
      publishWidget: true,
      coverageUntilUtc: receipt.coverageUntil,
      fallbackConfiguration: acceptedConfiguration,
    );
    await _persistSuccess(signature, events, reason);
    await _publishCommittedWidget(session, acceptedTarget, signature);
    // A new explicit choice made while the app had an older native snapshot
    // wins after rebasing above the accepted background generation.
    if (adoptNative &&
        activatesCandidate &&
        !rebasedNativeCandidate &&
        target.capturedAtUtc.isAfter(nativeLocation.capturedAtUtc)) {
      final revision = await session.beginIntent(
        target.mode,
        allowModeChange: true,
      );
      if (revision != null) {
        final rebased = target.copyWith(revision: revision);
        if (await session.stageCandidate(rebased)) {
          return _reconcileIOSNative(
            session: session,
            target: rebased,
            activatesCandidate: true,
            configuration: configuration.forLocation(rebased),
            history: history,
            reason: reason,
            now: now,
            rebasedNativeCandidate: true,
          );
        }
      }
    }
    final permissionDenied =
        receipt.experience.enabled &&
        !receipt.notificationsAllowed &&
        receipt.policies.values.any((policy) => policy['desired'] != 'off') &&
        receipt.policies.values.every((policy) => policy['effective'] == 'off');
    return PrayerScheduleResult(
      status: permissionDenied
          ? PrayerScheduleStatus.permissionDenied
          : receipt.error != null
          ? PrayerScheduleStatus.degraded
          : PrayerScheduleStatus.scheduled,
      scheduledCount: events.length,
      pendingCount: receipt.notificationCount + receipt.alarmCount,
      coverageUntil: receipt.coverageUntil,
      message: receipt.error,
    );
  }

  Future<PrayerScheduleResult> _reconcileMacNative({
    required PrayerLocationRepositorySession session,
    required PrayerLocationGeneration target,
    required bool activatesCandidate,
    required PrayerScheduleConfiguration configuration,
    required List<PrayerOccurrenceRecord> history,
    required String reason,
    required DateTime now,
  }) async {
    final gateway = macGateway ?? MacPrayerNotificationGateway();
    final receipt = await gateway.apply(configuration);
    final signature = '${configuration.signature}|mac:${receipt.revision}';
    // Native readback can retain an imminent occurrence's captured policy and
    // revision across publication. Shared storage acknowledges the current
    // generation while preserving the actual OS identity and delivery instant.
    final events = gateway
        .acknowledgedEvents(receipt)
        .map(
          (event) => event.copyWith(
            locationRevision: target.revision,
            scheduleRevision: receipt.revision,
            configurationSignature: signature,
          ),
        )
        .toList(growable: false);
    // A location is committed only after native publication is acknowledged.
    // Queue failure remains distinct from valid calculation/service readiness.
    await _commit(
      session: session,
      target: target,
      activatesCandidate: activatesCandidate,
      scheduleRevision: receipt.revision,
      configurationSignature: signature,
      digest: _digest(target.revision, signature, events),
      events: events,
      history: history,
      activatedAt: now,
      publishWidget: true,
      coverageUntilUtc: receipt.coverageUntil,
      fallbackConfiguration: configuration,
    );
    await _persistSuccess(signature, events, reason);
    await _publishCommittedWidget(session, target, signature);
    return PrayerScheduleResult(
      status: receipt.error != null
          ? PrayerScheduleStatus.degraded
          : !receipt.experience.enabled
          ? PrayerScheduleStatus.upToDate
          : receipt.authorization != 'authorized' &&
                receipt.authorization != 'provisional'
          ? PrayerScheduleStatus.permissionDenied
          : PrayerScheduleStatus.scheduled,
      scheduledCount: events.length,
      pendingCount: receipt.pendingCount,
      coverageUntil: receipt.coverageUntil,
      message: receipt.error,
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
      configuration: configuration,
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
    bool applied;
    if (configuration.linuxExperience?.configured == true) {
      final receipt = await LinuxPrayerNotificationGateway.reconcile(
        configuration,
        scheduleRevision: revision,
        cutover: journal.cutoverInstantUtc,
        handledOccurrences: history.map((record) => record.occurrenceId),
      );
      applied =
          receipt.deliveryOwner == 'native' &&
          receipt.values['locationRevision'] == target.revision &&
          receipt.values['scheduleRevision'] == revision &&
          receipt.values['configurationSignature'] == configuration.signature;
    } else {
      applied = await linuxScheduler.apply(
        PrayerNotificationPlan(
          events: events,
          configurationSignature: configuration.signature,
          requestedThrough: now.add(capacityPolicy.prayerHorizon),
          locationRevision: target.revision,
          scheduleRevision: revision,
        ),
      );
    }
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
    required bool allowRemoteRevisionRetry,
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
      final rebasedForRetry = await _rebaseJournalAboveServerRevision(
        session,
        remote.acceptedScheduleRevision,
        'remote-disable-${remote.status.name}',
        acceptedLocationRevision: remote.acceptedLocationRevision,
        candidateLocationRevision: target.revision,
      );
      if (rebasedForRetry && allowRemoteRevisionRetry) {
        return _reconcileLocked(
          session: session,
          target: target,
          activatesCandidate: activatesCandidate,
          reason: reason,
          allowRemoteRevisionRetry: false,
        );
      }
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
    DateTime? coverageUntilUtc,
    PrayerScheduleConfiguration? fallbackConfiguration,
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
        configuration:
            current.journal?.configurationSignature == configurationSignature
            ? current.journal?.configuration ?? fallbackConfiguration
            : fallbackConfiguration,
        coverageUntilUtc:
            coverageUntilUtc ??
            (events.isEmpty ? null : events.last.scheduledInstantUtc),
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
        configuration:
            current.journal?.configurationSignature == configurationSignature
            ? current.journal?.configuration ?? fallbackConfiguration
            : fallbackConfiguration,
        coverageUntilUtc:
            coverageUntilUtc ??
            (events.isEmpty ? null : events.last.scheduledInstantUtc),
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
      await session.repairProjections();
      if (deferWidgetPublication) return;
      await widgetPublisher(
        generation: state.activeLocation ?? target,
        scheduleRevision: state.scheduleRevision,
        publicationRevision: state.widgetPublicationRevision,
        configurationSignature: configurationSignature,
      );
      await session.markWidgetPublished(state.widgetPublicationRevision);
    } catch (error) {
      final issues = {
        ...session.state.workflowIssues,
        PrayerWorkflowIssue.widget,
      };
      await session.save(session.state.copyWith(workflowIssues: issues));
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
        await notifications.cancelNotifications([id]);
      } catch (_) {
        await _recordOperation(session, 'cancel-uncertain:$id');
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

  Future<DateTime?> _bridgeLocalAlerts({
    required PrayerLocationRepositorySession session,
    required List<PrayerNotificationEvent> desired,
    required Map<int, PendingNotification> pendingById,
    required int pendingCount,
    required bool allowExact,
  }) async {
    final until = _localOnlyUntil(session.state);
    var freeSlots = math.max(
      0,
      capacityPolicy.totalPendingLimit - pendingCount,
    );
    DateTime? through;
    for (final event in desired) {
      if (until != null && event.scheduledInstantUtc.isAfter(until)) break;
      if (!event.scheduledInstantUtc.isAfter(_now().toUtc())) continue;
      final pending = pendingById[event.id];
      if (!_matchesPending(event, pending)) {
        if (pending == null) {
          if (freeSlots == 0) break;
          freeSlots--;
        }
        try {
          if (!await notifications.schedulePrayerEvent(
            event,
            allowExact: allowExact,
          )) {
            break;
          }
        } catch (_) {
          await _recordOperation(session, 'bridge-uncertain:${event.id}');
          break;
        }
      }
      through = event.scheduledInstantUtc;
    }
    return through;
  }

  DateTime? _localOnlyUntil(PrayerReliabilityState state) {
    final acknowledgement = state.remoteOwnershipAcknowledgement;
    DateTime? limit;
    if (acknowledgement == null) {
      if (state.scheduleRevision > 0 || state.committedEvents.isNotEmpty) {
        limit = PrayerScheduleJournal.serverOwnsAll;
      }
    } else if (acknowledgement.enabled) {
      limit =
          acknowledgement.localCoverageUntilUtc ??
          PrayerScheduleJournal.serverOwnsAll;
    }
    return _earlier(limit, state.journal?.remoteOwnershipFloorUtc);
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  Future<bool> _rebaseJournalAboveServerRevision(
    PrayerLocationRepositorySession session,
    int? acceptedScheduleRevision,
    String category, {
    int? acceptedLocationRevision,
    required int candidateLocationRevision,
  }) async {
    final journal = session.state.journal;
    if (journal == null) return false;
    if ((acceptedLocationRevision != null &&
            (acceptedLocationRevision < 0 ||
                acceptedLocationRevision >
                    PrayerLocationGeneration.maxSafeRevision)) ||
        (acceptedScheduleRevision != null &&
            (acceptedScheduleRevision < 0 ||
                acceptedScheduleRevision >
                    PrayerLocationGeneration.maxSafeRevision))) {
      await _markDegraded(session, '$category-invalid-server-revision');
      return false;
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
      return false;
    }
    if (acceptedScheduleRevision == null ||
        acceptedScheduleRevision < journal.scheduleRevision) {
      return false;
    }
    if (acceptedScheduleRevision >= PrayerLocationGeneration.maxSafeRevision) {
      await _markDegraded(session, '$category-revision-space-exhausted');
      return false;
    }
    final rebasedRevision = acceptedScheduleRevision + 1;
    final rebasedEvents = journal.desiredEvents
        .map((event) => event.copyWith(scheduleRevision: rebasedRevision))
        .toList(growable: false);
    await session.save(
      session.state.copyWith(
        journal: PrayerScheduleJournal(
          configuration: journal.configuration,
          candidateLocationRevision: journal.candidateLocationRevision,
          previousLocationRevision: journal.previousLocationRevision,
          scheduleRevision: rebasedRevision,
          configurationSignature: journal.configurationSignature,
          cutoverInstantUtc: _now().toUtc(),
          phase: PrayerReconciliationPhase.degraded,
          desiredEvents: List.unmodifiable(rebasedEvents),
          desiredEventDigest: journal.desiredEventDigest,
          remoteOwnershipFloorUtc: journal.remoteOwnershipFloorUtc,
          completedOrUncertainOperations: const [],
          attemptCount: journal.attemptCount,
          lastErrorCategory: '$category-server-newer-rebased',
        ),
      ),
    );
    return true;
  }

  Future<PrayerScheduleResult> _degradedResult(
    PrayerLocationRepositorySession session,
    String category,
  ) async {
    await _markDegraded(session, category);
    return PrayerScheduleResult(
      status: PrayerScheduleStatus.degraded,
      coverageUntil: session.state.acknowledgedCoverageUntilUtc,
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

  DateTime? _notificationCoverageUntil({
    required PrayerLocationGeneration target,
    required List<PrayerNotificationEvent> localEvents,
    required PrayerPushSyncResult remote,
  }) {
    final remoteCoverage = remote.scheduledThroughUtc;
    if (capacityPolicy.platform == HudaNotificationPlatform.ios &&
        remoteCoverage != null) {
      return PrayerTimeZoneService.wallClockAtInstant(
        remoteCoverage,
        target.timeZoneId,
      );
    }
    return localEvents.isEmpty ? null : localEvents.last.scheduledTime;
  }

  DateTime? _notificationCoverageUntilInstant({
    required List<PrayerNotificationEvent> localEvents,
    required PrayerPushSyncResult remote,
  }) {
    if (capacityPolicy.platform == HudaNotificationPlatform.ios &&
        remote.scheduledThroughUtc != null) {
      return remote.scheduledThroughUtc;
    }
    return localEvents.isEmpty ? null : localEvents.last.scheduledInstantUtc;
  }

  Future<void> _persistSuccess(
    String signature,
    List<PrayerNotificationEvent> retainedEvents,
    String reason, {
    DateTime? coverageUntilInstant,
  }) async {
    final coverage =
        (coverageUntilInstant ??
                (retainedEvents.isEmpty
                    ? null
                    : retainedEvents.last.scheduledInstantUtc))
            ?.toUtc()
            .toIso8601String();
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
