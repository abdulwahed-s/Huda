import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/data/models/miqaat_lock/time_slot.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class TimeSlotPickerDialog extends StatefulWidget {
  final TimeSlot? existingSlot;

  const TimeSlotPickerDialog({
    super.key,
    this.existingSlot,
  });

  @override
  State<TimeSlotPickerDialog> createState() => _TimeSlotPickerDialogState();
}

class _TimeSlotPickerDialogState extends State<TimeSlotPickerDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<int> _selectedWeekdays;
  final TextEditingController _labelController = TextEditingController();

  final List<int> _allWeekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    if (widget.existingSlot != null) {
      _startTime = widget.existingSlot!.startTime;
      _endTime = widget.existingSlot!.endTime;
      _selectedWeekdays = List.from(widget.existingSlot!.weekdays);
      _labelController.text = widget.existingSlot!.label ?? '';
    } else {
      _startTime = const TimeOfDay(hour: 5, minute: 0);
      _endTime = const TimeOfDay(hour: 6, minute: 0);
      _selectedWeekdays = [];
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : theme.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    widget.existingSlot != null
                        ? l10n.editTimeSlot
                        : l10n.addTimeSlot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: _saveTimeSlot,
                    child: Text(
                      l10n.done,
                      style: TextStyle(
                        color: isDark
                            ? theme.colorScheme.primary
                            : theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: l10n.label,
                  hintText: l10n.labelHint,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                l10n.timeRange,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: l10n.startTime,
                      time: _startTime,
                      onTap: () => _selectTime(isStart: true),
                      theme: theme,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.hintColor,
                    ),
                  ),
                  Expanded(
                    child: _buildTimePicker(
                      label: l10n.endTime,
                      time: _endTime,
                      onTap: () => _selectTime(isStart: false),
                      theme: theme,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                l10n.repeatOn,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.leaveEmptyForEveryday,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.hintColor,
                ),
              ),
              SizedBox(height: 12.h),
              _buildWeekdaySelector(theme, l10n),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.hintColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final dayLabels = [
      l10n.sunday.substring(0, 5),
      l10n.monday.substring(0, 5),
      l10n.tuesday.substring(0, 5),
      l10n.wednesday.substring(0, 5),
      l10n.thursday.substring(0, 5),
      l10n.friday.substring(0, 5),
      l10n.saturday.substring(0, 5),
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _allWeekdays.map((day) {
        final isSelected = _selectedWeekdays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWeekdays.remove(day);
              } else {
                _selectedWeekdays.add(day);
              }
            });
          },
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? theme.colorScheme.primary : theme.primaryColor)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : theme.primaryColor.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                dayLabels[day - 1],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : theme.primaryColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveTimeSlot() {
    final cubit = context.read<MiqaatLockCubit>();

    final slot = TimeSlot(
      id: widget.existingSlot?.id ?? const Uuid().v4(),
      startTime: _startTime,
      endTime: _endTime,
      weekdays: _selectedWeekdays..sort(),
      label: _labelController.text.isNotEmpty ? _labelController.text : null,
    );

    if (widget.existingSlot != null) {
      cubit.updateTimeSlot(slot);
    } else {
      cubit.addTimeSlot(slot);
    }

    Navigator.pop(context);
  }
}
