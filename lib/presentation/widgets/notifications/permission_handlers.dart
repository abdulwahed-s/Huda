import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PermissionHandlers {
  static Future<void> requestNotificationPermission(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.enableNotificationsSettings,
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.settings,
          onPressed: () {
            // Open system settings
          },
        ),
      ),
    );
  }

  static Future<void> requestBatteryOptimization(BuildContext context) async {
    final cubit = context.read<NotificationsCubit>();
    final granted = await cubit.requestBatteryOptimizationExemption();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? AppLocalizations.of(context)!
                    .batteryOptimizationExemptionGranted
                : AppLocalizations.of(context)!
                    .batteryOptimizationExemptionDenied,
            style: const TextStyle(fontFamily: 'Amiri'),
          ),
          backgroundColor: granted ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }
}