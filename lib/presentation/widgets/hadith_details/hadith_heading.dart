import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';

class HadithHeading extends StatelessWidget {
  final String heading;
  final bool isDark;

  const HadithHeading({super.key, required this.heading, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cleanedHeading = HadithTextFormatter.format(heading).plainText;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.0.h),
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        cleanedHeading,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18.0.sp,
          fontWeight: FontWeight.bold,
          color: context.primaryColor,
        ),
      ),
    );
  }
}
