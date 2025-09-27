part of 'prayer_times_cubit.dart';

abstract class PrayerTimesState {}

class PrayerTimesInitial extends PrayerTimesState {}

class PrayerTimesLoading extends PrayerTimesState {}

class PrayerTimesLoaded extends PrayerTimesState {
  final PrayerTimes prayerTimes;
  final List<Placemark> placemarks;
  PrayerTimesLoaded(this.prayerTimes, this.placemarks);
}

class PrayerTimesError extends PrayerTimesState {
  final String message;
  PrayerTimesError(this.message);
}

class PrayerTimesLocationDenied extends PrayerTimesState {}

class PrayerTimesLocationPermanentlyDenied extends PrayerTimesState {}

class PrayerTimesLocationServiceDisabled extends PrayerTimesState {}
