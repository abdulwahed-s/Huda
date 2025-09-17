import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class LanguageBadge extends StatelessWidget {
  final String language;

  const LanguageBadge({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.primaryExtraLightColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        language.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
        ),
      ),
    );
  }
}