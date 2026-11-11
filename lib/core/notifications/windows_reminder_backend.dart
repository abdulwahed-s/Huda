import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/notifications/reminder_planner.dart';
import 'package:huda/core/notifications/reminder_rule_store.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/windows_notification_registration.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/windows_prayer_notification_gateway.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:synchronized/synchronized.dart';
import 'package:timezone/timezone.dart' as tz;

/// Windows reminders on the native notification worker that prayers use:
/// commands run off the UI thread, pending reads return each toast's text,
/// payload and delivery time, scheduling replaces every toast with the same
/// tag, and cancellation removes duplicates.
///
/// Toasts cannot repeat, so this backend expands each rule: a daily or weekly
/// reminder becomes [datedHorizon] of dated toasts, and random Athkar become
/// a series of up to [athkarLimit] toasts, each with its own random text. For
/// the planner it collapses them back into one entry per rule, marked
/// legacy when coverage runs low so the next sync tops them up. The rules are
/// also published to the prayer companion, which tops up the same toasts
/// while Huda is closed (`ReminderToastPlan` in the companion core).
class WindowsReminderBackend implements ReminderBackend {
  WindowsReminderBackend({
    WindowsPrayerNotificationGateway? gateway,
    Future<void> Function()? prepare,
    CacheHelper? cache,
    Future<bool> Function()? publish,
    tz.TZDateTime Function()? now,
    Random? random,
  }) : _gateway =
           gateway ?? WindowsPrayerNotificationGateway(protectNearDue: false),
       _prepare = prepare ?? _prepareWindows,
       _cache = cache,
       _publish = publish ?? WindowsPrayerTaskbarBridge.publishReminderRules,
       _now = now,
       _random = random ?? Random();

  static const datedHorizon = Duration(days: 60);
  static const athkarHorizon = Duration(days: 30);
  static const athkarLimit = 450;

  /// A sync tops toasts up once their coverage falls below these.
  static const datedRenewal = Duration(days: 45);
  static const athkarRenewal = Duration(days: 15);

  /// When reminders run out unless the companion or Huda renews them: the
  /// earliest last toast among repeating reminders, or null when none are
  /// queued. Updated by every inventory and apply.
  static final coverage = ValueNotifier<DateTime?>(null);

  final WindowsPrayerNotificationGateway _gateway;
  final Future<void> Function() _prepare;
  final CacheHelper? _cache;
  final Future<bool> Function() _publish;
  final tz.TZDateTime Function()? _now;
  final Random _random;
  final Lock _lock = Lock(reentrant: true);
  int _depth = 0;
  List<QueuedNotification>? _queued;

  CacheHelper get _store => _cache ?? getIt<CacheHelper>();
  tz.TZDateTime get _clock => _now?.call() ?? tz.TZDateTime.now(tz.local);

  static Future<void> _prepareWindows() async {
    await PrayerTimeZoneService.refreshLocalTimeZone();
    await WindowsNotificationRegistration.shared.ensureRegistered();
  }

  @override
  ReminderBackendCapabilities get capabilities =>
      const ReminderBackendCapabilities(supported: true);

  @override
  Future<void> prepare() => _prepare();

  /// Holds one queue snapshot, and the queue lock shared with the prayer
  /// companion, for every command in [action]. The outermost session
  /// releases it.
  @override
  Future<T> session<T>(Future<T> Function() action) =>
      _lock.synchronized(() async {
        _depth++;
        try {
          return await action();
        } finally {
          if (--_depth == 0) {
            _queued = null;
            await _gateway.releasePendingSnapshot();
          }
        }
      });

  /// Payloads stay as earlier releases wrote them, so their toasts still match.
  @override
  Future<String> scheduleMode() async => 'exactAllowWhileIdle';

  Future<List<QueuedNotification>> _load() async {
    if (_queued case final queued?) return queued;
    await _gateway.initialize();
    return _queued = [
      for (final request in await _gateway.pendingNotificationRequests())
        QueuedNotification(
          id: request.id,
          title: request.title,
          body: request.body,
          payload: request.payload,
          instantUtc: request is WindowsPendingPrayerNotification
              ? request.deliveryInstantUtc
              : null,
          ambiguous:
              request is WindowsPendingPrayerNotification && request.ambiguous,
        ),
    ];
  }

  static bool _isFixed(int id) =>
      id >= NotificationIds.kahfFriday && id <= NotificationIds.khatmaReminder;

  /// The rule a toast belongs to: a reminder ID for dated and earlier
  /// one-time toasts, 1101 for every Athkar toast, else its own ID.
  static int _ruleOf(int id) {
    if (NotificationIds.windowsReminderOf(id) case final reminder?) {
      return reminder;
    }
    if (NotificationIds.isRandomAthkar(id)) {
      return NotificationIds.randomAthkarBase + 1;
    }
    return id;
  }

  static bool _repeats(int rule) =>
      _isFixed(rule) || rule == NotificationIds.randomAthkarBase + 1;

