import 'package:equatable/equatable.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';

abstract class MiqaatLockState extends Equatable {
  const MiqaatLockState();

  @override
  List<Object?> get props => [];
}

class MiqaatLockInitial extends MiqaatLockState {
  const MiqaatLockInitial();
}

class MiqaatLockLoading extends MiqaatLockState {
  const MiqaatLockLoading();
}

class MiqaatLockLoaded extends MiqaatLockState {
  final MiqaatLockSettings settings;

  final List<LockedApp> installedApps;

  final MiqaatLockSession? activeSession;

  final MiqaatLockPermissions permissions;

  final bool isLoadingApps;

  final Set<String> completedTimeSlotIds;

  const MiqaatLockLoaded({
    required this.settings,
    this.installedApps = const [],
    this.activeSession,
    this.permissions = const MiqaatLockPermissions(),
    this.isLoadingApps = false,
    this.completedTimeSlotIds = const {},
  });

  MiqaatLockLoaded copyWith({
    MiqaatLockSettings? settings,
    List<LockedApp>? installedApps,
    MiqaatLockSession? activeSession,
    bool clearSession = false,
    MiqaatLockPermissions? permissions,
    bool? isLoadingApps,
    Set<String>? completedTimeSlotIds,
  }) {
    return MiqaatLockLoaded(
      settings: settings ?? this.settings,
      installedApps: installedApps ?? this.installedApps,
      activeSession:
          clearSession ? null : (activeSession ?? this.activeSession),
      permissions: permissions ?? this.permissions,
      isLoadingApps: isLoadingApps ?? this.isLoadingApps,
      completedTimeSlotIds: completedTimeSlotIds ?? this.completedTimeSlotIds,
    );
  }

  @override
  List<Object?> get props => [
        settings,
        installedApps,
        activeSession,
        permissions,
        isLoadingApps,
        completedTimeSlotIds
      ];
}

class MiqaatLockError extends MiqaatLockState {
  final String message;

  const MiqaatLockError(this.message);

  @override
  List<Object?> get props => [message];
}

class MiqaatLockPermissions extends Equatable {
  final bool accessibilityEnabled;

  final bool overlayPermissionGranted;

  final bool batteryOptimizationExempt;

  final bool screenTimeAuthorized;

  const MiqaatLockPermissions({
    this.accessibilityEnabled = false,
    this.overlayPermissionGranted = false,
    this.batteryOptimizationExempt = false,
    this.screenTimeAuthorized = false,
  });

  bool get isAndroidReady =>
      accessibilityEnabled &&
      overlayPermissionGranted &&
      batteryOptimizationExempt;

  bool get isIOSReady => screenTimeAuthorized;

  MiqaatLockPermissions copyWith({
    bool? accessibilityEnabled,
    bool? overlayPermissionGranted,
    bool? batteryOptimizationExempt,
    bool? screenTimeAuthorized,
  }) {
    return MiqaatLockPermissions(
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      overlayPermissionGranted:
          overlayPermissionGranted ?? this.overlayPermissionGranted,
      batteryOptimizationExempt:
          batteryOptimizationExempt ?? this.batteryOptimizationExempt,
      screenTimeAuthorized: screenTimeAuthorized ?? this.screenTimeAuthorized,
    );
  }

  @override
  List<Object?> get props => [
        accessibilityEnabled,
        overlayPermissionGranted,
        batteryOptimizationExempt,
        screenTimeAuthorized,
      ];
}
