import 'dart:convert';
import 'dart:math';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/services/calendar_notification_service.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/reminder_notification_content.dart';
import 'package:timezone/timezone.dart' as tz;

/// A daily reminder, or a weekly one when [weekday] is set.
class FixedReminder {
  const FixedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.weekday,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int? weekday;
}

/// What the user enabled, read from the settings pages' storage.
class ReminderSettings {
  const ReminderSettings({
    this.fixed = const [],
    this.randomAthkarMinutes,
    this.calendar = const [],
  });

  /// Only enabled reminders.
  final List<FixedReminder> fixed;

  /// Null when random Athkar are off.
  final int? randomAthkarMinutes;
  final List<CalendarReminder> calendar;

  factory ReminderSettings.fromCache(
    CacheHelper cache,
    ReminderNotificationContent content, {
    List<CalendarReminder> calendar = const [],
  }) => ReminderSettings.fromValues(
    (key) => cache.getData(key: key),
    content,
    calendar: calendar,
  );

  /// Settings from the values the settings pages save under each key.
  factory ReminderSettings.fromValues(
    Object? Function(String key) read,
    ReminderNotificationContent content, {
    List<CalendarReminder> calendar = const [],
  }) {
    bool enabled(String key) => read(key) == true;
    (int, int) time(String key, int hour, int minute) {
      final parts = '${read(key) ?? ''}'.split(':');
      final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
      return h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60
          ? (h, m)
          : (hour, minute);
    }

    FixedReminder reminder(
      int id,
      String title,
      String body,
      (int, int) at, [
      int? weekday,
    ]) => FixedReminder(
      id: id,
      title: title,
      body: body,
      hour: at.$1,
      minute: at.$2,
      weekday: weekday,
    );

    final khatmaHour = read('khatma_reminder_hour');
    final khatmaMinute = read('khatma_reminder_minute');
    final frequency = read('randomAthkarFrequency');
    return ReminderSettings(
      fixed: [
        if (enabled('kahfFriday'))
          reminder(
            NotificationIds.kahfFriday,
            content.kahfTitle,
            content.kahfBody,
            time('kahfFridayTime', 9, 0),
            DateTime.friday,
          ),
        if (enabled('sabahMasaa')) ...[
          reminder(
            NotificationIds.morningAthkar,
            content.morningTitle,
            content.morningBody,
            time('morningAthkarTime', 7, 0),
          ),
          reminder(
            NotificationIds.eveningAthkar,
            content.eveningTitle,
            content.eveningBody,
            time('eveningAthkarTime', 18, 0),
          ),
        ],
        if (enabled('quranReminder'))
          reminder(
            NotificationIds.quranReminder,
            content.quranTitle,
            content.quranBody,
            time('quranReminderTime', 19, 30),
          ),
        if (enabled('checklistReminder'))
          reminder(
            NotificationIds.checklistReminder,
            content.checklistTitle,
            content.checklistBody,
            time('checklistReminderTime', 20, 0),
          ),
        if (enabled('khatma_reminder_enabled'))
          reminder(
            NotificationIds.khatmaReminder,
            content.khatmaTitle,
            content.khatmaBody,
            (
              khatmaHour is int && khatmaHour >= 0 && khatmaHour < 24
                  ? khatmaHour
                  : 19,
              khatmaMinute is int && khatmaMinute >= 0 && khatmaMinute < 60
                  ? khatmaMinute
                  : 0,
            ),
          ),
      ],
      randomAthkarMinutes: enabled('randomAthkar')
          ? (frequency is int && frequency > 0 ? frequency : 60)
          : null,
      calendar: calendar,
    );
  }
}

class ReminderPlan {
  const ReminderPlan({
    required this.changes,
    required this.ownedBefore,
    required this.ownedAfter,
    this.athkarMinutes,
    this.athkarReshuffleAt,
  });

  final ReminderChanges changes;

  /// Queued notifications owned by the planned categories.
  final int ownedBefore;
  final int ownedAfter;

  /// The Athkar frequency actually scheduled, or null when none are. Repeating
  /// triggers can only express some frequencies, so it can differ from the
  /// one requested.
  final int? athkarMinutes;

