import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomDurationPickerContent extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const CustomDurationPickerContent({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = context.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.tune_rounded, color: primaryColor, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.customDuration,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        Container(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : primaryColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Column(
            children: [
              Text(
                '$selectedDuration',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.minutes,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6.h,
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withValues(alpha: 0.15),
            thumbColor: Colors.white,
            thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12.r, elevation: 4, pressedElevation: 8),
            overlayColor: primaryColor.withValues(alpha: 0.2),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 24.r),
          ),
          child: Slider(
            value: selectedDuration.toDouble(),
            min: MiqaatLockSettings.minCustomDuration.toDouble(),
            max: MiqaatLockSettings.maxCustomDuration.toDouble(),
            divisions: MiqaatLockSettings.maxCustomDuration -
                MiqaatLockSettings.minCustomDuration,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${MiqaatLockSettings.minCustomDuration}m',
              style: TextStyle(fontSize: 12.sp, color: theme.hintColor),
            ),
            Text(
              '${MiqaatLockSettings.maxCustomDuration}m',
              style: TextStyle(fontSize: 12.sp, color: theme.hintColor),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  l10n.confirm,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
