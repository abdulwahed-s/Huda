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
    final resolved = await (resolver ?? FlutterTimezone.getLocalTimezone)();
    return configureLocalTimeZone(resolved);
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
  static tz.TZDateTime fromWallClock(
    DateTime wallClock,
    String timeZoneName,
  ) {
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

  static DateTime wallClockAtInstant(
    DateTime instant,
    String timeZoneName,
  ) {
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
