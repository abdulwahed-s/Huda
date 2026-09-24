import 'dart:convert';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_reliability_storage.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';

class PrayerLocationStorageCorruptException implements Exception {
  const PrayerLocationStorageCorruptException();

  @override
  String toString() =>
      'The authoritative prayer-location database is corrupt or unsupported.';
}

class PrayerLocationRepository {
  PrayerLocationRepository({
    required this.cacheHelper,
    PrayerReliabilityStorage? storage,
    DateTime Function()? now,
  }) : _storage = storage,
       _now = now ?? DateTime.now;

  static const String generationProjectionKey = 'prayer_location_generation_v1';
  static const String widgetSettingsProjectionKey = 'prayer_widget_settings_v2';
  static const String localityKey = 'prayer_location_locality';
  static const String countryNameKey = 'prayer_location_country';

  final CacheHelper cacheHelper;
  PrayerReliabilityStorage? _storage;
  final DateTime Function() _now;

  Future<void> initialize() async {
    await synchronized((session) async {
      await session.repairProjections();
    });
  }

  Future<T> synchronized<T>(
    Future<T> Function(PrayerLocationRepositorySession session) action,
  ) async {
    PrayerTimeZoneService.initializeDatabase();
    final storage = await _resolveStorage();
    return storage.runExclusive(() async {
      final read = await storage.read();
      final state = await _stateFromRead(read);
      if (read.status == PrayerStorageReadStatus.absent ||
          read.status == PrayerStorageReadStatus.recoveredBackup) {
        await storage.write(state);
      }
      final session = PrayerLocationRepositorySession._(
        repository: this,
        storage: storage,
        state: state,
      );
      return action(session);
    });
  }

  Future<PrayerReliabilityState> readState() =>
      synchronized((session) async => session.state);

  Future<PrayerLocationGeneration?> readActive() =>
      synchronized((session) async => session.state.activeLocation);

  Future<int?> beginIntent(
    PrayerLocationMode mode, {
    bool allowModeChange = false,
    DateTime? automaticFixCapturedAtUtc,
  }) => synchronized(
    (session) => session.beginIntent(
      mode,
      allowModeChange: allowModeChange,
      automaticFixCapturedAtUtc: automaticFixCapturedAtUtc,
    ),
  );

  Future<bool> stageCandidate(PrayerLocationGeneration candidate) =>
      synchronized((session) => session.stageCandidate(candidate));

  Future<PrayerReliabilityStorage> _resolveStorage() async =>
      _storage ??= await AtomicPrayerReliabilityStorage.create();

  Future<PrayerReliabilityState> _stateFromRead(PrayerStorageRead read) async {
    switch (read.status) {
      case PrayerStorageReadStatus.valid:
      case PrayerStorageReadStatus.recoveredBackup:
        return read.state!;
      case PrayerStorageReadStatus.corrupt:
        throw const PrayerLocationStorageCorruptException();
      case PrayerStorageReadStatus.absent:
        return _migrateLegacyState();
    }
  }

  PrayerReliabilityState _migrateLegacyState() {
    PrayerTimeZoneService.initializeDatabase();
    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    final zone = cacheHelper
        .getDataString(key: PrayerTimesCalculator.timeZoneIdKey)
        ?.trim();
    final now = _now().toUtc();
    if (coordinates == null || zone == null || zone.isEmpty) {
      return const PrayerReliabilityState();
    }
    try {
      PrayerTimeZoneService.location(zone);
    } catch (_) {
      return const PrayerReliabilityState();
    }
    final country = PrayerTimesCalculator.countryCodeFromCache(cacheHelper);
    final revision = _initialRevision(now);
    final generation = PrayerLocationGeneration(
      revision: revision,
      mode: PrayerLocationMode.fromStorage(
        cacheHelper.getDataString(key: PrayerTimesCalculator.locationModeKey),
      ),
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      timeZoneId: zone,
      timeZoneProvenance: PrayerTimeZoneProvenance.legacyApproximate,
      countryCode: country.isEmpty ? null : country,
      locality: _normalized(cacheHelper.getDataString(key: localityKey)),
      countryName: _normalized(cacheHelper.getDataString(key: countryNameKey)),
      capturedAtUtc: now,
      committedAtUtc: now,
      source: PrayerLocationSource.migration,
    );
    return PrayerReliabilityState(
      revisionCounter: revision,
      latestIntentRevision: revision,
      latestIntentMode: generation.mode,
      activeLocation: generation,
    );
  }

  int _initialRevision(DateTime now) {
    final micros = now.microsecondsSinceEpoch;
    if (micros <= 0 || micros > PrayerLocationGeneration.maxSafeRevision) {
      return 1;
    }
    return micros;
  }

