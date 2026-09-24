import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_notification_models.dart';

enum PrayerReconciliationPhase {
  preparing,
  transferringOwnership,
  applyingLocal,
  degraded,
  committed;

  static PrayerReconciliationPhase? tryParse(Object? value) {
    if (value is! String) return null;
    for (final phase in values) {
      if (phase.name == value) return phase;
    }
    return null;
  }
}

enum PrayerOccurrenceDisposition {
  due,
  suppressed,
  confirmedDelivered,
  deliveryUncertain;

  static PrayerOccurrenceDisposition? tryParse(Object? value) {
    if (value is! String) return null;
    for (final disposition in values) {
      if (disposition.name == value) return disposition;
    }
    return null;
  }
}

class PrayerOccurrenceRecord {
  const PrayerOccurrenceRecord({
    required this.occurrenceId,
    required this.scheduledInstantUtc,
    required this.locationRevision,
    required this.scheduleRevision,
    required this.disposition,
    required this.recordedAtUtc,
  });

  final int occurrenceId;
  final DateTime scheduledInstantUtc;
  final int locationRevision;
  final int scheduleRevision;
  final PrayerOccurrenceDisposition disposition;
  final DateTime recordedAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'occurrenceId': occurrenceId,
    'scheduledInstantUtc': scheduledInstantUtc.toUtc().toIso8601String(),
    'locationRevision': locationRevision,
    'scheduleRevision': scheduleRevision,
    'disposition': disposition.name,
    'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
  };

  static PrayerOccurrenceRecord? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    final occurrenceId = json['occurrenceId'];
    final locationRevision = json['locationRevision'];
    final scheduleRevision = json['scheduleRevision'];
    final scheduled = _utcDate(json['scheduledInstantUtc']);
    final recorded = _utcDate(json['recordedAtUtc']);
    final disposition = PrayerOccurrenceDisposition.tryParse(
      json['disposition'],
    );
    if (occurrenceId is! int ||
        locationRevision is! int ||
        scheduleRevision is! int ||
        occurrenceId < 0 ||
        occurrenceId < PrayerNotificationEvent.modernIdStart ||
        occurrenceId >= PrayerNotificationEvent.modernIdEnd ||
        locationRevision < 0 ||
        locationRevision > PrayerLocationGeneration.maxSafeRevision ||
        scheduleRevision < 0 ||
        scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
        scheduled == null ||
        recorded == null ||
        disposition == null) {
      return null;
    }
    return PrayerOccurrenceRecord(
      occurrenceId: occurrenceId,
      scheduledInstantUtc: scheduled,
      locationRevision: locationRevision,
      scheduleRevision: scheduleRevision,
      disposition: disposition,
      recordedAtUtc: recorded,
    );
  }
}

class PrayerRemoteOwnershipAcknowledgement {
  const PrayerRemoteOwnershipAcknowledgement({
    required this.locationRevision,
    required this.scheduleRevision,
    required this.enabled,
    required this.acknowledgedAtUtc,
    this.localCoverageUntilUtc,
  });

  static const int schemaVersion = 1;

  final int locationRevision;
  final int scheduleRevision;
  final bool enabled;
  final DateTime? localCoverageUntilUtc;
  final DateTime acknowledgedAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'locationRevision': locationRevision,
    'scheduleRevision': scheduleRevision,
    'enabled': enabled,
    'localCoverageUntilUtc': localCoverageUntilUtc?.toUtc().toIso8601String(),
    'acknowledgedAtUtc': acknowledgedAtUtc.toUtc().toIso8601String(),
  };

  static PrayerRemoteOwnershipAcknowledgement? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    if (_integer(json['schemaVersion']) != schemaVersion) return null;
    final locationRevision = _integer(json['locationRevision']);
    final scheduleRevision = _integer(json['scheduleRevision']);
    final enabled = json['enabled'];
    final coverage = json['localCoverageUntilUtc'] == null
        ? null
        : _utcDate(json['localCoverageUntilUtc']);
    final acknowledgedAt = _utcDate(json['acknowledgedAtUtc']);
    if (locationRevision == null ||
        scheduleRevision == null ||
        enabled is! bool ||
        locationRevision < 0 ||
        locationRevision > PrayerLocationGeneration.maxSafeRevision ||
        scheduleRevision < 0 ||
        scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
        (json['localCoverageUntilUtc'] != null && coverage == null) ||
        (!enabled && coverage != null) ||
        acknowledgedAt == null) {
      return null;
    }
    return PrayerRemoteOwnershipAcknowledgement(
      locationRevision: locationRevision,
      scheduleRevision: scheduleRevision,
      enabled: enabled,
      localCoverageUntilUtc: coverage,
      acknowledgedAtUtc: acknowledgedAt,
    );
  }
}

