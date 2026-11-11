import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';

class IOSPrayerNotificationGateway {
  IOSPrayerNotificationGateway({required this.cache, required this.retirement});
  final CacheHelper cache;
  final PrayerPushRetirer retirement;
  Future<IOSPrayerStatus> readStatus() => IOSPrayerBridge.refresh();
  Future<IOSPrayerStatus> publish(
    PrayerScheduleConfiguration configuration, {
    String? migration,
    DateTime? nativeNotBefore,
    int? locationRevisionFloor,
  }) => IOSPrayerBridge.publishSchedule(
    configuration,
    migration: migration,
    nativeNotBefore: nativeNotBefore,
    locationRevisionFloor: locationRevisionFloor,
  );

  Future<IOSPrayerStatus> apply(
    PrayerScheduleConfiguration configuration, {
    required int legacyRevision,
    int? locationRevisionFloor,
  }) async {
    final before = await readStatus();
    if (before.ownsSchedule) {
      if ((before.schedule?.location.revision ?? 0) >
          configuration.location.revision) {
        return before;
      }
      return publish(
        configuration,
        locationRevisionFloor: locationRevisionFloor,
      );
    }
    DateTime? boundary;
    try {
      final saved = jsonDecode(
        cache.getDataString(key: PrayerPushService.nativeRetirementKey) ??
            'null',
      );
      if (saved is Map &&
          saved['ok'] == true &&
          saved['enabled'] == false &&
          saved['retired'] == true) {
        boundary = DateTime.tryParse(saved['nativeNotBefore'] as String);
        if (boundary?.isUtc != true) boundary = null;
      }
    } catch (_) {}
    if (boundary == null) {
      await publish(
        configuration,
        migration: 'pending',
        locationRevisionFloor: locationRevisionFloor,
      );
      final acknowledgement = await retirement.retire(
        locationRevision: configuration.location.revision,
        scheduleRevision: legacyRevision,
      );
      if (!acknowledgement.acknowledged ||
          acknowledgement.ownershipUntilUtc == null) {
        return readStatus();
      }
      boundary = acknowledgement.ownershipUntilUtc;
    }
    return publish(
      configuration,
      migration: 'native',
      nativeNotBefore: boundary,
      locationRevisionFloor: locationRevisionFloor,
    );
  }

  List<PrayerNotificationEvent> acknowledgedEvents(IOSPrayerStatus receipt) {
    final events = <PrayerNotificationEvent>[];
    for (final value in receipt.events) {
      final event = PrayerNotificationEvent.tryParse(value);
      if (event == null) {
        throw const FormatException('Invalid native iOS prayer occurrence.');
      }
      events.add(event);
    }
    events.sort(
      (a, b) => a.scheduledInstantUtc.compareTo(b.scheduledInstantUtc),
    );
    return events;
  }
}
