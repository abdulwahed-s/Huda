import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const PrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.8),
                ],
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: context.primaryColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : context.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : context.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}