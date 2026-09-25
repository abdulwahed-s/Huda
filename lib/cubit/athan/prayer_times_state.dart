part of 'prayer_times_cubit.dart';

abstract class PrayerTimesState {}

class PrayerTimesInitial extends PrayerTimesState {}

class PrayerTimesLoading extends PrayerTimesState {}

class PrayerTimesLoaded extends PrayerTimesState {
  final DailyPrayerTimes prayerTimes;
  final List<Placemark> placemarks;
  final Map<String, int> offsets;
  final PrayerScheduleResult? notificationSchedule;
  final bool notificationScheduleRetrying;

  PrayerTimesLoaded(
    this.prayerTimes,
    this.placemarks, {
    this.offsets = const {},
    this.notificationSchedule,
    this.notificationScheduleRetrying = false,
  });

  PrayerTimesLoaded copyWith({
    DailyPrayerTimes? prayerTimes,
    List<Placemark>? placemarks,
    Map<String, int>? offsets,
    PrayerScheduleResult? notificationSchedule,
    bool? notificationScheduleRetrying,
  }) {
    return PrayerTimesLoaded(
      prayerTimes ?? this.prayerTimes,
      placemarks ?? this.placemarks,
      offsets: offsets ?? this.offsets,
      notificationSchedule: notificationSchedule ?? this.notificationSchedule,
      notificationScheduleRetrying:
          notificationScheduleRetrying ?? this.notificationScheduleRetrying,
    );
  }
}

class PrayerTimesError extends PrayerTimesState {
  final String message;
  PrayerTimesError(this.message);
}

class PrayerTimesLocationDenied extends PrayerTimesState {}

class PrayerTimesLocationPermanentlyDenied extends PrayerTimesState {}

class PrayerTimesLocationServiceDisabled extends PrayerTimesState {}

class PrayerTimesNeedsSetup extends PrayerTimesState {}
