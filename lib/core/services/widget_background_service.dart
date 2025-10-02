import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class WidgetBackgroundService {
  static const String _widgetUpdateTaskName = 'updateHomeWidget';
  static const String _isEnabledKey = 'widget_background_updates_enabled';
  static const String _lastUpdateKey = 'last_widget_update_time';

  /// Initialize widget background updates with aggressive scheduling
  static Future<void> initialize() async {
    final isEnabled = await isBackgroundUpdatesEnabled();
    if (isEnabled) {
      await scheduleAggressiveUpdates();
    }
  }

  /// Schedule aggressive periodic widget updates with multiple fallbacks
  static Future<void> scheduleAggressiveUpdates() async {
    try {
      // Cancel all existing widget tasks first
      await Workmanager().cancelAll();

      // Strategy 1: Frequent updates every 30 minutes
      await Workmanager().registerPeriodicTask(
        'frequent-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(minutes: 2),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Strategy 2: Backup updates every 1 hour
      await Workmanager().registerPeriodicTask(
        'backup-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 35),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Strategy 3: Conservative fallback every 3 hours
      await Workmanager().registerPeriodicTask(
        'conservative-widget-update',
        _widgetUpdateTaskName,
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(hours: 1, minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Strategy 4: Immediate one-off update
      await Workmanager().registerOneOffTask(
        'immediate-widget-update',
        _widgetUpdateTaskName,
        initialDelay: const Duration(minutes: 1),
      );

      debugPrint('� Aggressive widget background updates scheduled');
      debugPrint('📅 Schedule: 30min, 1hr, 3hr intervals + immediate update');

      // Store scheduling time
      await _updateLastScheduleTime();
    } catch (e) {
      debugPrint('❌ Error scheduling aggressive widget updates: $e');
    }
  }

  /// Stop all widget background updates
  static Future<void> stopPeriodicUpdates() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('🛑 All widget background updates stopped');
    } catch (e) {
      debugPrint('❌ Error stopping widget updates: $e');
    }
  }

  /// Enable/disable background widget updates
  static Future<void> setBackgroundUpdatesEnabled(bool enabled) async {
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

  /// Check if background updates are enabled
  static Future<bool> isBackgroundUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isEnabledKey) ?? true; // Default to enabled
  }

  /// Force immediate widget update with reschedule
  static Future<void> forceUpdateNow() async {
    try {
      // Immediate update
      await Workmanager().registerOneOffTask(
        'force-update-${DateTime.now().millisecondsSinceEpoch}',
        _widgetUpdateTaskName,
        initialDelay: const Duration(seconds: 5),
      );

      // Also reschedule all tasks to ensure continuity
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

  /// Update last schedule time for tracking
  static Future<void> _updateLastScheduleTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_schedule_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating schedule time: $e');
    }
  }

  /// Update last update time for tracking
  static Future<void> updateLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last update time: $e');
    }
  }

  /// Get last update time for debugging
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
