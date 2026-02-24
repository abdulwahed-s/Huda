import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TimeSlot extends Equatable {
  final String id;

  final TimeOfDay startTime;

  final TimeOfDay endTime;

  final List<int> weekdays;

  final String? label;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.weekdays = const [],
    this.label,
  });

  bool isActiveAt(DateTime dateTime) {
    if (weekdays.isNotEmpty) {
      final dayOfWeek = dateTime.weekday;
      if (!weekdays.contains(dayOfWeek)) {
        return false;
      }
    }

    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      weekdays:
          (json['weekdays'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'weekdays': weekdays,
      'label': label,
    };
  }

  TimeSlot copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? weekdays,
    String? label,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekdays: weekdays ?? this.weekdays,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime, weekdays, label];
}
