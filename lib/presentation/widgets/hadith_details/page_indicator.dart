import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final bool isDark;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        'Page $currentPage of $lastPage',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
          fontFamily: "Amiri",
        ),
      ),
    );
  }
}
