import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RadioSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool showClearButton;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const RadioSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.showClearButton,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Icon(Icons.search_rounded,
                  color: theme.colorScheme.primary, size: 22.sp),
            ),
            prefixIconConstraints:
                BoxConstraints(minWidth: 48.w, minHeight: 40.h),
            suffixIcon: showClearButton
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.sp),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
