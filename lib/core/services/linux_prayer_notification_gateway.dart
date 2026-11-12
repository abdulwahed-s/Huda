import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/linux_prayer_experience.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/prayer_schedule_configuration.dart';
import 'package:huda/core/utils/platform_utils.dart';

class LinuxPrayerStatus {
  const LinuxPrayerStatus(this.values);
  final Map<String, dynamic> values;
  LinuxPrayerExperience get experience =>
      LinuxPrayerExperience.tryParse(values['experience']) ??
      LinuxPrayerTrayBridge.experience.value;
  bool get ready => values['ready'] == true;
  bool get supportsLockedAudio => values['supportsLockedAudio'] == true;

  /// 2 and later: per-prayer settings and reminders before prayers.
  int get experienceVersion => values['experienceVersion'] as int? ?? 1;
  String get deliveryOwner => values['deliveryOwner'] as String? ?? 'legacy';
  String get startupState => LinuxPrayerTrayBridge.status.value.startupEnabled
      ? 'enabled'
      : 'notRegistered';
  String? get error => values['error'] as String?;
  String? get audioError => values['audioError'] as String?;
  String? get audioSession => values['audioSession'] as String?;
  String? get focusSession => values['focusSession'] as String?;
  bool get focusCanDismiss => values['focusCanDismiss'] != false;
  List<Map<Object?, Object?>> get displays =>
      (values['displays'] as List? ?? const [])
          .map((e) => (e as Map).cast<Object?, Object?>())
          .toList();
}

/// Native receipts are authoritative. Preview commands never persist or transfer ownership.
abstract final class LinuxPrayerNotificationGateway {
  static final status = ValueNotifier(const LinuxPrayerStatus({}));
  static Timer? _watch;
  static bool _refreshing = false;
  static AudioCoordinator? _coordinator;
  static String? _handoffSession;
  static Future<void> install(AudioCoordinator coordinator) async {
    if (!PlatformUtils.isLinux || _watch != null) return;
    _coordinator = coordinator;
    coordinator.register(AudioCoordinator.adhan, () {
      final session = status.value.audioSession;
      if (session != null) {
        unawaited(
          command(
            'stopAudio',
            sessionId: session,
          ).catchError((Object _) => status.value),
        );
      }
    });
    try {
      await refresh();
    } catch (_) {
      /* The first presentation publication starts the service. */
    }
    _watch = Timer.periodic(const Duration(milliseconds: 500), (_) {
      unawaited(refresh().catchError((Object _) => status.value));
    });
  }

  static LinuxPrayerStatus _accept(Map<String, dynamic> values) {
    final next = LinuxPrayerStatus(values);
    final handoff = values['audioRequestSession'] as String?;
    if (handoff != null && _handoffSession != handoff && _coordinator != null) {
      _handoffSession = handoff;
      _coordinator!.requestAudio(AudioCoordinator.adhan);
      unawaited(
        command(
          'acknowledgeAudio',
          sessionId: handoff,
        ).catchError((Object _) => next),
      );
    }
    if (next.audioSession != null) {
      _coordinator?.requestAudio(AudioCoordinator.adhan);
    } else if (handoff == null) {
      _coordinator?.release(AudioCoordinator.adhan);
    }
    Map<String, dynamic> comparable(Map<String, dynamic> source) {
      final result = {...source}
        ..remove('changeSerial')
        ..remove('audioPosition');
      if (result['focus'] is Map) {
        result['focus'] = Map<String, dynamic>.from(result['focus'] as Map)
          ..remove('remainingSeconds')
          ..remove('deadlineUtcMs');
      }
      return result;
    }

    if (jsonEncode(comparable(status.value.values)) !=
        jsonEncode(comparable(values))) {
      status.value = next;
    }
    return next;
  }

  static Future<LinuxPrayerStatus> refresh() async {
    if (!PlatformUtils.isLinux || _refreshing) return status.value;
    _refreshing = true;
    try {
      final raw = await LinuxPrayerTrayBridge.channel
          .invokeMapMethod<String, dynamic>('experienceStatus');
      if (raw?['error'] != null) throw StateError(raw!['error'] as String);
      final json = raw?['experienceStatus'];
      if (json is String) {
        final result = _accept(jsonDecode(json) as Map<String, dynamic>);
        await LinuxPrayerTrayBridge.acceptExperienceReadback(result.values);
        return result;
      }
      return status.value;
    } finally {
      _refreshing = false;
    }
  }

  /// Whether prayers can move to the companion with the default reminders:
  /// it runs (started if needed), reports no error, still has the legacy
  /// owner, and the desktop shows silent notifications. (Its `ready` flag
  /// means native delivery is already active, so it is false until then.)
  static Future<bool> canAdoptDefault() async {
    if (!PlatformUtils.isLinux) return false;
    try {
      await LinuxPrayerTrayBridge.ensureService();
      final current = await refresh();
      final server = current.values['notificationServer'];
      return current.error == null &&
          current.deliveryOwner == 'legacy' &&
          server is Map &&
          server['silentSupported'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<LinuxPrayerStatus> command(
    String action, {
    required String sessionId,
    LinuxPrayerExperience? settings,
    double? volume,
  }) async {
    final raw = await LinuxPrayerTrayBridge.channel
        .invokeMapMethod<String, dynamic>('experienceCommand', {
          'json': jsonEncode({
            'action': action,
            'sessionId': sessionId,
            if (settings != null) 'settings': settings.toMap(),
            if (volume != null) 'volume': volume,
          }),
        });
    if (raw?['error'] != null || raw?['experienceStatus'] is! String) {
      throw StateError(
        raw?['error'] as String? ?? 'Prayer command unavailable.',
      );
    }
    return _accept(
      jsonDecode(raw!['experienceStatus'] as String) as Map<String, dynamic>,
    );
  }

  static Future<LinuxPrayerStatus> applyExperience(
    LinuxPrayerExperience next, {
    required bool startAtLogin,
  }) async => _accept(
    await LinuxPrayerTrayBridge.applyExperience(
      next,
      startAtLogin: startAtLogin,
    ),
  );
  static Future<LinuxPrayerStatus> reconcile(
    PrayerScheduleConfiguration configuration, {
    required int scheduleRevision,
    required DateTime cutover,
    Iterable<int> handledOccurrences = const [],
  }) async => _accept(
    await LinuxPrayerTrayBridge.applyExperience(
      configuration.linuxExperience!,
      startAtLogin: LinuxPrayerTrayBridge.preferences.value.startAtLogin,
      schedule: configuration,
      scheduleRevision: scheduleRevision,
      cutover: cutover,
      handledOccurrences: handledOccurrences,
    ),
  );

  @visibleForTesting
  static void resetForTesting() {
    _watch?.cancel();
    _watch = null;
    _coordinator = null;
    _handoffSession = null;
    _refreshing = false;
    status.value = const LinuxPrayerStatus({});
  }
}
