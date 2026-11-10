import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/android_reminder_backend.dart';
import 'package:huda/core/notifications/reminder_model.dart';

class ReminderBackendCapabilities {
  const ReminderBackendCapabilities({
    required this.supported,
    this.repeatsAthkar = false,
  });

  /// The platform can hold reminders at all.
  final bool supported;

  /// Random Athkar become a few repeating triggers (iOS, macOS). Elsewhere
  /// they are one interval rule and the backend picks the text at delivery.
  final bool repeatsAthkar;
}

/// Where reminders are scheduled on one platform. Every method works on
/// whole batches, so a sync reads the queue once and applies once.
abstract interface class ReminderBackend {
  ReminderBackendCapabilities get capabilities;

  /// Loads the plugin, time zone and channels before a sync.
  Future<void> prepare();

  /// Runs [action] against one consistent view of the queue.
  Future<T> session<T>(Future<T> Function() action);

  Future<List<QueuedNotification>> inventory();

  /// Android schedule mode recorded in payloads, so a permission change
  /// replaces notifications scheduled under the other mode.
  Future<String> scheduleMode();

  Future<ApplyReport> apply(ReminderChanges changes);

  static ReminderBackend forPlatform() {
    if (kIsWeb) return const UnsupportedReminderBackend();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidReminderBackend(),
      _ => const UnsupportedReminderBackend(),
    };
  }
}

/// The web and other platforms without scheduled notifications.
class UnsupportedReminderBackend implements ReminderBackend {
  const UnsupportedReminderBackend();

  @override
  ReminderBackendCapabilities get capabilities =>
      const ReminderBackendCapabilities(supported: false);

  @override
  Future<void> prepare() async {}

  @override
  Future<T> session<T>(Future<T> Function() action) => action();

  @override
  Future<List<QueuedNotification>> inventory() async => const [];

  @override
  Future<String> scheduleMode() async => 'exactAllowWhileIdle';

  @override
  Future<ApplyReport> apply(ReminderChanges changes) async =>
      ApplyReport(failed: {for (final item in changes.schedule) item.id});
}
