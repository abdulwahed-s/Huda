import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/linux_prayer_notification_scheduler.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_planner.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:synchronized/synchronized.dart';

class PrayerNotificationScheduler {
  PrayerNotificationScheduler({
    required this.cacheHelper,
    NotificationServices? notifications,
    NotificationCapacityPolicy? capacityPolicy,
    LinuxPrayerNotificationScheduler? linuxScheduler,
    PrayerPushSynchronizer? pushSynchronizer,
    DateTime Function()? now,
  })  : notifications = notifications ?? NotificationServices(),
        capacityPolicy = capacityPolicy ?? NotificationCapacityPolicy.current,
        linuxScheduler = linuxScheduler ?? LinuxPrayerNotificationScheduler(),
        pushSynchronizer = pushSynchronizer ??
            PrayerPushService(cacheHelper: cacheHelper, now: now),
        _now = now ?? DateTime.now;

  static const signatureKey = 'prayer_notification_plan_signature';
  static const coverageKey = 'prayer_notification_coverage_until';
  static const lastSuccessKey = 'prayer_notification_last_success';
  static const lastReasonKey = 'prayer_notification_last_reason';
  static const pendingCountKey = 'prayer_notification_pending_count';
  static const eventIdsKey = 'prayer_notification_event_ids';

  static final Lock _lock = Lock();

  final CacheHelper cacheHelper;
  final NotificationServices notifications;
  final NotificationCapacityPolicy capacityPolicy;
  final LinuxPrayerNotificationScheduler linuxScheduler;
  final PrayerPushSynchronizer pushSynchronizer;
  final DateTime Function() _now;

  Future<PrayerScheduleResult> reconcile({
    String reason = 'unspecified',
    bool force = false,
  }) {
    return _lock.synchronized(() => _reconcile(reason: reason, force: force));
  }

  Future<PrayerScheduleResult> _reconcile({
    required String reason,
    required bool force,
  }) async {
    if (capacityPolicy.platform == HudaNotificationPlatform.web ||
        capacityPolicy.platform == HudaNotificationPlatform.unsupported) {
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.unsupported,
        message: 'Scheduled prayer notifications are unavailable.',
      );
    }

    if (PrayerTimesCalculator.coordinatesFromCache(cacheHelper) == null) {
      await _disableRemoteFallback('location-unavailable');
      return const PrayerScheduleResult(
        status: PrayerScheduleStatus.locationUnavailable,
        message: 'A prayer location is required before scheduling.',
      );
    }

    try {
      await notifications.initialize();
      final planner = PrayerNotificationPlanner(cacheHelper);
      final now = _now();

      if (capacityPolicy.platform == HudaNotificationPlatform.linux) {
        final plan = planner.build(
          now: now,
          maxEvents: capacityPolicy.prayerPendingLimit,
          horizon: capacityPolicy.prayerHorizon,
          timeZoneName: notifications.timeZoneName,
        );
        if (plan == null) {
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.locationUnavailable,
          );
        }
        final installed = await linuxScheduler.apply(plan);
        if (!installed) {
          return const PrayerScheduleResult(
            status: PrayerScheduleStatus.failed,
            message: 'The Linux notification user service could not start.',
          );
        }
        await _persistSuccess(plan, plan.events, reason);
        return PrayerScheduleResult(
          status: PrayerScheduleStatus.scheduled,
          scheduledCount: plan.events.length,
          pendingCount: plan.events.length,
          coverageUntil: plan.coverageUntil,
        );
      }

      if (!await notifications.areNotificationsAllowed()) {
        await _disableRemoteFallback('notification-permission-denied');
        return const PrayerScheduleResult(
          status: PrayerScheduleStatus.permissionDenied,
          message: 'Notification permission is disabled.',
        );
      }

      var allPending = await notifications.pendingNotificationRequests();
      await _trimRandomAthkar(allPending.map((item) => item.id));
      allPending = await notifications.pendingNotificationRequests();

      final prayerPendingIds = allPending
          .map((request) => request.id)
          .where(PrayerNotificationEvent.isPrayerId)
          .toSet();
      final otherPendingCount = allPending.length - prayerPendingIds.length;
      final available = math.max(
        0,
        math.min(
          capacityPolicy.prayerPendingLimit,
          capacityPolicy.totalPendingLimit - otherPendingCount,
        ),
      );

      final plan = planner.build(
        now: now,
        maxEvents: available,
        horizon: capacityPolicy.prayerHorizon,
        timeZoneName: notifications.timeZoneName,
      );
      if (plan == null) {
        await _syncRemoteFallback(
          retainedEvents: const [],
          timeZoneName: notifications.timeZoneName,
          reason: '$reason-no-local-capacity',
        );
        return const PrayerScheduleResult(
          status: PrayerScheduleStatus.failed,
          message: 'No notification capacity is currently available.',
        );
      }

      final desiredById = {
        for (final event in plan.events) event.id: event,
      };
      final desiredIds = desiredById.keys.toSet();
      final signatureChanged = cacheHelper.getDataString(key: signatureKey) !=
          plan.configurationSignature;
      final requiresFullRefresh = force || signatureChanged;

