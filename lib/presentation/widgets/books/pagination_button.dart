import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class PaginationButton extends StatelessWidget {
  final BuildContext context;
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isCompact;

  const PaginationButton({
    super.key,
    required this.context,
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.onPressed,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon, size: 18.sp),
        label: const SizedBox.shrink(),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? context.primaryColor
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          foregroundColor: isEnabled
              ? Colors.white
              : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          elevation: isEnabled ? 3 : 0,
          shadowColor: isEnabled
              ? context.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12.w : 18.w,
            vertical: 14.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
    );
  }
}
