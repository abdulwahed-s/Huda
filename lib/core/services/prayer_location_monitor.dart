import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

enum PrayerBackgroundTravelState {
  disabled,
  enabled,
  foregroundOnly,
  permissionRequired,
  unsupported,
  unavailable,
}

@immutable
class PrayerLocationMonitoringStatus {
  const PrayerLocationMonitoringStatus({
    required this.preferenceEnabled,
    required this.locationMode,
    required this.state,
  });

  final bool preferenceEnabled;
  final PrayerLocationMode locationMode;
  final PrayerBackgroundTravelState state;
}

class PrayerLocationMonitor {
  PrayerLocationMonitor({required this.cacheHelper});

  static const backgroundTravelEnabledKey = 'prayer_background_travel_enabled';
  static const MethodChannel _nativeChannel = MethodChannel(
    'com.aw.huda/prayer_location_monitor',
  );
  static const MethodChannel _systemChannel = MethodChannel(
    'com.aw.huda/prayer_system',
  );

  final CacheHelper cacheHelper;
  StreamSubscription<Position>? _positionSubscription;
  Future<void> Function(Position position)? _onForegroundPosition;
  Future<void> Function()? _onNativeCandidate;
  Future<void> Function(String reason)? _onSystemChange;
  PrayerLocationMode _mode = PrayerLocationMode.manual;
  bool _foregroundActive = true;
  bool _channelsInstalled = false;

  bool get preferenceEnabled =>
      cacheHelper.getData(key: backgroundTravelEnabledKey) == true;

  Future<void> start({
    required PrayerLocationMode mode,
    required Future<void> Function(Position position) onForegroundPosition,
    required Future<void> Function() onNativeCandidate,
    required Future<void> Function(String reason) onSystemChange,
  }) async {
    _onForegroundPosition = onForegroundPosition;
    _onNativeCandidate = onNativeCandidate;
    _onSystemChange = onSystemChange;
    if (!_channelsInstalled) {
      _channelsInstalled = true;
      _nativeChannel.setMethodCallHandler((call) async {
        if (call.method == 'candidateAvailable') {
          await _onNativeCandidate?.call();
        }
      });
      _systemChannel.setMethodCallHandler((call) async {
        if (call.method == 'systemChanged') {
          await _onSystemChange?.call(call.arguments?.toString() ?? 'system');
        }
      });
    }
    await sync(mode);
  }

  Future<PrayerLocationMonitoringStatus> setEnabled(
    bool enabled, {
    bool requestPermission = true,
  }) async {
    final saved = await cacheHelper.saveData(
      key: backgroundTravelEnabledKey,
      value: enabled,
    );
    if (!saved) throw StateError('Could not save the travel-update setting');

    if (enabled && requestPermission && _supportsBackgroundTravel) {
      var foreground = await permissions.Permission.locationWhenInUse.status;
      if (!foreground.isGranted && !foreground.isLimited) {
        foreground = await permissions.Permission.locationWhenInUse.request();
      }
      if (foreground.isGranted || foreground.isLimited) {
        final always = await permissions.Permission.locationAlways.status;
        if (!always.isGranted) {
          await permissions.Permission.locationAlways.request();
        }
      }
    }
    return sync(_mode);
  }

  Future<PrayerLocationMonitoringStatus> sync(PrayerLocationMode mode) async {
    _mode = mode;
    await cacheHelper.reload();
    final status = await currentStatus(mode: mode);
    await _syncForegroundStream(status);
    if (_supportsBackgroundTravel) {
      try {
        await _nativeChannel.invokeMethod<Object?>('sync', <String, Object?>{
          'enabled': status.preferenceEnabled,
          'locationMode': mode.name,
        });
      } on MissingPluginException {
      } on PlatformException catch (error) {
        debugPrint('Could not synchronize prayer travel monitoring: $error');
      }
    }
    return currentStatus(mode: mode);
  }

  Future<void> setForegroundActive(bool active) async {
    _foregroundActive = active;
    final status = await currentStatus(mode: _mode);
    await _syncForegroundStream(status);
  }

  Future<PrayerLocationMonitoringStatus> currentStatus({
    PrayerLocationMode? mode,
  }) async {
    final effectiveMode = mode ?? _mode;
    final enabled = preferenceEnabled;
    if (effectiveMode != PrayerLocationMode.automatic || !enabled) {
      return PrayerLocationMonitoringStatus(
        preferenceEnabled: enabled,
        locationMode: effectiveMode,
        state: PrayerBackgroundTravelState.disabled,
      );
    }
    if (!_supportsBackgroundTravel) {
      return PrayerLocationMonitoringStatus(
        preferenceEnabled: enabled,
        locationMode: effectiveMode,
        state: PrayerBackgroundTravelState.unsupported,
      );
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return PrayerLocationMonitoringStatus(
          preferenceEnabled: enabled,
          locationMode: effectiveMode,
          state: PrayerBackgroundTravelState.unavailable,
        );
      }
      final foreground = await permissions.Permission.locationWhenInUse.status;
      if (!foreground.isGranted && !foreground.isLimited) {
        return PrayerLocationMonitoringStatus(
          preferenceEnabled: enabled,
          locationMode: effectiveMode,
          state: PrayerBackgroundTravelState.permissionRequired,
        );
      }
      final always = await permissions.Permission.locationAlways.status;
      return PrayerLocationMonitoringStatus(
        preferenceEnabled: enabled,
        locationMode: effectiveMode,
        state: always.isGranted
            ? PrayerBackgroundTravelState.enabled
            : PrayerBackgroundTravelState.foregroundOnly,
      );
    } catch (_) {
      return PrayerLocationMonitoringStatus(
        preferenceEnabled: enabled,
        locationMode: effectiveMode,
        state: PrayerBackgroundTravelState.unavailable,
      );
    }
  }

  Future<void> openAppSettings() => permissions.openAppSettings();

  Future<void> _syncForegroundStream(
    PrayerLocationMonitoringStatus status,
  ) async {
    final shouldListen =
        _foregroundActive &&
        _mode == PrayerLocationMode.automatic &&
        !kIsWeb &&
        !PlatformUtils.isLinux;
    if (!shouldListen) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _positionSubscription?.cancel();
        _positionSubscription = null;
        return;
      }
    } catch (error) {
      debugPrint('Could not inspect prayer location service state: $error');
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      return;
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      return;
    }
    if (_positionSubscription != null) return;
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 5000,
          ),
        ).listen(
          (position) => unawaited(_onForegroundPosition?.call(position)),
          onError: (Object error) {
            debugPrint('Prayer foreground location stream stopped: $error');
            _positionSubscription = null;
          },
          cancelOnError: true,
        );
  }

  bool get _supportsBackgroundTravel =>
      PlatformUtils.isAndroid || PlatformUtils.isIOS;

  Future<void> dispose() async {
    _foregroundActive = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _nativeChannel.setMethodCallHandler(null);
    _systemChannel.setMethodCallHandler(null);
    _channelsInstalled = false;
    _onForegroundPosition = null;
    _onNativeCandidate = null;
    _onSystemChange = null;
  }
}
