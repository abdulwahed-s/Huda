import 'package:flutter/painting.dart' show Color;
import 'package:timezone/timezone.dart' as tz;

/// Notification sources the orchestrator owns. Prayers and Sahur keep their
/// own schedulers; the orchestrator only leaves room for them.
enum ReminderCategory { reminder, randomAthkar, calendar }

/// How a notification is presented: Android channel and icon, Apple urgency.
enum ReminderStyle { dailyReminder, weeklyReminder, athkar, calendar }

/// Repetition the operating system performs without Huda running. Hourly
/// repeats at the same minute; daily and weekly at the same local time.
/// Interval repeats every `intervalMinutes`, showing one of `texts` each time.
enum NotificationRepeat { none, hourly, daily, weekly, interval }

/// One notification the operating system should hold.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.category,
    required this.style,
    required this.title,
    required this.body,
    required this.payload,
    required this.at,
    this.repeat = NotificationRepeat.none,
    this.color,
    this.intervalMinutes,
    this.texts = const [],
  });

  final int id;
  final ReminderCategory category;
  final ReminderStyle style;
  final String title;
  final String body;
  final String payload;

  /// The first, or only, delivery.
  final tz.TZDateTime at;
  final NotificationRepeat repeat;

  /// Android accent color, used by calendar events.
  final Color? color;

  /// For [NotificationRepeat.interval]: minutes between deliveries, and the
  /// texts one of which is picked at each delivery.
  final int? intervalMinutes;
  final List<String> texts;

  /// The rule native schedulers keep (Android engine, Linux and Windows
  /// companions): one-time, daily, weekly or interval. Later deliveries are
  /// computed from the hour, minute and ISO weekday in the device's zone.
  Map<String, Object?> toRule() {
    final kind = switch (repeat) {
      NotificationRepeat.none => 'once',
      NotificationRepeat.daily => 'daily',
      NotificationRepeat.weekly => 'weekly',
      NotificationRepeat.interval => 'interval',
      NotificationRepeat.hourly => throw UnsupportedError(
        'Hourly triggers are Apple-only; elsewhere Athkar use an interval',
      ),
    };
    final timed = kind == 'daily' || kind == 'weekly';
    return {
      'id': id,
      'kind': kind,
      'style': style.name,
      'title': title,
      'body': body,
      'payload': payload,
      'utcMillis': at.millisecondsSinceEpoch,
      'hour': timed ? at.hour : null,
      'minute': timed ? at.minute : null,
      'weekday': kind == 'weekly' ? at.weekday : null,
      'intervalMinutes': intervalMinutes,
      'texts': texts,
      'color': color?.toARGB32(),
    };
  }

  /// Whether [queued] already delivers this notification. Backends that can
  /// read delivery times back also compare the instant to the second.
  bool isSatisfiedBy(QueuedNotification? queued) =>
      queued != null &&
      !queued.ambiguous &&
      !queued.legacy &&
      queued.payload == payload &&
      queued.title == title &&
      queued.body == body &&
      (queued.instantUtc == null ||
          queued.instantUtc!.millisecondsSinceEpoch ~/ 1000 ==
              at.millisecondsSinceEpoch ~/ 1000);
}

/// A notification the operating system currently holds.
class QueuedNotification {
  const QueuedNotification({
    required this.id,
    this.title,
    this.body,
    this.payload,
    this.instantUtc,
    this.ambiguous = false,
    this.legacy = false,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;

  /// Null when the backend cannot read delivery times back.
  final DateTime? instantUtc;

  /// More than one notification shares this ID.
  final bool ambiguous;

  /// Held by the scheduler this backend replaces; scheduling the ID again
  /// moves it to the new one.
  final bool legacy;
}

/// Cancellations run before additions, so a replaced ID is never doubled.
class ReminderChanges {
  const ReminderChanges({this.cancel = const {}, this.schedule = const []});

  final Set<int> cancel;
  final List<PlannedNotification> schedule;

  bool get isEmpty => cancel.isEmpty && schedule.isEmpty;
}

class ApplyReport {
  const ApplyReport({this.failed = const {}});

  /// Notifications the operating system did not accept.
  final Set<int> failed;
}
