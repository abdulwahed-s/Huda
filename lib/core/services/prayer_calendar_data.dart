import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

class PrayerCalendarData {
  PrayerCalendarData(PrayerDisplaySnapshot snapshot)
    : assert(!snapshot.provisional),
      latitude = snapshot.location.latitude,
      longitude = snapshot.location.longitude,
      countryCode = snapshot.location.countryCode,
      locality = snapshot.location.locality,
      countryName = snapshot.location.countryName,
      timeZoneId = snapshot.location.timeZoneId,
      methodToken = snapshot.method,
      madhabToken = snapshot.madhab,
      highLatitudeToken = snapshot.highLatitude,
      angles = snapshot.angles,
      offsets = Map.unmodifiable(snapshot.offsets);

  final double latitude;
  final double longitude;
  final String? countryCode;
  final String? locality;
  final String? countryName;
  final String timeZoneId;
  final String methodToken;
  final String madhabToken;
  final String highLatitudeToken;
  final CustomPrayerAngles angles;
  final Map<String, int> offsets;

  CalculationMethod get resolvedMethod =>
      PrayerTimesCalculator.resolveMethod(methodToken, countryCode ?? '');

  DateTime localToday(DateTime instant) {
    final day = PrayerTimeZoneService.wallClockAtInstant(instant, timeZoneId);
    return DateTime(day.year, day.month, day.day);
  }

  DailyPrayerTimes calculate(DateTime civilDate) =>
      PrayerTimesCalculator.compute(
        Coordinates(latitude, longitude),
        DateTime(civilDate.year, civilDate.month, civilDate.day),
        methodToken: methodToken,
        countryCode: countryCode ?? '',
        timeZoneName: timeZoneId,
        madhab: PrayerTimesCalculator.madhabFromToken(madhabToken),
        highLatitudeRule: PrayerTimesCalculator.highLatitudeRuleFromToken(
          highLatitudeToken,
        ),
        customAngles: angles,
      );

  DateTime? adjusted(DailyPrayerTimes times, String key) {
    final base = switch (key) {
      'fajr' => times.fajr,
      'sunrise' => times.sunrise,
      'dhuhr' => times.dhuhr,
      'asr' => times.asr,
      'maghrib' => times.maghrib,
      'isha' => times.isha,
      _ => null,
    };
    return base?.add(Duration(minutes: offsets[key] ?? 0));
  }

  static List<DateTime> monthDates(int year, int month) => List.generate(
    DateTime(year, month + 1, 0).day,
    (index) => DateTime(year, month, index + 1),
    growable: false,
  );

  static List<DateTime> yearDates(int year) => [
    for (var month = 1; month <= 12; month++) ...monthDates(year, month),
  ];
}
