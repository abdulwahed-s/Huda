import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_card.dart';

class SettingsSection extends StatelessWidget {
  final NotificationPreferencesLoaded state;
  final bool isDark;
  final void Function() pickKahfTime;
  final void Function() pickAthkarTimes;
  final void Function() pickRandomAthkarFrequency;
  final void Function() pickQuranTime;
  final void Function() pickChecklistTime;

  const SettingsSection({
    super.key,
    required this.state,
    required this.isDark,
    required this.pickKahfTime,
    required this.pickAthkarTimes,
    required this.pickRandomAthkarFrequency,
    required this.pickQuranTime,
    required this.pickChecklistTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.islamicReminders,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            color: isDark ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 12.h),

        // Al-Kahf Friday
        NotificationCard(
          title: AppLocalizations.of(context)!.suratAlKahf,
          subtitle: AppLocalizations.of(context)!
              .everyFridayAtTime(state.kahfFridayTime),
          description: AppLocalizations.of(context)!.weeklyReminderKahf,
          icon: Icons.book_outlined,
          gradient: [Colors.green.shade400, Colors.green.shade600],
          value: state.kahfFriday,
          onChanged: (value) => context
              .read<NotificationsCubit>()
              .togglePreference('kahfFriday', value),
          onSettingsTap: () => pickKahfTime(),
        ),

        // Morning & Evening Athkar
        NotificationCard(
          title: AppLocalizations.of(context)!.morningEveningAthkarTitle,
          subtitle: AppLocalizations.of(context)!.dailyTimesSchedule(
              state.morningAthkarTime, state.eveningAthkarTime),
          description: AppLocalizations.of(context)!.dailyRemindersAthkar,
          icon: Icons.wb_sunny_outlined,
          gradient: [Colors.orange.shade400, Colors.orange.shade600],
          value: state.sabahMasaa,
          onChanged: (value) => context
              .read<NotificationsCubit>()
              .togglePreference('sabahMasaa', value),
          onSettingsTap: () => pickAthkarTimes(),
        ),

        // Random Athkar
        NotificationCard(
          title: AppLocalizations.of(context)!.randomAthkarTitle,
          subtitle: AppLocalizations.of(context)!
              .everyMinutes(state.randomAthkarFrequency.toString(), ''),
          description: AppLocalizations.of(context)!.periodicRemindersAthkar,
          icon: Icons.repeat_outlined,
          gradient: [Colors.blue.shade400, Colors.blue.shade600],
          value: state.randomAthkar,
          onChanged: (value) => context
              .read<NotificationsCubit>()
              .togglePreference('randomAthkar', value),
          onSettingsTap: () => pickRandomAthkarFrequency(),
        ),

        // Quran Reading Reminder
        NotificationCard(
          title: AppLocalizations.of(context)!.quranReadingReminderTitle,
          subtitle: AppLocalizations.of(context)!
              .dailyAtTime(state.quranReminderTime),
          description: AppLocalizations.of(context)!.dailyReminderQuran,
          icon: Icons.menu_book_outlined,
          gradient: [Colors.purple.shade400, Colors.purple.shade600],
          value: state.quranReminder,
          onChanged: (value) => context
              .read<NotificationsCubit>()
              .togglePreference('quranReminder', value),
          onSettingsTap: () => pickQuranTime(),
        ),

        // Daily Checklist Reminder
        NotificationCard(
            title: AppLocalizations.of(context)!.dailyChecklistReminder,
            subtitle: AppLocalizations.of(context)!
                .dailyChecklistSubtitle(state.checklistReminderTime),
            description:
                AppLocalizations.of(context)!.checklistReminderDescription,
            icon: Icons.checklist_rtl,
            gradient: [Colors.teal.shade400, Colors.teal.shade600],
            value: state.checklistReminder,
            onChanged: (value) => context
                .read<NotificationsCubit>()
                .togglePreference('checklistReminder', value),
            onSettingsTap: () => pickChecklistTime()),
      ],
    );
  }
}
