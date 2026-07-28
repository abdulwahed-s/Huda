import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';

part 'ramadan_state.dart';

class RamadanCubit extends Cubit<RamadanState> {
  final CacheHelper cacheHelper;
  static const _latKey = PrayerTimesCalculator.latKey;
  static const _lonKey = PrayerTimesCalculator.lonKey;
  static const _ramadanHijriMonth = 9;
  final HijriCalendarService? _hijriCalendarService;
  final UmmAlQuraCalendar _fallbackCalendar = UmmAlQuraCalendar();

  RamadanCubit(
    this.cacheHelper, {
    HijriCalendarService? hijriCalendarService,
  })  : _hijriCalendarService = hijriCalendarService,
        super(RamadanInitial());

  Future<void> loadRamadanData() async {
    emit(RamadanLoading());

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

      final now = DateTime.now();
      final todayHijri = _toHijri(now);
      final isRamadan = todayHijri.month == _ramadanHijriMonth;
      final currentDay = isRamadan ? todayHijri.day : 0;

      int ramadanHijriYear;
      if (isRamadan || todayHijri.month > _ramadanHijriMonth) {
        ramadanHijriYear = todayHijri.year;
      } else {
        ramadanHijriYear = todayHijri.year;
      }

      int daysUntilRamadan = 0;
      if (!isRamadan) {
        daysUntilRamadan = _calculateDaysUntilRamadan(now, todayHijri);
      }

      final coordinates = Coordinates(lat, lon);
      final prayerTimes =
          PrayerTimesCalculator.computeFromCache(cacheHelper, coordinates, now);
      final offsets = PrayerTimesCalculator.offsetsFromCache(cacheHelper);
      final fajrTime = PrayerTimesCalculator.adjustedTimeFor(
              prayerTimes, Prayer.fajr, offsets) ??
          prayerTimes.fajr ??
          now;
      final maghribTime = PrayerTimesCalculator.adjustedTimeFor(
              prayerTimes, Prayer.maghrib, offsets) ??
          prayerTimes.maghrib ??
          now;

      final ramadanDays = _buildRamadanDays(ramadanHijriYear, now);

      final qadhaaStatus = _loadQadhaaStatus(ramadanHijriYear);

      final daysWithStatus = ramadanDays.map((day) {
        final status = qadhaaStatus[day.dayNumber] ?? 'unknown';
        return day.copyWith(status: status);
      }).toList();

      final fastedCount =
          qadhaaStatus.values.where((s) => s == 'fasted').length;
      final missedCount =
          qadhaaStatus.values.where((s) => s == 'missed').length;

      emit(RamadanLoaded(
        isRamadan: isRamadan,
        currentDay: currentDay,
        daysUntilRamadan: daysUntilRamadan,
        hijriYear: ramadanHijriYear,
        fajrTime: fajrTime,
        maghribTime: maghribTime,
        qadhaaStatus: qadhaaStatus,
        ramadanDays: daysWithStatus,
        fastedCount: fastedCount,
        missedCount: missedCount,
      ));
    } catch (e) {
      emit(RamadanError(e.toString()));
    }
  }

  int _calculateDaysUntilRamadan(DateTime now, HijriDate todayHijri) {
    for (int i = 1; i <= 365; i++) {
      final futureDate = now.add(Duration(days: i));
      final futureHijri = _toHijri(futureDate);
      if (futureHijri.month == _ramadanHijriMonth && futureHijri.day == 1) {
        return i;
      }
    }
    return 0;
  }

  List<RamadanDayInfo> _buildRamadanDays(int hijriYear, DateTime now) {
    final List<RamadanDayInfo> days = [];

    DateTime? ramadanStart = _findRamadanStart(hijriYear);
    if (ramadanStart == null) return days;

    for (int day = 1; day <= 30; day++) {
      final gregorianDate = ramadanStart.add(Duration(days: day - 1));

      final hijriCheck = _toHijri(gregorianDate);
      if (hijriCheck.month != _ramadanHijriMonth) break;

      final dayOfWeek = _getDayOfWeek(gregorianDate.weekday);
      days.add(RamadanDayInfo(
        dayNumber: day,
        gregorianDate: gregorianDate,
        dayOfWeek: dayOfWeek,
        status: 'unknown',
      ));
    }

    return days;
  }

  DateTime? _findRamadanStart(int hijriYear) {
    final now = DateTime.now();

    for (int i = -200; i <= 200; i++) {
      final date = now.add(Duration(days: i));
      final hijri = _toHijri(date);
      if (hijri.year == hijriYear &&
          hijri.month == _ramadanHijriMonth &&
          hijri.day == 1) {
        return date;
      }
    }
    return null;
  }

  HijriDate _toHijri(DateTime date) =>
      _hijriCalendarService?.toHijri(date) ??
      _fallbackCalendar.toHijriDateTime(date).date;

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  Map<int, String> _loadQadhaaStatus(int hijriYear) {
    final key = 'ramadan_qadhaa_$hijriYear';
    final data = cacheHelper.getDataString(key: key);
    if (data != null) {
      try {
        final decoded = json.decode(data) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
      } catch (e) {
        debugPrint('Error loading qadhaa status: $e');
      }
    }
    return {};
  }

  Future<void> _saveQadhaaStatus(int hijriYear, Map<int, String> status) async {
    final key = 'ramadan_qadhaa_$hijriYear';
    final encoded =
        json.encode(status.map((k, v) => MapEntry(k.toString(), v)));
    await cacheHelper.saveData(key: key, value: encoded);
  }

  void setDayStatus(int dayNumber, String status) {
    if (state is! RamadanLoaded) return;
    final loaded = state as RamadanLoaded;

    final newStatus = Map<int, String>.from(loaded.qadhaaStatus);

    if (status == 'unknown') {
      newStatus.remove(dayNumber);
    } else {
      newStatus[dayNumber] = status;
    }

    final newDays = loaded.ramadanDays.map((day) {
      if (day.dayNumber == dayNumber) {
        return day.copyWith(status: status);
      }
      return day;
    }).toList();

    final fastedCount = newStatus.values.where((s) => s == 'fasted').length;
    final missedCount = newStatus.values.where((s) => s == 'missed').length;

    emit(loaded.copyWith(
      qadhaaStatus: newStatus,
      ramadanDays: newDays,
      fastedCount: fastedCount,
      missedCount: missedCount,
    ));

    _saveQadhaaStatus(loaded.hijriYear, newStatus);
  }

  Stream<DateTime> getTickStream() async* {
    while (true) {
      yield DateTime.now();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
