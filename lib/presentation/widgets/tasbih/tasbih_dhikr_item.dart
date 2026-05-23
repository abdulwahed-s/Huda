import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TasbihDhikrItem extends StatelessWidget {
  final String text;
  final int count;
  final int index;
  final Color primaryColor;
  final VoidCallback onDelete;
  final bool isDark;

  const TasbihDhikrItem({
    super.key,
    required this.text,
    required this.count,
    required this.index,
    required this.primaryColor,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withValues(alpha: 0.08)
            : primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 12.w),
          _IndexBadge(index: index, primaryColor: primaryColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15.sp,
                  height: 1.4,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87,
                ),
              ),
            ),
          ),
          _CountBadge(count: count, primaryColor: primaryColor),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.close_rounded,
              size: 16.sp,
              color: Colors.red.shade400,
            ),
            padding: EdgeInsets.all(8.w),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  final Color primaryColor;

  const _IndexBadge({required this.index, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color primaryColor;

  const _CountBadge({required this.count, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      margin: EdgeInsets.only(right: 4.w),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
}
