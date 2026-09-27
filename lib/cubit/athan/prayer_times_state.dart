part of 'prayer_times_cubit.dart';

abstract class PrayerTimesState {}

class PrayerTimesInitial extends PrayerTimesState {}

class PrayerTimesLoading extends PrayerTimesState {}

class PrayerTimesLoaded extends PrayerTimesState {
  final Set<PrayerWorkflowIssue> workflowIssues;
  final bool workflowRetrying;

  final bool updating;
  final bool? online;
  final bool provisional;
  final bool previousLocationNotifications;

  final List<String> countryCandidates;
  final DailyPrayerTimes prayerTimes;
  final List<Placemark> placemarks;
  final Map<String, int> offsets;
  final PrayerScheduleResult? notificationSchedule;
  final bool notificationScheduleRetrying;

  PrayerTimesLoaded(
    this.prayerTimes,
    this.placemarks, {
    this.workflowIssues = const {},
    this.workflowRetrying = false,
    this.updating = false,
    this.online,
    this.provisional = false,
    this.previousLocationNotifications = false,
    this.countryCandidates = const [],
    this.offsets = const {},
    this.notificationSchedule,
    this.notificationScheduleRetrying = false,
  });

  static const _onlineUnchanged = Object();

  PrayerTimesLoaded copyWith({
    Set<PrayerWorkflowIssue>? workflowIssues,
    bool? workflowRetrying,
    bool? updating,
    Object? online = _onlineUnchanged,
    DailyPrayerTimes? prayerTimes,
    List<Placemark>? placemarks,
    Map<String, int>? offsets,
    PrayerScheduleResult? notificationSchedule,
    bool? notificationScheduleRetrying,
  }) {
    return PrayerTimesLoaded(
      prayerTimes ?? this.prayerTimes,
      placemarks ?? this.placemarks,
      workflowIssues: workflowIssues ?? this.workflowIssues,
      workflowRetrying: workflowRetrying ?? this.workflowRetrying,
      updating: updating ?? this.updating,
      online: identical(online, _onlineUnchanged)
          ? this.online
          : online as bool?,
      provisional: provisional,
      previousLocationNotifications: previousLocationNotifications,
      countryCandidates: countryCandidates,
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
