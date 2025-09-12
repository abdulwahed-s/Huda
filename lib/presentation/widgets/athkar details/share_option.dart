import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const ShareOption({
    super.key,
    required this.icon,
    required this.title,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isLoading
              ? colorScheme.primary.withValues(alpha: 0.05)
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isLoading
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: 24.w,
                    ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
