import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:adhan/adhan.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:huda/core/utils/platform_utils.dart';
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
  static const _latKey = 'latitude';
  static const _lonKey = 'longitude';
  static const _fajrOffsetKey = 'prayer_offset_fajr';
  static const _dhuhrOffsetKey = 'prayer_offset_dhuhr';
  static const _asrOffsetKey = 'prayer_offset_asr';
  static const _maghribOffsetKey = 'prayer_offset_maghrib';
  static const _ishaOffsetKey = 'prayer_offset_isha';
  static const _sunriseOffsetKey = 'prayer_offset_sunrise';
  final LocationService _locationService = LocationService();

  Map<String, int> _prayerOffsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  Map<String, int> get prayerOffsets => Map.unmodifiable(_prayerOffsets);

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  Map<String, String> _getLocalizedPrayerContent(Prayer prayer) {
    if (_context == null) {
      final englishName = _getPrayerDisplayName(prayer);
      return {
        'title': '🕌 $englishName Prayer Time',
        'body':
            'It\'s time for $englishName prayer. May Allah accept your prayers.',
      };
    }

    final localizations = AppLocalizations.of(_context!);
    if (localizations == null) {
      final englishName = _getPrayerDisplayName(prayer);
      return {
        'title': '🕌 $englishName Prayer Time',
        'body':
            'It\'s time for $englishName prayer. May Allah accept your prayers.',
      };
    }

    final localizedPrayerName = _getLocalizedPrayerName(prayer, localizations);

    return {
      'title': localizations.notificationPrayerTimeTitle(localizedPrayerName),
      'body': localizations.notificationPrayerTimeBody(localizedPrayerName),
    };
  }

  String _getLocalizedPrayerNameForCountdown(Prayer prayer) {
    if (_context == null) {
      return _getPrayerDisplayName(prayer);
    }

    final localizations = AppLocalizations.of(_context!);
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
    await scheduleNotificationsForMultipleDays(notificationServices, 7);
  }

  Future<void> scheduleNotificationsForMultipleDays(
      NotificationServices notificationServices, int daysAhead) async {
    if (kIsWeb) {
      debugPrint('⏭️ Skipping notification scheduling on web platform');
      return;
    }

    if (state is! PrayerTimesLoaded) return;

    final latString = cacheHelper.getDataString(key: _latKey);
    final lonString = cacheHelper.getDataString(key: _lonKey);

    if (latString == null || lonString == null) {
      debugPrint('❌ Location not available for scheduling notifications');
      return;
    }

    final lat = double.tryParse(latString);
    final lon = double.tryParse(lonString);

    if (lat == null || lon == null) {
      debugPrint('❌ Invalid location coordinates for scheduling notifications');
      return;
    }

    await notificationServices.cancelAllPrayerNotifications();

    final coordinates = Coordinates(lat, lon);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;

    final now = DateTime.now();
    int totalScheduled = 0;

    for (int dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final date = DateComponents.from(targetDate);
      final prayerTimes = PrayerTimes(coordinates, date, params);

      final prayers = [
        (Prayer.fajr, prayerTimes.fajr),
        (Prayer.dhuhr, prayerTimes.dhuhr),
        (Prayer.asr, prayerTimes.asr),
        (Prayer.maghrib, prayerTimes.maghrib),
        (Prayer.isha, prayerTimes.isha),
      ];

      for (final prayerInfo in prayers) {
        final prayer = prayerInfo.$1;
        final baseTime = prayerInfo.$2;
        final offsetMinutes = _prayerOffsets[prayer.name.toLowerCase()] ?? 0;
        final time = baseTime.add(Duration(minutes: offsetMinutes));

        if (time.isAfter(now)) {
          final localizedContent = _getLocalizedPrayerContent(prayer);

          await notificationServices.schedulePrayerNotificationWithDate(
            prayer: prayer,
            title: localizedContent['title']!,
            body: localizedContent['body']!,
            scheduledTime: time,
            dayOffset: dayOffset,
          );
          totalScheduled++;
        }
      }
    }

    debugPrint(
        '✅ Prayer notifications scheduled for $daysAhead days ($totalScheduled total notifications)');
    debugPrint(
        '🛡️ Prayer notifications use dedicated IDs - no conflict with Islamic reminders');

    await _schedulePrayerNotificationsRenewal(daysAhead);
  }

  Future<void> _schedulePrayerNotificationsRenewal(int daysAhead) async {
    if (!PlatformUtils.isMobile) return;
    try {
      final workmanager = Workmanager();

      try {
        await workmanager.cancelByTag('test-initialization');
      } catch (initError) {
        debugPrint(
            '⚠️ WorkManager not initialized yet, skipping prayer renewal scheduling');
        debugPrint(
            '   This is normal during app startup - prayer notifications will still work');
        return;
      }

      await workmanager.cancelByTag('prayer-renewal');

      final renewalDays = (daysAhead - 1).clamp(1, 6);

      await workmanager.registerOneOffTask(
        'prayer-renewal-${DateTime.now().millisecondsSinceEpoch}',
        'renewPrayerNotifications',
        initialDelay: Duration(days: renewalDays),
        tag: 'prayer-renewal',
        constraints: Constraints(
          requiresBatteryNotLow: true,
          networkType: NetworkType.notRequired,
        ),
      );

      debugPrint(
          '🔄 Prayer notifications renewal scheduled for $renewalDays days from now');
    } catch (e) {
      debugPrint('❌ Error scheduling prayer notifications renewal: $e');
      debugPrint(
          '   Prayer notifications will still work - renewal will be handled on next app start');
    }
  }

  PrayerTimesCubit(this.cacheHelper) : super(PrayerTimesInitial());

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

  Future<void> savePrayerOffsets(Map<String, int> offsets) async {
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
    _prayerOffsets = Map.from(offsets);
    if (state is PrayerTimesLoaded) {
      final current = state as PrayerTimesLoaded;
      emit(PrayerTimesLoaded(current.prayerTimes, current.placemarks,
          offsets: _prayerOffsets));
    }
    await PrayerWidgetService.pushSettings();
    await scheduleNotificationsForToday(NotificationServices());
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
          await _locationService.getPlacemarks(lat, lon);

      final coordinates = Coordinates(lat, lon);
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      _loadOffsets();
      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
      await PrayerWidgetService.pushSettings();
      await scheduleNotificationsForToday(NotificationServices());
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  Future<void> setManualLocation(double lat, double lon) async {
    emit(PrayerTimesLoading());

    try {
      await cacheHelper.saveData(key: _latKey, value: lat.toString());
      await cacheHelper.saveData(key: _lonKey, value: lon.toString());

      final List<Placemark> placemarks =
          await _locationService.getPlacemarks(lat, lon);

      final coordinates = Coordinates(lat, lon);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.shafi;

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      emit(PrayerTimesLoaded(prayerTimes, placemarks));
      await scheduleNotificationsForToday(NotificationServices());
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
          await _locationService.getPlacemarks(lat, lon);

      final coordinates = Coordinates(lat, lon);
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      _loadOffsets();
      emit(PrayerTimesLoaded(prayerTimes, placemarks, offsets: _prayerOffsets));
      await PrayerWidgetService.pushSettings();
      await scheduleNotificationsForToday(NotificationServices());
    } catch (e) {
      if (e is LocationServiceDisabledFailure ||
          e.toString() == 'Exception: Location services are disabled.') {
        emit(PrayerTimesLocationServiceDisabled());
      } else if (e is LocationPermissionDeniedFailure ||
          e.toString() == 'Exception: Location permissions are denied.' ||
          e.toString() == 'Exception: Location permissions are denied') {
        emit(PrayerTimesLocationDenied());
      } else if (e is LocationPermissionPermanentlyDeniedFailure ||
          e.toString() ==
              'Exception: Location permissions are permanently denied.') {
        emit(PrayerTimesLocationPermanentlyDenied());
      } else {
        emit(PrayerTimesError(e.toString()));
      }
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
        final currentPrayerInfo = await _getCurrentOrNextPrayerTime(now);

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

  Future<NextPrayerInfo> _getCurrentOrNextPrayerTime(DateTime now) async {
    if (state is! PrayerTimesLoaded) {
      throw Exception('Prayer times not loaded');
    }

    final latString = cacheHelper.getDataString(key: _latKey);
    final lonString = cacheHelper.getDataString(key: _lonKey);

    if (latString == null || lonString == null) {
      throw Exception('Location not available');
    }

    final lat = double.tryParse(latString);
    final lon = double.tryParse(lonString);

    if (lat == null || lon == null) {
      throw Exception('Invalid location coordinates');
    }

    final coordinates = Coordinates(lat, lon);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;

    const gracePeriodMinutes = 25;

    final todayPrayerTimes =
        PrayerTimes(coordinates, DateComponents.from(now), params);
    final todayPrayers = [
      (
        Prayer.fajr,
        todayPrayerTimes.fajr
            .add(Duration(minutes: _prayerOffsets['fajr'] ?? 0))
      ),
      (
        Prayer.dhuhr,
        todayPrayerTimes.dhuhr
            .add(Duration(minutes: _prayerOffsets['dhuhr'] ?? 0))
      ),
      (
        Prayer.asr,
        todayPrayerTimes.asr.add(Duration(minutes: _prayerOffsets['asr'] ?? 0))
      ),
      (
        Prayer.maghrib,
        todayPrayerTimes.maghrib
            .add(Duration(minutes: _prayerOffsets['maghrib'] ?? 0))
      ),
      (
        Prayer.isha,
        todayPrayerTimes.isha
            .add(Duration(minutes: _prayerOffsets['isha'] ?? 0))
      ),
    ];

    for (final prayerInfo in todayPrayers) {
      final prayerTime = prayerInfo.$2;
      final secondsSincePrayer = now.difference(prayerTime).inSeconds;
      final minutesSincePrayer = secondsSincePrayer ~/ 60;

      if (secondsSincePrayer >= 0 && minutesSincePrayer < gracePeriodMinutes) {
        return NextPrayerInfo(
          name: _getLocalizedPrayerNameForCountdown(prayerInfo.$1),
          time: prayerTime,
          isPastPrayer: true,
          secondsPassed: secondsSincePrayer,
        );
      }
    }

    for (final prayerInfo in todayPrayers) {
      if (prayerInfo.$2.isAfter(now)) {
        return NextPrayerInfo(
            name: _getLocalizedPrayerNameForCountdown(prayerInfo.$1),
            time: prayerInfo.$2);
      }
    }

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowPrayerTimes =
        PrayerTimes(coordinates, DateComponents.from(tomorrow), params);

    return NextPrayerInfo(
        name: _getLocalizedPrayerNameForCountdown(Prayer.fajr),
        time: tomorrowPrayerTimes.fajr
            .add(Duration(minutes: _prayerOffsets['fajr'] ?? 0)));
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
