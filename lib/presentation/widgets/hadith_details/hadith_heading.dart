import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class HadithHeading extends StatelessWidget {
  final String heading;
  final bool isDark;

  const HadithHeading({
    super.key,
    required this.heading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
        heading,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18.0.sp,
          fontWeight: FontWeight.bold,
          fontFamily: "Amiri",
          color: context.primaryColor,
        ),
      ),
    );
  }
}
