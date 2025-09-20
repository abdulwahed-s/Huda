import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'date_header.dart';
import 'progress_indicator.dart';
import 'streak_counter.dart';

class ChecklistHeader extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final double progress;
  final int completedCount;
  final int totalItems;
  final int streakCount;
  final bool isPulsing;
  final bool isDark;

  const ChecklistHeader({
    super.key,
    required this.currentDate,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.progress,
    required this.completedCount,
    required this.totalItems,
    required this.streakCount,
    required this.isPulsing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colors.darkGradientStart,
                  colors.darkGradientMid,
                  colors.darkGradientEnd,
                ]
              : [
                  colors.primary,
                  colors.primaryVariant,
                  colors.primaryLight,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          DateHeader(
            currentDate: currentDate,
            onPreviousPressed: onPreviousPressed,
            onNextPressed: onNextPressed,
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          ProgressIndicatorWidget(
            progress: progress,
            completed: completedCount,
            total: totalItems,
            isDark: isDark,
          ),
          SizedBox(height: 10.h),
          StreakCounter(
            streakCount: streakCount,
            progress: progress,
            isPulsing: isPulsing,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}