  Future<void> _mirrorActive(PrayerLocationGeneration? active) async {
    if (active == null) {
      for (final key in <String>[
        generationProjectionKey,
        PrayerTimesCalculator.latKey,
        PrayerTimesCalculator.lonKey,
        PrayerTimesCalculator.timeZoneIdKey,
        PrayerTimesCalculator.locationModeKey,
        PrayerTimesCalculator.countryCodeKey,
        localityKey,
        countryNameKey,
      ]) {
        await _saveOrRemove(key, null);
      }
      return;
    }
    final encoded = jsonEncode(active.toJson());
    await _checkedSave(generationProjectionKey, encoded);

    await _checkedSave(PrayerTimesCalculator.latKey, '${active.latitude}');
    await _checkedSave(PrayerTimesCalculator.lonKey, '${active.longitude}');
    await _checkedSave(PrayerTimesCalculator.timeZoneIdKey, active.timeZoneId);
    await _checkedSave(PrayerTimesCalculator.locationModeKey, active.mode.name);
    await _saveOrRemove(
      PrayerTimesCalculator.countryCodeKey,
      active.countryCode,
    );
    await _saveOrRemove(localityKey, active.locality);
    await _saveOrRemove(countryNameKey, active.countryName);
  }

  Future<void> _checkedSave(String key, Object value) async {
    final saved = await cacheHelper.saveData(key: key, value: value);
    if (!saved) throw StateError('Failed to update prayer projection $key');
  }

  Future<void> _saveOrRemove(String key, String? value) async {
    final normalized = _normalized(value);
    final success = normalized == null
        ? await cacheHelper.removeData(key: key)
        : await cacheHelper.saveData(key: key, value: normalized);
    if (!success && cacheHelper.getData(key: key) != normalized) {
      throw StateError('Failed to update prayer projection $key');
    }
  }

  static String? _normalized(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  int _widgetProjectionRevision() {
    final raw = cacheHelper.getDataString(key: widgetSettingsProjectionKey);
    if (raw == null || raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 0;
      for (final key in const <String>['publicationRevision', 'revision']) {
        final value = decoded[key];
        if (value is int &&
            value >= 0 &&
            value <= PrayerLocationGeneration.maxSafeRevision) {
          return value;
        }
      }
    } catch (_) {}
    return 0;
  }
}

class PrayerLocationRepositorySession {
  PrayerLocationRepositorySession._({
    required PrayerLocationRepository repository,
    required PrayerReliabilityStorage storage,
    required PrayerReliabilityState state,
  }) : _repository = repository,
       _storage = storage,
       _state = state;

  final PrayerLocationRepository _repository;
  final PrayerReliabilityStorage _storage;
  PrayerReliabilityState _state;

  PrayerReliabilityState get state => _state;

  Future<int?> beginIntent(
    PrayerLocationMode mode, {
    bool allowModeChange = false,
    DateTime? automaticFixCapturedAtUtc,
  }) async {
    final activeMode = _state.activeLocation?.mode;
    if (!allowModeChange &&
        mode == PrayerLocationMode.automatic &&
        (activeMode == PrayerLocationMode.manual ||
            _state.latestIntentMode == PrayerLocationMode.manual)) {
      return null;
    }
    final active = _state.activeLocation;
    if (!allowModeChange &&
        mode == PrayerLocationMode.automatic &&
        automaticFixCapturedAtUtc != null &&
        active != null &&
        active.mode == PrayerLocationMode.automatic &&
        active.source != PrayerLocationSource.migration &&
        active.capturedAtUtc.isAfter(automaticFixCapturedAtUtc.toUtc())) {
      return null;
    }
    final intentStartedAtUtc = _repository._now().toUtc();
    final rawWallClockRevision = intentStartedAtUtc.microsecondsSinceEpoch;
    final wallClockRevision = rawWallClockRevision < 1
        ? 1
        : rawWallClockRevision > PrayerLocationGeneration.maxSafeRevision
        ? PrayerLocationGeneration.maxSafeRevision
        : rawWallClockRevision;
    final next = wallClockRevision > _state.revisionCounter
        ? wallClockRevision
        : _state.revisionCounter + 1;
    if (next > PrayerLocationGeneration.maxSafeRevision) {
      throw StateError('Prayer location revision space exhausted');
    }
    await save(
      _state.copyWith(
        revisionCounter: next,
        latestIntentRevision: next,
        latestIntentMode: mode,
        pendingCandidate: null,
        journal: null,
        occurrenceHistory: _historyAfterSupersedingJournal(intentStartedAtUtc),
      ),
    );
    return next;
  }

