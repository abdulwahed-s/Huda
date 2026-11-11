import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/data/models/hijri_event.dart';

/// One delivery for a calendar event on its stored Hijri date.
class CalendarReminder {
  const CalendarReminder({
    required this.eventId,
    required this.title,
    required this.body,
    required this.at,
    this.color = const Color(0xFF2196F3),
  });

  /// All-day events remind at 07:00 local time.
  factory CalendarReminder.forEvent(HijriEvent event, DateTime gregorianDay) {
    final start = event.isAllDay ? null : event.startTime;
    return CalendarReminder(
      eventId: event.id,
      title: event.title,
      body: event.description,
      at: DateTime(
        gregorianDay.year,
        gregorianDay.month,
        gregorianDay.day,
        start?.hour ?? 7,
        start?.minute ?? 0,
      ),
      color: Color(event.colorValue),
    );
  }

  final String eventId;
  final String title;
  final String body;
  final DateTime at;
  final Color color;

  int get id => NotificationIds.calendar(eventId);

  String get payload => jsonEncode({
    'type': 'calendar_event',
    'eventId': eventId,
    'at': at.toUtc().millisecondsSinceEpoch,
  });
}

/// Reads calendar events for the notification orchestrator, which plans and
/// applies their reminders together with every other reminder.
abstract final class CalendarNotificationService {
  /// Reminders for the events the calendar page stores under `events`.
  static List<CalendarReminder> remindersFromStorage(
    String? stored,
    DateTime Function(HijriDate) toGregorian,
  ) {
    if (stored == null || stored.isEmpty) return const [];
    final reminders = <CalendarReminder>[];
    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in decoded.entries) {
        final parts = key.split('/').map(int.tryParse).toList();
        if (parts.length != 3 || parts.contains(null)) continue;
        final DateTime day;
        try {
          day = toGregorian(HijriDate(parts[2]!, parts[1]!, parts[0]!));
        } catch (_) {
          continue;
        }
        for (final item in value as List) {
          final event = HijriEvent.fromJson(item as Map<String, dynamic>);
          if (event.notify) {
            reminders.add(CalendarReminder.forEvent(event, day));
          }
        }
      }
    } catch (error) {
      debugPrint('Stored calendar events are unreadable: $error');
    }
    return reminders;
  }
}
