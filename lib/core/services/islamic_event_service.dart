import 'package:hijri/hijri_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/models/islamic_event_config.dart';

class IslamicEventService {
  static const _cacheKey = 'active_islamic_event';
  static const _cacheTimestampKey = 'active_islamic_event_ts';
  static const _cacheTtl = Duration(hours: 6);

  final CacheHelper _cacheHelper;

  IslamicEventService({required CacheHelper cacheHelper})
      : _cacheHelper = cacheHelper;

  Future<IslamicEventConfig?> getActiveEvent() async {
    final cached = _getCachedEvent();
    final isFresh = _isCacheFresh();

    if (cached != null && isFresh) {
      return cached;
    }

    try {
      final event = await _fetchFromSupabase();
      await _cacheEvent(event);
      return event;
    } catch (_) {
      // Offline fallback: use stale cache but validate Hijri dates
      // to prevent showing an event the admin forgot to deactivate
      if (cached != null && _isEventActiveToday(cached)) {
        return cached;
      }
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

  bool _isEventActiveToday(IslamicEventConfig event) {
    final today = HijriCalendar.fromDate(DateTime.now());
    return today.hMonth == event.hijriMonth &&
        today.hDay >= event.hijriDayStart &&
        today.hDay <= event.hijriDayEnd;
  }

  IslamicEventConfig? _getCachedEvent() {
    final jsonString = _cacheHelper.getDataString(key: _cacheKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return IslamicEventConfig.fromJsonString(jsonString);
    } catch (_) {
      return null;
    }
  }

  bool _isCacheFresh() {
    final tsString = _cacheHelper.getDataString(key: _cacheTimestampKey);
    if (tsString == null) return false;
    final ts = int.tryParse(tsString);
    if (ts == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cachedAt) < _cacheTtl;
  }

  Future<void> _cacheEvent(IslamicEventConfig? event) async {
    if (event != null) {
      await _cacheHelper.saveData(key: _cacheKey, value: event.toJsonString());
    } else {
      await _cacheHelper.saveData(key: _cacheKey, value: '');
    }
    await _cacheHelper.saveData(
      key: _cacheTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