  List<PrayerOccurrenceRecord> _historyAfterSupersedingJournal(
    DateTime nowUtc,
  ) {
    final journal = _state.journal;
    if (journal == null) return _state.occurrenceHistory;
    final result = _state.occurrenceHistory.toList(growable: true);
    final known = result.map((record) => record.occurrenceId).toSet();
    for (final event in journal.desiredEvents) {
      if (known.contains(event.id) ||
          event.scheduledInstantUtc.isAfter(nowUtc)) {
        continue;
      }
      result.add(
        PrayerOccurrenceRecord(
          occurrenceId: event.id,
          scheduledInstantUtc: event.scheduledInstantUtc,
          locationRevision: event.locationRevision,
          scheduleRevision: event.scheduleRevision,
          disposition: PrayerOccurrenceDisposition.deliveryUncertain,
          recordedAtUtc: nowUtc,
        ),
      );
      known.add(event.id);
    }
    return List.unmodifiable(result);
  }

  Future<bool> stageCandidate(PrayerLocationGeneration candidate) async {
    if (!candidate.isValid ||
        candidate.revision != _state.latestIntentRevision ||
        candidate.mode != _state.latestIntentMode ||
        candidate.revision > _state.revisionCounter) {
      return false;
    }
    await save(_state.copyWith(pendingCandidate: candidate));
    return true;
  }

  Future<void> save(PrayerReliabilityState next) async {
    await _storage.write(next);
    _state = next;
  }

  Future<void> commitActive({
    required PrayerLocationGeneration generation,
    required int scheduleRevision,
    required String configurationSignature,
    required String desiredEventDigest,
    required List<PrayerNotificationEvent> events,
    required List<PrayerOccurrenceRecord> occurrenceHistory,
    required DateTime activatedAtUtc,
  }) async {
    if (_state.pendingCandidate?.revision != generation.revision ||
        _state.latestIntentRevision != generation.revision) {
      throw StateError('Prayer location candidate was superseded');
    }
    final committed = generation.copyWith(
      committedAtUtc: activatedAtUtc.toUtc(),
    );
    final publicationRevision = await _nextWidgetPublicationRevision();
    await save(
      _state.copyWith(
        activeLocation: committed,
        pendingCandidate: null,
        scheduleRevision: scheduleRevision,
        committedConfigurationSignature: configurationSignature,
        committedDesiredEventDigest: desiredEventDigest,
        committedEvents: List.unmodifiable(events),
        occurrenceHistory: List.unmodifiable(occurrenceHistory),
        journal: null,
        widgetPublicationRevision: publicationRevision,
        widgetPublicationPending: true,
        lastScheduleActivatedAtUtc: activatedAtUtc.toUtc(),
      ),
    );
    try {
      await _repository._mirrorActive(committed);
    } catch (_) {}
  }

  Future<void> commitScheduleForActive({
    required PrayerLocationGeneration generation,
    required int scheduleRevision,
    required String configurationSignature,
    required String desiredEventDigest,
    required List<PrayerNotificationEvent> events,
    required List<PrayerOccurrenceRecord> occurrenceHistory,
    required DateTime activatedAtUtc,
    required bool publishWidget,
  }) async {
    if (_state.activeLocation?.revision != generation.revision ||
        _state.latestIntentRevision > generation.revision &&
            _state.pendingCandidate != null) {
      throw StateError('Active prayer location changed during reconciliation');
    }
    final nextPublicationRevision = publishWidget
        ? await _nextWidgetPublicationRevision()
        : _state.widgetPublicationRevision;
    await save(
      _state.copyWith(
        scheduleRevision: scheduleRevision,
        committedConfigurationSignature: configurationSignature,
        committedDesiredEventDigest: desiredEventDigest,
        committedEvents: List.unmodifiable(events),
        occurrenceHistory: List.unmodifiable(occurrenceHistory),
        journal: null,
        widgetPublicationRevision: nextPublicationRevision,
        widgetPublicationPending:
            publishWidget || _state.widgetPublicationPending,
        lastScheduleActivatedAtUtc: activatedAtUtc.toUtc(),
      ),
    );
  }

  Future<void> markWidgetPublished(int publicationRevision) async {
    if (_state.widgetPublicationRevision != publicationRevision) return;
    await save(_state.copyWith(widgetPublicationPending: false));
  }

  Future<int> reserveWidgetPublication() async {
    final next = await _nextWidgetPublicationRevision();
    await save(
      _state.copyWith(
        widgetPublicationRevision: next,
        widgetPublicationPending: true,
      ),
    );
    return next;
  }

  Future<int> _nextWidgetPublicationRevision() async {
    await _repository.cacheHelper.reload();
    final projected = _repository._widgetProjectionRevision();
    final floor = _state.widgetPublicationRevision > projected
        ? _state.widgetPublicationRevision
        : projected;
    return _nextRevision(floor, 'widget publication');
  }

  Future<void> repairProjections() =>
      _repository._mirrorActive(_state.activeLocation);

  static int _nextRevision(int current, String label) {
    if (current < 0 || current >= PrayerLocationGeneration.maxSafeRevision) {
      throw StateError('$label revision space exhausted');
    }
    return current + 1;
  }
}