  static void _updateCoverage(Iterable<QueuedNotification> toasts) {
    final last = <int, DateTime>{};
    for (final toast in toasts) {
      final rule = _ruleOf(toast.id);
      final at = toast.instantUtc;
      if (at == null || !_repeats(rule)) continue;
      if (last[rule] case final known? when !at.isAfter(known)) continue;
      last[rule] = at;
    }
    coverage.value = last.isEmpty
        ? null
        : last.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  static bool _isLiveAthkar(String? payload) {
    try {
      final values = jsonDecode(payload ?? '');
      return values is List &&
          values.isNotEmpty &&
          values.first == ReminderPlanner.liveAthkarPayloadVersion;
    } on FormatException {
      return false;
    }
  }

  /// One entry per rule. Toasts that disagree, run low or were never
  /// published to the companion make the entry legacy, so the planner
  /// schedules the rule again and [apply] tops up or repairs its toasts.
  @override
  Future<List<QueuedNotification>> inventory() => session(() async {
    final toasts = await _cancelOldCalendarEvents(await _load());
    final published = {
      for (final rule in ReminderRuleStore.read(_store))
        rule['id']! as int: rule['payload'],
    };
    final now = _clock.toUtc();
    final byRule = <int, List<QueuedNotification>>{};
    final entries = <QueuedNotification>[];
    for (final toast in toasts) {
      final rule = _ruleOf(toast.id);
      if (_repeats(rule)) {
        byRule.putIfAbsent(rule, () => []).add(toast);
      } else {
        entries.add(toast);
      }
    }
    for (final MapEntry(key: rule, value: group) in byRule.entries) {
      final athkar = rule == NotificationIds.randomAthkarBase + 1;
      final series = [
        for (final toast in group)
          if (athkar ? _isLiveAthkar(toast.payload) : toast.id != rule) toast,
      ]..sort((a, b) => _instant(a).compareTo(_instant(b)));
      final latest = series.isEmpty ? null : series.last;
      final consistent =
          latest != null &&
          series.length == group.length &&
          series.every(
            (toast) =>
                !toast.ambiguous &&
                toast.payload == latest.payload &&
                toast.title == latest.title &&
                (athkar || toast.body == latest.body),
          );
      final renewal = athkar ? athkarRenewal : datedRenewal;
      final covered =
          latest != null && _instant(latest).isAfter(now.add(renewal));
      entries.add(
        QueuedNotification(
          id: rule,
          title: latest?.title,
          body: athkar ? '' : latest?.body,
          payload: latest?.payload,
          legacy: !consistent || !covered || published[rule] != latest.payload,
        ),
      );
    }
    _updateCoverage(toasts);
    return entries;
  });

  bool _cleaned = false;

  /// Huda 4.3.0 queued calendar events through flutter_local_notifications
  /// as one toast with no payload under a hashed ID. Their replacements are
  /// planned from the saved events, so the old ones would fire twice. Every
  /// toast Huda or its companion queues has a payload. Once per launch, on
  /// the first inventory's queue read.
  Future<List<QueuedNotification>> _cancelOldCalendarEvents(
    List<QueuedNotification> toasts,
  ) async {
    if (_cleaned) return toasts;
    final old = {
      for (final toast in toasts)
        if ((toast.payload ?? '').isEmpty &&
            ReminderPlanner.ownerOf(toast) == null &&
            !ReminderPlanner.isPrayer(toast))
          toast.id,
    };
    if (old.isNotEmpty) await _gateway.cancelNotifications(old);
    _cleaned = true;
    return _queued = [
      for (final toast in toasts)
        if (!old.contains(toast.id)) toast,
    ];
  }

  static DateTime _instant(QueuedNotification toast) =>
      toast.instantUtc ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @override
  Future<ApplyReport> apply(ReminderChanges changes) => session(() async {
    final queued = await _load();
    final now = _clock;
    final rules = {
      for (final rule in ReminderRuleStore.read(_store))
        rule['id']! as int: rule,
    };
    final cancel = <int>{};
    final add =
        <
          ({
            int rule,
            int id,
            DateTime at,
            String title,
            String body,
            String payload,
          })
        >[];
    for (final id in changes.cancel) {
      rules.remove(id);
      cancel.addAll(
        queued
            .where((toast) => _ruleOf(toast.id) == id)
            .map((toast) => toast.id),
      );
    }
    for (final notification in changes.schedule) {
      rules[notification.id] = notification.toRule();
      final held = [
        for (final toast in queued)
          if (_ruleOf(toast.id) == notification.id) toast,
      ];
      switch (notification.repeat) {
        case NotificationRepeat.none:
          cancel.addAll(
            held.map((toast) => toast.id).where((id) => id != notification.id),
          );
          add.add((
            rule: notification.id,
            id: notification.id,
            at: notification.at.toUtc(),
            title: notification.title,
            body: notification.body,
            payload: notification.payload,
          ));
        case NotificationRepeat.daily || NotificationRepeat.weekly:
          final wanted = {
            for (final date in ReminderPlanner.recurringDates(
              now: now,
              hour: notification.at.hour,
              minute: notification.at.minute,
              weekday: notification.repeat == NotificationRepeat.weekly
                  ? notification.at.weekday
                  : null,
              horizon: datedHorizon,
            ))
              NotificationIds.windowsReminderOccurrence(notification.id, date):
                  date.toUtc(),
          };
          final kept = <int>{};
          for (final toast in held) {
            final at = wanted[toast.id];
            if (at != null &&
                !toast.ambiguous &&
                toast.payload == notification.payload &&
                toast.title == notification.title &&
                toast.body == notification.body &&
                toast.instantUtc?.millisecondsSinceEpoch ==
                    at.millisecondsSinceEpoch ~/ 1000 * 1000) {
              kept.add(toast.id);
            } else if (at == null) {
              cancel.add(toast.id);
            }
          }
          for (final MapEntry(key: id, value: at) in wanted.entries) {
            if (kept.contains(id)) continue;
            add.add((
              rule: notification.id,
              id: id,
              at: at,
              title: notification.title,
              body: notification.body,
              payload: notification.payload,
            ));
          }
        case NotificationRepeat.interval:
          final kept = <int, DateTime>{};
          for (final toast in held) {
            final at = toast.instantUtc;
            if (!toast.ambiguous &&
                toast.payload == notification.payload &&
                toast.title == notification.title &&
                at != null &&
                at.isAfter(now.toUtc())) {
              kept[toast.id] = at;
            } else {
              cancel.add(toast.id);
            }
          }
          final free = [
            for (
              var id = NotificationIds.randomAthkarBase + 1;
              id <= NotificationIds.randomAthkarBase + athkarLimit;
              id++
            )
              if (!kept.containsKey(id)) id,
          ];
          final times = athkarTimes(
            first: notification.at.toUtc(),
            interval: Duration(minutes: notification.intervalMinutes!),
            existing: kept.values,
            now: now.toUtc(),
            count: free.length,
          );
          for (var index = 0; index < times.length; index++) {
            add.add((
              rule: notification.id,
              id: free[index],
              at: times[index],
              title: notification.title,
              body: notification
                  .texts[_random.nextInt(notification.texts.length)],
              payload: notification.payload,
            ));
          }
        case NotificationRepeat.hourly:
          throw UnsupportedError('Hourly triggers are Apple-only');
      }
    }

    if (cancel.isNotEmpty) {
      await _gateway.cancelNotifications(cancel);
      queued.removeWhere((toast) => cancel.contains(toast.id));
    }
    final accepted = <int>{};
    final attempted = <int>{};
    for (final toast in add) {
      attempted.add(toast.rule);
      try {
        await _gateway.scheduleToast(
          id: toast.id,
          instantUtc: toast.at,
          title: toast.title,
          body: toast.body,
          payload: toast.payload,
          shortDuration: true,
        );
      } on PlatformException catch (error) {
        debugPrint('Windows notification ${toast.id}: ${error.message}');
        continue;
      }
      accepted.add(toast.rule);
      queued
        ..removeWhere((item) => item.id == toast.id)
        ..add(
          QueuedNotification(
            id: toast.id,
            title: toast.title,
            body: toast.body,
            payload: toast.payload,
            instantUtc: toast.at,
          ),
        );
    }
    _updateCoverage(queued);
    await ReminderRuleStore.write(_store, rules.values);
    await _publish();
    // A rule fails only when none of its toasts were accepted; a full queue
    // can still leave a shorter series.
    return ApplyReport(failed: attempted.difference(accepted));
  });

  /// Continues the Athkar series: gaps before the last queued Athkar are
  /// filled, then times follow every interval up to [athkarHorizon]. The
  /// same as the companion's `ReminderToastPlan.AthkarTimes`.
  @visibleForTesting
  static List<DateTime> athkarTimes({
    required DateTime first,
    required Duration interval,
    required Iterable<DateTime> existing,
    required DateTime now,
    required int count,
  }) {
    final end = now.add(athkarHorizon);
    final future = existing.where((time) => time.isAfter(now)).toSet().toList()
      ..sort();
    final missing = <DateTime>[];
    var remaining = min(count, athkarLimit - future.length);
    var cursor = first.isAfter(now) ? first : now.add(interval);
    for (final scheduled in future.where((time) => time.isBefore(end))) {
      while (remaining > 0 &&
          cursor.isBefore(scheduled.subtract(const Duration(minutes: 1)))) {
        missing.add(cursor);
        remaining--;
        cursor = cursor.add(interval);
      }
      cursor = scheduled.add(interval);
    }
    while (remaining > 0 && cursor.isBefore(end)) {
      missing.add(cursor);
      remaining--;
      cursor = cursor.add(interval);
    }
    return missing;
  }
}
