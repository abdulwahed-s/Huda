import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CounterBadge extends StatelessWidget {
  final bool isCompleted;
  final ColorScheme colorScheme;
  final int repeatCount;
  final VoidCallback onResetCounter;

  const CounterBadge({
    super.key,
    required this.isCompleted,
    required this.colorScheme,
    required this.repeatCount,
    required this.onResetCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.15)
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.w,
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                repeatCount.toString(),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onResetCounter,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.refresh,
                color: colorScheme.primary,
                size: 16.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
