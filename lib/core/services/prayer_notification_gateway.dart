import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:huda/core/services/prayer_notification_models.dart';

abstract interface class PrayerNotificationGateway {
  Future<void> initialize();

  Future<String> refreshTimeZone();

  String get timeZoneName;

  Future<bool> areNotificationsAllowed();

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<bool> schedulePrayerEvent(PrayerNotificationEvent event);

  Future<void> cancelNotifications(Iterable<int> ids);
}
