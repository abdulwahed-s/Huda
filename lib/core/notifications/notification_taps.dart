import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/notifications/apple_reminder_backend.dart';
import 'package:huda/core/notifications/reminder_planner.dart';
import 'package:huda/core/notifications/test_notification.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/presentation/screens/app.dart';

/// Opens the page of a tapped notification, including the tap that launched
/// Huda. Each platform reports taps its own way:
/// - Android: the native package (`takeReminderTap`, read by
///   `AndroidPrayerNotificationStateService`);
/// - iOS and macOS: the runner's reminder channel (`tapped`, `takeTap`);
/// - Windows: the runner's toast activator (`tapped`, `takeTap` on
///   `com.aw.huda/windows_notification_taps`);
/// - Linux: the companion opens Huda with the payload, which the runner
///   passes on (`notificationTapped` on `LinuxPrayerTrayBridge.channel`).
abstract final class NotificationTaps {
  static bool _installed = false;

  @visibleForTesting
  static const windowsChannel = MethodChannel(
    'com.aw.huda/windows_notification_taps',
  );

  /// Listens for taps on iOS, macOS, Windows and Linux, and opens the one
  /// that launched Huda.
  static Future<void> install() async {
    if (_installed || kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _installed = true;
      LinuxPrayerTrayBridge.onNotificationTap(open);
      return;
    }
    final channel = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => AppleReminderBackend.channel,
      TargetPlatform.windows => windowsChannel,
      _ => null,
    };
    if (channel == null) return;
    _installed = true;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tapped') await _take(channel);
    });
    await _take(channel);
  }

  @visibleForTesting
  static void reset() => _installed = false;

  static Future<void> _take(MethodChannel channel) async {
    try {
      final payload = await channel.invokeMethod<String>('takeTap');
      if (payload != null) open(payload);
    } catch (error) {
      debugPrint('Notification tap could not be read: $error');
    }
  }

  /// Opens [payload]'s page once the navigator exists.
  static void open(String? payload, {int attempts = 20}) {
    final route = routeForPayload(payload);
    if (route == null) return;
    final navigator = App.navigatorKey.currentState;
    if (navigator != null) {
      unawaited(navigator.pushNamed(route));
    } else if (attempts > 0) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => open(payload, attempts: attempts - 1),
      );
    }
  }

  /// The page a tapped notification opens; null keeps the current page.
  static String? routeForPayload(String? payload) {
    Object? decoded;
    try {
      decoded = jsonDecode(payload ?? '');
    } on FormatException {
      return null;
    }
    if (decoded is Map) {
      return switch (decoded['type']) {
        'prayer_time' => AppRoute.prayerTimes,
        'calendar_event' => AppRoute.hijriCalendar,
        _ => null,
      };
    }
    if (decoded is List && decoded.isNotEmpty) {
      if (ReminderPlanner.isAthkarPayload(payload)) return AppRoute.athkar;
      if (decoded.first == TestNotification.payloadTag) {
        return AppRoute.notification;
      }
      if (decoded.first == 'huda-reminder-v1' && decoded.length > 1) {
        return switch (decoded[1]) {
          NotificationIds.morningAthkar ||
          NotificationIds.eveningAthkar => AppRoute.athkar,
          NotificationIds.checklistReminder => AppRoute.islamicChecklist,
          NotificationIds.kahfFriday ||
          NotificationIds.quranReminder ||
          NotificationIds.khatmaReminder => AppRoute.homeQuran,
          _ => null,
        };
      }
    }
    return null;
  }
}
