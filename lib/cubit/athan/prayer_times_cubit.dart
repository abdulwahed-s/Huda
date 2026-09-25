import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
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

  NextPrayerInfo({
    required this.name,
    required this.time,
    this.isPastPrayer = false,
    this.secondsPassed = 0,
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
  PrayerScheduleResult? _notificationScheduleResult;
  bool _notificationScheduleRetrying = false;

  Map<String, int> get prayerOffsets => Map.unmodifiable(_prayerOffsets);
  String get calculationMethodToken => _methodToken;
  String get madhabToken => _madhabToken;
  String get highLatitudeRuleToken => _highLatToken;
  CustomPrayerAngles get customPrayerAngles => _customAngles;
  PrayerLocationMode get locationMode => _locationMode;
  String? get prayerTimeZoneId => _prayerTimeZoneId;

  AppLocalizations? _localizations;

  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }

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
  }) : _notificationScheduler =
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
  }

  PrayerLocationCoordinator? get _coordinator {
    final repository = _locationRepository;
    if (repository == null) return null;
    return _locationCoordinator ??= PrayerLocationCoordinator(
      cacheHelper: cacheHelper,
      repository: repository,
      activator: _notificationScheduler,
      timeZoneResolver: _timeZoneResolver,
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
    );
  }

  void _publishNotificationSchedule(
    PrayerScheduleResult result, {
    bool retrying = false,
  }) {
    _notificationScheduleResult = result;
    _notificationScheduleRetrying = retrying;
    final current = state;
    if (current is PrayerTimesLoaded) {
      emit(
        current.copyWith(
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
      countryCode: countryCode ?? _countryCode,
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
    try {
      final zone = await _timeZoneResolver(latitude, longitude, countryCode);
      PrayerTimeZoneService.location(zone);
      return zone;
    } catch (_) {
      if (_prayerTimeZoneId != null) rethrow;
      final fallback = PrayerLocationTimeZoneService.legacyFallback(
        countryCode,
      );
      PrayerTimeZoneService.location(fallback);
      return fallback;
    }
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

    _methodToken = methodToken;
    _madhabToken = madhabToken;
    _highLatToken = highLatToken;
    _customAngles = sanitizedCustomAngles;
    _prayerOffsets = sanitizedOffsets;

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates != null) {
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
      'notification-schedule-retry',
      force: true,
    );
  }

  Future<PrayerScheduleResult> _reconcilePrayerNotifications(
    String reason, {
    bool force = false,
  }) async {
    _setNotificationScheduleRetrying(true);
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
      return result;
    } catch (error) {
      debugPrint('Could not update prayer notifications: $error');
      const result = PrayerScheduleResult(
        status: PrayerScheduleStatus.failed,
        message: PrayerPushErrorCode.unavailable,
      );
      _publishNotificationSchedule(result);
      return result;
    }
  }

  Future<void> loadPrayerTimes() async {
    emit(PrayerTimesLoading());

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
      emit(PrayerTimesError(error.toString()));
    }
  }

  Future<void> setManualLocation(
    double lat,
    double lon, {
    String? cityName,
    String? countryCode,
  }) async {
    if (_coordinator != null) {
      final previous = state is PrayerTimesLoaded
          ? state as PrayerTimesLoaded
          : null;
      emit(PrayerTimesLoading());
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
        explicitUserAction: true,
        suppliedMetadata: supplied,
      );
      await _renderCoordinatorResult(result, previous: previous);
      return;
    }
    emit(PrayerTimesLoading());

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
      emit(PrayerTimesError(e.toString()));
    }
  }

  Future<void> refreshLocationAndPrayerTimes() async {
    final previousPrayerTimes = state is PrayerTimesLoaded
        ? state as PrayerTimesLoaded
        : null;
    emit(PrayerTimesLoading());

    try {
      final position = await _currentLocationProvider();
      if (_coordinator != null) {
        final result = await _coordinator!.submit(
          fix: _fixFromPosition(position),
          mode: PrayerLocationMode.automatic,
          source: PrayerLocationSource.explicit,
          reason: 'device-location-changed',
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
        emit(previousPrayerTimes);
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
    try {
      final position = await _travelLocationProvider();
      if (position == null) return;

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
        if (result.activated || result.scheduleResult != null) {
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
      debugPrint('Could not refresh automatic prayer location: $error');
    } finally {
      _automaticLocationRefreshInProgress = false;
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
      await cacheHelper.removeData(key: key);
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        await cacheHelper.removeData(key: key);
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
          !capturedAt.isUtc ||
          zone.isEmpty) {
        await cacheHelper.removeData(key: key);
        return;
      }
      PrayerTimeZoneService.location(zone);
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
        timeZoneResolver: (_, _, _) async => zone,
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
      final latest = cacheHelper.getDataString(key: key);
      if (latest == raw && !_retryableNativeCandidate(result.status)) {
        await cacheHelper.removeData(key: key);
      }
    } catch (error) {
      debugPrint('Could not consume native prayer location candidate: $error');
    }
  }

  static bool _isSuccessfulLocationValidation(
    PrayerLocationUpdateResult result,
  ) =>
      result.activated ||
      result.status == PrayerLocationUpdateStatus.ignoredInsignificant;

  static bool _retryableNativeCandidate(PrayerLocationUpdateStatus status) =>
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
      debugPrint('Could not update prayer notifications: $error');
    }

    if (_coordinator == null) {
      try {
        await PrayerWidgetService.pushSettings();
      } catch (error) {
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
      _notificationScheduleResult = scheduleResult;
      _notificationScheduleRetrying = false;
    }
    final generation = result.generation;
    final canRenderDespiteSchedulingIssue =
        generation != null && scheduleResult != null;
    if (!result.activated && !canRenderDespiteSchedulingIssue) {
      if (previous != null) {
        emit(previous);
      } else {
        emit(
          PrayerTimesError(
            result.message ??
                'Prayer location update did not reach a safe activation point.',
          ),
        );
      }
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
                country: generation.countryName,
                isoCountryCode: generation.countryCode,
              ),
          ];
    final prayerTimes = _computeWithSettings(
      coordinates,
      _prayerCivilDate(DateTime.now()),
      countryCode: generation?.countryCode,
    );
    emit(_loadedState(prayerTimes, placemarks));
    if (result.activated) {
      await _locationMonitor?.sync(_locationMode);
    }
  }

  void _emitLocationFailure(Object error) {
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

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
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
      final prayerTimes = _computeWithSettings(coordinates, date);
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
    );
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