  /// When repeating Athkar should get newly shuffled text.
  final DateTime? athkarReshuffleAt;
}

/// Turns settings into the reminder rules one platform should hold and the
/// smallest set of changes from what it holds now. Pure: no I/O.
///
/// Every backend receives rules, never expanded instances: daily and weekly
/// reminders repeat, calendar events happen once, and random Athkar are
/// either one interval rule that picks its text at delivery or, on Apple
/// platforms, a few repeating triggers. Each backend turns rules into what
/// its operating system supports.
class ReminderPlanner {
  ReminderPlanner({
    required this.policy,
    required this.scheduleMode,
    required this.content,
    required this.now,
    this.repeatsAthkar = false,
  });

  static const reminderPayloadVersion = 'huda-reminder-v1';
  static const athkarPayloadVersion = 'huda-athkar-v1';
  static const repeatingAthkarPayloadVersion = 'huda-athkar-repeat-v1';
  static const liveAthkarPayloadVersion = 'huda-athkar-live-v1';

  static const athkarTexts = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'الْلَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  ];

  final NotificationCapacityPolicy policy;

  /// Random Athkar become repeating triggers (iOS, macOS) instead of one
  /// interval rule.
  final bool repeatsAthkar;
  final String scheduleMode;
  final ReminderNotificationContent content;
  final tz.TZDateTime now;

  /// The category owning [queued], or null for prayers and anything else
  /// the orchestrator must leave alone.
  static ReminderCategory? ownerOf(QueuedNotification queued) {
    if (_payloadType(queued.payload) == 'calendar_event') {
      return ReminderCategory.calendar;
    }
    final id = queued.id;
    if ((id >= NotificationIds.kahfFriday &&
            id <= NotificationIds.khatmaReminder) ||
        NotificationIds.windowsReminderOf(id) != null) {
      return ReminderCategory.reminder;
    }
    if (NotificationIds.isRandomAthkar(id)) {
      // Old releases used 1104 and 1105 for reminders.
      return (id == 1104 || id == 1105) && !isAthkarPayload(queued.payload)
          ? ReminderCategory.reminder
          : ReminderCategory.randomAthkar;
    }
    return null;
  }

  static bool isPrayer(QueuedNotification queued) =>
      PrayerNotificationEvent.isPrayerId(queued.id) ||
      const {
        'prayer_time',
        'prayer_renewal',
      }.contains(_payloadType(queued.payload));

  /// Plans [categories]; the others keep what they hold and still count
  /// against the shared limit.
  ReminderPlan plan(
    ReminderSettings settings,
    List<QueuedNotification> inventory, {
    Set<ReminderCategory> categories = const {...ReminderCategory.values},
  }) {
    final owned = {
      for (final category in ReminderCategory.values)
        category: <int, QueuedNotification>{},
    };
    var foreign = 0;
    for (final queued in inventory) {
      final owner = ownerOf(queued);
      if (owner != null) {
        owned[owner]![queued.id] = queued;
      } else if (!isPrayer(queued)) {
        foreign++;
      }
    }

    var remaining = max(
      0,
      policy.totalPendingLimit - policy.prayerReservedPending - foreign,
    );
    final cancel = <int>{};
    final schedule = <PlannedNotification>[];
    var ownedBefore = 0;
    var ownedAfter = 0;
    int? athkarMinutes;
    DateTime? athkarReshuffle;

    // Reminders, then the nearest calendar events, then random Athkar.
    for (final category
        in ReminderCategory.values.toList()
          ..sort((a, b) => _priority(a).compareTo(_priority(b)))) {
      final held = owned[category]!;
      if (!categories.contains(category)) {
        remaining = max(0, remaining - held.length);
        continue;
      }
      ownedBefore += held.length;
      final List<PlannedNotification> desired;
      switch (category) {
        case ReminderCategory.reminder:
          desired = _fixed(settings.fixed).take(remaining).toList();
        case ReminderCategory.calendar:
          desired = _calendar(
            settings.calendar,
          ).take(min(policy.calendarLimit, remaining)).toList();
        case ReminderCategory.randomAthkar:
          final minutes = settings.randomAthkarMinutes;
          if (repeatsAthkar) {
            final athkar = _repeatingAthkar(
              minutes,
              min(policy.repeatingAthkarLimit, remaining),
            );
            desired = athkar.desired;
            athkarMinutes = athkar.minutes;
            athkarReshuffle = athkar.reshuffleAt;
          } else {
            final live =
                minutes != null && min(policy.randomAthkarLimit, remaining) > 0;
            desired = [if (live) _liveAthkar(minutes)];
            athkarMinutes = live ? minutes : null;
          }
      }
      final wanted = {for (final item in desired) item.id};
      cancel.addAll(held.keys.where((id) => !wanted.contains(id)));
      schedule.addAll(
        desired.where((item) => !item.isSatisfiedBy(held[item.id])),
      );
      ownedAfter += desired.length;
      remaining = max(0, remaining - desired.length);
    }
    return ReminderPlan(
      changes: ReminderChanges(cancel: cancel, schedule: schedule),
      ownedBefore: ownedBefore,
      ownedAfter: ownedAfter,
      athkarMinutes: athkarMinutes,
      athkarReshuffleAt: athkarReshuffle,
    );
  }

