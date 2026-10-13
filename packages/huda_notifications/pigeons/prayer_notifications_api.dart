import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/prayer_api.g.dart',
  kotlinOut: 'android/src/main/kotlin/com/aw/huda/prayer/PrayerApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.aw.huda.prayer'),
  dartPackageName: 'huda_notifications',
))
class PolicyData {
  PolicyData({required this.schemaVersion, required this.revision, required this.values});
  int schemaVersion;
  int revision;
  // Versioned global values plus sparse perPrayer overrides; see CONTRACT.md.
  Map<String, Object?> values;
}

class CapabilityData {
  CapabilityData({required this.notifications, required this.silentChannel, required this.adhanChannel,
    required this.exactAlarms, required this.fullScreen, required this.flipSensor,
    required this.wakeUpSensor, required this.userUnlocked, required this.batteryExempt,
    required this.ringerMode, required this.dndAllowsAlarms, required this.alarmVolume});
  bool notifications;
  bool silentChannel;
  bool adhanChannel;
  bool exactAlarms;
  bool fullScreen;
  bool flipSensor;
  bool wakeUpSensor;
  bool userUnlocked;
  bool batteryExempt;
  int ringerMode;
  bool? dndAllowsAlarms;
  double alarmVolume;
}

class EventData {
  EventData({required this.id, required this.prayer, required this.utcMillis, required this.timeZone,
    required this.localDate, required this.title, required this.body, this.compatiblePayload});
  int id;
  String prayer;
  int utcMillis;
  String timeZone;
  String localDate;
  String title;
  String body;
  // CE companion only. Never persist in the execution DB or PendingIntents.
  String? compatiblePayload;
}

class DeliveryData {
  DeliveryData({required this.cursor, required this.id, required this.utcMillis,
    required this.receivedMillis, required this.locationRevision, required this.scheduleRevision,
    required this.backend, required this.outcome, required this.reason, this.sessionId});
  int cursor;
  int id;
  int utcMillis;
  int receivedMillis;
  int locationRevision;
  int scheduleRevision;
  String backend;
  String outcome;
  String reason;
  String? sessionId;
}

class HistoryPage {
  HistoryPage({required this.nextCursor, required this.records});
  int nextCursor;
  List<DeliveryData> records;
}

class RegistrationData {
  RegistrationData({required this.event, required this.token, required this.precision, required this.outcome});
  EventData event;
  String token;
  String precision;
  String outcome;
}

class PlanRequest {
  PlanRequest({required this.operationId, required this.expectedGeneration, required this.expectedPolicyRevision,
    required this.locationRevision, required this.scheduleRevision, required this.configurationDigest,
    required this.eventDigest, required this.eligibilitySignature, required this.quota, required this.events,
    required this.suppressedHistory, required this.legacyEvents});
  String operationId;
  int expectedGeneration;
  int expectedPolicyRevision;
  int locationRevision;
  int scheduleRevision;
  String configurationDigest;
  String eventDigest;
  String eligibilitySignature;
  int quota;
  List<EventData> events;
  List<DeliveryData> suppressedHistory;
  // Exact original plugin IDs and verified aliases are carried in EventData.
  List<EventData> legacyEvents;
}

class PlanReceipt {
  PlanReceipt({required this.operationId, required this.epoch, required this.generation,
    required this.locationRevision, required this.scheduleRevision, required this.configurationDigest,
    required this.eventDigest, required this.eligibilitySignature, required this.state, required this.quota,
    required this.registrations, required this.legacyCleanupIds, this.coverageUtcMillis, this.error});
  String operationId;
  String epoch;
  int generation;
  int locationRevision;
  int scheduleRevision;
  String configurationDigest;
  String eventDigest;
  String eligibilitySignature;
  String state;
  int quota;
  List<RegistrationData> registrations;
  List<int> legacyCleanupIds;
  int? coverageUtcMillis;
  String? error;
}

class FinalizeRequest {
  FinalizeRequest({required this.operationId, required this.generation, required this.configurationSignature,
    required this.configurationJson, required this.applicationDigest});
  String operationId;
  int generation;
  String configurationSignature;
  String configurationJson;
  String applicationDigest;
}

class SessionData {
  SessionData({required this.id, required this.occurrenceId, required this.prayer, required this.phase,
    required this.mode, required this.reciterId, required this.gain, required this.automatic,
    required this.scheduledUtcMillis, required this.startedElapsedMillis, this.limitMillis, this.reason});
  String id;
  int occurrenceId;
  String prayer;
  String phase;
  String mode;
  String reciterId;
  double gain;
  bool automatic;
  int scheduledUtcMillis;
  int startedElapsedMillis;
  int? limitMillis;
  String? reason;
}

class RuntimeSnapshot {
  RuntimeSnapshot({required this.contractVersion, required this.runtimeInstance, required this.sequence,
    required this.epoch, required this.backend, required this.policy, required this.capabilities,
    required this.pending, required this.latestOutcomes, this.plan, this.session, this.repairReason, this.navigationToken,
    this.preparingPlan});
  int contractVersion;
  String runtimeInstance;
  int sequence;
  String epoch;
  String backend;
  PolicyData policy;
  CapabilityData capabilities;
  List<RegistrationData> pending;
  List<DeliveryData> latestOutcomes;
  PlanReceipt? plan;
  SessionData? session;
  String? repairReason;
  String? navigationToken;
  PlanReceipt? preparingPlan;
}

