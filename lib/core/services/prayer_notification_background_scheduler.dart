import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

class PrayerNotificationBackgroundScheduler {
  static const String taskName = 'reconcilePrayerNotifications';
  static const String legacyTaskName = 'renewPrayerNotifications';
  static const String androidUniqueName =
      'huda-prayer-notifications-reconciliation';
  static const String androidTag = 'prayer-renewal';
  static const String iosIdentifier = 'com.aw.huda.prayerNotifications.refresh';

  static Future<void> ensureRegistered() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        androidUniqueName,
        taskName,
        frequency: const Duration(hours: 12),
        initialDelay: const Duration(hours: 6),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        tag: androidTag,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      return;
    }

    if (Platform.isIOS) {
      await Workmanager().registerPeriodicTask(
        iosIdentifier,
        iosIdentifier,
        initialDelay: const Duration(hours: 12),
      );
    }
  }
}