  static int _priority(ReminderCategory category) => switch (category) {
    ReminderCategory.reminder => 0,
    ReminderCategory.calendar => 1,
    ReminderCategory.randomAthkar => 2,
  };

  /// One repeating rule per reminder, soonest first, so a short budget
  /// keeps the nearest deliveries.
  List<PlannedNotification> _fixed(List<FixedReminder> reminders) {
    final planned = <PlannedNotification>[];
    for (final reminder in reminders) {
      final weekly = reminder.weekday != null;
      final next = recurringDates(
        now: now,
        hour: reminder.hour,
        minute: reminder.minute,
        weekday: reminder.weekday,
        horizon: const Duration(days: 8),
      ).first;
      planned.add(
        PlannedNotification(
          id: reminder.id,
          category: ReminderCategory.reminder,
          style: weekly
              ? ReminderStyle.weeklyReminder
              : ReminderStyle.dailyReminder,
          title: reminder.title,
          body: reminder.body,
          payload: jsonEncode([
            reminderPayloadVersion,
            reminder.id,
            weekly ? 'weekly' : 'daily',
            reminder.weekday,
            reminder.hour,
            reminder.minute,
            now.location.name,
            scheduleMode,
            reminder.title,
            reminder.body,
          ]),
          at: next,
          repeat: weekly ? NotificationRepeat.weekly : NotificationRepeat.daily,
        ),
      );
    }
    return planned..sort((a, b) => a.at.compareTo(b.at));
  }

  List<PlannedNotification> _calendar(List<CalendarReminder> reminders) {
    final byId = <int, PlannedNotification>{};
    for (final reminder
        in reminders.toList()..sort((a, b) => a.at.compareTo(b.at))) {
      if (!reminder.at.isAfter(now)) continue;
      // Two events sharing an ID is unlikely; the nearer one wins.
      byId.putIfAbsent(
        reminder.id,
        () => PlannedNotification(
          id: reminder.id,
          category: ReminderCategory.calendar,
          style: ReminderStyle.calendar,
          title: reminder.title,
          body: reminder.body,
          payload: reminder.payload,
          at: tz.TZDateTime.from(reminder.at, now.location),
          color: reminder.color,
        ),
      );
    }
    return byId.values.toList();
  }

  /// Random Athkar as one rule: the backend delivers every [minutes] and
  /// picks the text each time, so every Athkar is truly random.
  PlannedNotification _liveAthkar(int minutes) => PlannedNotification(
    id: NotificationIds.randomAthkarBase + 1,
    category: ReminderCategory.randomAthkar,
    style: ReminderStyle.athkar,
    title: content.randomAthkarTitle,
    body: '',
    payload: jsonEncode([liveAthkarPayloadVersion, minutes]),
    at: now.add(Duration(minutes: minutes)),
    repeat: NotificationRepeat.interval,
    intervalMinutes: minutes,
    texts: athkarTexts,
  );

