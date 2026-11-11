import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/notifications/notification_permissions.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/notifications/permission_explainer_sheet.dart';

class PermissionHandlers {
  /// Lets requirement cards refresh after a system permission flow completes.
  static final ValueNotifier<int> accessSettingsChanges = ValueNotifier(0);

  static void _notifyAccessSettingsChanged() {
    accessSettingsChanges.value++;
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required HudaSnackBarKind kind,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    HudaSnackBar.show(
      context,
      message: message,
      kind: kind,
      action: actionLabel == null
          ? null
          : HudaSnackBarAction(
              label: actionLabel,
              onPressed: onAction ?? () {},
            ),
      dismissible: kind == HudaSnackBarKind.warning,
    );
  }

  /// Asks for notification access. A prompt is explained first (unless the
  /// caller already explains it, [explain] false). Huda never opens the system
  /// settings by itself: when only the user can allow it there, a snack bar
  /// offers "Open settings".
  static Future<bool> requestNotificationPermission(
    BuildContext context, {
    bool explain = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    var state = await NotificationPermissions.state();
    if (!context.mounted) return false;
    if (state == NotificationPermissionState.granted ||
        state == NotificationPermissionState.provisional) {
      _notifyAccessSettingsChanged();
      return true;
    }

    if (state == NotificationPermissionState.promptable) {
      if (explain &&
          !await showPermissionExplainer(
            context,
            icon: Icons.notifications_active_outlined,
            title: l10n.permissionExplainerNotificationsTitle,
            message: l10n.permissionExplainerNotificationsMessage,
          )) {
        return false;
      }
      final granted = await NotificationPermissions.request();
      _notifyAccessSettingsChanged();
      if (!context.mounted) return granted;
      if (granted) {
        _showSnackBar(
          context,
          message: l10n.notificationsEnabled,
          kind: HudaSnackBarKind.success,
        );
        return true;
      }
      state = await NotificationPermissions.state();
      if (!context.mounted) return false;
    }

    _showSnackBar(
      context,
      message: l10n.enableNotificationsSettings,
      kind: HudaSnackBarKind.warning,
      actionLabel: state == NotificationPermissionState.settingsOnly
          ? l10n.openSettings
          : null,
      onAction: () async {
        await NotificationPermissions.openSettings();
        _notifyAccessSettingsChanged();
      },
    );
    return false;
  }

  static Future<bool> requestBatteryOptimization(BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();
    final granted = await cubit.requestBatteryOptimizationExemption();
    _notifyAccessSettingsChanged();

    if (context.mounted) {
      _showSnackBar(
        context,
        message: granted
            ? AppLocalizations.of(context)!.batteryOptimizationExemptionGranted
            : AppLocalizations.of(context)!.batteryOptimizationExemptionDenied,
        kind: granted ? HudaSnackBarKind.success : HudaSnackBarKind.warning,
      );
    }
    return granted;
  }

  static Future<bool> requestExactAlarmsPermission(BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();
    final granted = await cubit.requestExactAlarmsPermission();
    _notifyAccessSettingsChanged();
    return granted;
  }
}
