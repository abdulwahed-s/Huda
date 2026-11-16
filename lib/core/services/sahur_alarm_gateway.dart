import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/services/reminder_notification_content.dart';
import 'package:huda/l10n/app_localizations.dart';

class SahurAlarmSettings {
  const SahurAlarmSettings({
    this.enabled = false,
    this.type = 0,
    this.hour = 4,
    this.minute = 0,
    this.minutesBeforeFajr = 30,
  });

  factory SahurAlarmSettings.fromCache(CacheHelper cache) {
    final parts = '${cache.getData(key: 'sahurExactTime') ?? '04:00'}'.split(
      ':',
    );
    final hour = int.tryParse(parts.first);
    final minute = parts.length == 2 ? int.tryParse(parts.last) : null;
    final lead = cache.getData(key: 'sahurMinutesBeforeFajr');
    return SahurAlarmSettings(
      enabled: cache.getData(key: 'sahurAlarmEnabled') == true,
      type: cache.getData(key: 'sahurAlarmType') == 1 ? 1 : 0,
      hour: hour != null && hour >= 0 && hour < 24 ? hour : 4,
      minute: minute != null && minute >= 0 && minute < 60 ? minute : 0,
      minutesBeforeFajr: lead is int ? lead.clamp(10, 150) : 30,
    );
  }

  final bool enabled;
  final int type, hour, minute, minutesBeforeFajr;

  Map<String, Object> toMap(AppLocalizations l10n) => {
    'enabled': enabled,
    'type': type,
    'hour': hour,
    'minute': minute,
    'minutesBeforeFajr': minutesBeforeFajr,
    'locale': l10n.localeName,
    'title': l10n.sahurAlarmRinging,
    'body': l10n.sahurAlarmNotificationBody,
    'stop': l10n.stopAlarm,
  };
}

class SahurAlarmReceipt {
  const SahurAlarmReceipt({
    required this.accepted,
    this.notificationOnly = false,
  });
  final bool accepted, notificationOnly;
}

abstract interface class SahurAlarmGateway {
  Future<SahurAlarmReceipt> configure(
    SahurAlarmSettings settings, {
    bool requestPermission = false,
  });
}

/// The native stores own renewal and playback; Flutter only publishes settings.
class NativeSahurAlarmGateway implements SahurAlarmGateway {
  const NativeSahurAlarmGateway();
  static const channel = MethodChannel('com.aw.huda/sahur_alarm');

  static Future<bool> requiresNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return true;
    try {
      return !(await IOSPrayerBridge.refresh()).supportsAlarms;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<SahurAlarmReceipt> configure(
    SahurAlarmSettings settings, {
    bool requestPermission = false,
  }) async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return SahurAlarmReceipt(accepted: !settings.enabled);
    }
    final l10n = await ReminderNotificationContent.loadLocalizations();
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await IOSPrayerBridge.configureSahur(
          settings.toMap(l10n),
          requestPermission: requestPermission,
        );
        return SahurAlarmReceipt(
          accepted: !settings.enabled || status.sahurScheduled,
          notificationOnly: !status.supportsAlarms,
        );
      }
      final result = await channel.invokeMapMethod<String, Object?>(
        'configure',
        {'schemaVersion': 1, ...settings.toMap(l10n)},
      );
      return SahurAlarmReceipt(accepted: result?['accepted'] == true);
    } on PlatformException {
      throw const NotificationNotScheduledException(114);
    }
  }

  static Future<void> sync(
    CacheHelper cache, {
    bool requestPermission = false,
  }) async {
    final receipt = await const NativeSahurAlarmGateway().configure(
      SahurAlarmSettings.fromCache(cache),
      requestPermission: requestPermission,
    );
    if (!receipt.accepted) throw const NotificationNotScheduledException(114);
  }
}
