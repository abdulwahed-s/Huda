import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static Future<void> _openNotificationSettings() async {
    if (PlatformUtils.isMacOS) {
      final uri = Uri.parse(
          'x-apple.systempreferences:com.apple.Notifications-Settings');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final fallbackUri = Uri.parse('x-apple.systempreferences:');
        await launchUrl(fallbackUri);
      }
    } else {
      await openAppSettings();
    }
  }

  /// Requests notification access from a contextual notification feature.
  ///
  /// Android and iOS use their own request paths. When the OS will no longer
  /// display a prompt, the same action takes the user to the app settings.
  static Future<bool> requestNotificationPermission(
      BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();
    final isGranted = await cubit.getIsNotificationEnabled();
    if (!context.mounted) return false;

    if (isGranted) {
      _notifyAccessSettingsChanged();
      return true;
    }

    if (PlatformUtils.isAndroid) {
      return _requestAndroidNotificationPermission(context);
    }

    if (PlatformUtils.isIOS) {
      return _requestIosNotificationPermission(context);
    }

    if (context.mounted) {
      _showSnackBar(
        context,
        message: AppLocalizations.of(context)!.enableNotificationsSettings,
        kind: HudaSnackBarKind.warning,
        actionLabel: AppLocalizations.of(context)!.openSettings,
        onAction: _openNotificationSettings,
      );
    }
    return false;
  }

  static Future<bool> _requestAndroidNotificationPermission(
      BuildContext context) {
    return _requestNotificationPermissionForPlatform(context);
  }

  static Future<bool> _requestIosNotificationPermission(BuildContext context) {
    return _requestNotificationPermissionForPlatform(context);
  }

  static Future<bool> _requestNotificationPermissionForPlatform(
      BuildContext context) async {
    final currentStatus = await Permission.notification.status;
    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      if (context.mounted) {
        _showSnackBar(
          context,
          message: AppLocalizations.of(context)!.enableNotificationsSettings,
          kind: HudaSnackBarKind.warning,
          actionLabel: AppLocalizations.of(context)!.openSettings,
          onAction: _openNotificationSettings,
        );
      }
      await _openNotificationSettings();
      _notifyAccessSettingsChanged();
      return false;
    }

    final status = await Permission.notification.request();
    _notifyAccessSettingsChanged();

    if (!context.mounted) return status.isGranted;

    if (status.isGranted) {
      _showSnackBar(
        context,
        message: AppLocalizations.of(context)!.notificationsEnabled,
        kind: HudaSnackBarKind.success,
      );
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showSnackBar(
        context,
        message: AppLocalizations.of(context)!.enableNotificationsSettings,
        kind: HudaSnackBarKind.warning,
        actionLabel: AppLocalizations.of(context)!.openSettings,
        onAction: _openNotificationSettings,
      );
      await _openNotificationSettings();
      return false;
    }

    _showSnackBar(
      context,
      message: AppLocalizations.of(context)!.tapToEnableNotifications,
      kind: HudaSnackBarKind.info,
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
