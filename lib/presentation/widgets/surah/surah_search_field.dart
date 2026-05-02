import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final String hintText;
  final bool isDark;
  final Color accent;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SurahSearchField({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.hintText,
    required this.isDark,
    required this.accent,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: accent.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18.sp,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 16.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}
