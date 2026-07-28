import 'package:hijri_plus/hijri_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/local_recurring_fasting_event_calculator.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/data/models/islamic_event_config.dart';

typedef RemoteIslamicEventLoader = Future<IslamicEventConfig?> Function();

class IslamicEventService {
  static const _cacheKey = 'active_islamic_event';
  static const _cacheTimestampKey = 'active_islamic_event_ts';
  static const _cacheTtl = Duration(hours: 6);

  final CacheHelper _cacheHelper;
  final HijriCalendarService? _hijriCalendarService;
  final HijriDateResolver? _hijriDateResolver;
  final UmmAlQuraCalendar _fallbackCalendar = UmmAlQuraCalendar();
  final DateTime Function() _now;
  late final RemoteIslamicEventLoader _remoteEventLoader;
  late final LocalRecurringFastingEventCalculator _localFastingCalculator;

  IslamicEventService({
    required CacheHelper cacheHelper,
    HijriCalendarService? hijriCalendarService,
    HijriDateResolver? hijriDateResolver,
    DateTime Function()? now,
    RemoteIslamicEventLoader? remoteEventLoader,
    LocalRecurringFastingEventCalculator? localFastingCalculator,
  })  : _cacheHelper = cacheHelper,
        _hijriCalendarService = hijriCalendarService,
        _hijriDateResolver = hijriDateResolver,
        _now = now ?? DateTime.now {
    _remoteEventLoader = remoteEventLoader ?? _fetchFromSupabase;
    _localFastingCalculator = localFastingCalculator ??
        LocalRecurringFastingEventCalculator(
          toHijri: _toHijri,
          reminderWindowFor: _fastingReminderWindowFor,
        );
  }

  Future<IslamicEventConfig?> getActiveEvent() async {
    final now = _localNow();
    final remote = await _getActiveRemoteEvent(now);
    if (remote != null) return remote;

    try {
      return _localFastingCalculator.eventFor(now);
    } catch (_) {
      return null;
    }
  }

  DateTime? nextRefreshAt() {
    final now = _localNow();
    final localNext = _localFastingCalculator.nextRefreshAt(now);
    final remoteNext = _remoteCacheRefreshAt(now);
    if (localNext == null) return remoteNext;
    if (remoteNext == null || !remoteNext.isBefore(localNext)) {
      return localNext;
    }
    return remoteNext;
  }

  Future<IslamicEventConfig?> _getActiveRemoteEvent(DateTime now) async {
    final cached = _getCachedRemoteEvent();
    if (cached != null && _isCacheFresh(now) && _isEventActiveOn(cached, now)) {
      return cached;
    }

    try {
      final event = await _remoteEventLoader();
      final activeEvent = event != null &&
              event.isRemoteConfigured &&
              _isEventActiveOn(event, now)
          ? event
          : null;
      await _cacheRemoteEvent(activeEvent, now);
      return activeEvent;
    } catch (_) {
      if (cached != null && _isEventActiveOn(cached, now)) return cached;
      return null;
    }
  }

  Future<IslamicEventConfig?> _fetchFromSupabase() async {
    final response = await Supabase.instance.client
        .from('islamic_events')
        .select()
        .eq('is_active', true)
        .order('priority', ascending: false)
        .limit(1);

    if (response.isEmpty) return null;
    return IslamicEventConfig.fromJson(response.first);
  }

  bool _isEventActiveOn(IslamicEventConfig event, DateTime localNow) {
    final today = _toHijri(localNow);
    return today.month == event.hijriMonth &&
        today.day >= event.hijriDayStart &&
        today.day <= event.hijriDayEnd;
  }

  HijriDate _toHijri(DateTime date) {
    return _hijriDateResolver?.call(date) ??
        _hijriCalendarService?.toHijri(date) ??
        _fallbackCalendar.toHijriDateTime(date).date;
  }

  FastingReminderWindow? _fastingReminderWindowFor(DateTime targetLocalDate) {
    final coordinates =
        PrayerTimesCalculator.coordinatesFromCache(_cacheHelper);
    if (coordinates == null) return null;

    try {
      final previousDate = DateTime(
        targetLocalDate.year,
        targetLocalDate.month,
        targetLocalDate.day - 1,
      );
      final previousTimes = PrayerTimesCalculator.computeFromCache(
        _cacheHelper,
        coordinates,
        previousDate,
      );
      final targetTimes = PrayerTimesCalculator.computeFromCache(
        _cacheHelper,
        coordinates,
        targetLocalDate,
      );
      final offsets = PrayerTimesCalculator.offsetsFromCache(_cacheHelper);
      final maghrib = previousTimes.maghrib?.add(
        Duration(minutes: offsets['maghrib'] ?? 0),
      );
      final fajr = targetTimes.fajr?.add(
        Duration(minutes: offsets['fajr'] ?? 0),
      );
      if (maghrib == null || fajr == null || !fajr.isAfter(maghrib)) {
        return null;
      }
      return FastingReminderWindow(startsAt: maghrib, endsAt: fajr);
    } catch (_) {
      return null;
    }
  }

  IslamicEventConfig? _getCachedRemoteEvent() {
    final jsonString = _cacheHelper.getDataString(key: _cacheKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return IslamicEventConfig.fromJsonString(jsonString);
    } catch (_) {
      return null;
    }
  }

  bool _isCacheFresh(DateTime now) {
    final cachedAt = _cachedAt();
    if (cachedAt == null || cachedAt.isAfter(now)) return false;
    return now.difference(cachedAt) < _cacheTtl;
  }

  DateTime? _remoteCacheRefreshAt(DateTime now) {
    final cachedAt = _cachedAt();
    if (cachedAt == null) return null;
    final expiry = cachedAt.add(_cacheTtl);
    return expiry.isAfter(now) ? expiry : null;
  }

  DateTime? _cachedAt() {
    final tsString = _cacheHelper.getDataString(key: _cacheTimestampKey);
    final milliseconds = tsString == null ? null : int.tryParse(tsString);
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> _cacheRemoteEvent(
    IslamicEventConfig? event,
    DateTime now,
  ) async {
    if (event != null && !event.isRemoteConfigured) {
      throw ArgumentError.value(
        event,
        'event',
        'Only remote Islamic events may be cached.',
      );
    }
    await _cacheHelper.saveData(
      key: _cacheKey,
      value: event?.toJsonString() ?? '',
    );
    await _cacheHelper.saveData(
      key: _cacheTimestampKey,
      value: now.millisecondsSinceEpoch.toString(),
    );
  }

  DateTime _localNow() {
    final value = _now();
    return value.isUtc ? value.toLocal() : value;
  }
}