      final staleIds = prayerPendingIds.difference(desiredIds);
      if (staleIds.isNotEmpty) {
        await notifications.cancelNotifications(staleIds);
        prayerPendingIds.removeAll(staleIds);
      }

      final toSchedule = requiresFullRefresh
          ? plan.events
          : plan.events
              .where((event) => !prayerPendingIds.contains(event.id))
              .toList(growable: false);
      final scheduledIds = <int>{};
      for (var start = 0; start < toSchedule.length; start += 20) {
        final end = math.min(start + 20, toSchedule.length);
        final batch = toSchedule.sublist(start, end);
        final results = await Future.wait(
          batch.map(notifications.schedulePrayerEvent),
        );
        for (var index = 0; index < batch.length; index++) {
          if (results[index]) scheduledIds.add(batch[index].id);
        }
      }

      final verifiedPending = await notifications.pendingNotificationRequests();
      final verifiedIds = verifiedPending
          .map((request) => request.id)
          .where(desiredIds.contains)
          .toSet();
      final verifiedEvents = plan.events
          .where((event) => verifiedIds.contains(event.id))
          .toList(growable: false);

      final everyScheduleCallSucceeded =
          scheduledIds.length == toSchedule.length;
      final osRetainedCompletePlan = verifiedIds.length == desiredIds.length;
      if (!everyScheduleCallSucceeded || !osRetainedCompletePlan) {
        final contiguousEvents = <PrayerNotificationEvent>[];
        for (final event in plan.events) {
          if (!verifiedIds.contains(event.id)) break;
          contiguousEvents.add(event);
        }
        final contiguousIds = contiguousEvents.map((event) => event.id).toSet();
        final nonContiguousIds = verifiedIds.difference(contiguousIds);
        if (nonContiguousIds.isNotEmpty) {
          await notifications.cancelNotifications(nonContiguousIds);
        }
        await _syncRemoteFallback(
          retainedEvents: contiguousEvents,
          timeZoneName: notifications.timeZoneName,
          reason: '$reason-partial-local-coverage',
        );
        return PrayerScheduleResult(
          status: PrayerScheduleStatus.failed,
          scheduledCount: scheduledIds.length,
          pendingCount: contiguousEvents.length,
          coverageUntil: contiguousEvents.isEmpty
              ? null
              : contiguousEvents.last.scheduledTime,
          message: requiresFullRefresh
              ? 'The refreshed prayer plan was only partially retained.'
              : 'The operating system did not retain the complete prayer plan.',
        );
      }

      await _persistSuccess(plan, verifiedEvents, reason);
      await _syncRemoteFallback(
        retainedEvents: verifiedEvents,
        timeZoneName: notifications.timeZoneName,
        reason: reason,
      );
      final status = scheduledIds.isEmpty
          ? PrayerScheduleStatus.upToDate
          : PrayerScheduleStatus.scheduled;
      return PrayerScheduleResult(
        status: status,
        scheduledCount: scheduledIds.length,
        pendingCount: verifiedEvents.length,
        coverageUntil:
            verifiedEvents.isEmpty ? null : verifiedEvents.last.scheduledTime,
      );
    } catch (error, stackTrace) {
      debugPrint('Prayer notification reconciliation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return PrayerScheduleResult(
        status: PrayerScheduleStatus.failed,
        message: error.toString(),
      );
    }
  }

  Future<void> _trimRandomAthkar(Iterable<int> pendingIds) async {
    final ids = pendingIds
        .where((id) => id >= 1100 && id < 1550)
        .toList(growable: false)
      ..sort();
    if (ids.length <= capacityPolicy.randomAthkarLimit) return;
    await notifications.cancelNotifications(
      ids.skip(capacityPolicy.randomAthkarLimit),
    );
  }

  Future<void> _syncRemoteFallback({
    required List<PrayerNotificationEvent> retainedEvents,
    required String timeZoneName,
    required String reason,
  }) async {
    try {
      await pushSynchronizer.syncFallback(
        localCoverageUntil:
            retainedEvents.isEmpty ? null : retainedEvents.last.scheduledTime,
        timeZoneName: timeZoneName,
        reason: reason,
      );
    } catch (error) {
      debugPrint('Prayer push fallback sync failed: $error');
    }
  }

  Future<void> _disableRemoteFallback(String reason) async {
    try {
      await pushSynchronizer.disable(reason: reason);
    } catch (error) {
      debugPrint('Prayer push fallback disable failed: $error');
    }
  }

  Future<void> _persistSuccess(
    PrayerNotificationPlan plan,
    List<PrayerNotificationEvent> retainedEvents,
    String reason,
  ) async {
    final coverage = retainedEvents.isEmpty
        ? null
        : retainedEvents.last.scheduledTime.toIso8601String();
    await cacheHelper.saveData(
      key: signatureKey,
      value: plan.configurationSignature,
    );
    if (coverage == null) {
      await cacheHelper.removeData(key: coverageKey);
    } else {
      await cacheHelper.saveData(key: coverageKey, value: coverage);
    }
    await cacheHelper.saveData(
      key: lastSuccessKey,
      value: _now().toIso8601String(),
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
  }
}
