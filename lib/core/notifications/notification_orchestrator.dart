import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/notifications/reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/notifications/reminder_planner.dart';
import 'package:huda/core/services/calendar_notification_service.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/notification_capacity_policy.dart';
import 'package:huda/core/services/notification_ids.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/reminder_notification_content.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:synchronized/synchronized.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class ReminderSyncResult {
  const ReminderSyncResult({
    this.supported = true,
    this.failed = const {},
    this.athkarIncomplete = false,
    this.athkarMinutes,
  });

  final bool supported;

  /// Notifications the operating system did not accept.
  final Set<int> failed;

  /// Random Athkar are on but not all of them could be queued.
  final bool athkarIncomplete;

  /// The Athkar frequency actually scheduled. iOS and macOS repeating
  /// triggers can only express some frequencies; null when Athkar are off.
  final int? athkarMinutes;

  /// Whether any delivery of reminder [reminderId] was rejected, including
  /// its dated Windows toasts.
  bool reminderFailed(int reminderId) => failed.any(
    (id) =>
        id == reminderId || NotificationIds.windowsReminderOf(id) == reminderId,
  );
}

/// The single owner of reminder, random Athkar and calendar notifications.
///
/// Features save their settings and ask for a sync; the orchestrator reads
/// every setting, shares the platform's notification limit (leaving the
/// prayers' reserve), compares the plan with what the OS holds and applies
/// only the difference in one batch. Requests arriving close together run
/// as one sync. Prayers keep their own reconciler.
class NotificationOrchestrator {
  NotificationOrchestrator({
    required CacheHelper cache,
    ReminderBackend? backend,
    NotificationCapacityPolicy? policy,
    Future<List<CalendarReminder>> Function()? calendarReminders,
    Future<ReminderNotificationContent> Function()? content,
    tz.TZDateTime Function()? now,
    Future<void> Function(String reason)? onPrayerCapacityChanged,
    Future<void> Function(ReminderSyncResult result, int? athkarMinutes)?
    onAthkarScheduled,
    this.debounce = const Duration(milliseconds: 250),
    this.reshuffleWhileRunning = true,
  }) : _cache = cache,
       _backend = backend ?? ReminderBackend.forPlatform(),
       _policy = policy,
       _calendarReminders = calendarReminders,
       _content = content ?? ReminderNotificationContent.load,
       _now = now,
       _onPrayerCapacityChanged = onPrayerCapacityChanged ?? _reconcilePrayers,
       _onAthkarScheduled = onAthkarScheduled ?? _cleanUpAthkarRenewal;

  /// The app's instance, built from the service locator on first use.
  static NotificationOrchestrator get shared =>
      _shared ??= NotificationOrchestrator(cache: getIt<CacheHelper>());
  static NotificationOrchestrator? _shared;

  @visibleForTesting
  static set debugShared(NotificationOrchestrator? value) => _shared = value;

  final CacheHelper _cache;
  final ReminderBackend _backend;
  final NotificationCapacityPolicy? _policy;
  final Future<List<CalendarReminder>> Function()? _calendarReminders;
  final Future<ReminderNotificationContent> Function() _content;
  final tz.TZDateTime Function()? _now;
  final Future<void> Function(String reason) _onPrayerCapacityChanged;
  final Future<void> Function(ReminderSyncResult result, int? athkarMinutes)
  _onAthkarScheduled;
  final Duration debounce;

  /// While Huda runs, refresh repeating Athkar text at each new window, so
  /// every delivery shows a different Athkar.
  final bool reshuffleWhileRunning;
  Timer? _reshuffle;

  final Lock _lock = Lock();
  final Set<ReminderCategory> _requested = {};
  final List<String> _reasons = [];
  Completer<ReminderSyncResult>? _next;
  Timer? _timer;

  NotificationCapacityPolicy get _currentPolicy =>
      _policy ?? NotificationCapacityPolicy.current;

  /// Syncs soon. Requests made within [debounce] of each other run as one
  /// sync covering all of their categories, and share its result.
  Future<ReminderSyncResult> requestSync(
    String reason, {
    Set<ReminderCategory> categories = const {...ReminderCategory.values},
  }) {
    _requested.addAll(categories);
    _reasons.add(reason);
    final next = _next ??= Completer<ReminderSyncResult>();
    _timer?.cancel();
    _timer = Timer(debounce, _drain);
    return next.future;
  }

  /// Syncs now, after any sync already running. For startup and background
  /// work that must finish before continuing.
  Future<ReminderSyncResult> syncNow(
    String reason, {
    Set<ReminderCategory> categories = const {...ReminderCategory.values},
  }) => _lock.synchronized(() => _sync(categories, reason));

  void _drain() {
    _timer = null;
    _lock.synchronized(() async {
      final next = _next;
      if (next == null) return;
      _next = null;
      final categories = {..._requested};
      final reason = _reasons.join(', ');
      _requested.clear();
      _reasons.clear();
      try {
        next.complete(await _sync(categories, reason));
      } catch (error, stackTrace) {
        next.completeError(error, stackTrace);
      }
    });
  }

