import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda_notifications/huda_notifications.dart';
import 'package:huda/core/notifications/pending_notification.dart';

class AndroidPrayerNotificationGateway
    implements TransactionalPrayerNotificationGateway {
  AndroidPrayerNotificationGateway({PrayerHostApi? api})
    : api = api ?? PrayerHostApi();
  final PrayerHostApi api;
  RuntimeSnapshot? snapshot;
  String _timeZoneName = 'UTC';

  /// Prayers that Huda 4.3.0 and earlier scheduled through
  /// flutter_local_notifications and the native package still holds. They move
  /// to native plans and are then cancelled there.
  Future<List<EventData>> _legacyPrayers() async => [
    for (final event in await api.getLegacyNotifications())
      if (PrayerNotificationEvent.isPrayerId(event.id) &&
          event.prayer != 'standard')
        event,
  ];

  Future<void> _cancelLegacy(List<int> ids) async {
    if (ids.isNotEmpty) await api.cancelLegacyNotifications(ids);
  }

  @override
  Future<void> initialize() async {
    final result = await api.initialize(
      HudaPrayerNotifications.contractVersion,
    );
    if (result.contractVersion != HudaPrayerNotifications.contractVersion) {
      throw PlatformException(code: 'unsupportedContract');
    }
    snapshot = result;
    final preferences = await SharedPreferences.getInstance();
    final locale =
        preferences.getString('app_locale') ??
        preferences.getString('locale') ??
        'en';
    if (result.policy.values['localeCode'] != locale) {
      try {
        await api.setPolicy(
          PolicyData(
            schemaVersion: 1,
            revision: result.policy.revision,
            values: {...result.policy.values, 'localeCode': locale},
          ),
          result.policy.revision,
        );
        snapshot = await api.getSnapshot();
      } on PlatformException catch (error) {
        if (error.code != 'stalePolicy') rethrow;
        snapshot = await api.getSnapshot();
      }
    }
  }

  @override
  Future<bool> isEnabled() async {
    await initialize();
    return true;
  }

  @override
  Future<AndroidPrayerExperience> acknowledgedPolicy() async =>
      AndroidPrayerExperience.fromPolicy(await api.getPolicy());
  @override
  Future<RuntimeSnapshot> executionSnapshot() async =>
      snapshot = await api.getSnapshot();
  @override
  Future<String> refreshTimeZone() async =>
      _timeZoneName = await PrayerTimeZoneService.refreshLocalTimeZone();
  @override
  String get timeZoneName => _timeZoneName;
  @override
  Future<bool> areNotificationsAllowed() async =>
      (await api.getCapabilities()).notifications;
  @override
  Future<bool> canScheduleExactNotifications() async =>
      (await api.getCapabilities()).exactAlarms;
  @override
  Future<String> schedulingCapabilitySignature() async {
    final state = await executionSnapshot();
    final policy = AndroidPrayerExperience.fromPolicy(state.policy);
    return 'android-native-v1:${state.epoch}:${state.capabilities.exactAlarms ? 'exact' : 'inexact'}:${policy.eligibilitySignature}';
  }

  @override
  Future<int> reserveQuota(int standardPluginAlarmCount) async {
    final legacy = await api.getLegacyNotifications();
    final actualStandard = legacy
        .where(
          (event) =>
              !PrayerNotificationEvent.isPrayerId(event.id) ||
              event.prayer == 'standard',
        )
        .length;
    return api.updateQuota(
      QuotaData(
        standardCount: actualStandard > standardPluginAlarmCount
            ? actualStandard
            : standardPluginAlarmCount,
        sahurReservation: 30,
        widgetReservation: 8,
        auxiliaryReservation: 4,
        migrationReservation: 1,
      ),
    );
  }

  @override
  Future<HistoryPage> deliveryHistory(int afterCursor) =>
      api.getDeliveryHistory(afterCursor, 1000);
  @override
  Future<void> acknowledgeHistory(int cursor) => api.acknowledgeHistory(cursor);

  EventData _event(PrayerNotificationEvent event) => EventData(
    id: event.id,
    prayer: event.prayer.name,
    utcMillis: event.scheduledInstantUtc.millisecondsSinceEpoch,
    timeZone: event.timeZoneName,
    localDate:
        '${event.scheduledTime.year.toString().padLeft(4, '0')}-${event.scheduledTime.month.toString().padLeft(2, '0')}-${event.scheduledTime.day.toString().padLeft(2, '0')}',
    title: event.title,
    body: event.body,
    compatiblePayload: event.payload,
  );

  @override
  Future<PlanReceipt> prepareNativePlan({
    required String operationId,
    required int expectedGeneration,
    required AndroidPrayerExperience policy,
    required PrayerScheduleConfiguration configuration,
    required int scheduleRevision,
    required String eventDigest,
    required List<PrayerNotificationEvent> events,
    required List<PrayerOccurrenceRecord> history,
    required int quota,
  }) async {
    final interrupted = (await executionSnapshot()).preparingPlan;
    if (interrupted != null && interrupted.legacyCleanupIds.isNotEmpty) {
      await _cancelLegacy(interrupted.legacyCleanupIds);
      await api.acknowledgeLegacyCleanup(
        interrupted.operationId,
        interrupted.legacyCleanupIds,
      );
    }
    final legacy = <EventData>[];
    final now = DateTime.now().toUtc();
    for (final old in await _legacyPrayers()) {
      final payload = PrayerNotificationPayload.tryParse(
        old.compatiblePayload,
      );
      if (payload == null || !payload.scheduledUtc.isAfter(now)) {
        // Ambiguous old registrations cannot coexist with a strict native cutover.
        // Never cancel a potentially due old callback blindly.
        if (payload == null) {
          if (old.utcMillis <= 0) {
            throw PlatformException(code: 'legacyMappingRequired');
          }
          final oldInstant = DateTime.fromMillisecondsSinceEpoch(
            old.utcMillis,
            isUtc: true,
          );
          if (oldInstant.isAfter(now) &&
              oldInstant.difference(now) <= const Duration(seconds: 120)) {
            throw PlatformException(code: 'deadlineProtected');
          }
          final matches = events
              .where(
                (event) =>
                    event.scheduledInstantUtc.millisecondsSinceEpoch ==
                    old.utcMillis,
              )
              .toList();
          if (matches.length == 1) {
            final mapped = _event(matches.single);
            mapped.id = old.id;
            legacy.add(mapped);
          } else {
            await api.suppressUnmappedLegacy([old.id]);
            await _cancelLegacy([old.id]);
          }
          continue;
        }
        await _cancelLegacy([old.id]);
        continue;
      }
      if (payload.scheduledUtc.difference(now) <=
          const Duration(seconds: 120)) {
        throw PlatformException(code: 'deadlineProtected');
      }
      legacy.add(
        EventData(
          id: old.id,
          prayer: payload.prayer.name,
          utcMillis: payload.scheduledUtc.millisecondsSinceEpoch,
          timeZone: payload.timeZoneName,
          localDate:
              '${payload.scheduledTime.year.toString().padLeft(4, '0')}-${payload.scheduledTime.month.toString().padLeft(2, '0')}-${payload.scheduledTime.day.toString().padLeft(2, '0')}',
          title: old.title,
          body: old.body,
          compatiblePayload: old.compatiblePayload,
        ),
      );
    }
    final request = PlanRequest(
      operationId: operationId,
      expectedGeneration: expectedGeneration,
      expectedPolicyRevision: policy.policyRevision,
      locationRevision: configuration.location.revision,
      scheduleRevision: scheduleRevision,
      configurationDigest: sha256
          .convert(utf8.encode(configuration.signature))
          .toString(),
      eventDigest: eventDigest,
      eligibilitySignature: policy.eligibilitySignature,
      quota: quota,
      events: events.map(_event).toList(),
      legacyEvents: legacy,
      suppressedHistory: history
          .map(
            (record) => DeliveryData(
              cursor: 0,
              id: record.occurrenceId,
              utcMillis: record.scheduledInstantUtc.millisecondsSinceEpoch,
              receivedMillis: record.recordedAtUtc.millisecondsSinceEpoch,
              locationRevision: record.locationRevision,
              scheduleRevision: record.scheduleRevision,
              backend: 'dart',
              outcome: 'attempted',
              reason: record.disposition.name,
            ),
          )
          .toList(),
    );
    var receipt = await api.getPlanReceipt(operationId);
    if (receipt?.state == 'activated' || receipt?.state == 'finalized') {
      final current = (await executionSnapshot()).plan;
      if (current?.operationId != operationId) throw PlatformException(code: 'stalePlan');
      return current!;
    }
    for (var transfer = 0; transfer <= events.length + 1; transfer++) {
      receipt = await api.preparePlan(request);
      if (receipt.legacyCleanupIds.isNotEmpty) {
        await _cancelLegacy(receipt.legacyCleanupIds);
        await api.acknowledgeLegacyCleanup(
          operationId,
          receipt.legacyCleanupIds,
        );
        continue;
      }
      if (receipt.state != 'prepared') {
        throw PlatformException(
          code: receipt.error ?? 'registrationIncomplete',
          details: receipt.operationId,
        );
      }
      _verifyReceipt(receipt, request);
      // Cleanup stale legacy prayers after claims/ownership guard is active.
      final nativeIds = events.map((event) => event.id).toSet();
      await _cancelLegacy([
        for (final event in legacy)
          if (!nativeIds.contains(event.id)) event.id,
      ]);
      return receipt;
    }
    throw PlatformException(code: 'migrationRecoveryRequired');
  }

  void _verifyReceipt(PlanReceipt receipt, PlanRequest request) {
    if (receipt.configurationDigest != request.configurationDigest ||
        receipt.eventDigest != request.eventDigest ||
        receipt.locationRevision != request.locationRevision ||
        receipt.scheduleRevision != request.scheduleRevision ||
        receipt.eligibilitySignature != request.eligibilitySignature ||
        receipt.quota != request.quota ||
        !request.events.every(
          (event) => receipt.registrations.any(
            (registration) =>
                registration.event.id == event.id &&
                registration.event.utcMillis == event.utcMillis &&
                registration.outcome == 'registered' &&
                ['exact', 'inexact'].contains(registration.precision),
          ),
        )) {
      throw PlatformException(code: 'registrationIncomplete');
    }
  }

  @override
  Future<PlanReceipt> activateNativePlan(
    String operationId,
    int expectedGeneration,
  ) => api.activatePlan(operationId, expectedGeneration);
  @override
  Future<PlanReceipt> finalizeNativePlan(
    PlanReceipt receipt,
    PrayerScheduleConfiguration configuration,
    String eventDigest,
    Map<String, Object?> localizedLabels,
  ) => api.finalizePlan(
    FinalizeRequest(
      operationId: receipt.operationId,
      generation: receipt.generation,
      configurationSignature: configuration.signature,
      configurationJson: jsonEncode({
        ...configuration.toJson(),
        'methodToken': PrayerTimesCalculator.resolveMethod(
          configuration.methodToken,
          configuration.location.countryCode ?? '',
        ).name,
        'androidLabels': localizedLabels,
      }),
      applicationDigest: eventDigest,
    ),
  );

  @override
  Future<List<PendingNotification>> pendingNotificationRequests() async {
    final state = await executionSnapshot();
    return [
      for (final registration in state.pending)
        PendingNotification(
          registration.event.id,
          registration.event.title,
          registration.event.body,
          null,
        ),
    ];
  }

  @override
  Future<bool> schedulePrayerEvent(
    PrayerNotificationEvent event, {
    bool? allowExact,
  }) => Future.error(
    StateError('Android prayers require a native plan transaction.'),
  );
  @override
  Future<void> cancelNotifications(Iterable<int> ids) async {
    final state = await executionSnapshot();
    await api.cancelOccurrences(ids.toList(), state.plan?.generation ?? 0);
  }
}
