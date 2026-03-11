import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';

import 'miqaat_lock_shared_components.dart';

class TimeSlotsSection extends StatelessWidget {
  final List<TimeSlot> timeSlots;
  final VoidCallback onAddTimeSlot;
  final void Function(String id) onRemoveTimeSlot;

  const TimeSlotsSection({
    super.key,
    required this.timeSlots,
    required this.onAddTimeSlot,
    required this.onRemoveTimeSlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.schedule_rounded,
          title: l10n.timeSlots,
          theme: theme,
          primary: primary,
        ),
        SizedBox(height: 6.h),
        SharedCard(
          theme: theme,
          isDark: isDark,
          child: Column(
            children: [
              if (timeSlots.isEmpty)
                EmptyStateWidget(
                  icon: Icons.schedule_outlined,
                  message: l10n.noTimeSlotsConfigured,
                  theme: theme,
                  isDark: isDark,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: timeSlots.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1.h,
                    indent: 68.w,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final slot = timeSlots[index];
                    return _buildTimeSlotTile(slot, theme, l10n, context);
                  },
                ),
              if (timeSlots.length < MiqaatLockSettings.maxTimeSlots)
                AddButtonWidget(
                  icon: Icons.add_rounded,
                  label: l10n.addTimeSlot,
                  primary: primary,
                  subtitle:
                      '${timeSlots.length}/${MiqaatLockSettings.maxTimeSlots}',
                  onTap: onAddTimeSlot,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotTile(TimeSlot slot, ThemeData theme,
      AppLocalizations l10n, BuildContext context) {
    final startTime =
        '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${slot.endTime.hour.toString().padLeft(2, '0')}:${slot.endTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: context.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label ?? '$startTime – $endTime',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                if (slot.label != null)
                  Text(
                    '$startTime – $endTime',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.hintColor,
                    ),
                  )
                else
                  _buildWeekdayChips(slot.weekdays, l10n, theme, context),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.minus_circle_fill,
              color: Colors.red.withValues(alpha: 0.6),
              size: 22.sp,
            ),
            onPressed: () => onRemoveTimeSlot(slot.id),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayChips(List<int> weekdays, AppLocalizations l10n,
      ThemeData theme, BuildContext context) {
    if (weekdays.isEmpty) {
      return Text(
        l10n.everyday,
        style: TextStyle(fontSize: 12.sp, color: theme.hintColor),
      );
    }
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    final allDays = List.generate(7, (i) => i + 1);
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: allDays.map((d) {
        final isActive = weekdays.contains(d);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: isActive
                ? context.primaryColor.withValues(alpha: 0.15)
                : theme.hintColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            dayNames[d - 1].substring(0, min(3, dayNames[d - 1].length)),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? context.primaryColor : theme.hintColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