  /// Schedules [notification] once through this platform's reminder backend,
  /// between syncs; for the test notification. False when it was rejected.
  Future<bool> scheduleOnce(PlannedNotification notification) =>
      _lock.synchronized(() async {
        if (!_backend.capabilities.supported) return false;
        await _backend.prepare();
        final report = await _backend.session(
          () => _backend.apply(ReminderChanges(schedule: [notification])),
        );
        return !report.failed.contains(notification.id);
      });

  /// Reminder notifications the OS holds, for status and diagnostics.
  Future<List<QueuedNotification>> heldReminders() async {
    if (!_backend.capabilities.supported) return const [];
    await _backend.prepare();
    return [
      for (final queued in await _backend.inventory())
        if (ReminderPlanner.ownerOf(queued) != null) queued,
    ];
  }

  Future<ReminderSyncResult> _sync(
    Set<ReminderCategory> categories,
    String reason,
  ) async {
    if (!_backend.capabilities.supported) {
      return const ReminderSyncResult(supported: false);
    }
    await _backend.prepare();
    await _cache.reload();
    final content = await _content();
    final calendar = categories.contains(ReminderCategory.calendar)
        ? await (_calendarReminders ?? _storedCalendarReminders)()
        : const <CalendarReminder>[];
    final settings = ReminderSettings.fromCache(
      _cache,
      content,
      calendar: calendar,
    );
    final policy = _currentPolicy;

    final (plan, report) = await _backend.session(() async {
      final planner = ReminderPlanner(
        policy: policy,
        scheduleMode: await _backend.scheduleMode(),
        content: content,
        repeatsAthkar: _backend.capabilities.repeatsAthkar,
        now: _now?.call() ?? tz.TZDateTime.now(tz.local),
      );
      final plan = planner.plan(
        settings,
        await _backend.inventory(),
        categories: categories,
      );
      final report = plan.changes.isEmpty
          ? const ApplyReport()
          : await _backend.apply(plan.changes);
      return (plan, report);
    });

    final athkarSynced = categories.contains(ReminderCategory.randomAthkar);
    final athkarOn = settings.randomAthkarMinutes != null;
    final athkarRejected = report.failed.any(NotificationIds.isRandomAthkar);
    final result = ReminderSyncResult(
      failed: report.failed,
      athkarMinutes: plan.athkarMinutes,
      athkarIncomplete:
          athkarSynced &&
          athkarOn &&
          (athkarRejected || plan.athkarMinutes == null),
    );
    if (athkarSynced) _scheduleReshuffle(plan.athkarReshuffleAt);
    debugPrint(
      'Reminder sync ($reason): ${plan.changes.cancel.length} cancelled, '
      '${plan.changes.schedule.length} scheduled, '
      '${report.failed.length} rejected',
    );

    if (athkarSynced) {
      try {
        await _onAthkarScheduled(result, settings.randomAthkarMinutes);
      } catch (error) {
        debugPrint('Athkar renewal registration failed: $error');
      }
    }
    // Prayers use what reminders leave only where their reserve is below
    // their own limit; elsewhere reminder changes never affect them.
    if (plan.ownedAfter != plan.ownedBefore &&
        policy.prayerReservedPending < policy.prayerPendingLimit) {
      unawaited(
        _onPrayerCapacityChanged('reminder-capacity-changed').catchError(
          (Object error) => debugPrint('Prayer capacity update failed: $error'),
        ),
      );
    }
    return result;
  }

  void _scheduleReshuffle(DateTime? at) {
    _reshuffle?.cancel();
    _reshuffle = null;
    reshuffleAt = null;
    if (!reshuffleWhileRunning || at == null) return;
    reshuffleAt = at;
    // A minute late, so the window has turned on every clock.
    final delay =
        at.difference(_now?.call() ?? DateTime.now()) +
        const Duration(minutes: 1);
    _reshuffle = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => requestSync(
        'athkar-reshuffle',
        categories: {ReminderCategory.randomAthkar},
      ),
    );
  }

  /// When the running app next refreshes repeating Athkar text.
  @visibleForTesting
  DateTime? reshuffleAt;

  /// Stops pending timers; pending requests still complete.
  void dispose() {
    _reshuffle?.cancel();
    _reshuffle = null;
  }

  Future<List<CalendarReminder>> _storedCalendarReminders() async {
    final calendar = getIt.isRegistered<HijriCalendarService>()
        ? getIt<HijriCalendarService>()
        : HijriCalendarService(cache: _cache);
    await calendar.initialize();
    return CalendarNotificationService.remindersFromStorage(
      _cache.getDataString(key: 'events'),
      calendar.toGregorian,
    );
  }

  static Future<void> _reconcilePrayers(String reason) async {
    if (!getIt.isRegistered<PrayerNotificationScheduler>()) return;
    await getIt<PrayerNotificationScheduler>().reconcile(reason: reason);
  }

  static const renewalTaskName = 'renewAthkarNotifications';
  static const retryTaskName = 'retryAthkarScheduling';

  /// Random Athkar no longer run out, so the background renewal earlier
  /// releases registered on Android is cancelled.
  static Future<void> _cleanUpAthkarRenewal(
    ReminderSyncResult result,
    int? minutes,
  ) async {
    if (!PlatformUtils.isAndroid) return;
    await Workmanager().cancelByTag('athkar-renewal');
    await Workmanager().cancelByTag('athkar-retry');
  }
}
