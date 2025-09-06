import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/notifications/time_selection_row.dart';

class TimePickers {
  static Future<void> pickQuranTime(
    BuildContext context,
    String current,
    NotificationsCubit cubit,
  ) async {
    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppLocalizations.of(context)!.selectQuranReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      cubit.setContext(context);
      cubit.setQuranReminderTime(formatted);
    }
  }

  static Future<void> pickChecklistTime(
    BuildContext context,
    String current,
    NotificationsCubit cubit,
  ) async {
    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppLocalizations.of(context)!.selectChecklistReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      cubit.setContext(context);
      cubit.setChecklistReminderTime(formatted);
    }
  }

  static Future<void> pickKahfTime(
    BuildContext context,
    String current,
    NotificationsCubit cubit,
  ) async {
    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppLocalizations.of(context)!.selectKahfFridayTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      cubit.setContext(context);
      cubit.setKahfFridayTime(formatted);
    }
  }

  static void pickAthkarTimes(
    BuildContext context,
    String currentMorning,
    String currentEvening,
    NotificationsCubit cubit,
  ) {
    NavigatorState navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: const Icon(Icons.wb_sunny, color: Colors.orange),
            ),
            SizedBox(width: 10.w),
            Text(
              AppLocalizations.of(context)!.athkarTimes,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimeSelectionRow(
              label: AppLocalizations.of(context)!.morning,
              time: currentMorning,
              onTap: () async {
                final parts = currentMorning.split(':');
                final initialTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );

                final picked = await showTimePicker(
                  context: dialogContext,
                  initialTime: initialTime,
                  helpText:
                      AppLocalizations.of(context)!.selectMorningAthkarTime,
                );

                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  cubit.setContext(context);
                  cubit.setMorningAthkarTime(formatted);
                  navigator.pop();
                }
              },
            ),
            SizedBox(height: 12.h),
            TimeSelectionRow(
              label: AppLocalizations.of(context)!.evening,
              time: currentEvening,
              onTap: () async {
                final parts = currentEvening.split(':');
                final initialTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );

                final picked = await showTimePicker(
                  context: dialogContext,
                  initialTime: initialTime,
                  helpText:
                      AppLocalizations.of(context)!.selectEveningAthkarTime,
                );

                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  cubit.setContext(context);
                  cubit.setEveningAthkarTime(formatted);
                  navigator.pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.done,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
        ],
      ),
    );
  }
}