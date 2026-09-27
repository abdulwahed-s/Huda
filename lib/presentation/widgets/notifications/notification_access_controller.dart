import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:permission_handler/permission_handler.dart';

@immutable
class NotificationAccess {
  const NotificationAccess({
    required this.notificationsEnabled,
    this.notificationNeedsSettings = false,
    this.batteryOptimizationExempted = true,
    this.exactAlarmsAllowed = true,
  });

  final bool notificationsEnabled;

  final bool notificationNeedsSettings;
  final bool batteryOptimizationExempted;
  final bool exactAlarmsAllowed;

  bool get needsNotification => !notificationsEnabled;
  bool get needsBatteryOptimization => !batteryOptimizationExempted;
  bool get needsExactAlarms => !exactAlarmsAllowed;
  bool get isReady =>
      !needsNotification && !needsBatteryOptimization && !needsExactAlarms;
}

class NotificationAccessController extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationAccessController({required this.cubit, this.onAccessGained}) {
    WidgetsBinding.instance.addObserver(this);
    PermissionHandlers.accessSettingsChanges.addListener(refresh);
    refresh();
  }

  final NotificationsCubit cubit;

  Future<void> Function()? onAccessGained;

  NotificationAccess? _access;
  bool _isRequestInProgress = false;
  bool _disposed = false;
  final Completer<void> _ready = Completer<void>();

  Future<void> get ready => _ready.future;

  NotificationAccess? get access => _access;
  bool get isRequestInProgress => _isRequestInProgress;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final notificationsEnabled = await cubit.getIsNotificationEnabled();
    final exactAlarmsAllowed = PlatformUtils.isAndroid
        ? await cubit.canScheduleExactNotifications()
        : true;
    final batteryOptimizationExempted = PlatformUtils.isAndroid
        ? await cubit.getIsBatteryOptimizationExempted()
        : true;

    var notificationNeedsSettings = false;
    if (!notificationsEnabled &&
        (PlatformUtils.isAndroid || PlatformUtils.isIOS)) {
      final status = await Permission.notification.status;
      notificationNeedsSettings =
          status.isPermanentlyDenied || status.isRestricted;
    }

    if (_disposed) return;

    final previous = _access;
    final shouldReschedule =
        previous != null &&
        ((!previous.notificationsEnabled && notificationsEnabled) ||
            (!previous.exactAlarmsAllowed && exactAlarmsAllowed));
    _access = NotificationAccess(
      notificationsEnabled: notificationsEnabled,
      notificationNeedsSettings: notificationNeedsSettings,
      batteryOptimizationExempted: batteryOptimizationExempted,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
    _isRequestInProgress = false;
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();

    if (shouldReschedule) await onAccessGained?.call();
  }

  Future<void> requestNotifications(BuildContext context) =>
      _request(() => PermissionHandlers.requestNotificationPermission(context));

  Future<bool> requestNotificationPrompt(BuildContext context) async {
    if (!PlatformUtils.isAndroid && !PlatformUtils.isIOS) {
      await requestNotifications(context);
      return _access?.notificationsEnabled ?? false;
    }
    await _request(() => Permission.notification.request());
    return _access?.notificationsEnabled ?? false;
  }

  Future<void> requestBatteryOptimization(BuildContext context) =>
      _request(() => PermissionHandlers.requestBatteryOptimization(context));

  Future<void> requestExactAlarms(BuildContext context) =>
      _request(() => PermissionHandlers.requestExactAlarmsPermission(context));

  Future<void> _request(Future<void> Function() request) async {
    if (_isRequestInProgress) return;
    _isRequestInProgress = true;
    notifyListeners();
    await request();
    if (_disposed) return;
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    PermissionHandlers.accessSettingsChanges.removeListener(refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
