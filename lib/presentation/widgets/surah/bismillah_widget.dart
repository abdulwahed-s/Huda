import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/theme_extension.dart';

class BismillahWidget extends StatelessWidget {
  final Color? customTextColor;

  const BismillahWidget({super.key, this.customTextColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            height: 2.h,
            width: 50.w,
            decoration: BoxDecoration(
              gradient: customTextColor != null
                  ? null
                  : LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryVariantColor,
                      ],
                    ),
              color: customTextColor?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '\u{FDFD}',
            style: TextStyle(
              fontSize: 28.sp,
              color: customTextColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor
                      : context.primaryColor),
              shadows: [
                Shadow(
                  offset: Offset(0, 1.h),
                  blurRadius: 2.r,
                  color: customTextColor != null
                      ? customTextColor!.withValues(alpha: 0.2)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? context.primaryDarkColor.withValues(alpha: 0.5)
                          : Colors.black12),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 2.h,
            width: 50.w,
            decoration: BoxDecoration(
              gradient: customTextColor != null
                  ? null
                  : LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryVariantColor,
                      ],
                    ),
              color: customTextColor?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }
}
