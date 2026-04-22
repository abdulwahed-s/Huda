import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/utils/platform_utils.dart';

class WidgetBackgroundService {
  static const String _widgetUpdateTaskName = 'updateHomeWidget';
  static const String _isEnabledKey = 'widget_background_updates_enabled';
  static const String _lastUpdateKey = 'last_widget_update_time';

  static Future<void> initialize() async {
    if (!PlatformUtils.isMobile) return;
    final isEnabled = await isBackgroundUpdatesEnabled();
    if (isEnabled) {
      await scheduleAggressiveUpdates();
    }
  }

  static Future<void> _cancelWidgetTasks() async {
    const taskNames = [
      'frequent-widget-update',
      'backup-widget-update',
      'conservative-widget-update',
      'immediate-widget-update',
    ];
    for (final name in taskNames) {
      try {
        await Workmanager().cancelByUniqueName(name);
      } catch (e) {
        debugPrint('⚠️ Could not cancel widget task $name: $e');
      }
    }
  }

  static Future<void> scheduleAggressiveUpdates() async {
    if (!PlatformUtils.isMobile) return;

    await _cancelWidgetTasks();

    try {
      await Workmanager().registerPeriodicTask(
        'frequent-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(minutes: 2),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error registering frequent-widget-update: $e');
    }

    try {
      await Workmanager().registerPeriodicTask(
        'backup-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 35),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error registering backup-widget-update: $e');
    }

    try {
      await Workmanager().registerPeriodicTask(
        'conservative-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(hours: 1, minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error registering conservative-widget-update: $e');
    }

    try {
      await Workmanager().registerOneOffTask(
        'immediate-widget-update',
        _widgetUpdateTaskName,
        initialDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint('❌ Error registering immediate-widget-update: $e');
    }

    debugPrint('✅ Aggressive widget background updates scheduled');
    debugPrint('📅 Schedule: 30min, 1hr, 3hr intervals + immediate update');

    await _updateLastScheduleTime();
  }

  static Future<void> stopPeriodicUpdates() async {
    if (!PlatformUtils.isMobile) return;
    await _cancelWidgetTasks();
    debugPrint('🛑 Widget background updates stopped');
  }

  static Future<void> setBackgroundUpdatesEnabled(bool enabled) async {
    if (!PlatformUtils.isMobile) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isEnabledKey, enabled);

    if (enabled) {
      await scheduleAggressiveUpdates();
      debugPrint(
          '✅ Widget background updates enabled with aggressive scheduling');
    } else {
      await stopPeriodicUpdates();
      debugPrint('❌ Widget background updates disabled');
    }
  }

  static Future<bool> isBackgroundUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isEnabledKey) ?? true;
  }

  static Future<void> forceUpdateNow() async {
    if (!PlatformUtils.isMobile) return;
    try {
      await Workmanager().registerOneOffTask(
        'force-update-${DateTime.now().millisecondsSinceEpoch}',
        _widgetUpdateTaskName,
        initialDelay: const Duration(seconds: 5),
      );

      final isEnabled = await isBackgroundUpdatesEnabled();
      if (isEnabled) {
        await scheduleAggressiveUpdates();
      }

      await updateLastUpdateTime();
      debugPrint('🚀 Force widget update triggered and tasks rescheduled');
    } catch (e) {
      debugPrint('❌ Error in force update: $e');
    }
  }

  static Future<void> _updateLastScheduleTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_schedule_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating schedule time: $e');
    }
  }

  static Future<void> updateLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last update time: $e');
    }
  }

  static Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Error getting last update time: $e');
      return null;
    }
  }
}
