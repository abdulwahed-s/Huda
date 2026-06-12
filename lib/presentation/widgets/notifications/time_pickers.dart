import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/notifications/alarm_option_card.dart';
import 'package:huda/presentation/widgets/notifications/radio_dot.dart';
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
      if (context.mounted) {
        cubit.setContext(context);
      }
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
      if (context.mounted) {
        cubit.setContext(context);
      }
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
      if (context.mounted) {
        cubit.setContext(context);
      }
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
              style: const TextStyle(),
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
                  if (context.mounted) {
                    cubit.setContext(context);
                  }
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
                  if (context.mounted) {
                    cubit.setContext(context);
                  }
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
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  static void pickSahurAlarmSettings(
    BuildContext context,
    NotificationPreferencesLoaded state,
    NotificationsCubit cubit,
  ) {
    NavigatorState navigator = Navigator.of(context);

    int alarmType = state.sahurAlarmType;
    String exactTime = state.sahurExactTime;
    int minutesBefore = state.sahurMinutesBeforeFajr.clamp(10, 150);

    final primaryColor = Theme.of(context).colorScheme.primary;
    const fontStyle = TextStyle();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(Icons.alarm_rounded, color: primaryColor),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.sahurAlarmTitle,
                    style: fontStyle.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Option 1 — Exact Time
                  AlarmOptionCard(
                    selected: alarmType == 0,
                    accentColor: primaryColor,
                    onTap: () {
                      setState(() => alarmType = 0);
                      cubit.setSahurAlarmType(0);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RadioDot(
                                selected: alarmType == 0, color: primaryColor),
                            SizedBox(width: 10.w),
                            Text(
                              AppLocalizations.of(context)!.exactTime,
                              style: fontStyle.copyWith(
                                fontSize: 15.sp,
                                fontWeight: alarmType == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (alarmType == 0)
                              GestureDetector(
                                onTap: () async {
                                  final parts = exactTime.split(':');
                                  final picked = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: TimeOfDay(
                                      hour: int.parse(parts[0]),
                                      minute: int.parse(parts[1]),
                                    ),
                                  );
                                  if (picked != null) {
                                    final formatted =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    setState(() => exactTime = formatted);
                                    cubit.setSahurExactTime(formatted);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_rounded,
                                          size: 14.sp, color: Colors.white),
                                      SizedBox(width: 4.w),
                                      Text(
                                        exactTime,
                                        style: fontStyle.copyWith(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Option 2 — Minutes Before Fajr
                  AlarmOptionCard(
                    selected: alarmType == 1,
                    accentColor: primaryColor,
                    onTap: () {
                      setState(() => alarmType = 1);
                      cubit.setSahurAlarmType(1);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RadioDot(
                                selected: alarmType == 1, color: primaryColor),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.minutesBeforeFajr,
                                style: fontStyle.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: alarmType == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (alarmType == 1)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                      color:
                                          primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '$minutesBefore ${AppLocalizations.of(context)!.minutesUnit}',
                                  style: fontStyle.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (alarmType == 1) ...[
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Text('10',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade500)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.h,
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 7.r),
                                    overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 14.r),
                                    activeTrackColor: primaryColor,
                                    inactiveTrackColor:
                                        primaryColor.withValues(alpha: 0.1),
                                    thumbColor: primaryColor,
                                    overlayColor:
                                        primaryColor.withValues(alpha: 0.15),
                                  ),
                                  child: Slider(
                                    value: minutesBefore.toDouble(),
                                    min: 10,
                                    max: 150,
                                    divisions: 140,
                                    onChanged: (v) => setState(
                                        () => minutesBefore = v.toInt()),
                                    onChangeEnd: (v) => cubit
                                        .setSahurMinutesBeforeFajr(v.toInt()),
                                  ),
                                ),
                              ),
                              Text('150',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text(
                  AppLocalizations.of(context)!.done,
                  style: fontStyle.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
