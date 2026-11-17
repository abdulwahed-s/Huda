import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/mac_prayer_experience.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_method_label.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:synchronized/synchronized.dart';

class MacPrayerStatus {
  const MacPrayerStatus({
    this.revision = 0,
    this.ready = false,
    this.configurationSignature = '',
    this.supportsTimeSensitive = false,
    this.startupState = 'unavailable',
    this.authorization = 'notDetermined',
    this.notificationAlertStyle = 'unknown',
    this.pendingCount = 0,
    this.coverageUntil,
    this.nextEvent,
    this.audioReady = false,
    this.audioSession,
    this.focusSession,
    this.focusCanDismiss = true,
    this.error,
    this.audioError,
    this.experience = const MacPrayerExperience(),
    this.displays = const [],
    this.events = const [],
    this.hiddenLaunch = false,
  });
  final int revision, pendingCount;
  final bool ready,
      audioReady,
      focusCanDismiss,
      hiddenLaunch,
      supportsTimeSensitive;
  final String startupState,
      authorization,
      notificationAlertStyle,
      configurationSignature;
  final DateTime? coverageUntil, nextEvent;
  final String? audioSession, focusSession, error, audioError;
  final MacPrayerExperience experience;
  final List<Map<Object?, Object?>> displays, events;
  factory MacPrayerStatus.fromMap(Map<Object?, Object?> map) => MacPrayerStatus(
    revision: map['revision']! as int,
    ready: map['ready'] == true,
    configurationSignature: map['configurationSignature'] as String? ?? '',
    supportsTimeSensitive: map['supportsTimeSensitive'] == true,
    startupState: map['startupState']! as String,
    authorization: map['authorization']! as String,
    notificationAlertStyle:
        map['notificationAlertStyle'] as String? ?? 'unknown',
    pendingCount: map['pendingCount']! as int,
    coverageUntil: _date(map['coverageMillis']),
    nextEvent: _date(map['nextEventMillis']),
    audioReady: map['audioReady'] == true,
    audioSession: map['audioSession'] as String?,
    focusSession: map['focusSession'] as String?,
    focusCanDismiss: map['focusCanDismiss'] != false,
    error: map['error'] as String?,
    audioError: map['audioError'] as String?,
    experience: MacPrayerExperience.fromMap(map['experience']! as Map),
    displays: (map['displays']! as List).cast<Map<Object?, Object?>>(),
    events: (map['events']! as List).cast<Map<Object?, Object?>>(),
    hiddenLaunch: map['hiddenLaunch'] == true,
  );
  static DateTime? _date(Object? millis) => millis is num
      ? DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true)
      : null;
}

/// Bounded v1 channel. Native acknowledgements, rather than saved UI drafts,
/// determine the applied state. No method implicitly registers login startup.
class MacPrayerBridge {
  static const channel = MethodChannel('com.aw.huda/mac_prayer_service');
  static final status = ValueNotifier(const MacPrayerStatus());
  static bool _installed = false;
  static final _mutations = Lock();
  static Future<void> install(AudioCoordinator coordinator) async {
    if (!PlatformUtils.isMacOS || _installed) return;
    _installed = true;
    coordinator.register(AudioCoordinator.adhan, () {
      unawaited(command('stopAudio', sessionId: status.value.audioSession));
    });
    channel.setMethodCallHandler((call) async {
      if (call.method == 'statusChanged') {
        _accept(call.arguments as Map<Object?, Object?>);
      } else if (call.method == 'audioStarted') {
        coordinator.requestAudio(AudioCoordinator.adhan);
      } else if (call.method == 'audioStopped') {
        coordinator.release(AudioCoordinator.adhan);
      }
    });
    await refresh();
    if (status.value.audioSession != null) {
      coordinator.requestAudio(AudioCoordinator.adhan);
    }
  }

  static MacPrayerStatus _accept(Map<Object?, Object?> value) {
    final parsed = MacPrayerStatus.fromMap(value);
    status.value = parsed;
    return parsed;
  }

  static Future<MacPrayerStatus> _call(
    String method, [
    Map<String, Object?> extra = const {},
  ]) async {
    final result = await channel
        .invokeMapMethod<Object?, Object?>(method, {
          'schemaVersion': 1,
          ...extra,
        })
        .timeout(const Duration(seconds: 30));
    if (result == null) {
      throw StateError('Missing macOS prayer acknowledgement.');
    }
    return _accept(result);
  }

