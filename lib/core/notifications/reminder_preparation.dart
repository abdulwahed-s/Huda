import 'package:flutter/foundation.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/windows_notification_registration.dart';

/// Time zone and notification setup needed before scheduling. Android's
/// reminder channels are created by the native package when it posts.
Future<void> prepareReminderNotifications() async {
  await PrayerTimeZoneService.refreshLocalTimeZone();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await WindowsNotificationRegistration.shared.ensureRegistered();
  }
}
