import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/data/repository/miqaat_lock_repository.dart';
import 'miqaat_lock_state.dart';

class MiqaatLockCubit extends Cubit<MiqaatLockState>
    with WidgetsBindingObserver {
  final MiqaatLockRepository _repository;
  final Uuid _uuid = const Uuid();
  Timer? _progressTimer;
  bool _isInForeground = true;

  MiqaatLockCubit(this._repository) : super(const MiqaatLockInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentState = this.state;
    if (currentState is! MiqaatLockLoaded) return;
    if (!currentState.settings.isEnabled) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        _onHudaResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_isInForeground) {
          _isInForeground = false;
          _onHudaPaused();
        }
        break;
    }
  }

  Future<void> _onHudaResumed() async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final activeSlot = currentState.settings.getActiveTimeSlot();
    if (activeSlot == null) return;

    if (currentState.completedTimeSlotIds.contains(activeSlot.id)) return;

    final session = await _repository.startTrackingHudaTime(
      activeSlot.id,
      currentState.settings.goalDurationMinutes,
    );

    emit(currentState.copyWith(activeSession: session));

    _startProgressTimer();
  }

  Future<void> _onHudaPaused() async {
    _progressTimer?.cancel();

    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;
    if (currentState.activeSession == null) return;

    final session = await _repository.stopTrackingHudaTime();
    emit(currentState.copyWith(activeSession: session));
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final currentState = state;
      if (currentState is! MiqaatLockLoaded) return;

      final updated = await _repository.updateAccumulatedTime();
      if (updated == null) return;

      if (updated.isGoalCompleted) {
        _progressTimer?.cancel();
        await _onGoalCompleted(currentState, updated);
      } else {
        emit(currentState.copyWith(activeSession: updated));
      }
    });
  }

  Future<void> _onGoalCompleted(
      MiqaatLockLoaded currentState, MiqaatLockSession session) async {
    await _repository.stopTrackingHudaTime();

    await _repository.completeTimeSlot(session.timeSlotId);

    final newCompleted = {
      ...currentState.completedTimeSlotIds,
      session.timeSlotId
    };

    emit(currentState.copyWith(
      clearSession: true,
      completedTimeSlotIds: newCompleted,
    ));
  }

  void _checkAndStartTracking(MiqaatLockLoaded loadedState) {
    if (!loadedState.settings.isEnabled) return;
    if (!_isInForeground) return;

    final activeSlot = loadedState.settings.getActiveTimeSlot();
    if (activeSlot == null) return;
    if (loadedState.completedTimeSlotIds.contains(activeSlot.id)) return;

    _onHudaResumed();
  }

  Future<void> loadSettings() async {
    emit(const MiqaatLockLoading());

    try {
      final settings = _repository.loadSettings();
      final session = _repository.getCurrentSession();
      final permissions = await _checkPermissions();
      final completedSlots = _repository.getCompletedTimeSlotIds();

      final loadedState = MiqaatLockLoaded(
        settings: settings,
        activeSession: session,
        permissions: permissions,
        completedTimeSlotIds: completedSlots,
      );

      emit(loadedState);

      _checkAndStartTracking(loadedState);
    } catch (e) {
      emit(MiqaatLockError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> loadInstalledApps() async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    emit(currentState.copyWith(isLoadingApps: true));

    try {
      final apps = await _repository.getInstalledApps();
      emit(currentState.copyWith(
        installedApps: apps,
        isLoadingApps: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingApps: false));
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final newSettings = currentState.settings.copyWith(isEnabled: enabled);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));

    if (enabled && _isInForeground) {
      _checkAndStartTracking(currentState.copyWith(settings: newSettings));
    } else if (!enabled) {
      _progressTimer?.cancel();
    }
  }

  Future<void> setLockedApps(List<LockedApp> apps) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final newSettings = currentState.settings.copyWith(lockedApps: apps);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> addLockedApp(LockedApp app) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    if (currentState.settings.lockedApps
        .any((a) => a.packageId == app.packageId)) {
      return;
    }

    final newApps = [...currentState.settings.lockedApps, app];
    final newSettings = currentState.settings.copyWith(lockedApps: newApps);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> removeLockedApp(String packageId) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final newApps = currentState.settings.lockedApps
        .where((app) => app.packageId != packageId)
        .toList();
    final newSettings = currentState.settings.copyWith(lockedApps: newApps);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> toggleAppSelection(LockedApp app) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final isLocked = currentState.settings.lockedApps
        .any((a) => a.packageId == app.packageId);

    if (isLocked) {
      await removeLockedApp(app.packageId);
    } else {
      await addLockedApp(app);
    }
  }

  Future<void> addTimeSlot(TimeSlot slot) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    if (currentState.settings.timeSlots.length >=
        MiqaatLockSettings.maxTimeSlots) {
      return;
    }

    final newSlot = slot.copyWith(id: slot.id.isEmpty ? _uuid.v4() : slot.id);

    final newSlots = [...currentState.settings.timeSlots, newSlot];
    final newSettings = currentState.settings.copyWith(timeSlots: newSlots);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> updateTimeSlot(TimeSlot slot) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final newSlots = currentState.settings.timeSlots
        .map((s) => s.id == slot.id ? slot : s)
        .toList();
    final newSettings = currentState.settings.copyWith(timeSlots: newSlots);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> removeTimeSlot(String slotId) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final newSlots = currentState.settings.timeSlots
        .where((slot) => slot.id != slotId)
        .toList();
    final newSettings = currentState.settings.copyWith(timeSlots: newSlots);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> setGoalDuration(int minutes) async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    if (minutes < MiqaatLockSettings.minCustomDuration ||
        minutes > MiqaatLockSettings.maxCustomDuration) {
      return;
    }

    final newSettings =
        currentState.settings.copyWith(goalDurationMinutes: minutes);
    await _repository.saveSettings(newSettings);

    emit(currentState.copyWith(settings: newSettings));
  }

  Future<void> refreshPermissions() async {
    final currentState = state;
    if (currentState is! MiqaatLockLoaded) return;

    final permissions = await _checkPermissions();
    emit(currentState.copyWith(permissions: permissions));
  }

  Future<void> openAccessibilitySettings() async {
    await _repository.openAccessibilitySettings();
  }

  Future<void> requestOverlayPermission() async {
    await _repository.requestOverlayPermission();
  }

  Future<bool> requestScreenTimeAuthorization() async {
    final authorized = await _repository.requestScreenTimeAuthorization();
    await refreshPermissions();
    return authorized;
  }

  Future<MiqaatLockPermissions> _checkPermissions() async {
    if (Platform.isAndroid) {
      final accessibilityEnabled = await _repository.isAccessibilityEnabled();
      final overlayGranted = await _repository.isOverlayPermissionGranted();
      return MiqaatLockPermissions(
        accessibilityEnabled: accessibilityEnabled,
        overlayPermissionGranted: overlayGranted,
        batteryOptimizationExempt: true,
      );
    } else if (Platform.isIOS) {
      final screenTimeAuthorized = await _repository.isScreenTimeAuthorized();
      return MiqaatLockPermissions(
        screenTimeAuthorized: screenTimeAuthorized,
      );
    }
    return const MiqaatLockPermissions();
  }
}
