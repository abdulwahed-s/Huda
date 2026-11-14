import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/ios_prayer_experience.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:synchronized/synchronized.dart';

class IOSPrayerStatus {
  const IOSPrayerStatus({
    this.revision = 0,
    this.policyRevision = 0,
    this.ready = false,
    this.configurationSignature = '',
    this.experience = const IOSPrayerExperience(),
    this.notificationAuthorization = 'notDetermined',
    this.alarmAuthorization = 'unavailable',
    this.notificationSound = false,
    this.timeSensitiveAllowed = false,
    this.supportsAlarms = false,
    this.supportsSiri = false,
    this.fullAlarmAvailable = false,
    this.customAlarmSound = false,
    this.fullAlarmReciters = const {},
    this.backgroundRefresh = false,
    this.lowPowerMode = false,
    this.notificationCount = 0,
    this.otherNotificationCount = 0,
    this.alarmCount = 0,
    this.coverageUntil,
    this.optionalCoverageUntil,
    this.nextAlert,
    this.lastSuccess,
    this.migration = 'uninitialized',
    this.travelPending = false,
    this.error,
    this.backgroundError,
    this.schedule,
    this.policies = const {},
    this.events = const [],
  });
  final int revision,
      policyRevision,
      notificationCount,
      otherNotificationCount,
      alarmCount;
  final bool ready,
      notificationSound,
      timeSensitiveAllowed,
      supportsAlarms,
      supportsSiri,
      fullAlarmAvailable,
      customAlarmSound,
      backgroundRefresh,
      lowPowerMode,
      travelPending;
  final String configurationSignature,
      notificationAuthorization,
      alarmAuthorization,
      migration;
  final String? error, backgroundError;
  final DateTime? coverageUntil, optionalCoverageUntil, nextAlert, lastSuccess;
  final PrayerScheduleConfiguration? schedule;
  final IOSPrayerExperience experience;
  final Map<String, Map<Object?, Object?>> policies;
  final List<Map<Object?, Object?>> events;

  /// Reciters whose whole adhan is ready as an alarm sound.
  final Set<String> fullAlarmReciters;
  bool get ownsSchedule => migration == 'native' || migration == 'retired';
  bool get notificationsAllowed => [
    'authorized',
    'provisional',
    'ephemeral',
  ].contains(notificationAuthorization);
  factory IOSPrayerStatus.fromMap(Map<Object?, Object?> value) {
    if (value['schemaVersion'] != 1 || value['revision'] is! int) {
      throw const FormatException('Invalid native iOS prayer receipt.');
    }
    DateTime? date(String key) => value[key] is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (value[key]! as num).toInt(),
            isUtc: true,
          )
        : null;
    return IOSPrayerStatus(
      revision: value['revision']! as int,
      policyRevision: value['policyRevision']! as int,
      ready: value['ready'] == true,
      configurationSignature: value['configurationSignature']! as String,
      experience: IOSPrayerExperience.fromMap(value['experience']! as Map),
      notificationAuthorization: value['notificationAuthorization']! as String,
      alarmAuthorization: value['alarmAuthorization']! as String,
      notificationSound: value['notificationSound'] == true,
      timeSensitiveAllowed: value['timeSensitiveAllowed'] == true,
      supportsAlarms: value['supportsAlarms'] == true,
      supportsSiri: value['supportsSiri'] == true,
      fullAlarmAvailable: value['fullAlarmAvailable'] == true,
      customAlarmSound: value['customAlarmSound'] == true,
      fullAlarmReciters: {
        ...(value['fullAlarmReciters'] as List? ?? const []).cast<String>(),
      },
      backgroundRefresh: value['backgroundRefresh'] == true,
      lowPowerMode: value['lowPowerMode'] == true,
      notificationCount: value['notificationCount']! as int,
      otherNotificationCount: value['otherNotificationCount']! as int,
      alarmCount: value['alarmCount']! as int,
      coverageUntil: date('coverageMillis'),
      optionalCoverageUntil: date('optionalCoverageMillis'),
      nextAlert: date('nextAlertMillis'),
      lastSuccess: date('lastSuccessMillis'),
      migration: value['migration']! as String,
      travelPending: value['travelPending'] == true,
      error: value['error'] as String?,
      backgroundError: value['backgroundError'] as String?,
      schedule: PrayerScheduleConfiguration.tryParse(value['schedule']),
      policies: (value['policies']! as Map).map(
        (key, value) =>
            MapEntry(key as String, Map<Object?, Object?>.from(value as Map)),
      ),
      events: (value['events']! as List)
          .map((e) => Map<Object?, Object?>.from(e as Map))
          .toList(growable: false),
    );
  }
}

class IOSPrayerBridge {
  static const channel = MethodChannel('com.aw.huda/ios_prayer_service');
  static final status = ValueNotifier(const IOSPrayerStatus());
  static final _mutations = Lock();
  static bool _installed = false;
  static AudioCoordinator? _audio;
  static Future<void> install(
    AudioCoordinator coordinator, {
    required Future<void> Function() openPrayerTimes,
  }) async {
    if (!PlatformUtils.isIOS || _installed) return;
    _installed = true;
    _audio = coordinator;
    coordinator.register(
      AudioCoordinator.adhan,
      () => unawaited(stopPreview()),
    );
    channel.setMethodCallHandler((call) async {
      if (call.method == 'statusChanged') {
        _accept(call.arguments as Map<Object?, Object?>);
      }
      if (call.method == 'openPrayerTimes') {
        await channel.invokeMethod<bool>('consumeOpenPrayerTimes', {
          'schemaVersion': 1,
        });
        await openPrayerTimes();
      }
      if (call.method == 'audioStopped') {
        coordinator.release(AudioCoordinator.adhan);
      }
    });
    await refresh();
    final open = await channel.invokeMethod<bool>('consumeOpenPrayerTimes', {
      'schemaVersion': 1,
    });
    if (open == true) await openPrayerTimes();
  }

