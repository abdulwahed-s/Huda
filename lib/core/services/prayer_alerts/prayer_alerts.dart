import 'package:huda/core/services/android_prayer_experience_service.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda/core/services/prayer_alerts/android_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/ios_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/linux_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/mac_prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_controller.dart';
import 'package:huda/core/services/prayer_alerts/windows_prayer_alert_platform.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/platform_utils.dart';

export 'package:huda/core/services/prayer_alerts/prayer_alert_controller.dart';
export 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';

/// The prayer alert settings for this device. It outlives the sheet, so a
/// save that is still running finishes after the sheet closes.
abstract final class PrayerAlerts {
  static PrayerAlertController<Object?>? _shared;

  static PrayerAlertController<Object?> get shared =>
      _shared ??= PrayerAlertController<Object?>(_platform());

  static set shared(PrayerAlertController<Object?> controller) =>
      _shared = controller;

  static dynamic _platform() {
    if (PlatformUtils.isAndroid) {
      return AndroidPrayerAlertPlatform(
        settings: getIt<AndroidPrayerExperienceService>(),
        state: getIt<AndroidPrayerNotificationStateService>(),
      );
    }
    if (PlatformUtils.isIOS) return IOSPrayerAlertPlatform();
    if (PlatformUtils.isMacOS) return MacPrayerAlertPlatform();
    if (PlatformUtils.isWindows) return WindowsPrayerAlertPlatform();
    return LinuxPrayerAlertPlatform();
  }
}
