import 'package:flutter/material.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda_notifications/huda_notifications.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  Future<void>? _resumeCheck;
  bool _resumeCheckRequested = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _requestResumeCheck();
    }
  }

  /// Desktop windows resume on every focus change. Repeated resumes during a
  /// check run one more check afterwards instead of queueing one each.
  void _requestResumeCheck() {
    if (_resumeCheck != null) {
      _resumeCheckRequested = true;
      return;
    }
    _resumeCheck = () async {
      try {
        do {
          _resumeCheckRequested = false;
          await _checkAndResumeScheduling();
        } while (_resumeCheckRequested);
      } finally {
        _resumeCheck = null;
      }
    }();
  }

  Future<void> _checkAndResumeScheduling() async {
    try {
      if (HudaPrayerNotifications.isSupported &&
          getIt.isRegistered<AndroidPrayerNotificationStateService>()) {
        await getIt<AndroidPrayerNotificationStateService>().initialize();
      }
    } catch (error) {
      debugPrint('Android prayer state refresh failed: $error');
    }
    try {
      await getIt<HijriCalendarService>().refreshAutomaticAdjustmentIfDue();
    } catch (error) {
      debugPrint('Hijri calendar refresh check failed: $error');
    }

    try {
      await NotificationOrchestrator.shared.requestSync('app-resumed');
    } catch (error) {
      debugPrint('Reminder resume sync failed: $error');
    }

    try {
      final result = await getIt<PrayerNotificationScheduler>().reconcile(
        reason: 'app-resumed',
      );
      debugPrint(
        'Prayer notification resume status: ${result.status.name}; '
        'coverage=${result.coverageUntil}',
      );
    } catch (error) {
      debugPrint('Prayer notification resume check failed: $error');
    }
  }

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔄 App lifecycle manager initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔄 App lifecycle manager disposed');
  }
}
