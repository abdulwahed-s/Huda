import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class StatsCard extends StatelessWidget {
  final int totalCount;

  const StatsCard({
    super.key,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [context.darkGradientMid, context.darkGradientEnd]
              : [context.primaryExtraLightColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.athkarCollection,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.darkText : context.lightText,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!
                      .selectedAthkarGroups(totalCount),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'Tajawal',
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
