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
  });

  final HudaNotificationPlatform platform;
  final int totalPendingLimit;
  final int prayerPendingLimit;
  final int randomAthkarLimit;
  final Duration prayerHorizon;
  final bool supportsNativeScheduling;

  static NotificationCapacityPolicy get current => forPlatform(detect());

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
        );
      case HudaNotificationPlatform.ios:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.ios,
          totalPendingLimit: 60,
          prayerPendingLimit: 50,
          randomAthkarLimit: 4,
          prayerHorizon: Duration(days: 14),
          supportsNativeScheduling: true,
        );
      case HudaNotificationPlatform.macos:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.macos,
          totalPendingLimit: 1800,
          prayerPendingLimit: 900,
          randomAthkarLimit: 450,
          prayerHorizon: Duration(days: 180),
          supportsNativeScheduling: true,
        );
      case HudaNotificationPlatform.windows:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.windows,
          totalPendingLimit: 4000,
          prayerPendingLimit: 1825,
          randomAthkarLimit: 450,
          prayerHorizon: Duration(days: 365),
          supportsNativeScheduling: true,
        );
      case HudaNotificationPlatform.linux:
        return const NotificationCapacityPolicy(
          platform: HudaNotificationPlatform.linux,
          totalPendingLimit: 900,
          prayerPendingLimit: 900,
          randomAthkarLimit: 0,
          prayerHorizon: Duration(days: 180),
          supportsNativeScheduling: false,
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
