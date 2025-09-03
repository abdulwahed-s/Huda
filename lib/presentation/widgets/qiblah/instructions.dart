import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class Instructions extends StatelessWidget {
  final bool isAligned;
  final bool isDark;

  const Instructions({
    super.key,
    required this.isAligned,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 32.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: isAligned
            ? Border.all(
                color: isDark ? context.darkGradientEnd : context.primaryColor,
                width: 2,
              )
            : null,
      ),
      child: Text(
        isAligned
            ? AppLocalizations.of(context)!.perfectQiblahAlignment
            : AppLocalizations.of(context)!.rotateDeviceInstruction,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: "Amiri",
          fontWeight: isAligned ? FontWeight.w600 : FontWeight.w500,
          color: isAligned
              ? (isDark ? context.darkGradientEnd : context.primaryColor)
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