class PrayerScheduleJournal {
  const PrayerScheduleJournal({
    required this.candidateLocationRevision,
    required this.previousLocationRevision,
    required this.scheduleRevision,
    required this.configurationSignature,
    required this.cutoverInstantUtc,
    required this.phase,
    required this.desiredEvents,
    required this.desiredEventDigest,
    required this.attemptCount,
    this.acknowledgedRemoteScheduleRevision,
    this.acknowledgedRemoteOwnershipUntilUtc,
    this.completedOrUncertainOperations = const <String>[],
    this.lastErrorCategory,
  });

  static const int schemaVersion = 1;

  final int candidateLocationRevision;
  final int? previousLocationRevision;
  final int scheduleRevision;
  final String configurationSignature;
  final DateTime cutoverInstantUtc;
  final PrayerReconciliationPhase phase;
  final int? acknowledgedRemoteScheduleRevision;
  final DateTime? acknowledgedRemoteOwnershipUntilUtc;
  final List<PrayerNotificationEvent> desiredEvents;
  final String desiredEventDigest;
  final List<String> completedOrUncertainOperations;
  final int attemptCount;
  final String? lastErrorCategory;

  PrayerScheduleJournal copyWith({
    PrayerReconciliationPhase? phase,
    int? acknowledgedRemoteScheduleRevision,
    Object? acknowledgedRemoteOwnershipUntilUtc = _unset,
    List<String>? completedOrUncertainOperations,
    int? attemptCount,
    Object? lastErrorCategory = _unset,
  }) {
    return PrayerScheduleJournal(
      candidateLocationRevision: candidateLocationRevision,
      previousLocationRevision: previousLocationRevision,
      scheduleRevision: scheduleRevision,
      configurationSignature: configurationSignature,
      cutoverInstantUtc: cutoverInstantUtc,
      phase: phase ?? this.phase,
      acknowledgedRemoteScheduleRevision:
          acknowledgedRemoteScheduleRevision ??
          this.acknowledgedRemoteScheduleRevision,
      acknowledgedRemoteOwnershipUntilUtc:
          identical(acknowledgedRemoteOwnershipUntilUtc, _unset)
          ? this.acknowledgedRemoteOwnershipUntilUtc
          : acknowledgedRemoteOwnershipUntilUtc as DateTime?,
      desiredEvents: desiredEvents,
      desiredEventDigest: desiredEventDigest,
      completedOrUncertainOperations:
          completedOrUncertainOperations ?? this.completedOrUncertainOperations,
      attemptCount: attemptCount ?? this.attemptCount,
      lastErrorCategory: identical(lastErrorCategory, _unset)
          ? this.lastErrorCategory
          : lastErrorCategory as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'candidateLocationRevision': candidateLocationRevision,
    'previousLocationRevision': previousLocationRevision,
    'scheduleRevision': scheduleRevision,
    'configurationSignature': configurationSignature,
    'cutoverInstantUtc': cutoverInstantUtc.toUtc().toIso8601String(),
    'phase': phase.name,
    'acknowledgedRemoteScheduleRevision': acknowledgedRemoteScheduleRevision,
    'acknowledgedRemoteOwnershipUntilUtc': acknowledgedRemoteOwnershipUntilUtc
        ?.toUtc()
        .toIso8601String(),
    'desiredEvents': desiredEvents.map((event) => event.toJson()).toList(),
    'desiredEventDigest': desiredEventDigest,
    'completedOrUncertainOperations': completedOrUncertainOperations,
    'attemptCount': attemptCount,
    'lastErrorCategory': lastErrorCategory,
  };

  static PrayerScheduleJournal? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    if (_integer(json['schemaVersion']) != schemaVersion) return null;
    final candidateRevision = _integer(json['candidateLocationRevision']);
    final previousRevision = json['previousLocationRevision'] == null
        ? null
        : _integer(json['previousLocationRevision']);
    final scheduleRevision = _integer(json['scheduleRevision']);
    final configurationSignature = json['configurationSignature'];
    final cutover = _utcDate(json['cutoverInstantUtc']);
    final phase = PrayerReconciliationPhase.tryParse(json['phase']);
    final remoteRevision = json['acknowledgedRemoteScheduleRevision'] == null
        ? null
        : _integer(json['acknowledgedRemoteScheduleRevision']);
    final remoteBoundary = json['acknowledgedRemoteOwnershipUntilUtc'] == null
        ? null
        : _utcDate(json['acknowledgedRemoteOwnershipUntilUtc']);
    final digest = json['desiredEventDigest'];
    final attempts = _integer(json['attemptCount']);
    final rawEvents = json['desiredEvents'];
    final rawOperations = json['completedOrUncertainOperations'];
    if (candidateRevision == null ||
        scheduleRevision == null ||
        candidateRevision <= 0 ||
        candidateRevision > PrayerLocationGeneration.maxSafeRevision ||
        scheduleRevision <= 0 ||
        scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
        (json['previousLocationRevision'] != null &&
            (previousRevision == null ||
                previousRevision < 0 ||
                previousRevision > PrayerLocationGeneration.maxSafeRevision)) ||
        (json['acknowledgedRemoteScheduleRevision'] != null &&
            (remoteRevision == null ||
                remoteRevision < 0 ||
                remoteRevision > PrayerLocationGeneration.maxSafeRevision)) ||
        (json['acknowledgedRemoteOwnershipUntilUtc'] != null &&
            remoteBoundary == null) ||
        configurationSignature is! String ||
        configurationSignature.isEmpty ||
        cutover == null ||
        phase == null ||
        digest is! String ||
        digest.isEmpty ||
        attempts == null ||
        attempts <= 0 ||
        rawEvents is! List ||
        rawOperations is! List) {
      return null;
    }
    final events = <PrayerNotificationEvent>[];
    for (final raw in rawEvents) {
      final event = PrayerNotificationEvent.tryParse(raw);
      if (event == null ||
          event.locationRevision != candidateRevision ||
          event.scheduleRevision != scheduleRevision ||
          event.configurationSignature != configurationSignature) {
        return null;
      }
      events.add(event);
    }
    final operations = <String>[];
    for (final raw in rawOperations) {
      if (raw is! String) return null;
      operations.add(raw);
    }
    return PrayerScheduleJournal(
      candidateLocationRevision: candidateRevision,
      previousLocationRevision: previousRevision,
      scheduleRevision: scheduleRevision,
      configurationSignature: configurationSignature,
      cutoverInstantUtc: cutover,
      phase: phase,
      acknowledgedRemoteScheduleRevision: remoteRevision,
      acknowledgedRemoteOwnershipUntilUtc: remoteBoundary,
      desiredEvents: List.unmodifiable(events),
      desiredEventDigest: digest,
      completedOrUncertainOperations: List.unmodifiable(operations),
      attemptCount: attempts,
      lastErrorCategory: json['lastErrorCategory'] is String
          ? json['lastErrorCategory'] as String
          : null,
    );
  }
}

