import 'dart:async';

import 'package:flutter/services.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/services/desktop_prayer_settings_navigation.dart';

enum MacPrayerMenuStyle {
  iconOnly,
  iconNameCountdown,
  iconNameClock;

  static MacPrayerMenuStyle fromStorage(String? value) {
    return switch (value) {
      'iconOnly' => iconOnly,
      'iconNameClock' || 'nextPrayerClock' => iconNameClock,
      _ => iconNameCountdown,
    };
  }
}

class MacPrayerMenuPreferences {
  const MacPrayerMenuPreferences({
    this.enabled = true,
    this.style = MacPrayerMenuStyle.iconNameCountdown,
  });

  final bool enabled;
  final MacPrayerMenuStyle style;

  MacPrayerMenuPreferences copyWith({
    bool? enabled,
    MacPrayerMenuStyle? style,
  }) => MacPrayerMenuPreferences(
    enabled: enabled ?? this.enabled,
    style: style ?? this.style,
  );

  static MacPrayerMenuPreferences fromMap(Map<Object?, Object?>? map) =>
      MacPrayerMenuPreferences(
        enabled: map?['enabled'] is bool ? map!['enabled'] as bool : true,
        style: MacPrayerMenuStyle.fromStorage(map?['style'] as String?),
      );

  Map<String, Object> toMap() => {'enabled': enabled, 'style': style.name};
}

class MacPrayerMenuBridge {
  MacPrayerMenuBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.aw.huda/mac_prayer_menu',
  );
  static bool _installed = false;
  static String? _publishedPresentation;

  static void registerPrayerPageAction(bool Function() action) {
    DesktopPrayerSettingsNavigation.register(action);
  }

  static void unregisterPrayerPageAction(bool Function() action) {
    DesktopPrayerSettingsNavigation.unregister(action);
  }

  static bool openSettingsOnCurrentPrayerPage() {
    return DesktopPrayerSettingsNavigation.openOnCurrentPage();
  }

  static Future<void> install({
    required Future<void> Function() openSettings,
  }) async {
    if (!PlatformUtils.isMacOS || _installed) return;
    _installed = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openPrayerSettings') {
        await openSettings();
      }
    });
    await _channel.invokeMethod<void>('ready');
  }

  static Future<MacPrayerMenuPreferences> getPreferences() async {
    if (!PlatformUtils.isMacOS) return const MacPrayerMenuPreferences();
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getPreferences',
    );
    return MacPrayerMenuPreferences.fromMap(raw);
  }

  static Future<void> setPreferences(MacPrayerMenuPreferences preferences) =>
      PlatformUtils.isMacOS
      ? _channel.invokeMethod<void>('setPreferences', preferences.toMap())
      : Future<void>.value();

  static Future<void> syncPresentation(
    AppLocalizations l10n, {
    required Color primaryColor,
  }) async {
    if (!PlatformUtils.isMacOS) return;
    final colorValue = primaryColor.toARGB32();
    final presentationKey = '${l10n.localeName}:$colorValue';
    if (_publishedPresentation == presentationKey) return;
    _publishedPresentation = presentationKey;
    final strings = <String, String>{
      'prayerTimes': l10n.prayerTimes,
      'nextPrayer': l10n.nextPrayer,
      'prayerSettings': l10n.macPrayerMenuSettings,
      'quitHuda': l10n.macPrayerMenuQuit,
      'needsSetup': l10n.macPrayerMenuNeedsSetup,
      'verifyLocation': l10n.macPrayerMenuVerifyLocation,
      'nameCountdown': l10n.macPrayerMenuNameCountdown('{prayer}', '{time}'),
      'nameElapsed': l10n.macPrayerMenuNameElapsed('{prayer}', '{time}'),
      'current': l10n.prayerHeroStarted,
      'hourUnit': l10n.macPrayerMenuHourShort,
      'minuteUnit': l10n.macPrayerMenuMinuteShort,
      'fajr': l10n.fajr,
      'sunrise': l10n.prayerSunriseLabel,
      'dhuhr': l10n.dhuhr,
      'asr': l10n.asr,
      'maghrib': l10n.maghrib,
      'isha': l10n.isha,
      'stopAdhan': l10n.windowsPrayerStopAdhan,
      'dismissFocus': l10n.windowsPrayerDismissFocus,
      'serviceError': l10n.macPrayerApplyError,
    };
    try {
      await _channel.invokeMethod<void>('setPresentation', {
        'locale': l10n.localeName,
        'strings': strings,
        'primaryColor': colorValue,
      });
    } catch (_) {
      if (_publishedPresentation == presentationKey) {
        _publishedPresentation = null;
      }
      rethrow;
    }
  }
}
