import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class PermissionHandlers {
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

  static Future<void> requestNotificationPermission(
      BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();

    final isGranted = await cubit.getIsNotificationEnabled();

    if (isGranted) {
      if (context.mounted) {
        _showSnackBar(
          context,
          message: AppLocalizations.of(context)!.notificationsEnabled,
          kind: HudaSnackBarKind.success,
        );
      }
    } else {
      if (context.mounted) {
        if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
          _showSnackBar(
            context,
            message: AppLocalizations.of(context)!.enableNotificationsSettings,
            kind: HudaSnackBarKind.warning,
            actionLabel: AppLocalizations.of(context)!.settings,
            onAction: () => _openNotificationSettings(),
          );
        } else {
          final status = await Permission.notification.request();
          if (context.mounted) {
            if (status.isGranted) {
              _showSnackBar(
                context,
                message: AppLocalizations.of(context)!.notificationsEnabled,
                kind: HudaSnackBarKind.success,
              );
            } else if (status.isPermanentlyDenied) {
              _showSnackBar(
                context,
                message:
                    AppLocalizations.of(context)!.enableNotificationsSettings,
                kind: HudaSnackBarKind.warning,
                actionLabel: AppLocalizations.of(context)!.settings,
                onAction: () => openAppSettings(),
              );
            } else {
              _showSnackBar(
                context,
                message: AppLocalizations.of(context)!.tapToEnableNotifications,
                kind: HudaSnackBarKind.info,
              );
            }
          }
        }
      }
    }
  }

  static Future<void> requestBatteryOptimization(BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();
    final granted = await cubit.requestBatteryOptimizationExemption();

    if (context.mounted) {
      _showSnackBar(
        context,
        message: granted
            ? AppLocalizations.of(context)!.batteryOptimizationExemptionGranted
            : AppLocalizations.of(context)!.batteryOptimizationExemptionDenied,
        kind: granted ? HudaSnackBarKind.success : HudaSnackBarKind.warning,
      );
    }
  }
}
