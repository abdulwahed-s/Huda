import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranFontOptionTile extends StatelessWidget {
  final String fontFamily;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const QuranFontOptionTile({
    super.key,
    required this.fontFamily,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? const Color(0xFF252525) : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.0 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'بِسْمِ ٱللّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18.sp,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  height: 1.8,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? accent
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(height: 4.h),
                  Icon(Icons.check_circle_rounded,
                      color: accent, size: 18.sp),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
