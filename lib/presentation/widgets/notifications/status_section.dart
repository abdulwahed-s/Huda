import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/status_card.dart';

class StatusSection extends StatelessWidget {
  final bool isDark;
  final void Function() requestNotificationPermission;
  final void Function() requestBatteryOptimization;

  const StatusSection({
    super.key,
    required this.isDark,
    required this.requestNotificationPermission,
    required this.requestBatteryOptimization,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.status,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            color: isDark ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 12.h),

        // Permission Status
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            return FutureBuilder<bool>(
              future:
                  context.read<NotificationsCubit>().getIsNotificationEnabled(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? false;
                return StatusCard(
                  title: isEnabled
                      ? AppLocalizations.of(context)!.notificationsEnabled
                      : AppLocalizations.of(context)!.notificationsDisabled,
                  subtitle: isEnabled
                      ? AppLocalizations.of(context)!.notificationsActive
                      : AppLocalizations.of(context)!.tapToEnableNotifications,
                  icon: isEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: isEnabled ? Colors.green : Colors.red,
                  isEnabled: isEnabled,
                  onTap:
                      isEnabled ? null : () => requestNotificationPermission(),
                );
              },
            );
          },
        ),
        SizedBox(height: 8.h),

        // Battery Optimization Status
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            return FutureBuilder<bool>(
              future: context
                  .read<NotificationsCubit>()
                  .getIsBatteryOptimizationExempted(),
              builder: (context, snapshot) {
                final isExempted = snapshot.data ?? false;
                return StatusCard(
                  title: isExempted
                      ? AppLocalizations.of(context)!
                          .batteryOptimizationExemptionActive
                      : AppLocalizations.of(context)!
                          .batteryOptimizationExemptionInactive,
                  subtitle: isExempted
                      ? AppLocalizations.of(context)!
                          .notificationsWillWorkReliably
                      : AppLocalizations.of(context)!
                          .notificationsMayBeDelayedOrMissed,
                  icon: isExempted
                      ? Icons.battery_charging_full
                      : Icons.battery_alert,
                  color: isExempted ? Colors.green : Colors.orange,
                  isEnabled: isExempted,
                  onTap: isExempted ? null : () => requestBatteryOptimization(),
                  actionText: isExempted
                      ? null
                      : AppLocalizations.of(context)!.optimize,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
