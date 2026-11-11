import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda_notifications/huda_notifications.dart';
import 'package:huda/core/notifications/pending_notification.dart';

abstract interface class PrayerNotificationGateway {
  Future<void> initialize();

  Future<String> refreshTimeZone();

  String get timeZoneName;

  Future<bool> areNotificationsAllowed();

  Future<String> schedulingCapabilitySignature();

  Future<bool> canScheduleExactNotifications();

  Future<List<PendingNotification>> pendingNotificationRequests();

  /// [allowExact] lets batch callers skip the per-event exact-alarm
  /// permission lookup; when omitted it is queried for this event.
  Future<bool> schedulePrayerEvent(
    PrayerNotificationEvent event, {
    bool? allowExact,
  });

  Future<void> cancelNotifications(Iterable<int> ids);
}

/// Optional capabilities for backends with authoritative delivery metadata.
/// Existing mobile gateways can continue verifying their pending payloads.
abstract interface class VerifiedPrayerNotificationGateway {
  bool get supportsSafeReplacement;

  bool matchesPendingEvent(
    PrayerNotificationEvent event,
    PendingNotification? pending,
  );

  Future<void> releasePendingSnapshot();
}

abstract interface class TransactionalPrayerGatewayProvider {
  Future<TransactionalPrayerNotificationGateway?> transactionalPrayerBackend();
}

/// Optional Android transactions; existing platform gateways remain unchanged.
abstract interface class TransactionalPrayerNotificationGateway
    implements PrayerNotificationGateway {
  Future<bool> isEnabled();
  Future<AndroidPrayerExperience> acknowledgedPolicy();
  Future<RuntimeSnapshot> executionSnapshot();
  Future<int> reserveQuota(int standardPluginAlarmCount);
  Future<HistoryPage> deliveryHistory(int afterCursor);
  Future<void> acknowledgeHistory(int cursor);
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
  });
  Future<PlanReceipt> activateNativePlan(
    String operationId,
    int expectedGeneration,
  );
  Future<PlanReceipt> finalizeNativePlan(
    PlanReceipt receipt,
    PrayerScheduleConfiguration configuration,
    String eventDigest,
    Map<String, Object?> localizedLabels,
  );
}
