import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock_settings.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock_session.dart';
import 'package:huda/data/models/miqaat_lock/locked_app.dart';

class MiqaatLockRepository {
  static const String _settingsKey = 'miqaat_lock_settings';
  static const String _sessionKey = 'miqaat_lock_session';
  static const String _completedSlotsKey = 'miqaat_lock_completed_slots';
  static const String _completedSlotsDateKey =
      'miqaat_lock_completed_slots_date';
  static const MethodChannel _channel =
      MethodChannel('com.aw.huda/miqaat_lock');

  final SharedPreferences _prefs;

  MiqaatLockRepository(this._prefs);

  static Future<MiqaatLockRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MiqaatLockRepository(prefs);
  }

  MiqaatLockSettings loadSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) return const MiqaatLockSettings();
    try {
      return MiqaatLockSettings.fromJson(jsonDecode(json));
    } catch (e) {
      return const MiqaatLockSettings();
    }
  }

  Future<void> saveSettings(MiqaatLockSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

    await _syncSettingsToNative(settings);
  }

  Future<void> _syncSettingsToNative(MiqaatLockSettings settings) async {
    try {
      await _channel.invokeMethod('updateSettings', {
        'isEnabled': settings.isEnabled,
        'lockedApps': settings.lockedApps.map((app) => app.packageId).toList(),
        'timeSlots': settings.timeSlots.map((slot) => slot.toJson()).toList(),
        'goalDurationMinutes': settings.goalDurationMinutes,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to sync settings to native: ${e.message}');
    }
  }

  MiqaatLockSession? getCurrentSession() {
    final json = _prefs.getString(_sessionKey);
    if (json == null) return null;
    try {
      return MiqaatLockSession.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveSession(MiqaatLockSession session) async {
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<MiqaatLockSession> getOrCreateSession(
      String timeSlotId, int goalMinutes) async {
    final existing = getCurrentSession();
    if (existing != null && existing.timeSlotId == timeSlotId) {
      return existing;
    }

    final session = MiqaatLockSession(
      timeSlotId: timeSlotId,
      goalMinutes: goalMinutes,
    );
    await _saveSession(session);
    return session;
  }

  Future<MiqaatLockSession> startTrackingHudaTime(
      String timeSlotId, int goalMinutes) async {
    var session = await getOrCreateSession(timeSlotId, goalMinutes);
    session = session.copyWith(trackingStartTime: DateTime.now());
    await _saveSession(session);
    return session;
  }

  Future<MiqaatLockSession> stopTrackingHudaTime() async {
    final session = getCurrentSession();
    if (session == null || session.trackingStartTime == null) {
      return session ?? const MiqaatLockSession(timeSlotId: '', goalMinutes: 0);
    }

    final elapsed =
        DateTime.now().difference(session.trackingStartTime!).inSeconds;
    final newAccumulated = session.accumulatedSeconds + elapsed;

    final updated = session.copyWith(
      accumulatedSeconds: newAccumulated,
      clearTracking: true,
    );
    await _saveSession(updated);

    await _syncProgressToNative(updated);

    return updated;
  }

  Future<MiqaatLockSession?> updateAccumulatedTime() async {
    final session = getCurrentSession();
    if (session == null || session.trackingStartTime == null) return session;

    final elapsed =
        DateTime.now().difference(session.trackingStartTime!).inSeconds;
    final totalAccumulated = session.accumulatedSeconds + elapsed;

    return session.copyWith(
      accumulatedSeconds: totalAccumulated,
      trackingStartTime: session.trackingStartTime,
    );
  }

  Future<void> completeTimeSlot(String timeSlotId) async {
    final completedIds = getCompletedTimeSlotIds();
    completedIds.add(timeSlotId);
    await _prefs.setStringList(_completedSlotsKey, completedIds.toList());
    await _prefs.setString(
        _completedSlotsDateKey, DateTime.now().toIso8601String().split('T')[0]);

    await _prefs.remove(_sessionKey);

    try {
      await _channel.invokeMethod('completeTimeSlot', {
        'timeSlotId': timeSlotId,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to notify native of slot completion: ${e.message}');
    }
  }

  Set<String> getCompletedTimeSlotIds() {
    final storedDate = _prefs.getString(_completedSlotsDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (storedDate != today) {
      _prefs.remove(_completedSlotsKey);
      _prefs.setString(_completedSlotsDateKey, today);
      return {};
    }
    return (_prefs.getStringList(_completedSlotsKey) ?? []).toSet();
  }

  bool isTimeSlotCompleted(String timeSlotId) {
    return getCompletedTimeSlotIds().contains(timeSlotId);
  }

  Future<void> _syncProgressToNative(MiqaatLockSession session) async {
    try {
      await _channel.invokeMethod('updateSessionProgress', {
        'accumulatedSeconds': session.accumulatedSeconds,
        'goalMinutes': session.goalMinutes,
        'timeSlotId': session.timeSlotId,
        'isCompleted': session.isGoalCompleted,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to sync progress to native: ${e.message}');
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }

  Future<List<LockedApp>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final List<dynamic> apps = result as List<dynamic>;
      return apps
          .map((app) => LockedApp.fromJson(Map<String, dynamic>.from(app)))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get installed apps: ${e.message}');
      return [];
    }
  }

  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return Map<String, bool>.from(result);
    } on PlatformException {
      return {
        'accessibility': false,
        'overlay': false,
        'batteryOptimization': false,
      };
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open accessibility settings: ${e.message}');
    }
  }

  Future<bool> isOverlayPermissionGranted() async {
    try {
      return await _channel.invokeMethod('isOverlayPermissionGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint('Failed to request overlay permission: ${e.message}');
    }
  }

  Future<bool> isScreenTimeAuthorized() async {
    try {
      return await _channel.invokeMethod('isScreenTimeAuthorized') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestScreenTimeAuthorization() async {
    try {
      return await _channel.invokeMethod('requestScreenTimeAuthorization') ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
