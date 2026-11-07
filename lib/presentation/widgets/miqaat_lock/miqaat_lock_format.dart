import 'package:flutter/material.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// A time of day in the locale's own format (12 or 24 hours, numerals).
String miqaatTime(BuildContext context, TimeOfDay time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// A window's range, "5:00 AM – 6:00 AM".
String miqaatRange(BuildContext context, TimeSlot slot) =>
    '${miqaatTime(context, slot.startTime)} – ${miqaatTime(context, slot.endTime)}';

/// The short name of an ISO weekday (1 = Monday … 7 = Sunday).
String miqaatWeekday(BuildContext context, int weekday) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  // 2024-01-01 was a Monday.
  final day = DateTime(2024, 1, weekday);
  try {
    return DateFormat.E(locale).format(day);
  } catch (_) {
    return DateFormat.E().format(day);
  }
}

/// "Every day", or the window's days in week order.
String miqaatDays(BuildContext context, List<int> weekdays) {
  if (weekdays.isEmpty || weekdays.length == 7) {
    return AppLocalizations.of(context)!.everyday;
  }
  final sorted = [...weekdays]..sort();
  return sorted.map((d) => miqaatWeekday(context, d)).join(' · ');
}

/// When the next window starts after [now], within a week.
DateTime? miqaatNextWindow(List<TimeSlot> slots, DateTime now) {
  DateTime? best;
  for (var offset = 0; offset <= 7; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    for (final slot in slots) {
      if (slot.weekdays.isNotEmpty && !slot.weekdays.contains(day.weekday)) {
        continue;
      }
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );
      if (!start.isAfter(now)) continue;
      if (best == null || start.isBefore(best)) best = start;
    }
    if (best != null) return best;
  }
  return best;
}

/// "5:00 AM" today, "Fri 5:00 AM" on another day.
String miqaatWhen(BuildContext context, DateTime at, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final time = miqaatTime(context, TimeOfDay.fromDateTime(at));
  final sameDay =
      at.year == today.year && at.month == today.month && at.day == today.day;
  return sameDay ? time : '${miqaatWeekday(context, at.weekday)} $time';
}
