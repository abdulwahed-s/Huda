import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/miqaat_lock/duration_selection_tile.dart';

class DurationPickerSheet extends StatelessWidget {
  final int currentDuration;
  final ValueChanged<int> onDurationSelected;
  final VoidCallback onCustomDurationTap;

  const DurationPickerSheet({
    super.key,
    required this.currentDuration,
    required this.onDurationSelected,
    required this.onCustomDurationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 48.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: context.primaryColor, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.selectDuration,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  ...MiqaatLockSettings.defaultDurationOptions.map((duration) {
                    final isSelected = currentDuration == duration;
                    return DurationSelectionTile(
                      duration: duration,
                      isSelected: isSelected,
                      onTap: () => onDurationSelected(duration),
                    );
                  }),
                  DurationSelectionTile(
                    duration: null,
                    isSelected: !MiqaatLockSettings.defaultDurationOptions
                        .contains(currentDuration),
                    isCustom: true,
                    onTap: onCustomDurationTap,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
