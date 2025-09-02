import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class StatusIndicator extends StatelessWidget {
  final bool isAligned;
  final bool isDark;

  const StatusIndicator({
    super.key,
    required this.isAligned,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isAligned
            ? (isDark ? context.darkGradientEnd : context.primaryColor)
                .withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isAligned
              ? (isDark ? context.darkGradientEnd : context.primaryColor)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: isAligned
                  ? Colors.green
                  : (isDark ? Colors.white54 : Colors.black54),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            isAligned
                ? AppLocalizations.of(context)!.alignedWithQiblah
                : AppLocalizations.of(context)!.findingDirection,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "Amiri",
              color: isAligned
                  ? (isDark ? context.darkGradientEnd : context.primaryColor)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
