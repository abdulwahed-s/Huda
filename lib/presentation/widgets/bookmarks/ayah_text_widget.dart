import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AyahTextWidget extends StatelessWidget {
  final String ayahText;
  final bool isDark;

  const AyahTextWidget({
    super.key,
    required this.ayahText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? appColors.primary.withValues(alpha: 0.05)
            : appColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: appColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          ayahText,
          style: TextStyle(
            fontFamily: getQuranFonts() ,
            fontSize: 20.sp,
            height: 2.0,
            color: isDark ? appColors.darkText : appColors.lightText,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
