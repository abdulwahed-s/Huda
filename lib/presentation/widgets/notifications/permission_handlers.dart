import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SnackBarType { success, warning, info }

class PermissionHandlers {
  static void _showStyledSnackBar(
    BuildContext context, {
    required String message,
    required _SnackBarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (icon, colors) = switch (type) {
      _SnackBarType.success => (
          CupertinoIcons.checkmark_circle_fill,
          (const Color(0xFF059669), const Color(0xFF10B981)),
        ),
      _SnackBarType.warning => (
          CupertinoIcons.exclamationmark_triangle_fill,
          (const Color(0xFFD97706), const Color(0xFFF59E0B)),
        ),
      _SnackBarType.info => (
          CupertinoIcons.bell_fill,
          (const Color(0xFF2563EB), const Color(0xFF3B82F6)),
        ),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: colors.$1,
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white.withValues(alpha: 0.9),
                onPressed: onAction ?? () {},
              )
            : null,
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
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
        _showStyledSnackBar(
          context,
          message: AppLocalizations.of(context)!.notificationsEnabled,
          type: _SnackBarType.success,
        );
      }
    } else {
      if (context.mounted) {
        if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
          _showStyledSnackBar(
            context,
            message: AppLocalizations.of(context)!.enableNotificationsSettings,
            type: _SnackBarType.warning,
            actionLabel: AppLocalizations.of(context)!.settings,
            onAction: () => _openNotificationSettings(),
          );
        } else {
          final status = await Permission.notification.request();
          if (context.mounted) {
            if (status.isGranted) {
              _showStyledSnackBar(
                context,
                message: AppLocalizations.of(context)!.notificationsEnabled,
                type: _SnackBarType.success,
              );
            } else if (status.isPermanentlyDenied) {
              _showStyledSnackBar(
                context,
                message:
                    AppLocalizations.of(context)!.enableNotificationsSettings,
                type: _SnackBarType.warning,
                actionLabel: AppLocalizations.of(context)!.settings,
                onAction: () => openAppSettings(),
              );
            } else {
              _showStyledSnackBar(
                context,
                message: AppLocalizations.of(context)!.tapToEnableNotifications,
                type: _SnackBarType.info,
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
      _showStyledSnackBar(
        context,
        message: granted
            ? AppLocalizations.of(context)!.batteryOptimizationExemptionGranted
            : AppLocalizations.of(context)!.batteryOptimizationExemptionDenied,
        type: granted ? _SnackBarType.success : _SnackBarType.warning,
      );
    }
  }
}