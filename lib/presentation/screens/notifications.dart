import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/notifications/frequency_dialog.dart';
import 'package:huda/presentation/widgets/notifications/loading_state.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:huda/presentation/widgets/notifications/settings_section.dart';
import 'package:huda/presentation/widgets/notifications/status_section.dart';
import 'package:huda/presentation/widgets/notifications/time_pickers.dart';

extension NotificationContextExtension on BuildContext {
  Future<void> togglePreference(String key, bool value) async {
    final cubit = read<NotificationsCubit>();
    cubit.setContext(this);
    await cubit.togglePreference(key, value);
  }
}

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeNotifications();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final cubit = context.read<NotificationsCubit>();
    cubit.setContext(context);
    await cubit.getIsNotificationEnabled();
    await cubit.loadPreferences();
    await cubit.initializeNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : theme.primaryColor,
        ),
        title: Text(
          AppLocalizations.of(context)!.islamicNotifications,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            fontFamily: 'Amiri',
            color: isDark ? Colors.white : theme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(16.0.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  StatusSection(
                    isDark: isDark,
                    requestNotificationPermission: () =>
                        PermissionHandlers.requestNotificationPermission(
                            context),
                    requestBatteryOptimization: () =>
                        PermissionHandlers.requestBatteryOptimization(context),
                  ),
                  SizedBox(height: 24.h),
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      if (state is NotificationPreferencesLoaded) {
                        return SettingsSection(
                          state: state,
                          isDark: isDark,
                          pickKahfTime: () => TimePickers.pickKahfTime(
                              context,
                              state.kahfFridayTime,
                              context.read<NotificationsCubit>()),
                          pickAthkarTimes: () => TimePickers.pickAthkarTimes(
                              context,
                              state.morningAthkarTime,
                              state.eveningAthkarTime,
                              context.read<NotificationsCubit>()),
                          pickRandomAthkarFrequency: () => FrequencyDialog.show(
                              context, state.randomAthkarFrequency),
                          pickQuranTime: () => TimePickers.pickQuranTime(
                              context,
                              state.quranReminderTime,
                              context.read<NotificationsCubit>()),
                          pickChecklistTime: () =>
                              TimePickers.pickChecklistTime(
                                  context,
                                  state.checklistReminderTime,
                                  context.read<NotificationsCubit>()),
                        );
                      }
                      return const LoadingState();
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
