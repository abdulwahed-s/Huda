import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahIndexHeader extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final String title;
  final String subtitle;
  final String? currentSurahArabicName;

  const SurahIndexHeader({
    super.key,
    required this.isDark,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.currentSurahArabicName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (currentSurahArabicName != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 11.sp,
                    color: accent,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    currentSurahArabicName!,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
