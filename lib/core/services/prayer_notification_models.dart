import 'dart:convert';

import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationEvent {
  PrayerNotificationEvent({
    required this.id,
    required this.prayer,
    required this.scheduledTime,
    required DateTime scheduledInstantUtc,
    required this.timeZoneName,
    required this.title,
    required this.body,
  }) : scheduledInstantUtc = scheduledInstantUtc.toUtc();

  static const int modernIdStart = 300000000;
  static const int modernIdEnd = 400000000;
  static const int payloadSchemaVersion = 2;

  final int id;
  final Prayer prayer;

  /// Prayer time expressed as calendar/wall-clock components.
  final DateTime scheduledTime;

  /// The authoritative instant passed to every platform scheduler.
  final DateTime scheduledInstantUtc;
  final String timeZoneName;
  final String title;
  final String body;

  tz.TZDateTime get scheduledDateTime =>
      PrayerTimeZoneService.atInstant(scheduledInstantUtc, timeZoneName);

  String get payload => jsonEncode({
        'type': 'prayer_time',
        'schemaVersion': payloadSchemaVersion,
        'prayer': prayer.name,
        'scheduledTime': scheduledTime.toIso8601String(),
        'scheduledUtc': scheduledInstantUtc.toIso8601String(),
        'timeZone': timeZoneName,
      });

  bool matchesPendingPayload(String? value) {
    final pending = PrayerNotificationPayload.tryParse(value);
    return pending != null && pending.matches(this);
  }

  static int idFor(DateTime date, Prayer prayer) {
    final datePart = date.year * 10000 + date.month * 100 + date.day;
    return modernIdStart + (datePart - 20000000) * 10 + _prayerIndex(prayer);
  }

  static bool isPrayerId(int id) {
    return (id >= modernIdStart && id < modernIdEnd) ||
        (id >= 2000 && id <= 2599);
  }

  static int _prayerIndex(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 1;
      case Prayer.dhuhr:
        return 2;
      case Prayer.asr:
        return 3;
      case Prayer.maghrib:
        return 4;
      case Prayer.isha:
        return 5;
      case Prayer.sunrise:
        return 6;
      case Prayer.none:
        return 9;
    }
  }
}

class PrayerNotificationPayload {
  const PrayerNotificationPayload({
    required this.schemaVersion,
    required this.prayer,
    required this.scheduledTime,
    required this.scheduledUtc,
    required this.timeZoneName,
  });

  final int schemaVersion;
  final Prayer prayer;
  final DateTime scheduledTime;
  final DateTime scheduledUtc;
  final String timeZoneName;

  static PrayerNotificationPayload? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map || decoded['type'] != 'prayer_time') return null;

      final schemaVersion = decoded['schemaVersion'];
      final prayerName = decoded['prayer']?.toString();
      final scheduledTime = DateTime.tryParse(
        decoded['scheduledTime']?.toString() ?? '',
      );
      final scheduledUtc = DateTime.tryParse(
        decoded['scheduledUtc']?.toString() ?? '',
      );
      final timeZoneName = decoded['timeZone']?.toString().trim() ?? '';
      Prayer? prayer;
      for (final candidate in Prayer.values) {
        if (candidate.name == prayerName) {
          prayer = candidate;
          break;
        }
      }
      if (schemaVersion is! int ||
          prayer == null ||
          scheduledTime == null ||
          scheduledUtc == null ||
          timeZoneName.isEmpty) {
        return null;
      }
      return PrayerNotificationPayload(
        schemaVersion: schemaVersion,
        prayer: prayer,
        scheduledTime: scheduledTime,
        scheduledUtc: scheduledUtc.toUtc(),
        timeZoneName: timeZoneName,
      );
    } catch (_) {
      return null;
    }
  }

  bool matches(PrayerNotificationEvent event) {
    return schemaVersion == PrayerNotificationEvent.payloadSchemaVersion &&
        prayer == event.prayer &&
        timeZoneName == event.timeZoneName &&
        _sameWallClock(scheduledTime, event.scheduledTime) &&
        scheduledUtc.isAtSameMomentAs(event.scheduledInstantUtc);
  }

  static bool _sameWallClock(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute &&
        first.second == second.second &&
        first.millisecond == second.millisecond &&
        first.microsecond == second.microsecond;
  }
}

class PrayerNotificationPlan {
  const PrayerNotificationPlan({
    required this.events,
    required this.configurationSignature,
    required this.requestedThrough,
  });

  final List<PrayerNotificationEvent> events;
  final String configurationSignature;
  final DateTime requestedThrough;

  DateTime? get coverageUntil =>
      events.isEmpty ? null : events.last.scheduledTime;

  DateTime? get coverageUntilInstant =>
      events.isEmpty ? null : events.last.scheduledInstantUtc;
}

enum PrayerScheduleStatus {
  scheduled,
  upToDate,
  permissionDenied,
  locationUnavailable,
  unsupported,
  failed,
}

class PrayerScheduleResult {
  const PrayerScheduleResult({
    required this.status,
    this.scheduledCount = 0,
    this.pendingCount = 0,
    this.coverageUntil,
    this.message,
  });

  final PrayerScheduleStatus status;
  final int scheduledCount;
  final int pendingCount;
  final DateTime? coverageUntil;
  final String? message;

  bool get isSuccess =>
      status == PrayerScheduleStatus.scheduled ||
      status == PrayerScheduleStatus.upToDate;
}