class AudioAssetData {
  AudioAssetData({required this.reciterId, required this.version, required this.variant,
    required this.path, required this.bytes, required this.sha256, required this.durationMillis,
    this.nameEnglish, this.nameArabic});
  String reciterId;
  String version;
  String variant;
  String path;
  int bytes;
  String sha256;
  int durationMillis;
  String? nameEnglish;
  String? nameArabic;
}

class AudioStorageData {
  AudioStorageData({required this.root, required this.stagingRoot, required this.bundled});
  String root;
  String stagingRoot;
  AudioAssetData bundled;
}

class QuotaData {
  QuotaData({required this.standardCount, required this.sahurReservation, required this.widgetReservation,
    required this.auxiliaryReservation, required this.migrationReservation});
  int standardCount;
  int sahurReservation;
  int widgetReservation;
  int auxiliaryReservation;
  int migrationReservation;
}

/// A reminder the app owns: a one-time notification, a daily or weekly
/// repeat, or random Athkar at a fixed interval. Repeats re-arm themselves.
class ReminderData {
  ReminderData({required this.id, required this.kind, required this.style, required this.title,
    required this.body, required this.payload, required this.utcMillis, required this.hour,
    required this.minute, required this.weekday, required this.intervalMinutes, required this.texts,
    required this.color});
  int id;
  /// `once`, `daily`, `weekly` or `interval`.
  String kind;
  /// `dailyReminder`, `weeklyReminder`, `athkar` or `calendar`.
  String style;
  String title;
  /// Unused for `interval`, which picks one of [texts] at each delivery.
  String body;
  String payload;
  /// The next delivery.
  int utcMillis;
  int? hour;
  int? minute;
  /// ISO weekday, Monday = 1.
  int? weekday;
  int? intervalMinutes;
  List<String> texts;
  int? color;
}

/// Cancellations run before additions.
class ReminderBatch {
  ReminderBatch({required this.cancel, required this.schedule});
  List<int> cancel;
  List<ReminderData> schedule;
}

@HostApi()
abstract class PrayerHostApi {
  @async
  RuntimeSnapshot initialize(int contractVersion);
  @async
  CapabilityData getCapabilities();
  @async
  RuntimeSnapshot getSnapshot();
  @async
  PolicyData getPolicy();
  @async
  PolicyData setPolicy(PolicyData policy, int expectedRevision);
  @async
  int updateQuota(QuotaData quota);
  @async
  PlanReceipt preparePlan(PlanRequest request);
  @async
  PlanReceipt? getPlanReceipt(String operationId);
  @async
  PlanReceipt activatePlan(String operationId, int expectedGeneration);
  @async
  PlanReceipt finalizePlan(FinalizeRequest request);
  @async
  PlanReceipt abortPlan(String operationId);
  @async
  PlanReceipt acknowledgeLegacyCleanup(String operationId, List<int> ids);
  @async
  HistoryPage getDeliveryHistory(int afterCursor, int limit);
  @async
  void acknowledgeHistory(int cursor);
  @async
  List<EventData> getLegacyInventory(List<int> ids);
  @async
  void suppressUnmappedLegacy(List<int> ids);
  /// Lists stored plugin alarms. `prayer` is empty for a prayer, `standard` otherwise.
  @async
  List<EventData> getLegacyNotifications();
  /// Cancels these old alarms and forgets them.
  @async
  void cancelLegacyNotifications(List<int> ids);
  @async
  void cancelOccurrences(List<int> ids, int expectedGeneration);
  @async
  void resetPrayerBackend(bool clearHistory);
  @async
  AudioStorageData getAudioStorage();
  @async
  bool isAudioReady(String reciterId, String version);
  @async
  void registerVerifiedAudio(List<AudioAssetData> pair);
  @async
  List<String> removeUnreferencedAudio();

  /// Deletes one downloaded recording unless a prayer or a session uses it.
  @async
  List<String> removeAudio(String reciterId, String version);
  /// Watches for a flip without playing anything (the settings' "Try it");
  /// false when the phone has no sensor. Progress arrives as `flipProbe`
  /// events with `state` waiting, armed, detected or stopped.
  @async
  bool startFlipProbe();
  @async
  void stopFlipProbe();
  @async
  SessionData startPreview(String prayer);
  @async
  void stopPreview(String sessionId);
  @async
  EventData runDeliveryTest(String prayer, int delaySeconds);
  @async
  void stopSession(String sessionId);
  @async
  void dismissSession(String sessionId);
  @async
  void setSessionGain(String sessionId, double gain);
  @async
  void openAlarmOverview(String sessionId);
  @async
  CapabilityData openSettings(String target);
  @async
  void requestNotificationPermission();
  /// Applies a batch; returns the IDs the system did not accept.
  @async
  List<int> applyReminders(ReminderBatch batch);
  @async
  List<ReminderData> getReminders();
  /// The payload of a reminder tapped since the last call, once.
  @async
  String? takeReminderTap();
}
