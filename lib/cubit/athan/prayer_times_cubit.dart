import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:adhan/adhan.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/data/models/countdown_model.dart';

part 'prayer_times_state.dart';

class NextPrayerInfo {
  final String name;
  final DateTime time;

  NextPrayerInfo({required this.name, required this.time});
}

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final CacheHelper cacheHelper;
  static const _latKey = 'latitude';
  static const _lonKey = 'longitude';
  Future<void> scheduleNotificationsForToday(
      NotificationServices notificationServices) async {
    if (state is! PrayerTimesLoaded) return;

    final times = (state as PrayerTimesLoaded).prayerTimes;
    final prayers = {
      Prayer.fajr: times.fajr,
      Prayer.dhuhr: times.dhuhr,
      Prayer.asr: times.asr,
      Prayer.maghrib: times.maghrib,
      Prayer.isha: times.isha,
    };

    int id = 1;
    for (final entry in prayers.entries) {
      final prayerName = entry.key.name;
      final time = entry.value;
      if (time.isAfter(DateTime.now())) {
        await notificationServices.schedulePrayerNotification(
          id: id++,
          title: prayerName,
          scheduledTime: time,
        );
      }
    }
  }

  PrayerTimesCubit(this.cacheHelper) : super(PrayerTimesInitial());

  /// Load from cache or fetch if not found
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

        // Save to cache
        await cacheHelper.saveData(key: _latKey, value: lat.toString());
        await cacheHelper.saveData(key: _lonKey, value: lon.toString());
      }

      //get loaction name
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lon);

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
          await placemarkFromCoordinates(lat, lon);

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

  Stream<NextPrayerCountdown> getNextPrayerCountdown() async* {
    while (true) {
      if (state is! PrayerTimesLoaded) {
        yield const NextPrayerCountdown(
            prayerName: '...', duration: Duration.zero);
        await Future.delayed(Duration(seconds: 1));
        continue;
      }

      try {
        final nextPrayerInfo = await _getNextPrayerTime();
        final now = DateTime.now();
        final duration = nextPrayerInfo.time.difference(now);

        if (duration.isNegative) {
          // If somehow we get a negative duration, wait and retry
          await Future.delayed(Duration(seconds: 1));
          continue;
        }

        yield NextPrayerCountdown(
            prayerName: nextPrayerInfo.name, duration: duration);
      } catch (e) {
        print('Error in countdown stream: $e');
        yield const NextPrayerCountdown(
            prayerName: 'Error calculating next prayer',
            duration: Duration.zero);
      }

      await Future.delayed(Duration(seconds: 1));
    }
  }

  /// Get the next prayer time, even if it's tomorrow
  Future<NextPrayerInfo> _getNextPrayerTime() async {
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
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi;

    final now = DateTime.now();

    // First try today's prayers
    final todayPrayerTimes =
        PrayerTimes(coordinates, DateComponents.from(now), params);
    final todayPrayers = [
      (Prayer.fajr, todayPrayerTimes.fajr),
      (Prayer.dhuhr, todayPrayerTimes.dhuhr),
      (Prayer.asr, todayPrayerTimes.asr),
      (Prayer.maghrib, todayPrayerTimes.maghrib),
      (Prayer.isha, todayPrayerTimes.isha),
    ];

    // Check if there's a prayer left today
    for (final prayerInfo in todayPrayers) {
      if (prayerInfo.$2.isAfter(now)) {
        return NextPrayerInfo(
            name: _getPrayerDisplayName(prayerInfo.$1), time: prayerInfo.$2);
      }
    }

    // No prayers left today, get tomorrow's Fajr
    final tomorrow = now.add(Duration(days: 1));
    final tomorrowPrayerTimes =
        PrayerTimes(coordinates, DateComponents.from(tomorrow), params);

    return NextPrayerInfo(
        name: _getPrayerDisplayName(Prayer.fajr),
        time: tomorrowPrayerTimes.fajr);
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
