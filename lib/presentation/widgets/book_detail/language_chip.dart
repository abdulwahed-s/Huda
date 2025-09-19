import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:locale_names/locale_names.dart';

class LanguageChip extends StatelessWidget {
  final dynamic translation;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageChip({
    super.key,
    required this.translation,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? context.primaryColor
              : context.primaryColor.withValues(alpha: 0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.15),
                  context.primaryColor.withValues(alpha: 0.08),
                ],
              )
            : LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.05),
                  context.primaryColor.withValues(alpha: 0.02),
                ],
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16.sp,
                    color: context.primaryColor,
                  ),
                  SizedBox(width: 6.w),
                ],
                Text(
                  locale.nativeDisplayLanguage,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? context.primaryColor
                        : context.primaryColor.withValues(alpha: 0.8),
                    fontFamily: 'Amiri',
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor.withValues(alpha: 0.2)
                        : context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    translation.slang.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.primaryColor
                          : context.primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
