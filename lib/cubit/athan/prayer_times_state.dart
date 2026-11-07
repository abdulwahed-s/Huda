part of 'prayer_times_cubit.dart';

abstract class PrayerTimesState {}

class PrayerTimesInitial extends PrayerTimesState {}

class PrayerTimesLoading extends PrayerTimesState {}

class PrayerTimesLoaded extends PrayerTimesState {
  final PrayerIqamahSettings iqamahSettings;
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
    this.iqamahSettings = const PrayerIqamahSettings(),
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
    PrayerIqamahSettings? iqamahSettings,
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
      iqamahSettings: iqamahSettings ?? this.iqamahSettings,
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

/// No times yet: Huda has no place to calculate them for. [problem] says
/// why the last attempt didn't give one (null before any attempt, or when
/// the user simply hasn't chosen yet). [detail] is for logs only.
class PrayerTimesNeedsPlace extends PrayerTimesState {
  PrayerTimesNeedsPlace({this.problem, this.detail});

  final PrayerLocationProblem? problem;
  final String? detail;
}
