import 'dart:io';

import 'package:flutter/foundation.dart';

enum HudaNotificationPlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web,
  unsupported,
}

class NotificationCapacityPolicy {
  const NotificationCapacityPolicy({
    required this.platform,
    required this.totalPendingLimit,
    required this.prayerPendingLimit,
    required this.randomAthkarLimit,
    required this.prayerHorizon,
    required this.supportsNativeScheduling,
    this.randomAthkarHorizon = const Duration(days: 7),
    this.calendarLimit = 0,
    this.repeatingAthkarLimit = 0,
    int? prayerReservedPending,
  }) : _prayerReservedPending = prayerReservedPending;

  final HudaNotificationPlatform platform;
  final int totalPendingLimit;
  final int prayerPendingLimit;
  final int randomAthkarLimit;
  final Duration prayerHorizon;
  final bool supportsNativeScheduling;

  /// Windows has no background Athkar renewal, so it fills more of its queue.
  final Duration randomAthkarHorizon;

  /// The most calendar events queued at once; the nearest come first.
  final int calendarLimit;

  /// Slots random Athkar may use as repeating triggers, which never run out.
  /// Zero where Athkar are queued one by one instead.
  final int repeatingAthkarLimit;

  final int? _prayerReservedPending;

  /// Slots other notifications must leave for prayers. Reminders, calendar
  /// events and Athkar share `totalPendingLimit - prayerReservedPending`.
  int get prayerReservedPending => _prayerReservedPending ?? prayerPendingLimit;

  static NotificationCapacityPolicy get current =>
      debugOverride ?? forPlatform(detect());

  /// Lets tests use another platform's limits than the host's.
  @visibleForTesting
  static NotificationCapacityPolicy? debugOverride;

  static HudaNotificationPlatform detect() {
    if (kIsWeb) return HudaNotificationPlatform.web;
    if (Platform.isAndroid) return HudaNotificationPlatform.android;
    if (Platform.isIOS) return HudaNotificationPlatform.ios;
    if (Platform.isMacOS) return HudaNotificationPlatform.macos;
    if (Platform.isWindows) return HudaNotificationPlatform.windows;
    if (Platform.isLinux) return HudaNotificationPlatform.linux;
    return HudaNotificationPlatform.unsupported;
  }

  static NotificationCapacityPolicy forPlatform(
    HudaNotificationPlatform platform,
  ) {
    switch (platform) {
      case HudaNotificationPlatform.android:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.android,
          totalPendingLimit: 450,
          prayerPendingLimit: 300,
          randomAthkarLimit: 100,
          prayerHorizon: Duration(days: 60),
          supportsNativeScheduling: true,
          calendarLimit: 44,
        );
      case HudaNotificationPlatform.ios:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.ios,
          totalPendingLimit: 60,
          prayerPendingLimit: 50,
          randomAthkarLimit: 4,
          prayerHorizon: Duration(days: 14),
          supportsNativeScheduling: true,
          calendarLimit: 8,
          prayerReservedPending: 42,
          repeatingAthkarLimit: 12,
        );
      case HudaNotificationPlatform.macos:
        // Conservative shared budget until macOS queue acceptance/readback
        // tests justify a larger limit; 64 is not a verified macOS guarantee.
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.macos,
          totalPendingLimit: 60,
          prayerPendingLimit: 50,
          randomAthkarLimit: 4,
          prayerHorizon: Duration(days: 14),
          supportsNativeScheduling: true,
          calendarLimit: 8,
          prayerReservedPending: 42,
          repeatingAthkarLimit: 12,
        );
      case HudaNotificationPlatform.windows:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.windows,
          totalPendingLimit: 4000,
          prayerPendingLimit: 1825,
          randomAthkarLimit: 450,
          prayerHorizon: Duration(days: 365),
          supportsNativeScheduling: true,
          randomAthkarHorizon: Duration(days: 30),
          calendarLimit: 500,
        );
      case HudaNotificationPlatform.linux:
        // The companion delivers reminders itself; these limits only keep
        // its configuration small. Prayers are planned separately.
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.linux,
          totalPendingLimit: 1000,
          prayerPendingLimit: 900,
          randomAthkarLimit: 1,
          prayerHorizon: Duration(days: 180),
          supportsNativeScheduling: false,
          calendarLimit: 90,
        );
      case HudaNotificationPlatform.web:
      case HudaNotificationPlatform.unsupported:
        return NotificationCapacityPolicy(
          platform: platform,
          totalPendingLimit: 0,
          prayerPendingLimit: 0,
          randomAthkarLimit: 0,
          prayerHorizon: Duration.zero,
          supportsNativeScheduling: false,
        );
    }
  }
}
