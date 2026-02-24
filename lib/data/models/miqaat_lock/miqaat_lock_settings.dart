import 'package:equatable/equatable.dart';
import 'locked_app.dart';
import 'time_slot.dart';

class MiqaatLockSettings extends Equatable {
  final bool isEnabled;

  final List<LockedApp> lockedApps;

  final List<TimeSlot> timeSlots;

  final int goalDurationMinutes;

  static const int maxTimeSlots = 5;

  static const List<int> defaultDurationOptions = [5, 10, 15, 30];

  static const int minCustomDuration = 1;

  static const int maxCustomDuration = 120;

  const MiqaatLockSettings({
    this.isEnabled = false,
    this.lockedApps = const [],
    this.timeSlots = const [],
    this.goalDurationMinutes = 10,
  });

  bool isCurrentlyActive() {
    if (!isEnabled || timeSlots.isEmpty) return false;
    final now = DateTime.now();
    return timeSlots.any((slot) => slot.isActiveAt(now));
  }

  TimeSlot? getActiveTimeSlot() {
    if (!isEnabled || timeSlots.isEmpty) return null;
    final now = DateTime.now();
    try {
      return timeSlots.firstWhere((slot) => slot.isActiveAt(now));
    } catch (_) {
      return null;
    }
  }

  bool shouldLockApp(String packageId) {
    if (!isEnabled) return false;
    if (!lockedApps.any((app) => app.packageId == packageId)) return false;
    return isCurrentlyActive();
  }

  factory MiqaatLockSettings.fromJson(Map<String, dynamic> json) {
    return MiqaatLockSettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      lockedApps: (json['lockedApps'] as List<dynamic>?)
              ?.map((e) => LockedApp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goalDurationMinutes: json['goalDurationMinutes'] as int? ??
          json['sessionDurationMinutes'] as int? ??
          10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'lockedApps': lockedApps.map((e) => e.toJson()).toList(),
      'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
      'goalDurationMinutes': goalDurationMinutes,
    };
  }

  MiqaatLockSettings copyWith({
    bool? isEnabled,
    List<LockedApp>? lockedApps,
    List<TimeSlot>? timeSlots,
    int? goalDurationMinutes,
  }) {
    return MiqaatLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      lockedApps: lockedApps ?? this.lockedApps,
      timeSlots: timeSlots ?? this.timeSlots,
      goalDurationMinutes: goalDurationMinutes ?? this.goalDurationMinutes,
    );
  }

  @override
  List<Object?> get props =>
      [isEnabled, lockedApps, timeSlots, goalDurationMinutes];
}
