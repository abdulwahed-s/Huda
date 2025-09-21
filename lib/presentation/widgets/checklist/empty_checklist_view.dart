import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class EmptyChecklistView extends StatelessWidget {
  final bool isDark;

  const EmptyChecklistView({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  const Color(0xFF4CAF50).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2),
                  blurRadius: 16.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64.sp,
              color: colors.accent,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            AppLocalizations.of(context)!.noTasksForDay,
            style: TextStyle(
              fontSize: 20.sp,
              color: isDark ? colors.darkText : colors.primaryDark,
              fontWeight: FontWeight.bold,
              fontFamily: "Amiri",
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '"وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا"',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? colors.darkText : colors.primaryDark,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontFamily: "Amiri",
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}