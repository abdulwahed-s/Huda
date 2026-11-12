import 'package:huda/core/services/mac_prayer_bridge.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';

/// Publications hand calculation and OS request ownership to the resident Mac
/// service. Events returned here come from native pending-request readback.
class MacPrayerNotificationGateway {
  Future<MacPrayerStatus> apply(PrayerScheduleConfiguration configuration) =>
      MacPrayerBridge.publishSchedule(configuration);

  List<PrayerNotificationEvent> acknowledgedEvents(MacPrayerStatus status) {
    final events = <PrayerNotificationEvent>[];
    for (final raw in status.events) {
      final event = PrayerNotificationEvent.tryParse(raw);
      if (event == null) {
        throw const FormatException('Invalid native prayer receipt.');
      }
      events.add(event);
    }
    events.sort(
      (a, b) => a.scheduledInstantUtc.compareTo(b.scheduledInstantUtc),
    );
    return events;
  }
}
