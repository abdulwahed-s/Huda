import 'package:equatable/equatable.dart';

class MiqaatLockSession extends Equatable {
  final int accumulatedSeconds;

  final int goalMinutes;

  final String timeSlotId;

  final DateTime? trackingStartTime;

  bool get isGoalCompleted => accumulatedSeconds >= goalMinutes * 60;

  double get progress {
    if (goalMinutes <= 0) return 1.0;
    return (accumulatedSeconds / (goalMinutes * 60)).clamp(0.0, 1.0);
  }

  int get remainingSeconds {
    final remaining = (goalMinutes * 60) - accumulatedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isTracking => trackingStartTime != null;

  int get currentAccumulatedSeconds {
    if (trackingStartTime == null) return accumulatedSeconds;
    final elapsed = DateTime.now().difference(trackingStartTime!).inSeconds;
    return accumulatedSeconds + elapsed;
  }

  const MiqaatLockSession({
    this.accumulatedSeconds = 0,
    required this.goalMinutes,
    required this.timeSlotId,
    this.trackingStartTime,
  });

  MiqaatLockSession copyWith({
    int? accumulatedSeconds,
    int? goalMinutes,
    String? timeSlotId,
    DateTime? trackingStartTime,
    bool clearTracking = false,
  }) {
    return MiqaatLockSession(
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      trackingStartTime:
          clearTracking ? null : (trackingStartTime ?? this.trackingStartTime),
    );
  }

  factory MiqaatLockSession.fromJson(Map<String, dynamic> json) {
    return MiqaatLockSession(
      accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
      goalMinutes: json['goalMinutes'] as int? ?? 10,
      timeSlotId: json['timeSlotId'] as String? ?? '',
      trackingStartTime: json['trackingStartTime'] != null
          ? DateTime.parse(json['trackingStartTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accumulatedSeconds': accumulatedSeconds,
      'goalMinutes': goalMinutes,
      'timeSlotId': timeSlotId,
      'trackingStartTime': trackingStartTime?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [accumulatedSeconds, goalMinutes, timeSlotId, trackingStartTime];
}
