import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/windows_prayer_experience.dart';

/// Only scheduling inputs/projections cross the isolate boundary. Credentials,
/// reading history, and the rest of the preference file stay on the root side.
abstract final class WindowsPrayerWorkerPreferences {
  static final keys = <String>{
    WindowsPrayerExperience.preferencesKey,
    'locale',
    'app_locale',
    PrayerTimesCalculator.latKey,
    PrayerTimesCalculator.lonKey,
    PrayerTimesCalculator.countryCodeKey,
    PrayerTimesCalculator.timeZoneIdKey,
    PrayerTimesCalculator.locationModeKey,
    PrayerTimesCalculator.methodKey,
    PrayerTimesCalculator.madhabKey,
    PrayerTimesCalculator.highLatitudeRuleKey,
    PrayerTimesCalculator.customFajrAngleKey,
    PrayerTimesCalculator.customMaghribAngleKey,
    PrayerTimesCalculator.customIshaAngleKey,
    for (final prayer in PrayerTimesCalculator.offsetPrayerKeys)
      PrayerTimesCalculator.offsetKeyFor(prayer),
    PrayerLocationRepository.localityKey,
    PrayerLocationRepository.countryNameKey,
    PrayerLocationRepository.issuesProjectionKey,
    PrayerLocationRepository.displayProjectionKey,
    PrayerLocationRepository.generationProjectionKey,
    PrayerLocationRepository.widgetSettingsProjectionKey,
    PrayerNotificationScheduler.signatureKey,
    PrayerNotificationScheduler.coverageKey,
    PrayerNotificationScheduler.lastSuccessKey,
    PrayerNotificationScheduler.lastReasonKey,
    PrayerNotificationScheduler.pendingCountKey,
    PrayerNotificationScheduler.eventIdsKey,
  };

  static Future<Map<String, Object?>> read(CacheHelper cache) async {
    await cache.reload();
    return {for (final key in keys) key: cache.getData(key: key)};
  }

  /// Compare before writing so a late worker projection cannot overwrite a
  /// newer app-side preference. State mutations still use the physical lock.
  static Future<bool> write(
    CacheHelper cache,
    Map<Object?, Object?> request,
  ) async {
    final key = request['key']! as String;
    if (!keys.contains(key) || key == 'locale' || key == 'app_locale') {
      throw StateError('Worker cannot write preference $key');
    }
    final current = cache.getData(key: key);
    if (!equal(current, request['expected'])) return false;
    final value = request['value'];
    if (equal(current, storedValue(value))) return true;
    if (value == null) {
      final removed = await cache.removeData(key: key);
      return removed || cache.getData(key: key) == null;
    }
    return cache.saveData(
      key: key,
      value: value is List ? value.cast<int>() : value,
    );
  }

  static Object? storedValue(Object? value) =>
      value is List<int> ? value.map((id) => '$id').toList() : value;

  static bool equal(Object? first, Object? second) =>
      first is List && second is List
      ? listEquals(first, second)
      : first == second;
}

typedef WindowsPrayerWorkerRpc =
    Future<Object?> Function(String operation, Map<String, Object?> arguments);

class WindowsPrayerWorkerCache extends CacheHelper {
  WindowsPrayerWorkerCache(this._rpc);
  final WindowsPrayerWorkerRpc _rpc;
  Map<String, Object?> _values = {};

  @override
  Future<void> init() => reload();

  @override
  Future<void> reload() async {
    _values = Map<String, Object?>.from((await _rpc('read', {}))! as Map);
  }

  @override
  Object? getData({required String key}) => _values[key];

  @override
  String? getDataString({required String key}) => _values[key] as String?;

  @override
  Future<bool> containsKey({required String key}) async => _values[key] != null;

  @override
  Future<bool> saveData({required String key, required dynamic value}) async {
    final saved =
        (await _rpc('write', {
              'key': key,
              'expected': _values[key],
              'value': value,
            }))!
            as bool;
    if (saved) _values[key] = WindowsPrayerWorkerPreferences.storedValue(value);
    return saved;
  }

  @override
  Future<bool> removeData({required String key}) =>
      saveData(key: key, value: null);

  @override
  Future<dynamic> put({required String key, required dynamic value}) =>
      saveData(key: key, value: value);

  @override
  Future<bool> clearData() =>
      Future.error(StateError('A scheduling worker cannot clear preferences'));
}
