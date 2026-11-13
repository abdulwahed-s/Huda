import 'dart:io';
import 'package:huda/core/services/ios_prayer_bridge.dart';

import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/apple_reminder_backend.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/core/notifications/reminder_preparation.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/windows_prayer_notification_gateway.dart';
import 'package:huda/core/services/android_prayer_notification_gateway.dart';
import 'package:synchronized/synchronized.dart';
import 'package:huda/core/notifications/pending_notification.dart';

/// Prayer notifications for the generic reconciler, on each platform's own
/// backend: Android's native plans, Apple's runner channel, Windows' native
/// worker. iOS, macOS and Linux prayers otherwise go through their own
/// bridges in `PrayerNotificationScheduler`.
class NotificationServices
    implements
        PrayerNotificationGateway,
        VerifiedPrayerNotificationGateway,
        TransactionalPrayerGatewayProvider {
  static Future<void>? _initialization;
  static String _timeZoneName = 'UTC';
  static final _windows = WindowsPrayerNotificationGateway(
    protectNearDue: false,
  );
  static final _windowsLock = Lock();
  static final androidPrayerGateway = AndroidPrayerNotificationGateway();

  @override
  Future<TransactionalPrayerNotificationGateway?>
  transactionalPrayerBackend() async =>
      Platform.isAndroid && await androidPrayerGateway.isEnabled()
      ? androidPrayerGateway
      : null;

  Future<T> _withWindowsSnapshot<T>(Future<T> Function() action) =>
      _windowsLock.synchronized(() async {
        try {
          return await action();
        } finally {
          await _windows.releasePendingSnapshot();
        }
      });

  @override
  bool get supportsSafeReplacement => Platform.isWindows;

  @override
  bool matchesPendingEvent(
    PrayerNotificationEvent event,
    PendingNotification? pending,
  ) => Platform.isWindows
      ? _windows.matchesPendingEvent(event, pending)
      : event.matchesPendingPayload(pending?.payload);

  @override
  Future<void> releasePendingSnapshot() async {
    if (Platform.isWindows) await _windows.releasePendingSnapshot();
  }

  @override
  String get timeZoneName => _timeZoneName;

  @override
  Future<void> initialize() async {
    _initialization ??= _initializePlugin();
    try {
      await _initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    PrayerTimeZoneService.initializeDatabase();
    await refreshTimeZone();
    await prepareReminderNotifications();
    await _createNotificationChannel();
  }

  @override
  Future<String> refreshTimeZone() async {
    _timeZoneName = await PrayerTimeZoneService.refreshLocalTimeZone();
    return _timeZoneName;
  }

  @override
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    if (Platform.isWindows) return _windows.areNotificationsAllowed();
    return NotificationPermissions.areEnabled();
  }

  @override
  Future<bool> canScheduleExactNotifications() async {
    await initialize();
    return NotificationPermissions.canScheduleExact();
  }

  @override
  Future<String> schedulingCapabilitySignature() async {
    if (!Platform.isAndroid) return 'default';
    return await canScheduleExactNotifications()
        ? 'android-exact'
        : 'android-inexact';
  }

  /// Android prayers use the native package's own channels.
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) await androidPrayerGateway.initialize();
  }

  @override
  Future<bool> schedulePrayerEvent(
    PrayerNotificationEvent event, {
    bool? allowExact,
  }) async {
    await initialize();
    final now = DateTime.now().toUtc();
    if (Platform.isMacOS) {
      throw StateError(
        'macOS prayers require a native configuration publication.',
      );
    }
    if (Platform.isAndroid) {
      throw StateError(
        'Android prayer events require a native plan transaction.',
      );
    }
    if (!event.scheduledInstantUtc.isAfter(now)) {
      return false;
    }
    if (Platform.isWindows) {
      return _withWindowsSnapshot(
        () => _windows.schedulePrayerEvent(event, allowExact: allowExact),
      );
    }
    // Linux without its prayer service, and platforms without notifications.
    debugPrint('Prayer notifications are not available on this platform.');
    return false;
  }

  @override
  Future<List<PendingNotification>> pendingNotificationRequests() async {
    await initialize();
    if (Platform.isWindows) {
      return _withWindowsSnapshot(_windows.pendingNotificationRequests);
    }
    if (Platform.isAndroid) {
      return androidPrayerGateway.pendingNotificationRequests();
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return [
        for (final queued in await AppleReminderBackend().inventory())
          PendingNotification(
            queued.id,
            queued.title,
            queued.body,
            queued.payload,
          ),
      ];
    }
    return const [];
  }

  @override
  Future<void> cancelNotifications(Iterable<int> ids) async {
    await initialize();
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return;
    if (Platform.isWindows) {
      await _withWindowsSnapshot(() => _windows.cancelNotifications(unique));
      return;
    }
    if (Platform.isAndroid) {
      await androidPrayerGateway.cancelNotifications(
        unique.where(PrayerNotificationEvent.isPrayerId),
      );
      // Prayers older releases scheduled through the plugin.
      await androidPrayerGateway.api.cancelLegacyNotifications(unique);
      return;
    }
    if (Platform.isIOS) {
      final prayerIds = unique.where(PrayerNotificationEvent.isPrayerId);
      if (prayerIds.isNotEmpty) {
        await IOSPrayerBridge.cancel(ids: prayerIds.toList());
      }
    }
    if (Platform.isIOS || Platform.isMacOS) {
      await AppleReminderBackend.channel.invokeMethod<void>('cancel', {
        'ids': unique,
      });
    }
  }
}
