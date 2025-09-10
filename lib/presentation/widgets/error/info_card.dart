import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class InfoCard extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  
  const InfoCard({
    required this.isDark,
    required this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.primaryExtraLightColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryLightColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? context.primaryLightColor : context.primaryColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatic Error Reporting',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? Colors.white : context.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    fontFamily: "Amiri",
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'This error has been automatically reported to our development team for investigation.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 13.sp,
                    fontFamily: "Amiri",
                    height: 1.4,
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