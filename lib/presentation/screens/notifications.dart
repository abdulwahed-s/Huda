import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/notifications/frequency_dialog.dart';
import 'package:huda/presentation/widgets/notifications/loading_state.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';
import 'package:huda/presentation/widgets/notifications/settings_section.dart';
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

  Future<void> _togglePreference(String key, bool value) async {
    if (value &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;
    await context.togglePreference(key, value);
  }

  Future<void> _openReminderSettings(
    bool reminderEnabled,
    VoidCallback openSettings,
  ) async {
    if (reminderEnabled &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    if (mounted) {
      openSettings();
    }
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
              padding: EdgeInsets.fromLTRB(
                16.0.w,
                16.0.w,
                16.0.w,
                16.0.w + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NotificationRequirementsSection(
                    feature: NotificationFeature.reminders,
                    showConfiguredStatus: true,
                    onNotificationEnabled: _initializeNotifications,
                  ),
                  SizedBox(height: 24.h),
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      if (state is NotificationPreferencesLoaded) {
                        return SettingsSection(
                          state: state,
                          isDark: isDark,
                          pickKahfTime: () => _openReminderSettings(
                            state.kahfFriday,
                            () => TimePickers.pickKahfTime(
                              context,
                              state.kahfFridayTime,
                              context.read<NotificationsCubit>(),
                            ),
                          ),
                          pickAthkarTimes: () => _openReminderSettings(
                            state.sabahMasaa,
                            () => TimePickers.pickAthkarTimes(
                              context,
                              state.morningAthkarTime,
                              state.eveningAthkarTime,
                              context.read<NotificationsCubit>(),
                            ),
                          ),
                          pickRandomAthkarFrequency: () =>
                              _openReminderSettings(
                            state.randomAthkar,
                            () => FrequencyDialog.show(
                              context,
                              state.randomAthkarFrequency,
                            ),
                          ),
                          pickQuranTime: () => _openReminderSettings(
                            state.quranReminder,
                            () => TimePickers.pickQuranTime(
                              context,
                              state.quranReminderTime,
                              context.read<NotificationsCubit>(),
                            ),
                          ),
                          pickChecklistTime: () => _openReminderSettings(
                            state.checklistReminder,
                            () => TimePickers.pickChecklistTime(
                              context,
                              state.checklistReminderTime,
                              context.read<NotificationsCubit>(),
                            ),
                          ),
                          pickSahurAlarmSettings: () => _openReminderSettings(
                            state.sahurAlarmEnabled,
                            () => TimePickers.pickSahurAlarmSettings(
                              context,
                              state,
                              context.read<NotificationsCubit>(),
                            ),
                          ),
                          onPreferenceChanged: _togglePreference,
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
