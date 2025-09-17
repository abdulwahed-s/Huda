import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:locale_names/locale_names.dart';

class LanguageDisplay extends StatelessWidget {
  final Locale locale;

  const LanguageDisplay({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? context.darkTabBackground : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        locale.defaultDisplayLanguage,
        style: TextStyle(
          fontSize: 13.sp,
          fontFamily: 'Amiri',
          color: isDark
              ? context.darkText.withValues(alpha: 0.8)
              : context.lightText.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}