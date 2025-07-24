import 'package:flutter/material.dart';

class HijriEvent {
  final String id;
  final String title;
  final String description;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final int colorValue; // Store as ARGB int for SharedPreferences
  final int? notificationId;
  final bool notify;

  HijriEvent({
    required this.id,
    required this.title,
    required this.description,
    this.startTime,
    this.endTime,
    this.isAllDay = true,
    this.colorValue = 0xFF2196F3, // default blue
    this.notificationId,
    required this.notify,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime != null
            ? {'hour': startTime!.hour, 'minute': startTime!.minute}
            : null,
        'endTime': endTime != null
            ? {'hour': endTime!.hour, 'minute': endTime!.minute}
            : null,
        'isAllDay': isAllDay,
        'colorValue': colorValue,
        'notificationId': notificationId,
        'notify': notify,
      };

  factory HijriEvent.fromJson(Map<String, dynamic> json) => HijriEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: json['startTime'] != null
            ? TimeOfDay(
                hour: json['startTime']['hour'],
                minute: json['startTime']['minute'],
              )
            : null,
        endTime: json['endTime'] != null
            ? TimeOfDay(
                hour: json['endTime']['hour'],
                minute: json['endTime']['minute'],
              )
            : null,
        isAllDay: json['isAllDay'] ?? true,
        colorValue: json['colorValue'],
        notificationId: json['notificationId'],
         notify: json['notify'] ?? false,
      );
}
