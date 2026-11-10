import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/notifications/reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/notifications/reminder_preparation.dart';

/// iOS and macOS reminders through the runner's own channel
/// (`ReminderNotificationsChannel` in `ios/Runner/AppDelegate.swift`, and
/// `macos/Runner/MainFlutterWindow.swift`). Requests keep the identifier and
/// userInfo keys flutter_local_notifications used (the decimal ID, `payload`),
/// so requests from older releases are listed, replaced and cancelled the
/// same way, and their taps still route.
class AppleReminderBackend implements ReminderBackend {
  AppleReminderBackend({Future<void> Function()? prepare})
    : _prepare = prepare ?? prepareReminderNotifications;

  /// Also carries authorization and taps (`NotificationTaps`).
  static const channel = MethodChannel('com.aw.huda/reminder_notifications');

  final Future<void> Function() _prepare;
  Future<void>? _cleanup;

  static bool get _isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  ReminderBackendCapabilities get capabilities =>
      const ReminderBackendCapabilities(supported: true, repeatsAthkar: true);

  @override
  Future<void> prepare() async {
    await _prepare();
    final cleanup = _cleanup ??= _cancelOldCalendarEvents();
    try {
      await cleanup;
    } catch (_) {
      if (identical(_cleanup, cleanup)) _cleanup = null;
      rethrow;
    }
  }

  /// Huda 4.3.0 queued calendar events as yearly triggers with no payload
  /// under hashed IDs. Their one-time replacements are planned from the saved
  /// events, so the old ones would only fire twice. Once per launch is enough.
  ///
  /// flutter_local_notifications stored a missing payload as `''`. The hashed
  /// IDs can land in any range, prayers' included, but nothing else Huda ever
  /// queued is yearly without a payload, so the ID is not checked.
  Future<void> _cancelOldCalendarEvents() async {
    final old = [
      for (final request in await _pending())
        if (request.yearly && (request.queued.payload ?? '').isEmpty)
          request.queued.id,
    ];
    if (old.isNotEmpty) await _cancel(old);
  }

  @override
  Future<T> session<T>(Future<T> Function() action) => action();

  @override
  Future<List<QueuedNotification>> inventory() async => [
    for (final request in await _pending()) request.queued,
  ];

  Future<List<({QueuedNotification queued, bool yearly})>> _pending() async {
    final pending = await channel.invokeListMethod<Map>('pending') ?? const [];
    return [
      for (final request in pending)
        (
          queued: QueuedNotification(
            id: request['id']! as int,
            title: request['title'] as String?,
            body: request['body'] as String?,
            payload: request['payload'] as String?,
          ),
          yearly: request['yearly'] == true,
        ),
    ];
  }

  Future<void> _cancel(Iterable<int> ids) =>
      channel.invokeMethod<void>('cancel', {'ids': ids.toList()});

  /// Recorded in payloads; Apple has no exact-alarm permission.
  @override
  Future<String> scheduleMode() async => 'exactAllowWhileIdle';

  @override
  Future<ApplyReport> apply(ReminderChanges changes) async {
    if (changes.cancel.isNotEmpty) await _cancel(changes.cancel);
    final failed = <int>{};
    for (final notification in changes.schedule) {
      try {
        await channel.invokeMethod<void>(
          notification.repeat == NotificationRepeat.none
              ? 'scheduleOnce'
              : 'schedule',
          arguments(notification),
        );
      } catch (error) {
        debugPrint('Notification ${notification.id} was rejected: $error');
        failed.add(notification.id);
      }
    }
    // macOS can drop a request without an error when its queue is full, so
    // confirm the batch once against the system queue.
    if (_isMacOS && changes.schedule.isNotEmpty) {
      final held = {for (final request in await _pending()) request.queued.id};
      failed.addAll(
        changes.schedule
            .map((notification) => notification.id)
            .where((id) => !held.contains(id)),
      );
    }
    return ApplyReport(failed: failed);
  }

  /// One-time reminders fire at their instant. Repeating ones carry the
  /// wall-clock fields and no time zone, so they follow the device when
  /// travelling.
  @visibleForTesting
  static Map<String, Object?> arguments(PlannedNotification notification) => {
    'id': notification.id,
    'title': notification.title,
    'body': notification.body,
    'payload': notification.payload,
    // Calendar events alert normally; Athkar never break through Focus.
    'timeSensitive':
        notification.style == ReminderStyle.dailyReminder ||
        notification.style == ReminderStyle.weeklyReminder,
    ...switch (notification.repeat) {
      NotificationRepeat.none => {
        'utcMillis': notification.at.millisecondsSinceEpoch,
      },
      NotificationRepeat.interval => throw UnsupportedError(
        'Interval repeats need a backend that picks text at delivery',
      ),
      _ => {
        'minute': notification.at.minute,
        if (notification.repeat != NotificationRepeat.hourly)
          'hour': notification.at.hour,
        // Apple counts weekdays from Sunday = 1.
        if (notification.repeat == NotificationRepeat.weekly)
          'weekday': notification.at.weekday % 7 + 1,
      },
    },
  };
}
