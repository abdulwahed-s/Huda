import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:timezone/timezone.dart' as tz;

enum TestNotificationOutcome {
  /// Queued; it arrives even if Huda is closed.
  scheduled,

  /// Queued, but Android denies exact alarms, so it may arrive late.
  mayBeLate,

  /// Notifications are off for Huda.
  notificationsOff,

  /// Linux: Huda's background service, which delivers reminders, is not
  /// running.
  serviceNotRunning,

  /// The system did not accept it.
  failed,
}

/// The Notifications page's test notification (README decision 6). It goes
/// through the same path as real reminders, about [delay] ahead, so the user
/// can close Huda and still see it arrive:
/// - Android: the native reminder engine;
/// - iOS and macOS: the runner's reminder channel;
/// - Windows: a dated toast through the native worker;
/// - Linux: a one-time rule delivered by the companion.
abstract final class TestNotification {
  static const delay = Duration(seconds: 10);
  static const payloadTag = 'huda-test-v1';

  static Future<TestNotificationOutcome> send({
    required String title,
    required String body,
    NotificationOrchestrator? orchestrator,
    @visibleForTesting TargetPlatform? platform,
    @visibleForTesting bool Function()? linuxServiceRunning,
    @visibleForTesting Future<bool> Function()? notificationsEnabled,
    @visibleForTesting Future<bool> Function()? exactAlarms,
    @visibleForTesting DateTime Function()? now,
  }) async {
    try {
      final target = platform ?? defaultTargetPlatform;
      if (target == TargetPlatform.linux) {
        final running =
            linuxServiceRunning?.call() ??
            LinuxPrayerTrayBridge.status.value.serviceAvailable;
        if (!running) return TestNotificationOutcome.serviceNotRunning;
      } else if (!await (notificationsEnabled ??
          NotificationPermissions.areEnabled)()) {
        return TestNotificationOutcome.notificationsOff;
      }
      final exact = await (exactAlarms ??
          NotificationPermissions.canScheduleExact)();
      final at = (now?.call() ?? DateTime.now()).add(delay);
      final accepted = await (orchestrator ?? NotificationOrchestrator.shared)
          .scheduleOnce(
            PlannedNotification(
              id: NotificationIds.testNotification,
              category: ReminderCategory.reminder,
              style: ReminderStyle.dailyReminder,
              title: title,
              body: body,
              // The instant keeps every press distinct for backends that
              // compare payloads.
              payload: jsonEncode([payloadTag, at.millisecondsSinceEpoch]),
              at: tz.TZDateTime.from(at, tz.local),
              repeat: NotificationRepeat.none,
            ),
          );
      if (!accepted) return TestNotificationOutcome.failed;
      return exact
          ? TestNotificationOutcome.scheduled
          : TestNotificationOutcome.mayBeLate;
    } catch (error) {
      debugPrint('Test notification failed: $error');
      return TestNotificationOutcome.failed;
    }
  }
}