  /// Random Athkar as repeating triggers, which keep firing without Huda.
  /// Text is shuffled once per window, so syncs within a window change
  /// nothing and each window brings new text.
  ({List<PlannedNotification> desired, int? minutes, DateTime? reshuffleAt})
  _repeatingAthkar(int? requested, int capacity) {
    final pattern = requested == null
        ? null
        : repeatingAthkarPattern(requested, capacity);
    if (pattern == null) {
      return (desired: const [], minutes: null, reshuffleAt: null);
    }
    final window = max(pattern.minutes, 60);
    final rotation =
        now.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute ~/ window;
    final texts = List.of(athkarTexts)..shuffle(Random(rotation));
    final desired = <PlannedNotification>[];
    for (var slot = 0; slot < pattern.slots; slot++) {
      final offset = slot * pattern.minutes;
      final hour = pattern.hourly ? null : offset ~/ 60;
      final minute = offset % 60;
      var at = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day,
        hour ?? now.hour,
        minute,
      );
      while (!at.isAfter(now)) {
        at = at.add(
          pattern.hourly ? const Duration(hours: 1) : const Duration(days: 1),
        );
      }
      desired.add(
        PlannedNotification(
          id: NotificationIds.randomAthkarBase + 1 + slot,
          category: ReminderCategory.randomAthkar,
          style: ReminderStyle.athkar,
          title: content.randomAthkarTitle,
          body: texts[slot % texts.length],
          payload: jsonEncode([
            repeatingAthkarPayloadVersion,
            pattern.minutes,
            slot,
            rotation,
          ]),
          at: at,
          repeat: pattern.hourly
              ? NotificationRepeat.hourly
              : NotificationRepeat.daily,
        ),
      );
    }
    return (
      desired: desired,
      minutes: pattern.minutes,
      reshuffleAt: DateTime.fromMillisecondsSinceEpoch(
        (rotation + 1) * window * Duration.millisecondsPerMinute,
        isUtc: true,
      ),
    );
  }

  /// The repeating pattern closest to [requested] minutes that fits in
  /// [capacity] triggers: fixed minutes of every hour, or fixed times of
  /// every day. Equally close patterns resolve to the less frequent one.
  static ({int minutes, int slots, bool hourly})? repeatingAthkarPattern(
    int requested,
    int capacity,
  ) {
    final candidates = [
      for (final minutes in const [10, 12, 15, 20, 30, 60])
        (minutes: minutes, slots: 60 ~/ minutes, hourly: true),
      for (var minutes = 61; minutes <= 1440; minutes++)
        if (1440 % minutes == 0)
          (minutes: minutes, slots: 1440 ~/ minutes, hourly: false),
    ].where((pattern) => pattern.slots <= capacity);
    ({int minutes, int slots, bool hourly})? best;
    double distance(int minutes) => (log(minutes / requested)).abs();
    for (final pattern in candidates) {
      if (best == null ||
          distance(pattern.minutes) < distance(best.minutes) - 1e-9 ||
          (distance(pattern.minutes) - distance(best.minutes)).abs() < 1e-9 &&
              pattern.minutes > best.minutes) {
        best = pattern;
      }
    }
    return best;
  }

  static bool isAthkarPayload(String? payload) {
    try {
      final values = jsonDecode(payload ?? '');
      return values is List &&
          values.isNotEmpty &&
          (values.first == athkarPayloadVersion ||
              values.first == repeatingAthkarPayloadVersion ||
              values.first == liveAthkarPayloadVersion);
    } on FormatException {
      return false;
    }
  }

  static String? _payloadType(String? payload) {
    try {
      final decoded = jsonDecode(payload ?? '');
      return decoded is Map ? '${decoded['type']}' : null;
    } on FormatException {
      return null;
    }
  }

  /// Future local delivery times of a daily or weekly reminder.
  static List<tz.TZDateTime> recurringDates({
    required tz.TZDateTime now,
    required int hour,
    required int minute,
    int? weekday,
    required Duration horizon,
  }) {
    final end = now.add(horizon);
    final dates = <tz.TZDateTime>[];
    for (var day = 0; ; day++) {
      final date = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + day,
        hour,
        minute,
      );
      if (date.isAfter(end)) return dates;
      if (date.isAfter(now) && (weekday == null || date.weekday == weekday)) {
        dates.add(date);
      }
    }
  }
}
