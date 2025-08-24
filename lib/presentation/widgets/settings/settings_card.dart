import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;

  const SettingsCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

