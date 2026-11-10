import 'package:huda/core/notifications/reminder_preparation.dart';
import 'package:huda/core/notifications/reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/notifications/reminder_planner.dart';
import 'package:huda_notifications/huda_notifications.dart';

/// Android reminders in Huda's native engine (`huda_notifications`).
/// Each reminder is one alarm that re-arms itself, so daily, weekly and
/// Athkar reminders never run out, and random Athkar pick their text when
/// they fire. Reminders that Huda 4.3.0 and earlier scheduled through
/// flutter_local_notifications (FLN), which the native package still holds,
/// appear as legacy: the planner schedules them here again, which cancels the
/// old copy.
class AndroidReminderBackend implements ReminderBackend {
  AndroidReminderBackend({
    PrayerHostApi? host,
    Future<void> Function()? prepare,
  }) : _host = host ?? PrayerHostApi(),
       _prepare = prepare ?? prepareReminderNotifications;

  final PrayerHostApi _host;
  final Future<void> Function() _prepare;

  /// Old FLN reminder IDs at the last inventory.
  Set<int> _legacy = {};
  Future<void>? _cleanup;

  @override
  ReminderBackendCapabilities get capabilities =>
      const ReminderBackendCapabilities(supported: true);

  @override
  Future<void> prepare() async {
    await _prepare();
    final cleanup = _cleanup ??= _cancelUnknownLegacy();
    try {
      await cleanup;
    } catch (_) {
      if (identical(_cleanup, cleanup)) _cleanup = null;
      rethrow;
    }
  }

  /// Old FLN entries that neither a reminder nor a prayer owns, such as
  /// 4.3.0's yearly calendar events under hashed IDs. Their replacements are
  /// planned from settings, so they would only fire twice. Nothing schedules
  /// through FLN anymore, so once per launch is enough.
  Future<void> _cancelUnknownLegacy() async {
    final unknown = [
      for (final old in await _host.getLegacyNotifications())
        if (old.prayer == 'standard' && !_isReminder(old)) old.id,
    ];
    if (unknown.isNotEmpty) await _host.cancelLegacyNotifications(unknown);
  }

  @override
  Future<T> session<T>(Future<T> Function() action) => action();

  /// One entry per ID; the native entry wins. An ID FLN still holds is
  /// legacy, so the planner schedules it again and [apply] cancels the old
  /// copy. Old prayers are listed too; the prayer scheduler moves them.
  @override
  Future<List<QueuedNotification>> inventory() async {
    final native = await _host.getReminders();
    final old = await _host.getLegacyNotifications();
    _legacy = {
      for (final event in old)
        if (_isReminder(event)) event.id,
    };
    final nativeIds = {for (final reminder in native) reminder.id};
    return [
      for (final event in old)
        if (!nativeIds.contains(event.id))
          QueuedNotification(
            id: event.id,
            title: event.title,
            body: event.body,
            payload: event.compatiblePayload,
            legacy: _legacy.contains(event.id),
          ),
      // Native delivery times move with every repeat; the payload, which
      // carries a one-time reminder's instant, is compared instead.
      for (final reminder in native)
        QueuedNotification(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          payload: reminder.payload,
          legacy: _legacy.contains(reminder.id),
        ),
    ];
  }

  static bool _isReminder(EventData old) =>
      old.prayer == 'standard' &&
      ReminderPlanner.ownerOf(
            QueuedNotification(id: old.id, payload: old.compatiblePayload),
          ) !=
          null;

  @override
  Future<String> scheduleMode() async => 'native';

  @override
  Future<ApplyReport> apply(ReminderChanges changes) async {
    // Old FLN copies of every touched reminder go first, so an ID is never
    // delivered twice.
    final old = [
      for (final id in {
        ...changes.cancel,
        for (final item in changes.schedule) item.id,
      })
        if (_legacy.contains(id)) id,
    ];
    if (old.isNotEmpty) await _host.cancelLegacyNotifications(old);
    final failed = await _host.applyReminders(
      ReminderBatch(
        cancel: changes.cancel.toList(),
        schedule: changes.schedule.map(reminderData).toList(),
      ),
    );
    return ApplyReport(failed: failed.toSet());
  }

  static ReminderData reminderData(PlannedNotification notification) {
    final rule = notification.toRule();
    return ReminderData(
      id: rule['id']! as int,
      kind: rule['kind']! as String,
      style: rule['style']! as String,
      title: rule['title']! as String,
      body: rule['body']! as String,
      payload: rule['payload']! as String,
      utcMillis: rule['utcMillis']! as int,
      hour: rule['hour'] as int?,
      minute: rule['minute'] as int?,
      weekday: rule['weekday'] as int?,
      intervalMinutes: rule['intervalMinutes'] as int?,
      texts: (rule['texts']! as List).cast<String>(),
      color: rule['color'] as int?,
    );
  }
}
