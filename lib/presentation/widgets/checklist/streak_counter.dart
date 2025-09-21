import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/animated_fire_icon.dart';

class StreakCounter extends StatelessWidget {
  final int streakCount;
  final double progress;
  final bool isPulsing;
  final bool isDark;

  const StreakCounter({
    super.key,
    required this.streakCount,
    required this.progress,
    required this.isPulsing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colors.accent.withValues(alpha: 0.8),
                  colors.accent.withValues(alpha: 0.6)
                ]
              : [
                  colors.accent.withValues(alpha: 0.8),
                  colors.accentDark.withValues(alpha: 0.8)
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.3),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedFireIcon(
            streakCount: streakCount,
            progress: progress,
            isPulsing: isPulsing,
            size: 20.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            '$streakCount',
            style: TextStyle(
              color: isDark ? colors.darkText : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              fontFamily: "Amiri",
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            AppLocalizations.of(context)!.consecutiveDays,
            style: TextStyle(
              color: isDark ? colors.darkText : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              fontFamily: "Amiri",
            ),
          ),
        ],
      ),
    );
  }
}
