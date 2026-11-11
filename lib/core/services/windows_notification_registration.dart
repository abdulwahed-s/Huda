import 'package:flutter/services.dart';

/// Huda's Windows notification identity. Toasts from Huda, its companion and
/// older releases use it, so it must never change. The runner's toast
/// activator (`windows/runner/windows_notification_activator.cpp`), the
/// installer and the MSIX manifest use the same IDs.
class WindowsNotificationIdentity {
  const WindowsNotificationIdentity({
    required this.appName,
    required this.appUserModelId,
    required this.guid,
  });

  final String appName;
  final String appUserModelId;

  /// The toast activator's COM class ID.
  final String guid;
}

/// Registers Huda for toasts in installed and portable apps: the
/// AppUserModelID, its Start menu shortcut and the toast activator's COM
/// server. The runner receives the clicks.
class WindowsNotificationRegistration {
  WindowsNotificationRegistration({
    MethodChannel? channel,
    this.settings = defaultSettings,
  }) : _channel = channel ?? const MethodChannel(channelName);

  static final shared = WindowsNotificationRegistration();
  static const channelName = 'com.aw.huda/windows_notifications';
  static const appId = 'awr.Huda-IslamicCompanionApp';
  static const defaultSettings = WindowsNotificationIdentity(
    appName: 'Huda',
    appUserModelId: appId,
    guid: 'a8c22b55-049e-422f-b30f-863694de08c8',
  );

  final MethodChannel _channel;
  final WindowsNotificationIdentity settings;
  Future<void>? _registration;

  Future<void> ensureRegistered() async {
    final registration = _registration ??= _channel
        .invokeMethod<void>('register', {
          'appId': settings.appUserModelId,
          'appName': settings.appName,
          'activatorGuid': settings.guid,
        })
        .timeout(const Duration(seconds: 30));
    try {
      await registration;
    } catch (_) {
      if (identical(_registration, registration)) _registration = null;
      rethrow;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    await ensureRegistered();
    final setting = await _channel
        .invokeMethod<int>('settings', {'appId': settings.appUserModelId})
        .timeout(const Duration(seconds: 30));
    // NotificationSetting.Enabled is 0. Every OS block and an absent response
    // must prevent the app from claiming that notifications are permitted.
    return setting == 0;
  }
}
