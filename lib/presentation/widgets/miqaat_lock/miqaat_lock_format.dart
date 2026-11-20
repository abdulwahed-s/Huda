import 'package:flutter/material.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String miqaatTime(BuildContext context, TimeOfDay time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String miqaatRange(BuildContext context, TimeSlot slot) =>
    '${miqaatTime(context, slot.startTime)} – ${miqaatTime(context, slot.endTime)}';

String miqaatWeekday(BuildContext context, int weekday) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final day = DateTime(2024, 1, weekday);
  try {
    return DateFormat.E(locale).format(day);
  } catch (_) {
    return DateFormat.E().format(day);
  }
}

String miqaatDays(BuildContext context, List<int> weekdays) {
  if (weekdays.isEmpty || weekdays.length == 7) {
    return AppLocalizations.of(context)!.everyday;
  }
  final sorted = [...weekdays]..sort();
  return sorted.map((d) => miqaatWeekday(context, d)).join(' · ');
}

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

String miqaatWhen(BuildContext context, DateTime at, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final time = miqaatTime(context, TimeOfDay.fromDateTime(at));
  final sameDay =
      at.year == today.year && at.month == today.month && at.day == today.day;
  return sameDay ? time : '${miqaatWeekday(context, at.weekday)} $time';
}
