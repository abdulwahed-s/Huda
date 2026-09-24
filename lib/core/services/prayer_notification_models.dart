import 'dart:convert';

import 'package:huda/core/services/prayer_location_generation.dart';
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
    this.locationRevision = 0,
    this.scheduleRevision = 0,
    this.configurationSignature = '',
  }) : scheduledInstantUtc = scheduledInstantUtc.toUtc();

  static const int modernIdStart = 300000000;
  static const int modernIdEnd = 400000000;
  static const int payloadSchemaVersion = 3;

  final int id;
  final Prayer prayer;

  /// Prayer time expressed as calendar/wall-clock components.
  final DateTime scheduledTime;

  /// The authoritative instant passed to every platform scheduler.
  final DateTime scheduledInstantUtc;
  final String timeZoneName;
  final String title;
  final String body;
  final int locationRevision;
  final int scheduleRevision;
  final String configurationSignature;

  tz.TZDateTime get scheduledDateTime =>
      PrayerTimeZoneService.atInstant(scheduledInstantUtc, timeZoneName);

  String get payload => jsonEncode({
    'type': 'prayer_time',
    'schemaVersion': payloadSchemaVersion,
    'occurrenceId': id,
    'locationRevision': locationRevision,
    'scheduleRevision': scheduleRevision,
    'configurationSignature': configurationSignature,
    'prayer': prayer.name,
    'scheduledTime': scheduledTime.toIso8601String(),
    'scheduledUtc': scheduledInstantUtc.toIso8601String(),
    'timeZone': timeZoneName,
  });

  PrayerNotificationEvent copyWith({
    int? locationRevision,
    int? scheduleRevision,
    String? configurationSignature,
  }) {
    return PrayerNotificationEvent(
      id: id,
      prayer: prayer,
      scheduledTime: scheduledTime,
      scheduledInstantUtc: scheduledInstantUtc,
      timeZoneName: timeZoneName,
      title: title,
      body: body,
      locationRevision: locationRevision ?? this.locationRevision,
      scheduleRevision: scheduleRevision ?? this.scheduleRevision,
      configurationSignature:
          configurationSignature ?? this.configurationSignature,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'prayer': prayer.name,
    'scheduledTime': scheduledTime.toIso8601String(),
    'scheduledUtc': scheduledInstantUtc.toIso8601String(),
    'timeZone': timeZoneName,
    'title': title,
    'body': body,
    'locationRevision': locationRevision,
    'scheduleRevision': scheduleRevision,
    'configurationSignature': configurationSignature,
  };

  static PrayerNotificationEvent? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, Object?>.from(value);
    final id = json['id'];
    final prayerName = json['prayer'];
    final scheduledTimeText = json['scheduledTime'];
    final scheduledUtcText = json['scheduledUtc'];
    final scheduledTime = DateTime.tryParse(
      scheduledTimeText?.toString() ?? '',
    );
    final scheduledUtc = DateTime.tryParse(scheduledUtcText?.toString() ?? '');
    final locationRevision = json['locationRevision'];
    final scheduleRevision = json['scheduleRevision'];
    final signature = json['configurationSignature'];
    final zone = json['timeZone'];
    final title = json['title'];
    final body = json['body'];
    Prayer? prayer;
    if (prayerName is String) {
      for (final candidate in Prayer.values) {
        if (candidate.name == prayerName) prayer = candidate;
      }
    }
    if (id is! int ||
        prayer == null ||
        !_isObligatoryPrayer(prayer) ||
        scheduledTime == null ||
        scheduledTime.isUtc ||
        scheduledTimeText is! String ||
        scheduledUtc == null ||
        !scheduledUtc.isUtc ||
        scheduledUtcText is! String ||
        !scheduledUtcText.endsWith('Z') ||
        locationRevision is! int ||
        scheduleRevision is! int ||
        locationRevision <= 0 ||
        locationRevision > PrayerLocationGeneration.maxSafeRevision ||
        scheduleRevision <= 0 ||
        scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
        signature is! String ||
        signature.isEmpty ||
        zone is! String ||
        !_validTimeZone(zone) ||
        title is! String ||
        title.isEmpty ||
        body is! String ||
        body.isEmpty ||
        id < modernIdStart ||
        id >= modernIdEnd ||
        id != idFor(scheduledTime, prayer)) {
      return null;
    }
    return PrayerNotificationEvent(
      id: id,
      prayer: prayer,
      scheduledTime: scheduledTime,
      scheduledInstantUtc: scheduledUtc,
      timeZoneName: zone,
      title: title,
      body: body,
      locationRevision: locationRevision,
      scheduleRevision: scheduleRevision,
      configurationSignature: signature,
    );
  }

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

  static bool _isObligatoryPrayer(Prayer prayer) =>
      prayer == Prayer.fajr ||
      prayer == Prayer.dhuhr ||
      prayer == Prayer.asr ||
      prayer == Prayer.maghrib ||
      prayer == Prayer.isha;

  static bool _validTimeZone(String value) {
    try {
      PrayerTimeZoneService.location(value.trim());
      return value.trim().isNotEmpty;
    } catch (_) {
      return false;
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
    this.occurrenceId,
    this.locationRevision,
    this.scheduleRevision,
    this.configurationSignature,
  });

  final int schemaVersion;
  final Prayer prayer;
  final DateTime scheduledTime;
  final DateTime scheduledUtc;
  final String timeZoneName;
  final int? occurrenceId;
  final int? locationRevision;
  final int? scheduleRevision;
  final String? configurationSignature;

  static PrayerNotificationPayload? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map || decoded['type'] != 'prayer_time') return null;

      final schemaVersion = decoded['schemaVersion'];
      final prayerName = decoded['prayer']?.toString();
      final scheduledTimeText = decoded['scheduledTime'];
      final scheduledUtcText = decoded['scheduledUtc'];
      final scheduledTime = DateTime.tryParse(
        scheduledTimeText?.toString() ?? '',
      );
      final scheduledUtc = DateTime.tryParse(
        scheduledUtcText?.toString() ?? '',
      );
      final timeZoneName = decoded['timeZone']?.toString().trim() ?? '';
      Prayer? prayer;
      for (final candidate in Prayer.values) {
        if (candidate.name == prayerName) {
          prayer = candidate;
          break;
        }
      }
      if ((schemaVersion != 2 &&
              schemaVersion != PrayerNotificationEvent.payloadSchemaVersion) ||
          prayer == null ||
          scheduledTime == null ||
          scheduledTime.isUtc ||
          scheduledTimeText is! String ||
          scheduledUtc == null ||
          !scheduledUtc.isUtc ||
          scheduledUtcText is! String ||
          !scheduledUtcText.endsWith('Z') ||
          !PrayerNotificationEvent._validTimeZone(timeZoneName)) {
        return null;
      }
      final occurrenceId = decoded['occurrenceId'];
      final locationRevision = decoded['locationRevision'];
      final scheduleRevision = decoded['scheduleRevision'];
      final signature = decoded['configurationSignature'];
      if (schemaVersion == PrayerNotificationEvent.payloadSchemaVersion &&
          (occurrenceId is! int ||
              occurrenceId < PrayerNotificationEvent.modernIdStart ||
              occurrenceId >= PrayerNotificationEvent.modernIdEnd ||
              occurrenceId !=
                  PrayerNotificationEvent.idFor(scheduledTime, prayer) ||
              locationRevision is! int ||
              locationRevision <= 0 ||
              locationRevision > PrayerLocationGeneration.maxSafeRevision ||
              scheduleRevision is! int ||
              scheduleRevision <= 0 ||
              scheduleRevision > PrayerLocationGeneration.maxSafeRevision ||
              signature is! String ||
              signature.isEmpty)) {
        return null;
      }
      return PrayerNotificationPayload(
        schemaVersion: schemaVersion,
        prayer: prayer,
        scheduledTime: scheduledTime,
        scheduledUtc: scheduledUtc.toUtc(),
        timeZoneName: timeZoneName,
        occurrenceId: occurrenceId is int ? occurrenceId : null,
        locationRevision: locationRevision is int ? locationRevision : null,
        scheduleRevision: scheduleRevision is int ? scheduleRevision : null,
        configurationSignature: signature is String ? signature : null,
      );
    } catch (_) {
      return null;
    }
  }

  bool matches(PrayerNotificationEvent event) {
    return schemaVersion == PrayerNotificationEvent.payloadSchemaVersion &&
        occurrenceId == event.id &&
        locationRevision == event.locationRevision &&
        scheduleRevision == event.scheduleRevision &&
        configurationSignature == event.configurationSignature &&
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
    this.locationRevision = 0,
    this.scheduleRevision = 0,
  });

  final List<PrayerNotificationEvent> events;
  final String configurationSignature;
  final DateTime requestedThrough;
  final int locationRevision;
  final int scheduleRevision;

  PrayerNotificationPlan withScheduleRevision(int revision) {
    return PrayerNotificationPlan(
      events: List.unmodifiable(
        events.map((event) => event.copyWith(scheduleRevision: revision)),
      ),
      configurationSignature: configurationSignature,
      requestedThrough: requestedThrough,
      locationRevision: locationRevision,
      scheduleRevision: revision,
    );
  }

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
  degraded,
  deferred,
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
      status == PrayerScheduleStatus.upToDate ||
      status == PrayerScheduleStatus.permissionDenied ||
      status == PrayerScheduleStatus.unsupported;
}