class PrayerReliabilityState {
  const PrayerReliabilityState({
    this.revisionCounter = 0,
    this.latestIntentRevision = 0,
    this.latestIntentMode,
    this.scheduleRevision = 0,
    this.widgetPublicationRevision = 0,
    this.activeLocation,
    this.pendingCandidate,
    this.committedConfigurationSignature,
    this.committedDesiredEventDigest,
    this.committedEvents = const <PrayerNotificationEvent>[],
    this.occurrenceHistory = const <PrayerOccurrenceRecord>[],
    this.remoteOwnershipAcknowledgement,
    this.journal,
    this.widgetPublicationPending = false,
    this.lastScheduleActivatedAtUtc,
  });

  static const int schemaVersion = 1;

  final int revisionCounter;
  final int latestIntentRevision;
  final PrayerLocationMode? latestIntentMode;
  final int scheduleRevision;
  final int widgetPublicationRevision;
  final PrayerLocationGeneration? activeLocation;
  final PrayerLocationGeneration? pendingCandidate;
  final String? committedConfigurationSignature;
  final String? committedDesiredEventDigest;
  final List<PrayerNotificationEvent> committedEvents;
  final List<PrayerOccurrenceRecord> occurrenceHistory;
  final PrayerRemoteOwnershipAcknowledgement? remoteOwnershipAcknowledgement;
  final PrayerScheduleJournal? journal;
  final bool widgetPublicationPending;
  final DateTime? lastScheduleActivatedAtUtc;