  static IOSPrayerStatus _accept(Map<Object?, Object?> value) {
    final parsed = IOSPrayerStatus.fromMap(value);
    status.value = parsed;
    return parsed;
  }

  static Future<IOSPrayerStatus> _call(
    String method, [
    Map<String, Object?> extra = const {},
  ]) async {
    final result = await channel
        .invokeMapMethod<Object?, Object?>(method, {
          'schemaVersion': 1,
          ...extra,
        })
        .timeout(const Duration(seconds: 30));
    if (result == null) throw StateError('Missing iOS prayer acknowledgement.');
    return _accept(result);
  }

  static Future<IOSPrayerStatus> refresh() => _call('status');
  static Future<IOSPrayerStatus> reconcile() =>
      _mutations.synchronized(() => _call('reconcile'));
  static Future<IOSPrayerStatus> applyExperience(
    IOSPrayerExperience experience,
  ) => _mutations.synchronized(() async {
    experience.validate();
    final before = await refresh();
    return _call('setExperience', {
      'expectedRevision': before.revision,
      'experience': experience.toMap(),
    });
  });
  static Future<IOSPrayerStatus> publishSchedule(
    PrayerScheduleConfiguration configuration, {
    String? migration,
    DateTime? nativeNotBefore,
    int? locationRevisionFloor,
  }) => _mutations.synchronized(() async {
    final before = await refresh();
    final receipt = await _call('configure', {
      'expectedRevision': before.revision,
      'configurationSignature': configuration.signature,
      'schedule': configuration.toJson(),
      if (locationRevisionFloor != null)
        'locationRevisionFloor': locationRevisionFloor,
      if (migration != null) 'migration': migration,
      if (nativeNotBefore != null)
        'nativeNotBeforeMillis': nativeNotBefore.millisecondsSinceEpoch,
    });
    if (receipt.revision < before.revision ||
        receipt.configurationSignature != configuration.signature) {
      throw StateError('iOS prayer configuration was not acknowledged.');
    }
    return receipt;
  });
  static Future<IOSPrayerStatus> requestNotifications() =>
      _call('requestNotifications');
  static Future<IOSPrayerStatus> requestAlarms() => _call('requestAlarms');
  static Future<IOSPrayerStatus> openSettings() => _call('openSettings');
  static Future<IOSPrayerStatus> cancel({
    Iterable<int>? ids,
    bool disable = false,
  }) => _mutations.synchronized(
    () => _call('cancel', {
      if (ids != null) 'ids': ids.toList(),
      'disable': disable,
    }),
  );
  static Future<IOSPrayerStatus> testDelivery(
    IOSPrayerMode mode, {
    required String reciterId,
    required String audioVersion,
    required String title,
    required String body,
  }) => _call('testDelivery', {
    'mode': mode.name,
    'reciterId': reciterId,
    'audioVersion': audioVersion,
    'title': title,
    'body': body,
  });
  static Future<IOSPrayerStatus> cancelTests() => _call('cancelTests');

  /// Installs a downloaded reciter's clip and makes its alarm file.
  static Future<IOSPrayerStatus> installAudio(Map<String, Object?> audio) =>
      _call('installAudio', audio);
  static Future<void> preview(String path) async {
    _audio?.requestAudio(AudioCoordinator.adhan);
    try {
      await _call('previewAudio', {'path': path});
    } catch (_) {
      _audio?.release(AudioCoordinator.adhan);
      rethrow;
    }
  }

  static Future<void> stopPreview() async {
    try {
      await _call('stopAudio');
    } finally {
      _audio?.release(AudioCoordinator.adhan);
    }
  }

  static String? _presentationKey;
  static Future<void> syncPresentation(AppLocalizations l10n) =>
      _mutations.synchronized(() async {
        if (!PlatformUtils.isIOS || _presentationKey == l10n.localeName) return;
        final before = await refresh();
        final names = {
          'fajr': l10n.fajr,
          'sunrise': l10n.prayerSunriseLabel,
          'dhuhr': l10n.dhuhr,
          'asr': l10n.asr,
          'maghrib': l10n.maghrib,
          'isha': l10n.isha,
        };
        await _call('setPresentation', {
          'expectedRevision': before.revision,
          'strings': {
            ...names,
            'setup': l10n.macPrayerMenuNeedsSetup,
            'stop': l10n.windowsPrayerStopAdhan,
            'renewalTitle': l10n.iosPrayerRenewalTitle,
            'renewalBody': l10n.iosPrayerRenewalBody,
            'advanceTitle': l10n.iosPrayerAdvanceTitle,
            'advanceBody': l10n.iosPrayerAdvanceBody('{prayer}', '{minutes}'),
            for (final name in names.entries) ...{
              '${name.key}Title': l10n.notificationPrayerTimeTitle(name.value),
              '${name.key}Body': l10n.notificationPrayerTimeBody(name.value),
            },
          },
        });
        _presentationKey = l10n.localeName;
      });
}
