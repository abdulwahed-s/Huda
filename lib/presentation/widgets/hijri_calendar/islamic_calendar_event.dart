import 'package:flutter/material.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/data/models/hijri_event.dart';

class IslamicCalendarEvent {
  const IslamicCalendarEvent({
    required this.eventKey,
    required this.hijriMonth,
    required this.hijriDayStart,
    required this.hijriDayEnd,
    required this.colorValue,
    required this.icon,
  });

  final String eventKey;
  final int hijriMonth;
  final int hijriDayStart;
  final int hijriDayEnd;
  final int colorValue;
  final IconData icon;

  Color get color => Color(colorValue);

  bool occursOn(HijriDate date) {
    return date.month == hijriMonth &&
        date.day >= hijriDayStart &&
        date.day <= hijriDayEnd;
  }

  HijriEvent markerFor(HijriDate date) {
    return HijriEvent(
      id: 'islamic-calendar-$eventKey-${date.year}-${date.month}-${date.day}',
      title: eventKey,
      description: '',
      colorValue: colorValue,
      notify: false,
    );
  }
}

abstract final class IslamicCalendarEvents {
  static const all = <IslamicCalendarEvent>[
    IslamicCalendarEvent(
      eventKey: 'ramadan',
      hijriMonth: 9,
      hijriDayStart: 1,
      hijriDayEnd: 1,
      colorValue: 0xFF7E57C2,
      icon: Icons.nightlight_round,
    ),
    IslamicCalendarEvent(
      eventKey: 'last_ten_ramadan',
      hijriMonth: 9,
      hijriDayStart: 21,
      hijriDayEnd: 30,
      colorValue: 0xFF5E35B1,
      icon: Icons.nights_stay_rounded,
    ),
    IslamicCalendarEvent(
      eventKey: 'eid_al_fitr',
      hijriMonth: 10,
      hijriDayStart: 1,
      hijriDayEnd: 3,
      colorValue: 0xFF00897B,
      icon: Icons.auto_awesome_rounded,
    ),
    IslamicCalendarEvent(
      eventKey: 'eid_al_adha',
      hijriMonth: 12,
      hijriDayStart: 10,
      hijriDayEnd: 13,
      colorValue: 0xFF8D6E63,
      icon: Icons.mosque_rounded,
    ),
    IslamicCalendarEvent(
      eventKey: 'day_of_arafah',
      hijriMonth: 12,
      hijriDayStart: 9,
      hijriDayEnd: 9,
      colorValue: 0xFF42A5F5,
      icon: Icons.terrain_rounded,
    ),
    IslamicCalendarEvent(
      eventKey: 'first_ten_dhul_hijjah',
      hijriMonth: 12,
      hijriDayStart: 1,
      hijriDayEnd: 10,
      colorValue: 0xFFF9A825,
      icon: Icons.wb_sunny_outlined,
    ),
    IslamicCalendarEvent(
      eventKey: 'ashura',
      hijriMonth: 1,
      hijriDayStart: 10,
      hijriDayEnd: 10,
      colorValue: 0xFF1565C0,
      icon: Icons.brightness_7_rounded,
    ),
    IslamicCalendarEvent(
      eventKey: 'days_of_tashreeq',
      hijriMonth: 12,
      hijriDayStart: 11,
      hijriDayEnd: 13,
      colorValue: 0xFFEF6C00,
      icon: Icons.celebration_rounded,
    ),
  ];

  static List<IslamicCalendarEvent> forDate(HijriDate date) {
    return all.where((event) => event.occursOn(date)).toList(growable: false);
  }

  static Map<String, List<HijriEvent>> withMarkers({
    required Map<String, List<HijriEvent>> userEvents,
    required HijriDate focusedMonth,
    required int daysInFocusedMonth,
  }) {
    final eventsByDate = <String, List<HijriEvent>>{
      for (final entry in userEvents.entries)
        entry.key: List<HijriEvent>.from(entry.value),
    };

    for (final event in all) {
      if (event.hijriMonth != focusedMonth.month) continue;

      final endDay = event.hijriDayEnd.clamp(1, daysInFocusedMonth).toInt();
      for (var day = event.hijriDayStart; day <= endDay; day++) {
        final date = HijriDate(focusedMonth.year, event.hijriMonth, day);
        final key = HijriCalendarService.eventKey(date);
        eventsByDate.putIfAbsent(key, () => <HijriEvent>[]).add(
              event.markerFor(date),
            );
      }
    }

    return eventsByDate;
  }
}
