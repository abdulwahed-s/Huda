import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;
  final bool isDark;

  const ProgressIndicatorWidget({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.dailyProgress,
                style: TextStyle(
                  color: isDark ? colors.darkText : Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Amiri",
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  color: isDark ? colors.darkText : Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Amiri",
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? colors.darkText : Colors.white),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${(progress * 100).toInt()}% ${AppLocalizations.of(context)!.completedPercentage}',
            style: TextStyle(
              color: isDark ? colors.darkText : Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: "Amiri",
            ),
          ),
        ],
      ),
    );
  }
}