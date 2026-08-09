import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/data/services/location_service.dart';
import 'package:huda/core/errors/location_failures.dart';
import 'package:huda/core/services/prayer_widget_service.dart';

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
  static const _latKey = PrayerTimesCalculator.latKey;
  static const _lonKey = PrayerTimesCalculator.lonKey;
  static const _countryCodeKey = PrayerTimesCalculator.countryCodeKey;
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

  Map<String, int> get prayerOffsets => Map.unmodifiable(_prayerOffsets);
  String get calculationMethodToken => _methodToken;
  String get madhabToken => _madhabToken;
  String get highLatitudeRuleToken => _highLatToken;

  AppLocalizations? _localizations;

  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }

  PrayerTimesCubit(
    this.cacheHelper, {
    LocationService? locationService,
    PrayerNotificationScheduler? notificationScheduler,
  })  : _notificationScheduler = notificationScheduler ??
            PrayerNotificationScheduler(cacheHelper: cacheHelper),
        _locationService = locationService,
        super(PrayerTimesInitial()) {
    _loadOffsets();
    _loadSettings();
  }

  void _loadOffsets() {
    _prayerOffsets = {
      'fajr': (cacheHelper.getData(key: _fajrOffsetKey) as int?) ?? 0,
      'sunrise': (cacheHelper.getData(key: _sunriseOffsetKey) as int?) ?? 0,
      'dhuhr': (cacheHelper.getData(key: _dhuhrOffsetKey) as int?) ?? 0,
      'asr': (cacheHelper.getData(key: _asrOffsetKey) as int?) ?? 0,
      'maghrib': (cacheHelper.getData(key: _maghribOffsetKey) as int?) ?? 0,
      'isha': (cacheHelper.getData(key: _ishaOffsetKey) as int?) ?? 0,
    };
  }

  void _loadSettings() {
    _methodToken = cacheHelper.getDataString(key: _methodKey) ??
        PrayerTimesCalculator.defaultMethodToken;
    _madhabToken = cacheHelper.getDataString(key: _madhabKey) ??
        PrayerTimesCalculator.defaultMadhabToken;
    _highLatToken = cacheHelper.getDataString(key: _highLatKey) ??
        PrayerTimesCalculator.defaultHighLatitudeToken;
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
      madhab: PrayerTimesCalculator.madhabFromToken(_madhabToken),
      highLatitudeRule:
          PrayerTimesCalculator.highLatitudeRuleFromToken(_highLatToken),
    );
  }

  Future<void> _cachePlacemark(List<Placemark> placemarks) async {
    if (placemarks.isEmpty) return;
    final placemark = placemarks.first;
    final code = (placemark.isoCountryCode ?? '').trim();
    if (code.trim().isNotEmpty) {
      await cacheHelper.saveData(key: _countryCodeKey, value: code.trim());
    }
    await _saveOrRemove(_localityKey, placemark.locality);
    await _saveOrRemove(_countryNameKey, placemark.country);
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
    await _persistOffsets(offsets);
    _prayerOffsets = Map.from(offsets);
    if (state is PrayerTimesLoaded) {
      final current = state as PrayerTimesLoaded;
      emit(PrayerTimesLoaded(current.prayerTimes, current.placemarks,
          offsets: _prayerOffsets));
    }
    await PrayerWidgetService.pushSettings();
    await _reconcilePrayerNotifications('offsets-changed', force: true);
  }

  Future<void> savePrayerSettings({
    required String methodToken,
    required String madhabToken,
    required String highLatToken,
    required Map<String, int> offsets,
  }) async {
    await cacheHelper.saveData(key: _methodKey, value: methodToken);
    await cacheHelper.saveData(key: _madhabKey, value: madhabToken);
    await cacheHelper.saveData(key: _highLatKey, value: highLatToken);
    await _persistOffsets(offsets);

    _methodToken = methodToken;
    _madhabToken = madhabToken;
    _highLatToken = highLatToken;
    _prayerOffsets = Map.from(offsets);

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates != null) {
      final placemarks = state is PrayerTimesLoaded
          ? (state as PrayerTimesLoaded).placemarks
          : <Placemark>[];
      final prayerTimes = _computeWithSettings(coordinates, DateTime.now());
      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
    }

    await PrayerWidgetService.pushSettings();
    await _reconcilePrayerNotifications('calculation-settings-changed',
        force: true);
  }

  Future<void> _persistOffsets(Map<String, int> offsets) async {
    await cacheHelper.saveData(
        key: _fajrOffsetKey, value: offsets['fajr'] ?? 0);
    await cacheHelper.saveData(
        key: _dhuhrOffsetKey, value: offsets['dhuhr'] ?? 0);
    await cacheHelper.saveData(key: _asrOffsetKey, value: offsets['asr'] ?? 0);
    await cacheHelper.saveData(
        key: _maghribOffsetKey, value: offsets['maghrib'] ?? 0);
    await cacheHelper.saveData(
        key: _ishaOffsetKey, value: offsets['isha'] ?? 0);
    await cacheHelper.saveData(
        key: _sunriseOffsetKey, value: offsets['sunrise'] ?? 0);
  }

  String _getLocalizedPrayerNameForCountdown(Prayer prayer) {
    final localizations = _localizations;
    if (localizations == null) {
      return _getPrayerDisplayName(prayer);
    }

    return _getLocalizedPrayerName(prayer, localizations);
  }

  String _getLocalizedPrayerName(
      Prayer prayer, AppLocalizations localizations) {
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
      NotificationServices notificationServices) async {
    await _reconcilePrayerNotifications('prayer-times-requested');
  }

  Future<void> scheduleNotificationsForMultipleDays(
      NotificationServices notificationServices, int daysAhead) async {
    await _reconcilePrayerNotifications('multi-day-prayer-times-requested');
  }

  Future<void> refreshNotificationSchedule() async {
    await _reconcilePrayerNotifications(
      'notification-permission-granted',
      force: true,
    );
  }

  Future<void> _reconcilePrayerNotifications(
    String reason, {
    bool force = false,
  }) async {
    final result = await _notificationScheduler.reconcile(
      reason: reason,
      force: force,
    );
    debugPrint(
      'Prayer notification status: ${result.status.name}; '
      'pending=${result.pendingCount}; coverage=${result.coverageUntil}',
    );
  }

  Future<void> loadPrayerTimes() async {
    emit(PrayerTimesLoading());

    try {
      double? lat =
          double.tryParse(cacheHelper.getDataString(key: _latKey) ?? '');
      double? lon =
          double.tryParse(cacheHelper.getDataString(key: _lonKey) ?? '');

      if (lat == null || lon == null) {
        final position = await getCurrentLocation();
        lat = position.latitude;
        lon = position.longitude;

        await cacheHelper.saveData(key: _latKey, value: lat.toString());
        await cacheHelper.saveData(key: _lonKey, value: lon.toString());
      }

      final List<Placemark> placemarks =
          await _locations.getPlacemarks(lat, lon);
      await _cachePlacemark(placemarks);

      _loadSettings();
      _loadOffsets();

      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(coordinates, DateTime.now());

      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
      await PrayerWidgetService.pushSettings();
      await _reconcilePrayerNotifications('location-loaded', force: true);
    } catch (e) {
      _emitLocationFailure(e);
    }
  }

  void loadCachedPrayerTimes() {
    if (state is PrayerTimesLoading) return;

    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cacheHelper);
    if (coordinates == null) {
      if (state is! PrayerTimesLoaded) emit(PrayerTimesNeedsSetup());
      return;
    }

    try {
      _loadSettings();
      _loadOffsets();
      final prayerTimes = _computeWithSettings(coordinates, DateTime.now());
      final currentPlacemarks = state is PrayerTimesLoaded
          ? (state as PrayerTimesLoaded).placemarks
          : const <Placemark>[];
      final placemarks = currentPlacemarks.isNotEmpty
          ? currentPlacemarks
          : _cachedPlacemarks();
      emit(PrayerTimesLoaded(
        prayerTimes,
        placemarks,
        offsets: _prayerOffsets,
      ));
    } catch (error) {
      emit(PrayerTimesError(error.toString()));
    }
  }

  Future<void> setManualLocation(double lat, double lon,
      {String? cityName, String? countryCode}) async {
    emit(PrayerTimesLoading());

    try {
      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());

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
        placemarks = await _locations.getPlacemarks(lat, lon);
        country = placemarks.isNotEmpty
            ? (placemarks.first.isoCountryCode ?? '').trim()
            : '';
      }
      await cacheHelper.saveData(key: _countryCodeKey, value: country);
      await _cachePlacemark(placemarks);

      _loadSettings();
      _loadOffsets();

      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(coordinates, DateTime.now(),
          countryCode: country);

      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
      await PrayerWidgetService.pushSettings();
      await _reconcilePrayerNotifications('manual-location-changed',
          force: true);
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  Future<void> refreshLocationAndPrayerTimes() async {
    emit(PrayerTimesLoading());

    try {
      final position = await getCurrentLocation();
      final lat = position.latitude;
      final lon = position.longitude;

      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());

      final List<Placemark> placemarks =
          await _locations.getPlacemarks(lat, lon);
      await _cachePlacemark(placemarks);

      _loadSettings();
      _loadOffsets();

      final coordinates = Coordinates(lat, lon);
      final prayerTimes = _computeWithSettings(coordinates, DateTime.now());

      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
      await PrayerWidgetService.pushSettings();
      await _reconcilePrayerNotifications('device-location-changed',
          force: true);
    } catch (e) {
      _emitLocationFailure(e);
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
            prayerName: '...', duration: Duration.zero);
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
            duration: Duration.zero);
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

    const gracePeriodMinutes = 25;

    final todayPrayerTimes = _computeWithSettings(coordinates, now);
    final todayPrayers = _adjustedPrayers(todayPrayerTimes);

    for (final (prayer, prayerTime) in todayPrayers) {
      final secondsSincePrayer = now.difference(prayerTime).inSeconds;
      final minutesSincePrayer = secondsSincePrayer ~/ 60;

      if (secondsSincePrayer >= 0 && minutesSincePrayer < gracePeriodMinutes) {
        return NextPrayerInfo(
          name: _getLocalizedPrayerNameForCountdown(prayer),
          time: prayerTime,
          isPastPrayer: true,
          secondsPassed: secondsSincePrayer,
        );
      }
    }

    for (final (prayer, prayerTime) in todayPrayers) {
      if (prayerTime.isAfter(now)) {
        return NextPrayerInfo(
            name: _getLocalizedPrayerNameForCountdown(prayer),
            time: prayerTime);
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    for (var dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final prayerTimes = _computeWithSettings(coordinates, date);
      for (final (prayer, prayerTime) in _adjustedPrayers(prayerTimes)) {
        if (prayerTime.isAfter(now)) {
          return NextPrayerInfo(
            name: _getLocalizedPrayerNameForCountdown(prayer),
            time: prayerTime,
          );
        }
      }
    }

    throw Exception('No upcoming prayer time available in the next 7 days');
  }

  List<(Prayer, DateTime)> _adjustedPrayers(DailyPrayerTimes prayerTimes) {
    final result = <(Prayer, DateTime)>[];
    void add(Prayer prayer, DateTime? base) {
      if (base == null) return;
      final key = prayer.name.toLowerCase();
      result.add((
        prayer,
        base.add(Duration(minutes: _prayerOffsets[key] ?? 0)),
      ));
    }

    add(Prayer.fajr, prayerTimes.fajr);
    add(Prayer.dhuhr, prayerTimes.dhuhr);
    add(Prayer.asr, prayerTimes.asr);
    add(Prayer.maghrib, prayerTimes.maghrib);
    add(Prayer.isha, prayerTimes.isha);
    result.sort((left, right) => left.$2.compareTo(right.$2));
    return result;
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
