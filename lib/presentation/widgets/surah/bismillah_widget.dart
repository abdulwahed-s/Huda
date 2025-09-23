import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';

class BismillahWidget extends StatelessWidget {
  const BismillahWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // Decorative line
          Container(
            height: 2.h,
            width: 50.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryVariantColor,
                ],
              ),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          SizedBox(height: 12.h),

          // Bismillah text
          Text(
            '﷽',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28.sp,
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.accentColor // Bright accent color
                  : context.primaryColor,
              shadows: [
                Shadow(
                  offset: Offset(0, 1.h),
                  blurRadius: 2.r,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.primaryDarkColor
                          .withValues(alpha: 0.5) // Primary dark shadow
                      : Colors.black12,
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Decorative line
          Container(
            height: 2.h,
            width: 50.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryVariantColor,
                ],
              ),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }
}
