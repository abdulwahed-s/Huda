import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/calendar_notification_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/hijri_event.dart';

part 'hijri_calendar_state.dart';

class HijriCalendarCubit extends Cubit<HijriCalendarState> {
  HijriCalendarCubit() : super(HijriCalendarState()) {
    _loadEvents();
  }

  final CacheHelper cacheHelper = getIt<CacheHelper>();
  final now = DateTime.now();

  Future<void> _loadEvents() async {
    final data = cacheHelper.getData(key: 'events');
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      final loaded = decoded.map((key, value) {
        final list = (value as List)
            .map((e) => HijriEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(key, list);
      });
      emit(state.copyWith(events: loaded));
    }
  }

  Future<void> _saveEvents() async {
    final encoded = json.encode(state.events.map(
      (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
    ));
    await cacheHelper.saveData(key: 'events', value: encoded);
  }

  void addEvent(DateTime selectedGregorian, HijriEvent event) {
    final hijriDate = HijriCalendar.fromDate(selectedGregorian);
    final key = hijriDate.toString();

    final current = Map<String, List<HijriEvent>>.from(state.events);
    final updated = List<HijriEvent>.from(current[key] ?? []);
    updated.add(event);
    current[key] = updated;
    emit(state.copyWith(events: current));
    _saveEvents();

    if (event.notify) {
      _scheduleEventNotification(selectedGregorian, event);
    }
  }

  void removeEvent(DateTime selectedGregorian, HijriEvent event) {
    final hijriDate = HijriCalendar.fromDate(selectedGregorian);
    final key = hijriDate.toString();

    // Create a completely new map and new lists
    final newEvents = Map<String, List<HijriEvent>>.fromEntries(
      state.events.entries.map((entry) {
        if (entry.key == key) {
          return MapEntry(
              key, entry.value.where((e) => e.id != event.id).toList());
        }
        return MapEntry(entry.key, List<HijriEvent>.from(entry.value));
      }),
    );

    emit(state.copyWith(events: newEvents));
    _saveEvents();

    final notifId = event.id.hashCode.abs();
    CalendarNotificationService().cancelNotification(notifId);
  }

  void updateEvent(
      DateTime selectedGregorian, HijriEvent oldEvent, HijriEvent newEvent) {
    removeEvent(selectedGregorian, oldEvent);
    addEvent(selectedGregorian, newEvent);
  }

  void _scheduleEventNotification(DateTime date, HijriEvent event) {
    if (kIsWeb) return;

    final notifId = event.id.hashCode.abs();

    final dateTime = event.isAllDay
        ? DateTime(
            date.year, date.month, date.day, 7, 0) // default morning reminder
        : DateTime(date.year, date.month, date.day, event.startTime!.hour,
            event.startTime!.minute);

    if (dateTime.isAfter(now)) {
      CalendarNotificationService().scheduleNotification(
        id: notifId,
        title: event.title,
        body: event.description,
        dateTime: dateTime,
        color: Color(event.colorValue),
      );
    }
  }

  void editEvent(DateTime selectedGregorian, HijriEvent updatedEvent) {
    final hijriDate = HijriCalendar.fromDate(selectedGregorian);
    final key = hijriDate.toString();

    final current = Map<String, List<HijriEvent>>.from(state.events);
    final list = List<HijriEvent>.from(current[key] ?? []);
    final index = list.indexWhere((e) => e.id == updatedEvent.id);

    if (index != -1) {
      list[index] = updatedEvent;
      current[key] = list;
      emit(state.copyWith(events: current));
      _saveEvents();

      final notifId = updatedEvent.id.hashCode.abs();
      CalendarNotificationService().cancelNotification(notifId);
      if (updatedEvent.notify) {
        _scheduleEventNotification(selectedGregorian, updatedEvent);
      }
    }
  }
}
