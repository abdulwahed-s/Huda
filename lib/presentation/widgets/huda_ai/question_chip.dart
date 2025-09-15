import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class QuestionChip extends StatelessWidget {
  final BuildContext context;
  final String text;
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  const QuestionChip({
    super.key,
    required this.context,
    required this.text,
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? context.darkCardBackground : Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? context.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          splashColor: context.primaryColor.withValues(alpha: 0.2),
          highlightColor: context.primaryColor.withValues(alpha: 0.1),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    icon,
                    color: context.primaryColor,
                    size: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  text,
                  style: TextStyle(
                    color: isDark ? context.darkText : context.lightText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Amiri',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
