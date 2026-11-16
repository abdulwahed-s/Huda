import 'dart:convert';

/// Every notification ID range Huda schedules. Reconcilers cancel by range,
/// so ranges must never overlap:
///
/// - 114–143: native Sahur alarms (also used by the legacy compatibility receiver).
/// - 1001–1006: Islamic reminders; 1099: the test notification;
///   1101–1550: random Athkar.
/// - 2000–2599 and 300000000–399999999: prayers ([PrayerNotificationEvent]).
/// - 410000000–410999999: Android native prayer service notifications
///   (410000010: the prayer countdown, `com.aw.huda.countdown`).
/// - 420000000–429999999: calendar events.
/// - 430000000–439999999: dated Windows reminder occurrences.
/// - 440000000–539999999: reminders before a prayer on Android, Windows and
///   Linux (the prayer's occurrence ID + [prayerAdvanceOffset]). Android's
///   native package derives and queues them from its prayer rows; Windows and
///   Linux never queue them, only claim them once in the companion's ledger.
///   macOS queues them as `advance-<day>/<prayer>`; iOS uses its own native
///   IDs.
abstract final class NotificationIds {
  static const sahurBase = 114;
  static const sahurLimit = 30;
  static bool isSahur(int id) => id >= sahurBase && id < sahurBase + sahurLimit;

  static const kahfFriday = 1001;
  static const morningAthkar = 1002;
  static const eveningAthkar = 1003;
  static const quranReminder = 1004;
  static const checklistReminder = 1005;
  static const khatmaReminder = 1006;

  /// The Notifications page's test notification, outside every other range.
  static const testNotification = 1099;

  /// Random Athkar use `randomAthkarBase + 1` through `+ limit`.
  static const randomAthkarBase = 1100;
  static const randomAthkarHistoricalLimit = 450;

  static const calendarBase = 420000000;
  static const calendarRange = 10000000;

  static const windowsReminderBase = 430000000;
  static const windowsReminderRange = 10000000;

  static const prayerAdvanceOffset = 140000000;

  static bool isPrayerAdvance(int id) =>
      id >= 300000000 + prayerAdvanceOffset &&
      id < 400000000 + prayerAdvanceOffset;

  static bool isRandomAthkar(int id) =>
      id > randomAthkarBase &&
      id <= randomAthkarBase + randomAthkarHistoricalLimit;

  /// Stable across launches and SDK versions, unlike [String.hashCode].
  static int calendar(String eventId) =>
      calendarBase + _fnv1a32(eventId) % calendarRange;

  static bool isCalendar(int id) =>
      id >= calendarBase && id < calendarBase + calendarRange;

  /// Windows toasts cannot repeat, so each date of a daily or weekly reminder
  /// gets its own tag: base + (YYYYMMDD - 20000000) * 10 + slot.
  static int windowsReminderOccurrence(int reminderId, DateTime localDate) {
    final slot = reminderId - 1000;
    if (slot < 1 || slot > 9) {
      throw ArgumentError.value(reminderId, 'reminderId');
    }
    final date = localDate.year * 10000 + localDate.month * 100 + localDate.day;
    return windowsReminderBase + (date - 20000000) * 10 + slot;
  }

  /// The reminder ID owning a dated Windows occurrence, or null.
  static int? windowsReminderOf(int id) {
    if (id < windowsReminderBase ||
        id >= windowsReminderBase + windowsReminderRange) {
      return null;
    }
    final slot = (id - windowsReminderBase) % 10;
    return slot == 0 ? null : 1000 + slot;
  }

  static int _fnv1a32(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      // hash * 0x01000193 mod 2^32, split so no product exceeds 2^53.
      hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
    }
    return hash;
  }
}
