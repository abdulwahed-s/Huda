import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/geolocator.dart' show Position;
import 'package:huda/core/services/get_current_location.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_location_time_zone_service.dart';
import 'package:huda/core/services/prayer_location_coordinator.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/prayer_location_monitor.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/data/services/location_service.dart';
import 'package:huda/core/errors/location_failures.dart';
import 'package:huda/core/services/prayer_widget_service.dart';

export 'package:huda/core/services/prayer_location_generation.dart'
    show PrayerLocationMode;

part 'prayer_times_state.dart';

class NextPrayerInfo {
  final String name;
  final DateTime time;
  final bool isPastPrayer;
  final int secondsPassed;
  final Prayer? prayer;

  NextPrayerInfo({
    required this.name,
    required this.time,
    this.isPastPrayer = false,
    this.secondsPassed = 0,
    this.prayer,
  });
}

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final CacheHelper cacheHelper;
  final Future<Position> Function() _currentLocationProvider;
  final Future<Position?> Function() _travelLocationProvider;
  final PrayerTimeZoneResolver _timeZoneResolver;
  final Future<List<Placemark>> Function(double, double)? _placemarkProvider;
  static const _latKey = PrayerTimesCalculator.latKey;
  static const _lonKey = PrayerTimesCalculator.lonKey;
  static const _countryCodeKey = PrayerTimesCalculator.countryCodeKey;
  static const _timeZoneIdKey = PrayerTimesCalculator.timeZoneIdKey;
  static const _locationModeKey = PrayerTimesCalculator.locationModeKey;
  static const _lastLocationValidationKey =
      'prayer_location_last_validation_ms';
  static const _methodKey = PrayerTimesCalculator.methodKey;
  static const _madhabKey = PrayerTimesCalculator.madhabKey;
  static const _highLatKey = PrayerTimesCalculator.highLatitudeRuleKey;
  static const _localityKey = 'prayer_location_locality';
  static const _countryNameKey = 'prayer_location_country';
  static const _fajrOffsetKey = 'prayer_offset_fajr';
  static const _dhuhrOffsetKey = 'prayer_offset_dhuhr';
  static const _asrOffsetKey = 'prayer_offset_asr';
  static const _maghribOffsetKey = 'prayer_offset_maghrib';
  static const _ishaOffsetKey = 'prayer_offset_isha';
  static const _sunriseOffsetKey = 'prayer_offset_sunrise';
  LocationService? _locationService;
  final PrayerNotificationScheduler _notificationScheduler;
  final PrayerLocationRepository? _locationRepository;
  final PrayerLocationMonitor? _locationMonitor;
  PrayerLocationCoordinator? _locationCoordinator;
  LocationService get _locations => _locationService ??= LocationService();

  Map<String, int> _prayerOffsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  String _methodToken = PrayerTimesCalculator.defaultMethodToken;
  String _madhabToken = PrayerTimesCalculator.defaultMadhabToken;
  String _highLatToken = PrayerTimesCalculator.defaultHighLatitudeToken;
  String? _prayerTimeZoneId;
  PrayerLocationMode _locationMode = PrayerLocationMode.automatic;
  bool _automaticLocationRefreshInProgress = false;
  CustomPrayerAngles _customAngles = CustomPrayerAngles.defaults;
  PrayerDisplaySnapshot? _display;
  final Set<PrayerWorkflowIssue> _issues = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool? _online;
  bool _workflowRetrying = false;

  bool _userRetrying = false;

  int _updates = 0;
  Timer? _updatesSettling;
  int _displayEpoch = 0;
  Timer? _dayRollover;
  int? _enrichmentAttemptRevision;
  bool _legacyVerificationAttempted = false;
  int? _countryQuestionDismissedRevision;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;
  final Future<List<ConnectivityResult>> Function()? _connectivityCheck;
  final Duration _networkRetryDelay;
  Timer? _networkRetryTimer;
  DateTime? _lastNetworkRetry;
  final Set<PrayerWorkflowIssue> _knownPersistedIssues = {};
  PrayerScheduleResult? _notificationScheduleResult;
  bool _notificationScheduleRetrying = false;

  Set<PrayerWorkflowIssue> get workflowIssues => Set.unmodifiable(_issues);
  Map<String, int> get prayerOffsets => Map.unmodifiable(_prayerOffsets);
  String get calculationMethodToken => _methodToken;
  String get madhabToken => _madhabToken;
  String get highLatitudeRuleToken => _highLatToken;
  CustomPrayerAngles get customPrayerAngles => _customAngles;
  PrayerLocationMode get locationMode => _locationMode;
  String? get prayerTimeZoneId => _prayerTimeZoneId;

  PrayerDisplaySnapshot? get verifiedExportSnapshot {
    final display = _display;
    final current = state;
    if (current is! PrayerTimesLoaded ||
        current.provisional ||
        display == null ||
        display.provisional ||
        !display.location.isValid) {
      return null;
    }
    final times = current.prayerTimes;
    if ([
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ].every((time) => time == null)) {
      return null;
    }
    return PrayerDisplaySnapshot(
      location: display.location.copyWith(
        verificationReasons: List.unmodifiable(
          display.location.verificationReasons,
        ),
        countryCandidates: List.unmodifiable(
          display.location.countryCandidates,
        ),
      ),
      method: display.method,
      madhab: display.madhab,
      highLatitude: display.highLatitude,
      angles: display.angles,
      offsets: Map.unmodifiable(display.offsets),
      revision: display.revision,
      issues: Set.unmodifiable(display.issues),
    );
  }

  AppLocalizations? _localizations;

  void setLocalizations(AppLocalizations localizations) {
    final changed = _localizations?.localeName != localizations.localeName;
    _localizations = localizations;
    if (changed && _display != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _renderDisplay());
    }
  }

  String? _countryDisplayName(String? code, String? fallback) =>
      PrayerCountryNames.localized(
        code,
        _localizations?.localeName ??
            cacheHelper.getDataString(key: 'locale') ??
            'en',
      ) ??
      fallback;

  PrayerTimesCubit(
    this.cacheHelper, {
    LocationService? locationService,
    PrayerNotificationScheduler? notificationScheduler,
    PrayerLocationRepository? locationRepository,
    PrayerLocationMonitor? locationMonitor,
    Future<Position> Function()? currentLocationProvider,
    Future<Position?> Function()? travelLocationProvider,
    PrayerTimeZoneResolver? timeZoneResolver,
    Future<List<Placemark>> Function(double, double)? placemarkProvider,
    @visibleForTesting Stream<List<ConnectivityResult>>? connectivityChanges,
    @visibleForTesting
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    @visibleForTesting Duration networkRetryDelay = const Duration(seconds: 4),
  }) : _connectivityChanges = connectivityChanges,
       _connectivityCheck = connectivityCheck,
       _networkRetryDelay = networkRetryDelay,
       _notificationScheduler =
           notificationScheduler ??
           PrayerNotificationScheduler(cacheHelper: cacheHelper),
       _locationRepository = locationRepository,
       _locationMonitor = locationMonitor,
       _locationService = locationService,
       _currentLocationProvider = currentLocationProvider ?? getCurrentLocation,
       _travelLocationProvider =
           travelLocationProvider ?? getCurrentLocationForTravelValidation,
       _timeZoneResolver =
           timeZoneResolver ?? PrayerLocationTimeZoneService.resolveExact,
       _placemarkProvider = placemarkProvider,
       super(PrayerTimesInitial()) {
    _loadOffsets();
    _loadSettings();
    _restoreNotificationScheduleProjection();
    final raw = cacheHelper.getDataString(
      key: PrayerLocationRepository.displayProjectionKey,
    );
    if (raw != null) {
      try {
        _display = PrayerDisplaySnapshot.tryParse(jsonDecode(raw));
      } catch (_) {
        _issues.add(PrayerWorkflowIssue.storage);
      }
    }
    if (_display == null) {
      try {
        final generation = PrayerLocationGeneration.tryParse(
          jsonDecode(
            cacheHelper.getDataString(
                  key: PrayerLocationRepository.generationProjectionKey,
                ) ??
                'null',
          ),
        );
        if (generation != null) {
          _display = PrayerDisplaySnapshot.fromCache(
            cacheHelper,
            generation,
            issues: {
              if (!generation.calculationVerified)
                PrayerWorkflowIssue.verification,
            },
          );
        }
      } catch (_) {
        _issues.add(PrayerWorkflowIssue.storage);
      }
    }
    _issues.addAll(_display?.issues ?? {});
    try {
      final pending =
          jsonDecode(
                cacheHelper.getDataString(
                      key: PrayerLocationRepository.issuesProjectionKey,
                    ) ??
                    '[]',
              )
              as List;
      _issues.addAll(
        pending.map(
          (name) => PrayerWorkflowIssue.values.byName(name as String),
        ),
      );
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.storage);
    }
    _knownPersistedIssues.addAll(_issues);
    _observeConnectivity();
  }

  PrayerLocationCoordinator? get _coordinator {
    final repository = _locationRepository;
    if (repository == null) return null;
    return _locationCoordinator ??= PrayerLocationCoordinator(
      cacheHelper: cacheHelper,
      repository: repository,
      activator: _notificationScheduler,
      timeZoneResolver: _timeZoneResolver,
      onDisplay: _acceptDisplay,
      metadataResolver: (latitude, longitude) async {
        final placemarks = await _resolvePlacemarks(
          latitude,
          longitude,
          preserveCachedMetadata: false,
        );
        if (placemarks.isEmpty) return const PrayerLocationMetadata();
        final place = placemarks.first;
        return PrayerLocationMetadata(
          countryCode: place.isoCountryCode,
          locality: place.locality,
          countryName: place.country,
        );
      },
    );
  }

  void _restoreNotificationScheduleProjection() {
    final rawCoverage = cacheHelper.getDataString(
      key: PrayerNotificationScheduler.coverageKey,
    );
    final coverage = DateTime.tryParse(rawCoverage ?? '');
    if (coverage == null) return;
    _notificationScheduleResult = PrayerScheduleResult(
      status: coverage.isAfter(DateTime.now())
          ? PrayerScheduleStatus.upToDate
          : PrayerScheduleStatus.deferred,
      coverageUntil: coverage,
    );
  }

  PrayerTimesLoaded _loadedState(
    DailyPrayerTimes prayerTimes,
    List<Placemark> placemarks,
  ) {
    return PrayerTimesLoaded(
      prayerTimes,
      placemarks,
      offsets: _prayerOffsets,
      notificationSchedule: _notificationScheduleResult,
      notificationScheduleRetrying: _notificationScheduleRetrying,
      workflowIssues: Set.unmodifiable(_issues),
      workflowRetrying: _userRetrying,
      updating: _isUpdating,
      online: _online,
      provisional: _display?.provisional ?? false,
      previousLocationNotifications:
          _display != null &&
          _display!.location.revision != _activeProjectionRevision,
      countryCandidates: _countryQuestion,
    );
  }

  List<String> get _countryQuestion {
    final display = _display;
    if (display == null ||
        !display.provisional ||
        display.location.countryCode != null ||
        !PrayerTimesCalculator.requiresCountry(display.method) ||
        _countryQuestionDismissedRevision == display.location.revision) {
      return const [];
    }
    return display.location.countryCandidates;
  }

  void _publishNotificationSchedule(
    PrayerScheduleResult result, {
    bool retrying = false,
  }) {
    if (!result.isSuccess && result.coverageUntil == null) {
      result = PrayerScheduleResult(
        status: result.status,
        scheduledCount: result.scheduledCount,
        pendingCount: result.pendingCount,
        coverageUntil: _notificationScheduleResult?.coverageUntil,
        message: result.message,
      );
    }
    final hadNotificationIssue = _issues.contains(
      PrayerWorkflowIssue.notifications,
    );
    if ((result.isSuccess &&
            result.status != PrayerScheduleStatus.permissionDenied) ||
        result.message ==
            PrayerNotificationScheduler.verificationPendingMessage) {
      _issues.remove(PrayerWorkflowIssue.notifications);
    } else {
      _issues.add(PrayerWorkflowIssue.notifications);
    }
    if (hadNotificationIssue !=
        _issues.contains(PrayerWorkflowIssue.notifications)) {
      final display = _display;
      if (display != null) {
        _display = display.withIssues(_issues, advanceRevision: true);
        unawaited(_refreshWidgetStatus());
      }
    }
    _notificationScheduleResult = result;
    _notificationScheduleRetrying = retrying;
    final current = state;
    if (current is PrayerTimesLoaded) {
      emit(
        current.copyWith(
          workflowIssues: Set.unmodifiable(_issues),
          notificationSchedule: result,
          notificationScheduleRetrying: retrying,
        ),
      );
    }
  }

  void _setNotificationScheduleRetrying(bool retrying) {
    _notificationScheduleRetrying = retrying;
    final current = state;
    if (current is PrayerTimesLoaded) {
      emit(current.copyWith(notificationScheduleRetrying: retrying));
    }
  }

  bool get _isUpdating => _updates > 0 || (_updatesSettling?.isActive ?? false);

  void _beginUpdate() {
    _updatesSettling?.cancel();
    if (_updates++ == 0) _emitUpdating();
  }

  void _endUpdate() {
    if (--_updates > 0) return;
    _updatesSettling = Timer(const Duration(milliseconds: 300), _emitUpdating);
  }

  Future<T> _whileUpdating<T>(Future<T> Function() work) async {
    _beginUpdate();
    try {
      return await work();
    } finally {
      _endUpdate();
    }
  }

  void _emitUpdating() {
    final current = state;
    if (isClosed || current is! PrayerTimesLoaded) return;
    emit(current.copyWith(updating: _isUpdating));
  }

  void _loadOffsets() {
    _prayerOffsets = PrayerTimesCalculator.sanitizeOffsets({
      'fajr': (cacheHelper.getData(key: _fajrOffsetKey) as int?) ?? 0,
      'sunrise': (cacheHelper.getData(key: _sunriseOffsetKey) as int?) ?? 0,
      'dhuhr': (cacheHelper.getData(key: _dhuhrOffsetKey) as int?) ?? 0,
      'asr': (cacheHelper.getData(key: _asrOffsetKey) as int?) ?? 0,
      'maghrib': (cacheHelper.getData(key: _maghribOffsetKey) as int?) ?? 0,
      'isha': (cacheHelper.getData(key: _ishaOffsetKey) as int?) ?? 0,
    });
  }

  void _loadSettings() {
    _methodToken =
        cacheHelper.getDataString(key: _methodKey) ??
        PrayerTimesCalculator.defaultMethodToken;
    _madhabToken =
        cacheHelper.getDataString(key: _madhabKey) ??
        PrayerTimesCalculator.defaultMadhabToken;
    _highLatToken =
        cacheHelper.getDataString(key: _highLatKey) ??
        PrayerTimesCalculator.defaultHighLatitudeToken;
    _customAngles = PrayerTimesCalculator.customAnglesFromCache(cacheHelper);
    _prayerTimeZoneId = PrayerTimesCalculator.timeZoneNameFromCache(
      cacheHelper,
    );
    _locationMode = PrayerLocationMode.fromStorage(
      cacheHelper.getDataString(key: _locationModeKey),
    );
  }

  String get _countryCode =>
      PrayerTimesCalculator.countryCodeFromCache(cacheHelper);

  DailyPrayerTimes _computeWithSettings(
    Coordinates coordinates,
    DateTime date, {
    String? countryCode,
  }) {
    return PrayerTimesCalculator.compute(
      coordinates,
      date,
      methodToken: _methodToken,
      countryCode:
          countryCode ??
          (_display == null
              ? _countryCode
              : _display!.location.countryCode ?? ''),
      timeZoneName: _prayerTimeZoneId,
      madhab: PrayerTimesCalculator.madhabFromToken(_madhabToken),
      highLatitudeRule: PrayerTimesCalculator.highLatitudeRuleFromToken(
        _highLatToken,
      ),
      customAngles: _customAngles,
    );
  }

  DateTime _prayerCivilDate(DateTime instant) {
    final zone = _prayerTimeZoneId;
    if (zone == null) return instant.toLocal();
    return PrayerTimeZoneService.wallClockAtInstant(instant, zone);
  }

  Future<String> _resolveTimeZone(
    double latitude,
    double longitude,
    String countryCode,
  ) async {
    final zone = await _timeZoneResolver(
      latitude,
      longitude,
      countryCode,
    ).timeout(const Duration(seconds: 5));
    PrayerTimeZoneService.location(zone);
    return zone;
  }

  Future<void> _persistTimeZone(String zone) async {
    await cacheHelper.saveData(key: _timeZoneIdKey, value: zone);
    _prayerTimeZoneId = zone;
  }

  Future<void> _persistLocationMode(PrayerLocationMode mode) async {
    await cacheHelper.saveData(key: _locationModeKey, value: mode.name);
    _locationMode = mode;
    await _locationMonitor?.sync(mode);
  }

  Future<void> _cachePlacemark(List<Placemark> placemarks) async {
    if (placemarks.isEmpty) {
      await _clearPlacemarkCache();
      return;
    }
    final placemark = placemarks.first;
    final code = (placemark.isoCountryCode ?? '').trim();
    await _saveOrRemove(_countryCodeKey, code);
    await _saveOrRemove(_localityKey, placemark.locality);
    await _saveOrRemove(_countryNameKey, placemark.country);
  }

  Future<void> _clearPlacemarkCache() async {
    await cacheHelper.removeData(key: _countryCodeKey);
    await cacheHelper.removeData(key: _localityKey);
    await cacheHelper.removeData(key: _countryNameKey);
  }

  Future<List<Placemark>> _resolvePlacemarks(
    double lat,
    double lon, {
    required bool preserveCachedMetadata,
  }) async {
    final cached = _cachedPlacemarks();
    if (preserveCachedMetadata && cached.isNotEmpty) return cached;

    try {
      final placemarks = _placemarkProvider == null
          ? await _locations.getPlacemarks(lat, lon)
          : await _placemarkProvider(lat, lon);
      return placemarks;
    } catch (error) {
      debugPrint('Could not resolve prayer location name: $error');
      if (preserveCachedMetadata) return cached;
      return const [];
    }
  }

  Future<void> _saveOrRemove(String key, String? value) async {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      await cacheHelper.removeData(key: key);
    } else {
      await cacheHelper.saveData(key: key, value: normalized);
    }
  }

  List<Placemark> _cachedPlacemarks() {
    final locality = cacheHelper.getDataString(key: _localityKey)?.trim() ?? '';
    final country =
        cacheHelper.getDataString(key: _countryNameKey)?.trim() ?? '';
    final countryCode = _countryCode.trim().toUpperCase();
    if (locality.isEmpty && country.isEmpty && countryCode.isEmpty) {
      return const [];
    }
    return [
      Placemark(
        locality: locality,
        country: country.isEmpty ? countryCode : country,
        isoCountryCode: countryCode,
      ),
    ];
  }

  Future<void> savePrayerOffsets(Map<String, int> offsets) async {
    final sanitized = PrayerTimesCalculator.sanitizeOffsets(offsets);
    _displayEpoch++;
    if (_display != null && _locationRepository != null) {
      await _acceptDisplay(_display!.withSettings(offsets: sanitized));
      if (!_display!.provisional) {
        await _reconcilePrayerNotifications('offsets-changed', force: true);
      }
      return;
    }
    final repository = _locationRepository;
    if (repository == null) {
      await _persistOffsets(sanitized);
    } else {
      await repository.synchronized((_) => _persistOffsets(sanitized));
    }
    _prayerOffsets = sanitized;
    if (state is PrayerTimesLoaded) {
      final current = state as PrayerTimesLoaded;
      emit(current.copyWith(offsets: _prayerOffsets));
    }
    if (_coordinator == null) await PrayerWidgetService.pushSettings();
    await _refreshDisplaySettings();
    await _reconcilePrayerNotifications('offsets-changed', force: true);
  }

  Future<void> savePrayerSettings({
    required String methodToken,
    required String madhabToken,
    required String highLatToken,
    required Map<String, int> offsets,
    required CustomPrayerAngles customAngles,
  }) async {
    final sanitizedCustomAngles = CustomPrayerAngles.fromStoredValues(
      fajr: customAngles.fajr,
      maghrib: customAngles.maghrib,
      isha: customAngles.isha,
    );
    final sanitizedOffsets = PrayerTimesCalculator.sanitizeOffsets(offsets);
    _displayEpoch++;
    if (_display != null && _locationRepository != null) {
      await _acceptDisplay(
        _display!.withSettings(
          method: methodToken,
          madhab: madhabToken,
          highLatitude: highLatToken,
          angles: sanitizedCustomAngles,
          offsets: sanitizedOffsets,
        ),
      );
      if (!_display!.provisional) {
        await _reconcilePrayerNotifications(
          'calculation-settings-changed',
          force: true,
        );
      }
      return;
    }
    Future<void> persistSettings() async {
      await cacheHelper.saveData(key: _methodKey, value: methodToken);
      await cacheHelper.saveData(key: _madhabKey, value: madhabToken);
      await cacheHelper.saveData(key: _highLatKey, value: highLatToken);
      await _persistCustomAngles(sanitizedCustomAngles);
      await _persistOffsets(sanitizedOffsets);
    }

    final repository = _locationRepository;
    if (repository == null) {
      await persistSettings();
    } else {
      await repository.synchronized((_) => persistSettings());
    }

    _displayEpoch++;
    _methodToken = methodToken;
    _madhabToken = madhabToken;
    _highLatToken = highLatToken;
    _customAngles = sanitizedCustomAngles;
    _prayerOffsets = sanitizedOffsets;

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates != null && _display == null) {
      final placemarks = state is PrayerTimesLoaded
          ? (state as PrayerTimesLoaded).placemarks
          : <Placemark>[];
      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(DateTime.now()),
      );
      emit(_loadedState(prayerTimes, placemarks));
    }

    if (_coordinator == null) await PrayerWidgetService.pushSettings();
    await _refreshDisplaySettings();
    await _reconcilePrayerNotifications(
      'calculation-settings-changed',
      force: true,
    );
  }

  Future<void> _persistCustomAngles(CustomPrayerAngles angles) async {
    await cacheHelper.saveData(
      key: PrayerTimesCalculator.customFajrAngleKey,
      value: CustomPrayerAngles.canonical(angles.fajr),
    );
    await cacheHelper.saveData(
      key: PrayerTimesCalculator.customMaghribAngleKey,
      value: CustomPrayerAngles.canonical(angles.maghrib),
    );
    await cacheHelper.saveData(
      key: PrayerTimesCalculator.customIshaAngleKey,
      value: CustomPrayerAngles.canonical(angles.isha),
    );
  }

  Future<void> _persistOffsets(Map<String, int> offsets) async {
    await cacheHelper.saveData(
      key: _fajrOffsetKey,
      value: offsets['fajr'] ?? 0,
    );
    await cacheHelper.saveData(
      key: _dhuhrOffsetKey,
      value: offsets['dhuhr'] ?? 0,
    );
    await cacheHelper.saveData(key: _asrOffsetKey, value: offsets['asr'] ?? 0);
    await cacheHelper.saveData(
      key: _maghribOffsetKey,
      value: offsets['maghrib'] ?? 0,
    );
    await cacheHelper.saveData(
      key: _ishaOffsetKey,
      value: offsets['isha'] ?? 0,
    );
    await cacheHelper.saveData(
      key: _sunriseOffsetKey,
      value: offsets['sunrise'] ?? 0,
    );
  }

  String _getLocalizedPrayerNameForCountdown(Prayer prayer) {
    final localizations = _localizations;
    if (localizations == null) {
      return _getPrayerDisplayName(prayer);
    }

    return _getLocalizedPrayerName(prayer, localizations);
  }

  String _getLocalizedPrayerName(
    Prayer prayer,
    AppLocalizations localizations,
  ) {
    switch (prayer) {
      case Prayer.fajr:
        return localizations.fajr;
      case Prayer.dhuhr:
        return localizations.dhuhr;
      case Prayer.asr:
        return localizations.asr;
      case Prayer.maghrib:
        return localizations.maghrib;
      case Prayer.isha:
        return localizations.isha;
      default:
        return _getPrayerDisplayName(prayer);
    }
  }

  Future<void> scheduleNotificationsForToday(
    NotificationServices notificationServices,
  ) async {
    await _reconcilePrayerNotifications('prayer-times-requested');
  }

  Future<void> scheduleNotificationsForMultipleDays(
    NotificationServices notificationServices,
    int daysAhead,
  ) async {
    await _reconcilePrayerNotifications('multi-day-prayer-times-requested');
  }

  Future<void> refreshNotificationSchedule() async {
    await _reconcilePrayerNotifications(
      'notification-schedule-refresh',
      force: true,
    );
  }

  Future<void> retryNotificationSchedule() async {
    await _reconcilePrayerNotifications(
      'notification-schedule-retry',
      force: true,
      userRetry: true,
    );
  }

  Future<PrayerScheduleResult> _reconcilePrayerNotifications(
    String reason, {
    bool force = false,
    bool userRetry = false,
  }) async {
    if (!userRetry) {
      return _whileUpdating(() => _reconcile(reason, force: force));
    }
    _setNotificationScheduleRetrying(true);
    return _reconcile(reason, force: force);
  }

  Future<PrayerScheduleResult> _reconcile(
    String reason, {
    required bool force,
  }) async {
    try {
      final result = await _notificationScheduler.reconcile(
        reason: reason,
        force: force,
      );
      debugPrint(
        'Prayer notification status: ${result.status.name}; '
        'pending=${result.pendingCount}; coverage=${result.coverageUntil}',
      );
      _publishNotificationSchedule(result);
      await _persistDisplayIssues();
      return result;
    } catch (error) {
      _issues.add(PrayerWorkflowIssue.notifications);
      _renderDisplay();
      debugPrint('Could not update prayer notifications: $error');
      const result = PrayerScheduleResult(
        status: PrayerScheduleStatus.failed,
        message: PrayerPushErrorCode.unavailable,
      );
      _publishNotificationSchedule(result);
      await _persistDisplayIssues();
      return result;
    }
  }

  Future<void> loadPrayerTimes() => _whileUpdating(_loadPrayerTimes);

  Future<void> _loadPrayerTimes() async {
    if (_workflowRetrying) return;
    try {
      final restored = await _locationRepository?.readState();
      _display = restored?.displaySnapshot ?? _display;
      _issues.addAll(restored?.workflowIssues ?? {});
      _knownPersistedIssues.addAll(restored?.workflowIssues ?? {});
      if (restored?.acknowledgedCoverageUntilUtc != null) {
        _notificationScheduleResult = PrayerScheduleResult(
          status: restored!.journal == null
              ? PrayerScheduleStatus.upToDate
              : PrayerScheduleStatus.deferred,
          coverageUntil: restored.acknowledgedCoverageUntilUtc,
        );
      }
      if (restored?.journal != null) {
        _issues.add(PrayerWorkflowIssue.notifications);
      }
      if (restored?.widgetPublicationPending == true) {
        _issues.add(PrayerWorkflowIssue.widget);
      }
      _issues.addAll(_display?.issues ?? {});
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.storage);
    }
    if (_display != null) {
      await _acceptDisplay(_display!);
      await _verifyLegacyManualDisplay();
      return;
    }
    if (state is! PrayerTimesLoaded) emit(PrayerTimesLoading());

    try {
      var coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);

      if (coordinates == null && _coordinator != null) {
        final position = await _currentLocationProvider();
        final result = await _coordinator!.submit(
          fix: _fixFromPosition(position),
          mode: PrayerLocationMode.automatic,
          source: PrayerLocationSource.explicit,
          reason: 'initial-device-location',
          explicitUserAction: true,
        );
        await _renderCoordinatorResult(result);
        return;
      }
      final usingCachedCoordinates = coordinates != null;

      if (coordinates == null) {
        final position = await _currentLocationProvider();
        coordinates = Coordinates(position.latitude, position.longitude);
      }

      final placemarks = await _resolvePlacemarks(
        coordinates.latitude,
        coordinates.longitude,
        preserveCachedMetadata: usingCachedCoordinates,
      );

      final countryCode = placemarks.isNotEmpty
          ? (placemarks.first.isoCountryCode ?? '').trim()
          : _countryCode;
      String? resolvedZone;
      if (_prayerTimeZoneId == null || !usingCachedCoordinates) {
        resolvedZone = await _resolveTimeZone(
          coordinates.latitude,
          coordinates.longitude,
          countryCode,
        );
      }

      if (!usingCachedCoordinates) {
        await cacheHelper.saveData(
          key: _latKey,
          value: coordinates.latitude.toString(),
        );
        await cacheHelper.saveData(
          key: _lonKey,
          value: coordinates.longitude.toString(),
        );
        await _persistLocationMode(PrayerLocationMode.automatic);
      }
      await _cachePlacemark(placemarks);
      if (resolvedZone != null) await _persistTimeZone(resolvedZone);

      _loadSettings();
      _loadOffsets();

      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(DateTime.now()),
      );

      emit(_loadedState(prayerTimes, placemarks));
      await _syncLoadedPrayerTimes('location-loaded');
    } catch (e) {
      _emitLocationFailure(e);
    }
  }

  void loadCachedPrayerTimes() {
    unawaited(_checkConnectivity());
    if (_display != null) {
      _renderDisplay();
      return;
    }
    if (state is PrayerTimesLoading) return;

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates == null) {
      // Keep actionable failure states intact when the app resumes after a
      // permission or settings dialog. Only the untouched initial state means
      // that location setup has not been attempted yet.
      if (state is PrayerTimesInitial) emit(PrayerTimesNeedsSetup());
      return;
    }

    try {
      _loadSettings();
      _loadOffsets();
      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(DateTime.now()),
      );
      final currentPlacemarks = state is PrayerTimesLoaded
          ? (state as PrayerTimesLoaded).placemarks
          : const <Placemark>[];
      final placemarks = currentPlacemarks.isNotEmpty
          ? currentPlacemarks
          : _cachedPlacemarks();
      emit(_loadedState(prayerTimes, placemarks));
    } catch (error) {
      _issues.add(PrayerWorkflowIssue.calculation);
      unawaited(_persistDisplayIssues());
      emit(PrayerTimesError(error.toString()));
    }
  }

  Future<void> setManualLocation(
    double lat,
    double lon, {
    String? cityName,
    String? countryCode,
  }) => _whileUpdating(
    () => _setManualLocation(
      lat,
      lon,
      cityName: cityName,
      countryCode: countryCode,
    ),
  );

  Future<void> _setManualLocation(
    double lat,
    double lon, {
    String? cityName,
    String? countryCode,
  }) async {
    final epoch = ++_displayEpoch;
    _issues.remove(PrayerWorkflowIssue.location);
    if (_coordinator != null) {
      final previous = state is PrayerTimesLoaded
          ? state as PrayerTimesLoaded
          : null;
      if (state is! PrayerTimesLoaded) emit(PrayerTimesLoading());
      final parts = (cityName ?? '')
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      final supplied = cityName == null && countryCode == null
          ? null
          : PrayerLocationMetadata(
              locality: parts.isEmpty ? null : parts.first,
              countryName: parts.length > 1 ? parts.last : null,
              countryCode: countryCode,
            );
      final result = await _coordinator!.submit(
        fix: PrayerLocationFix(
          latitude: lat,
          longitude: lon,
          capturedAtUtc: DateTime.now().toUtc(),
        ),
        mode: PrayerLocationMode.manual,
        source: PrayerLocationSource.explicit,
        reason: 'manual-location-changed',
        isCurrent: () => !isClosed && epoch == _displayEpoch,
        explicitUserAction: true,
        suppliedMetadata: supplied,
      );
      await _renderCoordinatorResult(result, previous: previous);
      return;
    }
    if (state is! PrayerTimesLoaded) emit(PrayerTimesLoading());

    try {
      final List<Placemark> placemarks;
      String country = (countryCode ?? '').trim();
      if (cityName != null && cityName.trim().isNotEmpty) {
        final parts = cityName
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        placemarks = [
          Placemark(
            locality: parts.isNotEmpty ? parts.first : cityName.trim(),
            country: parts.length > 1 ? parts.last : '',
            isoCountryCode: country,
          ),
        ];
      } else {
        placemarks = await _resolvePlacemarks(
          lat,
          lon,
          preserveCachedMetadata: false,
        );
        country = placemarks.isNotEmpty
            ? (placemarks.first.isoCountryCode ?? '').trim()
            : '';
      }
      final zone = await _resolveTimeZone(lat, lon, country);

      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());
      await _persistLocationMode(PrayerLocationMode.manual);
      await _cachePlacemark(placemarks);
      await _persistTimeZone(zone);

      _loadSettings();
      _loadOffsets();

      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(DateTime.now()),
        countryCode: country,
      );

      emit(_loadedState(prayerTimes, placemarks));
      await _syncLoadedPrayerTimes('manual-location-changed');
    } catch (e) {
      _emitLocationFailure(e);
    }
  }

  Future<void> refreshLocationAndPrayerTimes() =>
      _whileUpdating(_refreshLocationAndPrayerTimes);

  Future<void> _refreshLocationAndPrayerTimes() async {
    final epoch = ++_displayEpoch;
    final previousPrayerTimes = state is PrayerTimesLoaded
        ? state as PrayerTimesLoaded
        : null;
    if (state is! PrayerTimesLoaded) emit(PrayerTimesLoading());

    try {
      final position = await _currentLocationProvider();
      _issues.remove(PrayerWorkflowIssue.location);
      if (_coordinator != null) {
        final result = await _coordinator!.submit(
          fix: _fixFromPosition(position),
          mode: PrayerLocationMode.automatic,
          source: PrayerLocationSource.explicit,
          reason: 'device-location-changed',
          isCurrent: () => !isClosed && epoch == _displayEpoch,
          explicitUserAction: true,
        );
        await _renderCoordinatorResult(result, previous: previousPrayerTimes);
        return;
      }
      final lat = position.latitude;
      final lon = position.longitude;

      final placemarks = await _resolvePlacemarks(
        lat,
        lon,
        preserveCachedMetadata: false,
      );

      final countryCode = placemarks.isNotEmpty
          ? (placemarks.first.isoCountryCode ?? '').trim()
          : _countryCode;
      final zone = await _resolveTimeZone(lat, lon, countryCode);

      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());
      await _persistLocationMode(PrayerLocationMode.automatic);
      await _cachePlacemark(placemarks);
      await _persistTimeZone(zone);

      _loadSettings();
      _loadOffsets();

      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(DateTime.now()),
      );

      emit(_loadedState(prayerTimes, placemarks));
      await _syncLoadedPrayerTimes('device-location-changed');
    } catch (e) {
      if (previousPrayerTimes != null) {
        // A refresh failure must not discard an already usable manual or
        // cached schedule. The user can retry precise device location later.
        _issues.add(PrayerWorkflowIssue.location);
        emit(previousPrayerTimes);
        await _persistDisplayIssues();
        _renderDisplay();
      } else {
        _emitLocationFailure(e);
      }
    }
  }

  Future<void> refreshAutomaticLocationIfNeeded({
    DateTime? now,
    bool force = false,
  }) async {
    await cacheHelper.reload();
    _loadSettings();
    _loadOffsets();
    final checkTime = now ?? DateTime.now();
    _refreshLoadedStateFromCache(checkTime);
    if (_locationMode != PrayerLocationMode.automatic ||
        _automaticLocationRefreshInProgress) {
      return;
    }

    final lastValidation =
        (cacheHelper.getData(key: _lastLocationValidationKey) as int?) ?? 0;
    if (!force && _shouldThrottleValidation(checkTime, lastValidation)) {
      return;
    }

    _automaticLocationRefreshInProgress = true;
    _beginUpdate();
    try {
      final position = await _travelLocationProvider();
      if (position == null) return;
      _issues.remove(PrayerWorkflowIssue.location);

      if (_coordinator != null) {
        final result = await _coordinator!.submit(
          fix: _fixFromPosition(position),
          mode: PrayerLocationMode.automatic,
          source: PrayerLocationSource.foreground,
          reason: 'automatic-travel-location-changed',
        );
        if (_isSuccessfulLocationValidation(result)) {
          await _recordSuccessfulLocationValidation(checkTime);
        }
        if (result.generation != null) {
          await _renderCoordinatorResult(result);
        } else if (result.status ==
            PrayerLocationUpdateStatus.ignoredInsignificant) {
          _refreshLoadedStateFromCache(checkTime);
        } else if (result.status !=
                PrayerLocationUpdateStatus.ignoredManualMode &&
            result.status != PrayerLocationUpdateStatus.superseded) {
          debugPrint(
            'Automatic prayer location remained unchanged: '
            '${result.status.name} ${result.message ?? ''}',
          );
        }
        return;
      }

      final previous = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
      String? nearbyResolvedZone;
      if (previous != null) {
        final distance = distanceMeters(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < 10000) {
          nearbyResolvedZone = await _resolveTimeZone(
            position.latitude,
            position.longitude,
            _countryCode,
          );
          if (nearbyResolvedZone == _prayerTimeZoneId) {
            await _recordSuccessfulLocationValidation(checkTime);
            return;
          }
        }
      }

      final lat = position.latitude;
      final lon = position.longitude;
      final placemarks = await _resolvePlacemarks(
        lat,
        lon,
        preserveCachedMetadata: false,
      );
      final countryCode = placemarks.isNotEmpty
          ? (placemarks.first.isoCountryCode ?? '').trim()
          : '';
      final zone =
          nearbyResolvedZone ?? await _resolveTimeZone(lat, lon, countryCode);

      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());
      await _persistLocationMode(PrayerLocationMode.automatic);
      await _cachePlacemark(placemarks);
      await _persistTimeZone(zone);

      _loadSettings();
      _loadOffsets();
      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(
        coordinates,
        _prayerCivilDate(checkTime),
        countryCode: countryCode,
      );
      emit(_loadedState(prayerTimes, placemarks));
      await _syncLoadedPrayerTimes('automatic-travel-location-changed');
      await _recordSuccessfulLocationValidation(checkTime);
    } catch (error) {
      _issues.add(PrayerWorkflowIssue.location);
      _renderDisplay();
      await _persistDisplayIssues();
      debugPrint('Could not refresh automatic prayer location: $error');
    } finally {
      _automaticLocationRefreshInProgress = false;
      _endUpdate();
    }
  }

  Future<void> submitForegroundPosition(Position position) async {
    final coordinator = _coordinator;
    if (coordinator == null || _locationMode != PrayerLocationMode.automatic) {
      return;
    }
    final result = await coordinator.submit(
      fix: _fixFromPosition(position),
      mode: PrayerLocationMode.automatic,
      source: PrayerLocationSource.foreground,
      reason: 'foreground-position-change',
    );
    if (_isSuccessfulLocationValidation(result)) {
      await _recordSuccessfulLocationValidation(DateTime.now());
    }
    if (result.activated || result.scheduleResult != null) {
      await _renderCoordinatorResult(result);
    }
  }

  Future<void> consumeQueuedNativeLocationCandidate() async {
    final repository = _locationRepository;
    if (repository == null) return;
    await cacheHelper.reload();
    const key = 'prayer_location_native_candidate_v1';
    final raw = cacheHelper.getDataString(key: key);
    if (raw == null || raw.isEmpty) return;
    if (cacheHelper.getData(
          key: PrayerLocationMonitor.backgroundTravelEnabledKey,
        ) !=
        true) {
      await PrayerLocationMonitor.consumeNativeCandidate(raw);
      return;
    }
    _beginUpdate();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        _issues.add(PrayerWorkflowIssue.nativeCandidate);
        await _persistDisplayIssues();
        _renderDisplay();
        await PrayerLocationMonitor.consumeNativeCandidate(raw);
        return;
      }
      double? number(String field) {
        final value = decoded[field];
        if (value is! num) return null;
        final parsed = value.toDouble();
        return parsed.isFinite ? parsed : null;
      }

      final latitude = number('latitude');
      final longitude = number('longitude');
      final accuracy = number('accuracyMeters');
      final capturedAt = DateTime.tryParse(
        decoded['capturedAtUtc']?.toString() ?? '',
      );
      final zone = decoded['timeZoneId']?.toString().trim() ?? '';
      if (latitude == null ||
          longitude == null ||
          accuracy == null ||
          capturedAt == null ||
          !capturedAt.isUtc) {
        _issues.add(PrayerWorkflowIssue.nativeCandidate);
        await _persistDisplayIssues();
        _renderDisplay();
        await PrayerLocationMonitor.consumeNativeCandidate(raw);
        return;
      }
      if (zone.isNotEmpty) PrayerTimeZoneService.location(zone);
      final metadata = PrayerLocationMetadata(
        countryCode: decoded['countryCode']?.toString(),
      );
      final source =
          decoded['source']?.toString() ==
              PrayerLocationSource.iosSignificantChange.name
          ? PrayerLocationSource.iosSignificantChange
          : PrayerLocationSource.androidBackground;
      final coordinator = PrayerLocationCoordinator(
        cacheHelper: cacheHelper,
        repository: repository,
        activator: _notificationScheduler,
        timeZoneResolver: _timeZoneResolver,
        onDisplay: _acceptDisplay,
        metadataResolver: (_, _) async => metadata,
      );
      final result = await coordinator.submit(
        fix: PrayerLocationFix(
          latitude: latitude,
          longitude: longitude,
          capturedAtUtc: capturedAt,
          accuracyMeters: accuracy,
        ),
        mode: PrayerLocationMode.automatic,
        source: source,
        reason: '${source.name}-queued-candidate',
        suppliedMetadata: metadata,
      );
      if (_isSuccessfulLocationValidation(result)) {
        await _recordSuccessfulLocationValidation(DateTime.now());
      }
      if (result.activated || result.scheduleResult != null) {
        await _renderCoordinatorResult(result);
      }
      await cacheHelper.reload();
      final latest = cacheHelper.getDataString(key: key);
      if (latest == raw && !_retryableNativeCandidate(result.status)) {
        if (await PrayerLocationMonitor.consumeNativeCandidate(raw)) {
          _issues.remove(PrayerWorkflowIssue.nativeCandidate);
        }
      } else if (_retryableNativeCandidate(result.status)) {
        _issues.add(PrayerWorkflowIssue.nativeCandidate);
      }
      await _persistDisplayIssues();
      _renderDisplay();
    } catch (error) {
      _issues.add(PrayerWorkflowIssue.nativeCandidate);
      _renderDisplay();
      await _persistDisplayIssues();
      debugPrint('Could not consume native prayer location candidate: $error');
    } finally {
      _endUpdate();
    }
  }

  static bool _isSuccessfulLocationValidation(
    PrayerLocationUpdateResult result,
  ) =>
      result.activated ||
      result.status == PrayerLocationUpdateStatus.ignoredInsignificant;

  static bool _retryableNativeCandidate(PrayerLocationUpdateStatus status) =>
      status == PrayerLocationUpdateStatus.timeZoneUnavailable ||
      status == PrayerLocationUpdateStatus.deferredCountry ||
      status == PrayerLocationUpdateStatus.degraded ||
      status == PrayerLocationUpdateStatus.failed;

  static bool _shouldThrottleValidation(
    DateTime now,
    int lastValidationMillis,
  ) {
    if (lastValidationMillis <= 0 ||
        now.millisecondsSinceEpoch < lastValidationMillis) {
      return false;
    }
    return now.millisecondsSinceEpoch - lastValidationMillis <
        const Duration(minutes: 30).inMilliseconds;
  }

  Future<void> _recordSuccessfulLocationValidation(DateTime validatedAt) {
    return cacheHelper.saveData(
      key: _lastLocationValidationKey,
      value: validatedAt.millisecondsSinceEpoch,
    );
  }

  void _refreshLoadedStateFromCache(DateTime now) {
    if (_display != null) {
      _renderDisplay(now: now);
      return;
    }
    if (state is! PrayerTimesLoaded) return;
    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates == null) return;
    final loaded = state as PrayerTimesLoaded;
    final cachedPlacemarks = _cachedPlacemarks();
    emit(
      _loadedState(
        _computeWithSettings(coordinates, _prayerCivilDate(now)),
        cachedPlacemarks.isEmpty ? loaded.placemarks : cachedPlacemarks,
      ),
    );
  }

  @visibleForTesting
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

  Future<void> _syncLoadedPrayerTimes(String reason) async {
    try {
      await _reconcilePrayerNotifications(reason, force: true);
    } catch (error) {
      _issues.add(PrayerWorkflowIssue.notifications);
      _renderDisplay();
      debugPrint('Could not update prayer notifications: $error');
    }

    if (_coordinator == null) {
      try {
        await PrayerWidgetService.pushSettings();
      } catch (error) {
        _issues.add(PrayerWorkflowIssue.widget);
        await _persistDisplayIssues();
        _renderDisplay();
        debugPrint('Could not update prayer widgets: $error');
      }
    }
  }

  PrayerLocationFix _fixFromPosition(Position position) {
    return PrayerLocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      capturedAtUtc: position.timestamp.toUtc(),
      accuracyMeters: position.accuracy,
    );
  }

  Future<void> _renderCoordinatorResult(
    PrayerLocationUpdateResult result, {
    PrayerTimesLoaded? previous,
  }) async {
    final scheduleResult = result.scheduleResult;
    if (scheduleResult != null) {
      _publishNotificationSchedule(scheduleResult);
    }
    if (result.status == PrayerLocationUpdateStatus.superseded ||
        result.status == PrayerLocationUpdateStatus.ignoredInsignificant ||
        result.status == PrayerLocationUpdateStatus.ignoredManualMode) {
      return;
    }
    final generation = result.generation;
    final canRenderDespiteSchedulingIssue = generation != null;
    if (!result.activated && !canRenderDespiteSchedulingIssue) {
      _issues.add(PrayerWorkflowIssue.location);
      if (previous != null) {
        _issues.add(PrayerWorkflowIssue.location);
        emit(previous);
        await _persistDisplayIssues();
        _renderDisplay();
      } else {
        await _persistDisplayIssues();
        emit(
          PrayerTimesError(
            result.message ??
                'Prayer location update did not reach a safe activation point.',
          ),
        );
      }
      return;
    }
    if (isClosed) return;
    if (generation != null &&
        _display?.location.revision == generation.revision) {
      _renderDisplay();
      unawaited(_enrichCurrentDisplay());
      return;
    }
    await cacheHelper.reload();
    _loadSettings();
    _loadOffsets();
    if (generation != null) {
      _locationMode = generation.mode;
      _prayerTimeZoneId = generation.timeZoneId;
    }
    final coordinates = generation == null
        ? PrayerTimesCalculator.coordinatesFromCache(cacheHelper)
        : Coordinates(generation.latitude, generation.longitude);
    if (coordinates == null) {
      emit(PrayerTimesNeedsSetup());
      return;
    }
    final placemarks = generation == null
        ? _cachedPlacemarks()
        : <Placemark>[
            if (generation.locality != null ||
                generation.countryName != null ||
                generation.countryCode != null)
              Placemark(
                locality: generation.locality,
                country: _countryDisplayName(
                  generation.countryCode,
                  generation.countryName,
                ),
                isoCountryCode: generation.countryCode,
              ),
          ];
    final prayerTimes = _computeWithSettings(
      coordinates,
      _prayerCivilDate(DateTime.now()),
      countryCode: generation == null ? null : generation.countryCode ?? '',
    );
    emit(_loadedState(prayerTimes, placemarks));
    if (result.activated) {
      await _locationMonitor?.sync(_locationMode);
    }
  }

  void _emitLocationFailure(Object error) {
    _issues.add(PrayerWorkflowIssue.location);
    unawaited(_persistDisplayIssues());
    if (state is PrayerTimesLoaded) {
      _renderDisplay();
      return;
    }
    final message = error.toString();
    if (error is LocationServiceDisabledFailure ||
        message == 'Exception: Location services are disabled.') {
      emit(PrayerTimesLocationServiceDisabled());
    } else if (error is LocationPermissionDeniedFailure ||
        message == 'Exception: Location permissions are denied.' ||
        message == 'Exception: Location permissions are denied') {
      emit(PrayerTimesLocationDenied());
    } else if (error is LocationPermissionPermanentlyDeniedFailure ||
        message == 'Exception: Location permissions are permanently denied.') {
      emit(PrayerTimesLocationPermanentlyDenied());
    } else {
      emit(PrayerTimesError(message));
    }
  }

  Stream<NextPrayerCountdown> getNextPrayerCountdown() async* {
    while (true) {
      if (state is! PrayerTimesLoaded) {
        yield const NextPrayerCountdown(
          prayerName: '...',
          duration: Duration.zero,
        );
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      try {
        final now = DateTime.now();
        final currentPrayerInfo = await getCurrentOrNextPrayerTime(now);

        if (currentPrayerInfo.isPastPrayer) {
          yield NextPrayerCountdown(
            prayerName: currentPrayerInfo.name,
            duration: Duration.zero,
            isPastPrayer: true,
            secondsPassed: currentPrayerInfo.secondsPassed,
            prayer: currentPrayerInfo.prayer,
            instant: currentPrayerInfo.time,
          );
        } else {
          final duration = currentPrayerInfo.time.difference(now);

          if (duration.isNegative) {
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          yield NextPrayerCountdown(
            prayerName: currentPrayerInfo.name,
            duration: duration,
            prayer: currentPrayerInfo.prayer,
            instant: currentPrayerInfo.time,
          );
        }
      } catch (e) {
        debugPrint('Error in countdown stream: $e');
        yield const NextPrayerCountdown(
          prayerName: 'Error calculating next prayer',
          duration: Duration.zero,
        );
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @visibleForTesting
  Future<NextPrayerInfo> getCurrentOrNextPrayerTime(DateTime now) async {
    if (state is! PrayerTimesLoaded) {
      throw Exception('Prayer times not loaded');
    }

    final coordinates = _display == null
        ? PrayerTimesCalculator.coordinatesFromCache(cacheHelper)
        : Coordinates(
            _display!.location.latitude,
            _display!.location.longitude,
          );
    if (coordinates == null) {
      throw Exception('Location not available');
    }

    final civilNow = _prayerCivilDate(now);
    final civilAnchor = DateTime.utc(
      civilNow.year,
      civilNow.month,
      civilNow.day,
    );
    final transitions = <PrayerTransition>[];
    for (var dayOffset = -1; dayOffset <= 7; dayOffset++) {
      final parts = civilAnchor.add(Duration(days: dayOffset));
      final date = DateTime(parts.year, parts.month, parts.day);
      final prayerTimes =
          _display?.computeDate(date) ??
          _computeWithSettings(coordinates, date);
      for (final entry in PrayerTimesCalculator.dailyAdjustedInstants(
        prayerTimes,
        _prayerOffsets,
      ).entries) {
        transitions.add(
          PrayerTransition(prayer: entry.key, instant: entry.value),
        );
      }
    }

    final moment = PrayerMomentResolver.resolve(
      now: now,
      transitions: transitions,
    );
    if (moment == null) {
      throw Exception('No upcoming prayer time available in the next 7 days');
    }
    return NextPrayerInfo(
      name: _getLocalizedPrayerNameForCountdown(moment.prayer),
      time: moment.prayerInstant,
      isPastPrayer: moment.isElapsed,
      secondsPassed: moment.isElapsed
          ? now.toUtc().difference(moment.prayerInstant).inSeconds
          : 0,
      prayer: moment.prayer,
    );
  }

  int? get _activeProjectionRevision {
    try {
      return (jsonDecode(
                cacheHelper.getDataString(
                      key: PrayerLocationRepository.generationProjectionKey,
                    ) ??
                    '{}',
              )
              as Map)['revision']
          as int?;
    } catch (_) {
      return null;
    }
  }

  void _observeConnectivity() {
    try {
      _connectivitySubscription =
          (_connectivityChanges ?? Connectivity().onConnectivityChanged).listen(
            (values) {
              final wasOnline = _online;
              _online = !values.contains(ConnectivityResult.none);
              _renderDisplay();
              if (_online == false) {
                _networkRetryTimer?.cancel();
              } else if (wasOnline == false) {
                _scheduleNetworkRetry(reconnected: true);
              }
            },
            onError: (Object _) {
              _online = null;
              _renderDisplay();
            },
          );
    } catch (_) {
      _online = null;
    }
    unawaited(_checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    try {
      _online =
          !(await (_connectivityCheck ?? Connectivity().checkConnectivity)()
                  .timeout(const Duration(seconds: 3)))
              .contains(ConnectivityResult.none);
    } catch (_) {
      _online = null;
    }
    if (isClosed) return;
    _renderDisplay();
    if (_online == true) _scheduleNetworkRetry();
  }

  void _scheduleNetworkRetry({bool reconnected = false}) {
    final minimumInterval = reconnected
        ? const Duration(seconds: 30)
        : const Duration(minutes: 5);
    final last = _lastNetworkRetry;
    if (last != null && DateTime.now().difference(last) < minimumInterval) {
      return;
    }
    _networkRetryTimer?.cancel();
    _networkRetryTimer = Timer(_networkRetryDelay, () {
      unawaited(_retryNetworkIssues());
    });
  }

  Future<void> _retryNetworkIssues() async {
    if (isClosed || _workflowRetrying || _online == false) return;
    final notifications =
        _issues.contains(PrayerWorkflowIssue.notifications) &&
        !_issues.contains(PrayerWorkflowIssue.verification);
    final locality =
        _display != null && _issues.contains(PrayerWorkflowIssue.locality);
    if (!notifications && !locality) return;
    _lastNetworkRetry = DateTime.now();
    _workflowRetrying = true;
    _beginUpdate();
    final epoch = _displayEpoch;
    try {
      if (notifications) {
        await _reconcilePrayerNotifications('reconnect-retry', force: true);
      }
      final display = _display;
      if (locality && display != null && !isClosed && epoch == _displayEpoch) {
        try {
          final enriched = await _coordinator?.enrichDisplay(
            display,
            isCurrent: () => !isClosed && epoch == _displayEpoch,
          );
          if (enriched != null && !isClosed && epoch == _displayEpoch) {
            await _acceptDisplay(enriched);
          }
        } catch (_) {
        }
      }
    } finally {
      _workflowRetrying = false;
      if (!isClosed) {
        await _persistDisplayIssues();
        _renderDisplay();
      }
      _endUpdate();
    }
  }

  void _renderDisplay({DateTime? now}) {
    if (isClosed) return;
    final display = _display;
    if (display == null) {
      final current = state;
      if (current is PrayerTimesLoaded) {
        emit(
          current.copyWith(
            workflowIssues: Set.unmodifiable(_issues),
            workflowRetrying: _userRetrying,
            updating: _isUpdating,
            online: _online,
          ),
        );
      }
      return;
    }
    try {
      _methodToken = display.method;
      _madhabToken = display.madhab;
      _highLatToken = display.highLatitude;
      _customAngles = display.angles;
      _prayerTimeZoneId = display.location.timeZoneId;
      _locationMode = display.location.mode;
      _prayerOffsets = display.offsets;
      final location = display.location;
      _dayRollover?.cancel();
      final instant = now ?? DateTime.now();
      final civil = PrayerTimeZoneService.wallClockAtInstant(
        instant,
        location.timeZoneId,
      );
      final midnight = PrayerTimeZoneService.fromWallClock(
        DateTime(civil.year, civil.month, civil.day + 1),
        location.timeZoneId,
      );
      _dayRollover = Timer(midnight.difference(instant), () {
        _renderDisplay();
        final latest = _display;
        if (latest != null) unawaited(_acceptDisplay(latest));
      });
      emit(
        _loadedState(display.compute(now ?? DateTime.now()), [
          Placemark(
            locality:
                location.locality ??
                '${location.latitude.toStringAsFixed(3)}, ${location.longitude.toStringAsFixed(3)}',
            country:
                _countryDisplayName(
                  location.countryCode,
                  location.countryName,
                ) ??
                '',
            isoCountryCode: location.countryCode,
          ),
        ]),
      );
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.calculation);
      final current = state;
      if (current is PrayerTimesLoaded) {
        emit(current.copyWith(workflowIssues: Set.unmodifiable(_issues)));
      } else {
        emit(PrayerTimesNeedsSetup());
      }
    }
  }

  Future<void> _acceptDisplay(PrayerDisplaySnapshot display) =>
      _whileUpdating(() => _acceptDisplayNow(display));

  Future<void> _acceptDisplayNow(PrayerDisplaySnapshot display) async {
    if (isClosed ||
        (_display != null &&
            (_display!.location.revision > display.location.revision ||
                (_display!.location.revision == display.location.revision &&
                    _display!.revision > display.revision)))) {
      return;
    }
    _display = display;
    _issues.removeAll({
      PrayerWorkflowIssue.verification,
      PrayerWorkflowIssue.locality,
    });
    _issues.addAll(display.issues);
    if (display.provisional) _issues.add(PrayerWorkflowIssue.verification);
    _renderDisplay();
    await _persistDisplayIssues();
    if (isClosed || _display?.revision != display.revision) return;
    try {
      await PrayerWidgetService.publishDisplay(
        display,
        cacheHelper: cacheHelper,
      );
      if (_display?.revision != display.revision) return;
      _issues.remove(PrayerWorkflowIssue.widget);
    } catch (_) {
      if (_display?.revision != display.revision) return;
      _issues.add(PrayerWorkflowIssue.widget);
    }
    await _persistDisplayIssues();
    _renderDisplay();
  }

  Future<void> _verifyLegacyManualDisplay() async {
    final display = _display;
    final coordinator = _coordinator;
    if (display == null ||
        coordinator == null ||
        _legacyVerificationAttempted) {
      return;
    }
    final location = display.location;
    final legacyManual =
        location.mode == PrayerLocationMode.manual &&
        location.timeZoneProvenance ==
            PrayerTimeZoneProvenance.legacyApproximate;
    final needsCandidates =
        display.provisional &&
        location.countryCode == null &&
        location.countryCandidates.isEmpty;
    if (!legacyManual && !needsCandidates) return;
    _legacyVerificationAttempted = true;
    final epoch = ++_displayEpoch;
    try {
      final result = await coordinator.submit(
        fix: PrayerLocationFix(
          latitude: location.latitude,
          longitude: location.longitude,
          capturedAtUtc: location.capturedAtUtc,
          accuracyMeters: location.accuracyMeters,
        ),
        mode: location.mode,
        source: location.source,
        reason: 'offline-reevaluation',
        explicitUserAction: true,
        calculationSettings: display,
        suppliedMetadata: PrayerLocationMetadata(
          countryCode: location.countryCode,
          locality: location.locality,
          countryName: location.countryName,
        ),
        isCurrent: () => !isClosed && epoch == _displayEpoch,
      );
      if (isClosed || epoch != _displayEpoch) return;
      await _renderCoordinatorResult(
        result,
        previous: state is PrayerTimesLoaded
            ? state as PrayerTimesLoaded
            : null,
      );
    } catch (error) {
      debugPrint('Could not re-evaluate prayer location: $error');
    }
  }

  Future<void> _enrichCurrentDisplay() async {
    final display = _display;
    if (display == null ||
        _online == false ||
        !display.issues.contains(PrayerWorkflowIssue.locality) ||
        _enrichmentAttemptRevision == display.location.revision) {
      return;
    }
    _enrichmentAttemptRevision = display.location.revision;
    final epoch = _displayEpoch;
    bool current() =>
        !isClosed &&
        epoch == _displayEpoch &&
        _display?.revision == display.revision;
    try {
      final updated = await _coordinator?.enrichDisplay(
        display,
        isCurrent: current,
      );
      if (updated != null && current()) await _acceptDisplay(updated);
    } catch (_) {
    }
  }

  Future<void> _refreshWidgetStatus() async {
    final revision = _display?.revision;
    if (revision == null) return;
    await _persistDisplayIssues();
    final display = _display;
    if (isClosed || display?.revision != revision) return;
    try {
      await PrayerWidgetService.publishDisplay(
        display!,
        cacheHelper: cacheHelper,
      );
      if (_display?.revision != revision) return;
      if (_issues.remove(PrayerWorkflowIssue.widget)) {
        await _persistDisplayIssues();
      }
    } catch (_) {
      if (_display?.revision != revision) return;
      _issues.add(PrayerWorkflowIssue.widget);
      await _persistDisplayIssues();
      _renderDisplay();
    }
  }

  Future<void> _persistDisplayIssues() async {
    try {
      await _locationRepository?.updateIssues(
        add: {..._issues},
        remove: _knownPersistedIssues.difference(_issues),
      );
      _knownPersistedIssues
        ..clear()
        ..addAll(_issues);
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.storage);
    }
    final display = _display;
    if (display == null) {
      return;
    }
    _display = display.withIssues(_issues);
    try {
      final accepted = await _locationRepository?.saveDisplay(_display!);
      if (accepted == false) {
        final latest =
            (await _locationRepository?.readState())?.displaySnapshot;
        if (latest != null &&
            (latest.location.revision > display.location.revision ||
                (latest.location.revision == display.location.revision &&
                    latest.revision > display.revision))) {
          _display = latest;
          _issues.addAll(latest.issues);
          _renderDisplay();
        } else {
          _issues.add(PrayerWorkflowIssue.storage);
        }
      }
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.storage);
    }
  }

  Future<void> _refreshDisplaySettings() async {
    final display = _display;
    if (display == null) return;
    await _acceptDisplay(
      PrayerDisplaySnapshot.fromCache(
        cacheHelper,
        display.location,
        issues: _issues,
      ),
    );
  }

  Future<void> chooseCountry(String countryCode) =>
      _whileUpdating(() => _chooseCountry(countryCode));

  Future<void> _chooseCountry(String countryCode) async {
    final display = _display;
    final repository = _locationRepository;
    final coordinator = _coordinator;
    if (display == null ||
        repository == null ||
        coordinator == null ||
        _workflowRetrying ||
        isClosed) {
      return;
    }
    _workflowRetrying = true;
    final epoch = ++_displayEpoch;
    _renderDisplay();
    try {
      final l = display.location;
      await repository.saveCountryChoice(
        PrayerCountryChoice(
          countryCode: countryCode,
          latitude: l.latitude,
          longitude: l.longitude,
          chosenAtUtc: DateTime.now().toUtc(),
        ),
      );
      final result = await coordinator.submit(
        fix: PrayerLocationFix(
          latitude: l.latitude,
          longitude: l.longitude,
          capturedAtUtc: l.capturedAtUtc,
          accuracyMeters: l.accuracyMeters,
        ),
        mode: l.mode,
        source: l.source,
        reason: 'country-chosen',
        explicitUserAction: true,
        calculationSettings: display,
        suppliedMetadata: PrayerLocationMetadata(
          locality: l.locality,
          countryName: l.countryName,
        ),
        isCurrent: () => !isClosed && epoch == _displayEpoch,
      );
      if (epoch == _displayEpoch && !isClosed) {
        await _renderCoordinatorResult(
          result,
          previous: state is PrayerTimesLoaded
              ? state as PrayerTimesLoaded
              : null,
        );
      }
    } catch (_) {
      _issues.add(PrayerWorkflowIssue.storage);
    } finally {
      _workflowRetrying = false;
      await _persistDisplayIssues();
      _renderDisplay();
    }
  }

  void dismissCountryQuestion() {
    final display = _display;
    if (display == null) return;
    _countryQuestionDismissedRevision = display.location.revision;
    _renderDisplay();
  }

  Future<void> retryPrayerUpdates() async {
    if (_workflowRetrying || isClosed) return;
    _workflowRetrying = true;
    _userRetrying = true;
    final epoch = ++_displayEpoch;
    _renderDisplay();
    try {
      final display = _display;
      if (display == null) {
        await refreshLocationAndPrayerTimes();
        return;
      }
      if (_issues.contains(PrayerWorkflowIssue.storage)) {
        await _retryStep('storage', PrayerWorkflowIssue.storage, () async {
          await _locationRepository?.initialize();
          _issues.remove(PrayerWorkflowIssue.storage);
        });
      }
      var notificationsRecovered = true;
      await _retryStep('journal', PrayerWorkflowIssue.storage, () async {
        final reliability = await _locationRepository?.readState();
        if (reliability?.journal != null) {
          final recovery = await _reconcilePrayerNotifications(
            'offline-recovery',
            force: true,
            userRetry: true,
          );
          notificationsRecovered = recovery.isSuccess;
        }
      });
      if (!notificationsRecovered) return;
      final l = display.location;
      final automatic = l.mode == PrayerLocationMode.automatic;
      if (!automatic) {
        _issues.remove(PrayerWorkflowIssue.location);
      }
      Position? fresh;
      if (automatic &&
          (_issues.contains(PrayerWorkflowIssue.verification) ||
              _issues.contains(PrayerWorkflowIssue.location) ||
              _issues.contains(PrayerWorkflowIssue.nativeCandidate))) {
        try {
          fresh = await _travelLocationProvider().timeout(
            const Duration(seconds: 20),
          );
        } catch (_) {}
        if (fresh != null) _issues.remove(PrayerWorkflowIssue.location);
      }
      final priorRevision = _display?.location.revision;
      final resubmitIssue = _issues.contains(PrayerWorkflowIssue.verification)
          ? PrayerWorkflowIssue.verification
          : PrayerWorkflowIssue.storage;
      await _retryStep('location', resubmitIssue, () async {
        final needsResubmit =
            _issues.contains(PrayerWorkflowIssue.verification) ||
            l.revision != (await _locationRepository?.readActive())?.revision;
        if (needsResubmit || fresh != null) {
          final result = await _coordinator?.submit(
            fix: fresh == null
                ? PrayerLocationFix(
                    latitude: l.latitude,
                    longitude: l.longitude,
                    capturedAtUtc: l.capturedAtUtc,
                    accuracyMeters: l.accuracyMeters,
                  )
                : _fixFromPosition(fresh),
            mode: l.mode,
            source: fresh == null ? l.source : PrayerLocationSource.foreground,
            reason: 'offline-retry',
            explicitUserAction: true,
            enrich: true,
            calculationSettings: display,
            isCurrent: () => !isClosed && epoch == _displayEpoch,
          );
          if (result != null && epoch == _displayEpoch && !isClosed) {
            await _renderCoordinatorResult(
              result,
              previous: state is PrayerTimesLoaded
                  ? state as PrayerTimesLoaded
                  : null,
            );
          }
        } else if (_issues.contains(PrayerWorkflowIssue.locality)) {
          await _retryStep('locality', PrayerWorkflowIssue.locality, () async {
            final enriched = await _coordinator?.enrichDisplay(
              display,
              isCurrent: () => !isClosed && epoch == _displayEpoch,
            );
            if (enriched != null && epoch == _displayEpoch && !isClosed) {
              await _acceptDisplay(enriched);
            }
          });
        }
      });
      if (_issues.contains(PrayerWorkflowIssue.notifications) &&
          !_issues.contains(PrayerWorkflowIssue.verification)) {
        await _reconcilePrayerNotifications(
          'offline-retry',
          force: true,
          userRetry: true,
        );
      }
      if (_issues.contains(PrayerWorkflowIssue.nativeCandidate)) {
        await _retryStep(
          'native candidate',
          PrayerWorkflowIssue.nativeCandidate,
          () async {
            await consumeQueuedNativeLocationCandidate();
            await cacheHelper.reload();
            final queued = cacheHelper.getDataString(
              key: 'prayer_location_native_candidate_v1',
            );
            if (_issues.contains(PrayerWorkflowIssue.nativeCandidate) &&
                (queued == null || queued.isEmpty) &&
                _display?.location.revision != priorRevision) {
              _issues.remove(PrayerWorkflowIssue.nativeCandidate);
            }
          },
        );
      }
      if (_issues.contains(PrayerWorkflowIssue.calculation)) {
        await _retryStep(
          'calculation',
          PrayerWorkflowIssue.calculation,
          () async {
            _display?.compute(DateTime.now());
            _issues.remove(PrayerWorkflowIssue.calculation);
          },
        );
      }
      final latest = _display;
      if (_issues.contains(PrayerWorkflowIssue.widget) && latest != null) {
        await _retryStep('widget', PrayerWorkflowIssue.widget, () async {
          await PrayerWidgetService.publishDisplay(
            latest,
            cacheHelper: cacheHelper,
          );
          _issues.remove(PrayerWorkflowIssue.widget);
        });
      }
    } catch (error, stack) {
      debugPrint('Prayer updates retry failed: $error\n$stack');
    } finally {
      _workflowRetrying = false;
      _userRetrying = false;
      await _persistDisplayIssues();
      _renderDisplay();
    }
  }

  Future<void> _retryStep(
    String step,
    PrayerWorkflowIssue issue,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stack) {
      _issues.add(issue);
      debugPrint('Prayer retry step "$step" failed: $error\n$stack');
    }
  }

  @override
  Future<void> close() async {
    _displayEpoch++;
    _dayRollover?.cancel();
    _networkRetryTimer?.cancel();
    _updatesSettling?.cancel();
    await _connectivitySubscription?.cancel();
    return super.close();
  }

  String _getPrayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }
}
