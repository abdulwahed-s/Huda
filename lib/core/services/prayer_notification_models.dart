import 'dart:convert';

import 'package:prayer_time_plus/prayer_time_plus.dart';

class PrayerNotificationEvent {
  const PrayerNotificationEvent({
    required this.id,
    required this.prayer,
    required this.scheduledTime,
    required this.title,
    required this.body,
  });

  static const int modernIdStart = 300000000;
  static const int modernIdEnd = 400000000;

  final int id;
  final Prayer prayer;
  final DateTime scheduledTime;
  final String title;
  final String body;

  String get payload => jsonEncode({
        'type': 'prayer_time',
        'prayer': prayer.name,
        'scheduledTime': scheduledTime.toIso8601String(),
      });

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
