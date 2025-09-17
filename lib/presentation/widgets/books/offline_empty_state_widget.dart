import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class OfflineEmptyStateWidget extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const OfflineEmptyStateWidget({
    super.key,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? context.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color:
                  isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64.sp,
              color: isDark
                  ? context.darkText.withValues(alpha: 0.3)
                  : context.lightText.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Downloaded Books',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? context.darkText : context.lightText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Download books when online to access them offline',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark
                    ? context.darkText.withValues(alpha: 0.7)
                    : context.lightText.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: context.primaryColor, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: context.primaryColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Check Connection',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
