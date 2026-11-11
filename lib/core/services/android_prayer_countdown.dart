import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the Android countdown notification looks.
enum PrayerCountdownStyle { progress, timetable, minimal }

/// The user's countdown choices. Native code reads them from the same
/// preferences, so the countdown keeps working while Huda is closed.
@immutable
class PrayerCountdownSettings {
  const PrayerCountdownSettings({
    this.enabled = false,
    this.style = PrayerCountdownStyle.progress,
    this.lockScreen = true,
    this.showSunrise = true,
    this.liveUpdate = false,
  });

  final bool enabled;
  final PrayerCountdownStyle style;
  final bool lockScreen;

  /// Timetable only: include sunrise in the day's times.
  final bool showSunrise;

  /// Minimal and Progress on Android 16: use Android's own template, so the
  /// timer shows in the status bar (a Live Update) and the notification's
  /// header instead of Huda's worded timer in the body.
  final bool liveUpdate;

  PrayerCountdownSettings copyWith({
    bool? enabled,
    PrayerCountdownStyle? style,
    bool? lockScreen,
    bool? showSunrise,
    bool? liveUpdate,
  }) => PrayerCountdownSettings(
    enabled: enabled ?? this.enabled,
    style: style ?? this.style,
    lockScreen: lockScreen ?? this.lockScreen,
    showSunrise: showSunrise ?? this.showSunrise,
    liveUpdate: liveUpdate ?? this.liveUpdate,
  );
}

/// What Android reports about the countdown right now.
@immutable
class PrayerCountdownStatus {
  const PrayerCountdownStatus({
    required this.posted,
    required this.notificationsAllowed,
    required this.channelBlocked,
    required this.hasLocation,
    required this.liveUpdateSupported,
    required this.liveUpdateAllowed,
  });

  factory PrayerCountdownStatus.fromMap(Map<Object?, Object?> map) =>
      PrayerCountdownStatus(
        posted: map['posted'] == true,
        notificationsAllowed: map['notificationsAllowed'] != false,
        channelBlocked: map['channelBlocked'] == true,
        hasLocation: map['hasLocation'] == true,
        liveUpdateSupported: map['liveUpdateSupported'] == true,
        liveUpdateAllowed: map['liveUpdateAllowed'] == true,
      );

  final bool posted;
  final bool notificationsAllowed;
  final bool channelBlocked;
  final bool hasLocation;
  final bool liveUpdateSupported;
  final bool liveUpdateAllowed;
}

/// The system page [AndroidPrayerCountdown.openSettings] opens.
enum PrayerCountdownSettingsTarget { app, channel, liveUpdate }

/// The Android countdown lives in native code (`com.aw.huda.countdown`); this
/// only saves the user's choices and reads its status.
abstract final class AndroidPrayerCountdown {
  static const _channel = MethodChannel('com.aw.huda/prayer_countdown');

  // The enabled key is the one the old Dart foreground service used.
  static const enabledKey = 'persistent_prayer_countdown_enabled';
  static const styleKey = 'prayer_countdown_style';
  static const lockScreenKey = 'prayer_countdown_lock_screen';
  static const showSunriseKey = 'prayer_countdown_show_sunrise';
  static const liveUpdateKey = 'prayer_countdown_live_update';

  static Future<PrayerCountdownSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = PrayerCountdownSettings();
    final style = prefs.getString(styleKey);
    return PrayerCountdownSettings(
      enabled: prefs.getBool(enabledKey) ?? defaults.enabled,
      style: PrayerCountdownStyle.values.firstWhere(
        (value) => value.name == style,
        orElse: () => defaults.style,
      ),
      lockScreen: prefs.getBool(lockScreenKey) ?? defaults.lockScreen,
      showSunrise: prefs.getBool(showSunriseKey) ?? defaults.showSunrise,
      liveUpdate: prefs.getBool(liveUpdateKey) ?? defaults.liveUpdate,
    );
  }

  /// Saves [settings] and has Android show, restyle or remove the countdown.
  static Future<PrayerCountdownStatus> save(
    PrayerCountdownSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, settings.enabled);
    await prefs.setString(styleKey, settings.style.name);
    await prefs.setBool(lockScreenKey, settings.lockScreen);
    await prefs.setBool(showSunriseKey, settings.showSunrise);
    await prefs.setBool(liveUpdateKey, settings.liveUpdate);
    return refresh();
  }

  /// Reposts the countdown from the saved settings, for example at startup.
  static Future<PrayerCountdownStatus> refresh() => _status('apply');

  static Future<PrayerCountdownStatus> status() => _status('status');

  static Future<bool> openSettings(
    PrayerCountdownSettingsTarget target,
  ) async =>
      await _channel.invokeMethod<bool>('openSettings', {
        'target': target.name,
      }) ??
      false;

  static Future<PrayerCountdownStatus> _status(String method) async {
    final map = await _channel.invokeMapMethod<Object?, Object?>(method);
    return PrayerCountdownStatus.fromMap(map ?? const {});
  }
}
