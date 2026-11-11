import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/services/notification_services.dart';
import 'package:huda/core/services/android_prayer_experience.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';

@immutable
class NotificationAccess {
  const NotificationAccess({
    required this.notificationsEnabled,
    this.notificationNeedsSettings = false,
    this.batteryOptimizationExempted = true,
    this.exactAlarmsAllowed = true,
    this.prayerChannelsAllowed = true,
    this.fullScreenAllowed = true,
    this.flipSensorAvailable = true,
  });

  final bool notificationsEnabled;

  final bool notificationNeedsSettings;
  final bool batteryOptimizationExempted;
  final bool exactAlarmsAllowed;
  final bool prayerChannelsAllowed;
  final bool fullScreenAllowed;
  final bool flipSensorAvailable;

  bool get needsNotification => !notificationsEnabled;
  bool get needsBatteryOptimization => !batteryOptimizationExempted;
  bool get needsExactAlarms => !exactAlarmsAllowed;
  bool get isReady =>
      !needsNotification && !needsBatteryOptimization && !needsExactAlarms;
  bool get isPrayerReady => isReady && prayerChannelsAllowed;
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
    var prayerChannelsAllowed = true;
    var fullScreenAllowed = true;
    var flipSensorAvailable = true;
    if (PlatformUtils.isAndroid) {
      try {
        final gateway = NotificationServices.androidPrayerGateway;
        if (await gateway.isEnabled()) {
          final state = await gateway.executionSnapshot();
          final policy = AndroidPrayerExperience.fromPolicy(state.policy);
          prayerChannelsAllowed = policy.enabledPrayers.every(
            (prayer) => policy.effective(prayer)['mode'] == 'silent'
                ? state.capabilities.silentChannel
                : state.capabilities.adhanChannel,
          );
          fullScreenAllowed = state.capabilities.fullScreen;
          flipSensorAvailable = state.capabilities.flipSensor;
        }
      } catch (_) {
        /* Existing notification permissions remain available during native recovery. */
      }
    }

    final notificationNeedsSettings =
        !notificationsEnabled &&
        await NotificationPermissions.state() ==
            NotificationPermissionState.settingsOnly;

    if (_disposed) return;

    final previous = _access;
    final shouldReschedule =
        previous != null &&
        ((!previous.notificationsEnabled && notificationsEnabled) ||
            (!previous.exactAlarmsAllowed && exactAlarmsAllowed) ||
            (!previous.prayerChannelsAllowed && prayerChannelsAllowed));
    _access = NotificationAccess(
      notificationsEnabled: notificationsEnabled,
      notificationNeedsSettings: notificationNeedsSettings,
      batteryOptimizationExempted: batteryOptimizationExempted,
      exactAlarmsAllowed: exactAlarmsAllowed,
      prayerChannelsAllowed: prayerChannelsAllowed,
      fullScreenAllowed: fullScreenAllowed,
      flipSensorAvailable: flipSensorAvailable,
    );
    _isRequestInProgress = false;
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();

    if (shouldReschedule) await onAccessGained?.call();
  }

  /// [explain] false when the caller's own card already says why.
  Future<void> requestNotifications(
    BuildContext context, {
    bool explain = true,
  }) => _request(
    () => PermissionHandlers.requestNotificationPermission(
      context,
      explain: explain,
    ),
  );

  /// Opens the system page; only from a tap on "Open settings".
  Future<void> openNotificationSettings() =>
      _request(NotificationPermissions.openSettings);

  Future<void> requestBatteryOptimization(BuildContext context) =>
      _request(() => PermissionHandlers.requestBatteryOptimization(context));

  Future<void> requestExactAlarms(BuildContext context) =>
      _request(() => PermissionHandlers.requestExactAlarmsPermission(context));
  Future<void> openPrayerChannelSettings() => _request(() async {
    final gateway = NotificationServices.androidPrayerGateway;
    final state = await gateway.executionSnapshot();
    await gateway.api.openSettings(
      state.capabilities.adhanChannel ? 'silentChannel' : 'adhanChannel',
    );
  });

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
