import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:huda/core/services/android_prayer_experience_service.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/notifications/notification_taps.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda_notifications/huda_notifications.dart';

class AndroidPrayerNotificationStateService extends ChangeNotifier {
  AndroidPrayerNotificationStateService({
    required this.platform,
    required this.settings,
    required this.audioCoordinator,
  });
  final HudaPrayerNotifications platform;
  final AndroidPrayerExperienceService settings;
  final AudioCoordinator audioCoordinator;
  RuntimeSnapshot? snapshot;
  Object? error;
  StreamSubscription<Map<String, Object?>>? _subscription;
  final _events = StreamController<Map<String, Object?>>.broadcast();

  /// Native events for widgets (the channel allows one listener: this one).
  Stream<Map<String, Object?>> get events => _events.stream;
  Future<void>? _refreshing;
  Timer? _reconnect;
  bool _needsRefresh = false;
  String? _preemptedSessionId;
  bool _disposed = false;
  final _handledNavigation = <String>{};

  /// A tapped reminder's payload, kept until a navigator can open its page.
  String? _reminderTap;
  Future<void> initialize() async {
    if (!HudaPrayerNotifications.isSupported) return;
    audioCoordinator.register(AudioCoordinator.adhan, () {
      final session = snapshot?.session;
      if (session != null) {
        _preemptedSessionId = session.id;
        unawaited(platform.host.stopSession(session.id));
      }
    });
    _listen();
    await platform.initialize();
    await refresh();
  }

  void _listen() {
    if (_disposed || _subscription != null) return;
    _subscription = platform.events.listen(
      (event) {
        _events.add(event);
        // Full snapshots recover any missed, reordered or restarted advisory stream.
        if (event['type'] != 'flipProbe') unawaited(refresh());
      },
      onError: (Object streamError) {
        error = streamError;
        if (!_disposed) notifyListeners();
        _scheduleReconnect();
      },
      onDone: _scheduleReconnect,
    );
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnect?.isActive == true) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _reconnect = Timer(const Duration(seconds: 2), () {
      if (_disposed) return;
      _listen();
      unawaited(refresh());
    });
  }

  Future<void> refresh() {
    _needsRefresh = true;
    return _refreshing ??= _drainRefresh().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<void> _drainRefresh() async {
    while (_needsRefresh && !_disposed) {
      _needsRefresh = false;
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    if (!HudaPrayerNotifications.isSupported || _disposed) return;
    try {
      snapshot = await platform.host.getSnapshot();
      await settings.refresh();
      error = null;
      if (snapshot?.session?.phase == 'playing' &&
          snapshot?.session?.id != _preemptedSessionId) {
        audioCoordinator.requestAudio(AudioCoordinator.adhan);
      } else {
        audioCoordinator.release(AudioCoordinator.adhan);
      }
      final token = snapshot?.navigationToken;
      if (token != null && !_handledNavigation.contains(token)) {
        final navigator = App.navigatorKey.currentState;
        if (navigator != null) {
          _handledNavigation.add(token);
          navigator.pushNamed('/prayerTimes');
        }
      }
      _reminderTap ??= await platform.host.takeReminderTap();
      final tap = _reminderTap;
      final navigator = App.navigatorKey.currentState;
      if (tap != null && navigator != null) {
        _reminderTap = null;
        final route = NotificationTaps.routeForPayload(tap);
        if (route != null) navigator.pushNamed(route);
      }
    } catch (failure) {
      error = failure;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> stop() async {
    final id = snapshot?.session?.id;
    if (id != null) await platform.host.stopSession(id);
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    unawaited(_subscription?.cancel());
    audioCoordinator.unregister(AudioCoordinator.adhan);
    unawaited(_events.close());
    super.dispose();
  }
}
