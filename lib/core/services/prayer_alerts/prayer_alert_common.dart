import 'dart:async';

import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/service_locator.dart';

/// Rebuilds the prayer schedule after settings change, as the old dialogs did.
Future<void> reconcilePrayerAlerts(String reason) async {
  final PrayerScheduleResult result;
  try {
    result = await getIt<PrayerNotificationScheduler>().reconcile(
      reason: reason,
      force: true,
    );
  } catch (error) {
    throw PrayerAlertApplyException(
      PrayerAlertSaveFailure.scheduleFailed,
      error,
    );
  }
  if (!result.isSuccess &&
      result.status != PrayerScheduleStatus.degraded &&
      result.status != PrayerScheduleStatus.locationUnavailable) {
    throw PrayerAlertApplyException(
      PrayerAlertSaveFailure.scheduleFailed,
      result.message,
    );
  }
}

/// Desktop tests: Huda (or its companion) is running, so the alert is shown
/// after a short wait here, through the same native preview as before.
class DelayedPrayerTest {
  Timer? _timer;
  Completer<bool>? _waiting;

  /// True when the wait ended normally, false when [cancel]led.
  Future<bool> wait([Duration delay = const Duration(seconds: 10)]) {
    cancel();
    final waiting = _waiting = Completer<bool>();
    _timer = Timer(delay, () {
      if (!waiting.isCompleted) waiting.complete(true);
    });
    return waiting.future;
  }

  void cancel() {
    _timer?.cancel();
    final waiting = _waiting;
    if (waiting != null && !waiting.isCompleted) waiting.complete(false);
    _waiting = null;
  }
}

/// Maps a shared style to the minute options that can be shown.
int clampBefore(int minutes, List<int> options) =>
    options.contains(minutes) ? minutes : 0;
