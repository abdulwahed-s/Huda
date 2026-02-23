import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlarmOptionCard extends StatelessWidget {
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const AlarmOptionCard({
    super.key,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: isDark ? 0.12 : 0.06)
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: isDark ? 0.6 : 0.4)
                : isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