  PrayerReliabilityState copyWith({
    int? revisionCounter,
    int? latestIntentRevision,
    Object? latestIntentMode = _unset,
    int? scheduleRevision,
    int? widgetPublicationRevision,
    Object? activeLocation = _unset,
    Object? pendingCandidate = _unset,
    Object? committedConfigurationSignature = _unset,
    Object? committedDesiredEventDigest = _unset,
    List<PrayerNotificationEvent>? committedEvents,
    List<PrayerOccurrenceRecord>? occurrenceHistory,
    Object? remoteOwnershipAcknowledgement = _unset,
    Object? journal = _unset,
    bool? widgetPublicationPending,
    Object? lastScheduleActivatedAtUtc = _unset,
  }) {
    return PrayerReliabilityState(
      revisionCounter: revisionCounter ?? this.revisionCounter,
      latestIntentRevision: latestIntentRevision ?? this.latestIntentRevision,
      latestIntentMode: identical(latestIntentMode, _unset)
          ? this.latestIntentMode
          : latestIntentMode as PrayerLocationMode?,
      scheduleRevision: scheduleRevision ?? this.scheduleRevision,
      widgetPublicationRevision:
          widgetPublicationRevision ?? this.widgetPublicationRevision,
      activeLocation: identical(activeLocation, _unset)
          ? this.activeLocation
          : activeLocation as PrayerLocationGeneration?,
      pendingCandidate: identical(pendingCandidate, _unset)
          ? this.pendingCandidate
          : pendingCandidate as PrayerLocationGeneration?,
      committedConfigurationSignature:
          identical(committedConfigurationSignature, _unset)
          ? this.committedConfigurationSignature
          : committedConfigurationSignature as String?,
      committedDesiredEventDigest:
          identical(committedDesiredEventDigest, _unset)
          ? this.committedDesiredEventDigest
          : committedDesiredEventDigest as String?,
      committedEvents: committedEvents ?? this.committedEvents,
      occurrenceHistory: occurrenceHistory ?? this.occurrenceHistory,
      remoteOwnershipAcknowledgement:
          identical(remoteOwnershipAcknowledgement, _unset)
          ? this.remoteOwnershipAcknowledgement
          : remoteOwnershipAcknowledgement
                as PrayerRemoteOwnershipAcknowledgement?,
      journal: identical(journal, _unset)
          ? this.journal
          : journal as PrayerScheduleJournal?,
      widgetPublicationPending:
          widgetPublicationPending ?? this.widgetPublicationPending,
      lastScheduleActivatedAtUtc: identical(lastScheduleActivatedAtUtc, _unset)
          ? this.lastScheduleActivatedAtUtc
          : lastScheduleActivatedAtUtc as DateTime?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'revisionCounter': revisionCounter,
    'latestIntentRevision': latestIntentRevision,
    'latestIntentMode': latestIntentMode?.name,
    'scheduleRevision': scheduleRevision,
    'widgetPublicationRevision': widgetPublicationRevision,
    'activeLocation': activeLocation?.toJson(),
    'pendingCandidate': pendingCandidate?.toJson(),
    'committedConfigurationSignature': committedConfigurationSignature,
    'committedDesiredEventDigest': committedDesiredEventDigest,
    'committedEvents': committedEvents.map((event) => event.toJson()).toList(),
    'occurrenceHistory': occurrenceHistory
        .map((event) => event.toJson())
        .toList(),
    'remoteOwnershipAcknowledgement': remoteOwnershipAcknowledgement?.toJson(),
    'journal': journal?.toJson(),
    'widgetPublicationPending': widgetPublicationPending,
    'lastScheduleActivatedAtUtc': lastScheduleActivatedAtUtc
        ?.toUtc()
        .toIso8601String(),
  };

  static PrayerReliabilityState? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    if (_integer(json['schemaVersion']) != schemaVersion) return null;
    final revisionCounter = _integer(json['revisionCounter']);
    final latestIntentRevision = _integer(json['latestIntentRevision']);
    final latestIntentMode = json['latestIntentMode'] == null
        ? null
        : PrayerLocationMode.tryParse(json['latestIntentMode']);
    final scheduleRevision = _integer(json['scheduleRevision']);
    final publicationRevision = _integer(json['widgetPublicationRevision']);
    final active = json['activeLocation'] == null
        ? null
        : PrayerLocationGeneration.tryParse(json['activeLocation']);
    final candidate = json['pendingCandidate'] == null
        ? null
        : PrayerLocationGeneration.tryParse(json['pendingCandidate']);
    final journal = json['journal'] == null
        ? null
        : PrayerScheduleJournal.tryParse(json['journal']);
    final remoteAcknowledgement = json['remoteOwnershipAcknowledgement'] == null
        ? null
        : PrayerRemoteOwnershipAcknowledgement.tryParse(
            json['remoteOwnershipAcknowledgement'],
          );
    final activatedAt = json['lastScheduleActivatedAtUtc'] == null
        ? null
        : _utcDate(json['lastScheduleActivatedAtUtc']);
    if (revisionCounter == null ||
        latestIntentRevision == null ||
        scheduleRevision == null ||
        publicationRevision == null ||
        revisionCounter < 0 ||
        revisionCounter > PrayerLocationGeneration.maxSafeRevision ||
        latestIntentRevision < 0 ||
        latestIntentRevision > PrayerLocationGeneration.maxSafeRevision ||
        (json['latestIntentMode'] != null && latestIntentMode == null) ||
        scheduleRevision < 0 ||
        scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
        publicationRevision < 0 ||
        publicationRevision > PrayerLocationGeneration.maxSafeRevision ||
        (json['activeLocation'] != null && active == null) ||
        (json['pendingCandidate'] != null && candidate == null) ||
        (json['journal'] != null && journal == null) ||
        (json['remoteOwnershipAcknowledgement'] != null &&
            remoteAcknowledgement == null) ||
        (json['lastScheduleActivatedAtUtc'] != null && activatedAt == null) ||
        json['committedEvents'] is! List ||
        json['occurrenceHistory'] is! List ||
        json['widgetPublicationPending'] is! bool) {
      return null;
    }
    final events = <PrayerNotificationEvent>[];
    for (final raw in json['committedEvents']! as List) {
      final event = PrayerNotificationEvent.tryParse(raw);
      if (event == null) return null;
      events.add(event);
    }
    final history = <PrayerOccurrenceRecord>[];
    for (final raw in json['occurrenceHistory']! as List) {
      final record = PrayerOccurrenceRecord.tryParse(raw);
      if (record == null) return null;
      history.add(record);
    }
    final maximumRevision = <int>[
      latestIntentRevision,
      active?.revision ?? 0,
      candidate?.revision ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    final journalLocationRevision = candidate?.revision ?? active?.revision;
    final committedSignature = json['committedConfigurationSignature'] is String
        ? json['committedConfigurationSignature'] as String
        : null;
    final committedDigest = json['committedDesiredEventDigest'] is String
        ? json['committedDesiredEventDigest'] as String
        : null;
    final committedEventsAreConsistent = events.every(
      (event) =>
          active != null &&
          event.locationRevision == active.revision &&
          event.scheduleRevision == scheduleRevision &&
          event.configurationSignature == committedSignature,
    );
    if (revisionCounter < maximumRevision ||
        (candidate != null &&
            (candidate.revision != latestIntentRevision ||
                candidate.mode != latestIntentMode)) ||
        !committedEventsAreConsistent ||
        (events.isNotEmpty &&
            (scheduleRevision <= 0 ||
                committedSignature == null ||
                committedSignature.isEmpty ||
                committedDigest == null ||
                committedDigest.isEmpty)) ||
        (journal != null && journal.scheduleRevision < scheduleRevision) ||
        (journal != null &&
            journalLocationRevision != journal.candidateLocationRevision) ||
        (remoteAcknowledgement != null &&
            remoteAcknowledgement.locationRevision > revisionCounter)) {
      return null;
    }
    return PrayerReliabilityState(
      revisionCounter: revisionCounter,
      latestIntentRevision: latestIntentRevision,
      latestIntentMode: latestIntentMode,
      scheduleRevision: scheduleRevision,
      widgetPublicationRevision: publicationRevision,
      activeLocation: active,
      pendingCandidate: candidate,
      committedConfigurationSignature: committedSignature,
      committedDesiredEventDigest: committedDigest,
      committedEvents: List.unmodifiable(events),
      occurrenceHistory: List.unmodifiable(history),
      remoteOwnershipAcknowledgement: remoteAcknowledgement,
      journal: journal,
      widgetPublicationPending: json['widgetPublicationPending']! as bool,
      lastScheduleActivatedAtUtc: activatedAt,
    );
  }
}

DateTime? _utcDate(Object? value) {
  if (value is! String || !value.endsWith('Z')) return null;
  return DateTime.tryParse(value)?.toUtc();
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

const Object _unset = Object();
