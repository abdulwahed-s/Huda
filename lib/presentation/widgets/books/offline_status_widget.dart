import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class OfflineStatusWidget extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onRetry;

  const OfflineStatusWidget({
    super.key,
    required this.count,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.offline_bolt_rounded,
            size: 48.sp,
            color: context.primaryColor,
          ),
          SizedBox(height: 12.h),
          Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? context.darkText : context.lightText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Showing $count downloaded books',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? context.darkText.withValues(alpha: 0.7)
                  : context.lightText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
