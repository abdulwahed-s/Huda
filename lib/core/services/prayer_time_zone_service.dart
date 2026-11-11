import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class PrayerTimeZoneService {
  static bool _databaseInitialized = false;
  static String? _configuredLocalTimeZoneName;

  static bool get isDatabaseInitialized => _databaseInitialized;

  static String? get configuredLocalTimeZoneName =>
      _configuredLocalTimeZoneName;

  static void initializeDatabase() {
    if (_databaseInitialized) return;
    tz_data.initializeTimeZones();
    _databaseInitialized = true;
  }

  /// Resolves and applies the device's current IANA timezone.
  ///
  /// Resolution errors intentionally propagate. Scheduling in UTC after a
  /// failed lookup would create a valid-looking alarm at the wrong instant.
  static Future<String> refreshLocalTimeZone({
    Future<String> Function()? resolver,
  }) async {
    if (resolver == null && !kIsWeb && Platform.isLinux) {
      final active = linuxActiveTimeZone();
      if (active != null) {
        try {
          return configureLocalTimeZone(active);
        } on Object {
          // Not in the timezone database: use the plugin's answer below.
        }
      }
    }
    final resolved = await (resolver ?? FlutterTimezone.getLocalTimezone)();
    return configureLocalTimeZone(resolved);
  }

  /// The zone `/etc/localtime` links to, which is the one Linux uses.
  ///
  /// flutter_timezone asks `timedatectl` first, which the Snap's confinement
  /// denies, and then reads `/etc/timezone`, which Ubuntu doesn't update when
  /// the zone changes. A stale `/etc/timezone` put a reminder's first
  /// delivery hours off (notification-rework/linux.md, K1).
  @visibleForTesting
  static String? linuxActiveTimeZone({String path = '/etc/localtime'}) {
    try {
      final target = Link(path).targetSync();
      const marker = 'zoneinfo/';
      final index = target.lastIndexOf(marker);
      if (index < 0) return null;
      var name = target.substring(index + marker.length);
      for (final prefix in ['posix/', 'right/']) {
        if (name.startsWith(prefix)) name = name.substring(prefix.length);
      }
      return name.isEmpty ? null : name;
    } on FileSystemException {
      return null;
    }
  }

  static String configureLocalTimeZone(String timeZoneName) {
    initializeDatabase();
    final normalized = timeZoneName.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        timeZoneName,
        'timeZoneName',
        'A non-empty IANA timezone is required.',
      );
    }
    final location = tz.getLocation(normalized);
    tz.setLocalLocation(location);
    _configuredLocalTimeZoneName = location.name;
    return location.name;
  }

  static tz.Location location(String timeZoneName) {
    initializeDatabase();
    return tz.getLocation(timeZoneName);
  }

  /// Interprets [wallClock] components in [timeZoneName].
  static tz.TZDateTime fromWallClock(DateTime wallClock, String timeZoneName) {
    return tz.TZDateTime(
      location(timeZoneName),
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond,
    );
  }

  /// Represents [instant] in [timeZoneName] without changing the instant.
  static tz.TZDateTime atInstant(DateTime instant, String timeZoneName) {
    return tz.TZDateTime.from(instant, location(timeZoneName));
  }

  static DateTime wallClockAtInstant(DateTime instant, String timeZoneName) {
    final zoned = atInstant(instant, timeZoneName);
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
      zoned.microsecond,
    );
  }
}