  static Future<MacPrayerStatus> refresh() => _call('status');
  static Future<MacPrayerStatus> applyExperience(
    MacPrayerExperience settings,
  ) => _mutations.synchronized(() async {
    settings.validate();
    final before = await refresh();
    // Registration is its own explicit user command. A configuration publication
    // cannot restore revoked consent during automatic reconciliation.
    final requestedStartup = settings.startAtLogin;
    final applied = await _call('setExperience', {
      'expectedRevision': before.revision,
      'experience': settings.copyWith(startAtLogin: false).toMap(),
      'preserveStartup':
          settings.backgroundEnabled && before.experience.startAtLogin,
    });
    if (requestedStartup != applied.experience.startAtLogin) {
      return _call('setStartup', {'enabled': requestedStartup});
    }
    return applied;
  });

  static Future<MacPrayerStatus> publishSchedule(
    PrayerScheduleConfiguration configuration,
  ) => _mutations.synchronized(() async {
    final before = await refresh();
    final result = await _call('configure', {
      'expectedRevision': before.revision,
      'configurationSignature': configuration.signature,
      'schedule': {
        ...configuration.toJson(),
        'methodToken': PrayerTimesCalculator.resolveMethod(
          configuration.methodToken,
          configuration.location.countryCode ?? '',
        ).name,
      },
    });
    if (result.revision < before.revision ||
        result.configurationSignature != configuration.signature) {
      throw StateError('Configuration was not applied.');
    }
    return result;
  });

  static Future<MacPrayerStatus> command(
    String command, {
    String? sessionId,
    MacPrayerExperience? settings,
    String? prayer,
  }) => _call(command, {
    if (sessionId != null) 'sessionId': sessionId,
    if (settings != null) 'experience': settings.toMap(),
    if (prayer != null) 'prayer': prayer,
  });
  static Future<void> openLoginSettings() =>
      channel.invokeMethod<void>('openLoginSettings', {'schemaVersion': 1});
  static Future<void> openNotificationSettings() => channel.invokeMethod<void>(
    'openNotificationSettings',
    {'schemaVersion': 1},
  );
  static Future<MacPrayerStatus> requestNotifications() =>
      _call('requestNotifications');
  static String? _presentationKey;
  static Future<void> syncPresentation(
    AppLocalizations l10n, {
    required int primaryColor,
    required String themeMode,
    required bool use24HourClock,
    String fontFamily = 'Amiri',
    String numerals = 'western',
    double textScale = 1,
  }) => _mutations.synchronized(() async {
    if (!PlatformUtils.isMacOS) return;
    final key =
        '${l10n.localeName}:$primaryColor:$themeMode:$use24HourClock:$fontFamily:$numerals:$textScale';
    if (_presentationKey == key) return;
    final names = {
      'fajr': l10n.fajr,
      'sunrise': l10n.prayerSunriseLabel,
      'dhuhr': l10n.dhuhr,
      'asr': l10n.asr,
      'maghrib': l10n.maghrib,
      'isha': l10n.isha,
    };
    await _call('setPresentation', {
      'locale': l10n.localeName,
      'primaryColor': primaryColor,
      'themeMode': themeMode,
      'use24HourClock': use24HourClock,
      'fontFamily': fontFamily,
      'numerals': numerals,
      'textScale': textScale.isFinite ? textScale.clamp(.5, 2.0) : 1.0,
      'strings': {
        ...names,
        for (final method in CalculationMethod.values)
          'method:${method.name}': prayerCalendarMethodLabel(l10n, method.name),
        'advanceBody': l10n.iosPrayerAdvanceBody('{prayer}', '{minutes}'),
        'stop': l10n.windowsPrayerStopAdhan,
        'dismiss': l10n.windowsPrayerDismissFocus,
        'emergencyExit': l10n.macPrayerEmergencyExit,
        'focusMessage': l10n.windowsPrayerFocusMessage,
        'verse': l10n.macPrayerVerse,
        'verseReference': l10n.windowsPrayerFocusVerseReference,
        'remaining': l10n.windowsPrayerFocusTimeRemaining,
        'lockedHint': l10n.windowsPrayerFocusLockedHint,
        'setup': l10n.macPrayerMenuNeedsSetup,
        'renewalTitle': l10n.iosPrayerRenewalTitle,
        'renewalBody': l10n.iosPrayerRenewalBody,
        for (final name in names.entries) ...{
          '${name.key}Title': l10n.notificationPrayerTimeTitle(name.value),
          '${name.key}Body': l10n.notificationPrayerTimeBody(name.value),
        },
      },
    });
    _presentationKey = key;
  });
}
