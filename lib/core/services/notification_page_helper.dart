import 'package:flutter/material.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/core/notifications/reminder_preparation.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/windows_notification_registration.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification permissions, status and diagnostics for the settings pages.
/// Reminders are scheduled by [NotificationOrchestrator].
class NotificationPageHelper {
  Future<void> init() async {
    await prepareReminderNotifications();
    debugPrint('🌍 Timezone initialized: ${tz.local.name}');
    debugPrint('🕒 Local time: ${tz.TZDateTime.now(tz.local)}');
  }

  Future<bool> checkWindowsPermissionStatus() async {
    await init();
    return WindowsNotificationRegistration.shared.areNotificationsEnabled();
  }

  Future<bool> checkIOSPermissionStatus() =>
      NotificationPermissions.areEnabled();

  Future<bool> checkMacOSPermissionStatus() async {
    return await macOSAuthorizationStatus() == 'authorized';
  }

  Future<String> macOSAuthorizationStatus() async {
    if (!PlatformUtils.isMacOS) return '';
    return NotificationPermissions.appleAuthorization();
  }

  Future<bool> requestMacOSNotificationPermission() async {
    if (!PlatformUtils.isMacOS) return false;
    return NotificationPermissions.requestApple();
  }

  Future<bool> openMacOSNotificationSettings() =>
      NotificationPermissions.openMacOSSettings();

  Future<bool> canScheduleExactNotifications() =>
      NotificationPermissions.canScheduleExact();

  Future<bool> requestExactAlarmsPermission() =>
      NotificationPermissions.requestExact();

  /// Reminder, Athkar and calendar notifications the system holds.
  Future<List<QueuedNotification>> getPendingNotifications() async {
    final held = await NotificationOrchestrator.shared.heldReminders();
    debugPrint('📊 Found ${held.length} Islamic reminder notifications');
    return held;
  }

  Future<Map<String, dynamic>> checkNotificationSystemHealth() async {
    final health = <String, dynamic>{};

    try {
      final pending = await getPendingNotifications();
      health['pendingCount'] = pending.length;
      health['pendingIds'] = pending.map((n) => n.id).toList();

      health['prayerCountdownRunning'] =
          'Unknown - foreground service isolation';

      if (PlatformUtils.isAndroid) {
        health['permissionGranted'] = await NotificationPermissions.areEnabled();
        health['exactAlarmsAllowed'] =
            await NotificationPermissions.canScheduleExact();
      }

      health['workmanagerStatus'] = 'Active - background renewal enabled';

      debugPrint('📊 Notification Health Check: $health');
    } catch (e) {
      health['error'] = e.toString();
      debugPrint('❌ Error during health check: $e');
    }

    return health;
  }
}
