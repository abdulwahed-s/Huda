import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/hijri_event.dart';

part 'hijri_calendar_state.dart';

class HijriCalendarCubit extends Cubit<HijriCalendarState> {
  HijriCalendarCubit({
    CacheHelper? cacheHelper,
    HijriCalendarService? calendarService,
    NotificationOrchestrator? reminders,
  })  : cacheHelper = cacheHelper ?? getIt<CacheHelper>(),
        calendarService = calendarService ?? getIt<HijriCalendarService>(),
        _reminders = reminders,
        super(HijriCalendarState()) {
    _loadEvents();
  }

  final CacheHelper cacheHelper;
  final HijriCalendarService calendarService;
  final NotificationOrchestrator? _reminders;
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

  /// Completes with false when the event's reminder could not be scheduled.
  Future<bool> addEvent(DateTime selectedGregorian, HijriEvent event) async {
    final hijriDate = calendarService.toHijri(selectedGregorian);
    final key = HijriCalendarService.eventKey(hijriDate);

    final current = Map<String, List<HijriEvent>>.from(state.events);
    final updated = List<HijriEvent>.from(current[key] ?? []);
    updated.add(event);
    current[key] = updated;
    emit(state.copyWith(events: current));
    await _saveEvents();
    return _syncReminders(event.notify ? event.id : null);
  }

  void removeEvent(DateTime selectedGregorian, HijriEvent event) {
    final hijriDate = calendarService.toHijri(selectedGregorian);
    final key = HijriCalendarService.eventKey(hijriDate);

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
    _saveEvents().then((_) => _syncReminders(null));
  }

  Future<bool> updateEvent(
      DateTime selectedGregorian, HijriEvent oldEvent, HijriEvent newEvent) {
    removeEvent(selectedGregorian, oldEvent);
    return addEvent(selectedGregorian, newEvent);
  }

  /// Applies the saved events' reminders. False when [eventId]'s reminder
  /// was not accepted; past events have nothing to accept.
  Future<bool> _syncReminders(String? eventId) async {
    if (kIsWeb) return true;
    final result = await (_reminders ?? NotificationOrchestrator.shared)
        .requestSync('calendar-changed',
            categories: {ReminderCategory.calendar});
    return eventId == null ||
        result.supported &&
            !result.failed.contains(NotificationIds.calendar(eventId));
  }

  /// Completes with false when the event's reminder could not be scheduled.
  Future<bool> editEvent(
      DateTime selectedGregorian, HijriEvent updatedEvent) async {
    final hijriDate = calendarService.toHijri(selectedGregorian);
    final key = HijriCalendarService.eventKey(hijriDate);

    final current = Map<String, List<HijriEvent>>.from(state.events);
    final list = List<HijriEvent>.from(current[key] ?? []);
    final index = list.indexWhere((e) => e.id == updatedEvent.id);

    if (index != -1) {
      list[index] = updatedEvent;
      current[key] = list;
      emit(state.copyWith(events: current));
      await _saveEvents();
      return _syncReminders(updatedEvent.notify ? updatedEvent.id : null);
    }
    return true;
  }
}
