import 'package:flutter/foundation.dart';
import 'package:huda/core/notifications/apple_reminder_backend.dart';
import 'package:huda/core/services/windows_notification_registration.dart';
import 'package:huda_notifications/huda_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:url_launcher/url_launcher.dart';

/// What Huda can do about notification access right now.
enum NotificationPermissionState {
  /// Notifications are allowed.
  granted,

  /// Apple's quiet delivery: allowed, without banners or sound.
  provisional,

  /// The system prompt can still be shown.
  promptable,

  /// Only the user can change it, in the system settings.
  settingsOnly,
}

/// Whether Huda may show notifications, and the system prompts and settings
/// for it, through Huda's own platform code on every platform.
abstract final class NotificationPermissions {
  static TargetPlatform? get _platform =>
      kIsWeb ? null : defaultTargetPlatform;
  static bool get _apple =>
      _platform == TargetPlatform.iOS || _platform == TargetPlatform.macOS;

  @visibleForTesting
  static PrayerHostApi android = PrayerHostApi();

  /// Notifications are allowed (Android also needs the permission on 13+).
  static Future<bool> areEnabled() async => switch (_platform) {
    TargetPlatform.android => (await android.getCapabilities()).notifications,
    TargetPlatform.iOS ||
    TargetPlatform.macOS => const {
      'authorized',
      'provisional',
    }.contains(await appleAuthorization()),
    TargetPlatform.windows =>
      WindowsNotificationRegistration.shared.areNotificationsEnabled(),
    _ => true,
  };

  /// The single source for notification access, shared by every page.
  static Future<NotificationPermissionState> state() async {
    try {
      switch (_platform) {
        case TargetPlatform.android:
          if ((await android.getCapabilities()).notifications) {
            return NotificationPermissionState.granted;
          }
          final status = await handler.Permission.notification.status;
          return status.isPermanentlyDenied || status.isRestricted
              ? NotificationPermissionState.settingsOnly
              : NotificationPermissionState.promptable;
        case TargetPlatform.iOS || TargetPlatform.macOS:
          return switch (await appleAuthorization()) {
            'authorized' => NotificationPermissionState.granted,
            'provisional' => NotificationPermissionState.provisional,
            'denied' => NotificationPermissionState.settingsOnly,
            _ => NotificationPermissionState.promptable,
          };
        case TargetPlatform.windows:
          return await WindowsNotificationRegistration.shared
                  .areNotificationsEnabled()
              ? NotificationPermissionState.granted
              : NotificationPermissionState.settingsOnly;
        default:
          return NotificationPermissionState.granted;
      }
    } catch (error) {
      debugPrint('Unable to read notification access: $error');
      return NotificationPermissionState.promptable;
    }
  }

  /// Shows the system prompt where one exists; true when allowed afterwards.
  /// Never opens the system settings; see [openSettings].
  static Future<bool> request() async {
    switch (_platform) {
      case TargetPlatform.android:
        try {
          await handler.Permission.notification.request();
        } catch (error) {
          debugPrint('Unable to request notification permission: $error');
        }
        return areEnabled();
      case TargetPlatform.iOS || TargetPlatform.macOS:
        return requestApple();
      default:
        return areEnabled();
    }
  }

  /// Opens the system page where the user can allow Huda's notifications.
  /// Only call this from something the user tapped.
  static Future<void> openSettings() async {
    try {
      switch (_platform) {
        case TargetPlatform.windows:
          await launchUrl(Uri.parse('ms-settings:notifications'));
        case TargetPlatform.macOS:
          if (await openMacOSSettings()) return;
          await launchUrl(
            Uri.parse(
              'x-apple.systempreferences:com.apple.Notifications-Settings',
            ),
          );
        case TargetPlatform.android || TargetPlatform.iOS:
          await handler.openAppSettings();
        default:
          break;
      }
    } catch (error) {
      debugPrint('Unable to open notification settings: $error');
    }
  }

  /// `authorized`, `denied`, `provisional` or `notDetermined` on iOS and
  /// macOS; empty elsewhere or when it can't be read.
  static Future<String> appleAuthorization() async {
    if (!_apple) return '';
    try {
      return await AppleReminderBackend.channel.invokeMethod<String>(
            'authorization',
          ) ??
          '';
    } catch (error) {
      debugPrint('Unable to read notification authorization: $error');
      return '';
    }
  }

  /// Shows the system prompt on iOS and macOS; true when granted.
  static Future<bool> requestApple() async {
    if (!_apple) return false;
    try {
      return await AppleReminderBackend.channel.invokeMethod<bool>(
            'requestAuthorization',
          ) ??
          false;
    } catch (error) {
      debugPrint('Unable to request notification permission: $error');
      return false;
    }
  }

  /// Opens Huda's page in macOS Notifications settings.
  static Future<bool> openMacOSSettings() async {
    if (_platform != TargetPlatform.macOS) return false;
    try {
      return await AppleReminderBackend.channel.invokeMethod<bool>(
            'openSettings',
          ) ??
          false;
    } catch (error) {
      debugPrint('Unable to open notification settings: $error');
      return false;
    }
  }

  /// Exact alarms are allowed. Always true outside Android.
  static Future<bool> canScheduleExact() async {
    if (_platform != TargetPlatform.android) return true;
    try {
      return (await android.getCapabilities()).exactAlarms;
    } catch (error) {
      debugPrint('Unable to check exact alarm access: $error');
      return false;
    }
  }

  /// Opens Android's exact alarm setting. Returns the current state; the
  /// caller checks again when Huda resumes.
  static Future<bool> requestExact() async {
    if (await canScheduleExact()) return true;
    try {
      return (await android.openSettings('exact')).exactAlarms;
    } catch (error) {
      debugPrint('Unable to request exact alarm access: $error');
      return false;
    }
  }
}
