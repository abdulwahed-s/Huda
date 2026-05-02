import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahIndexGridTile extends StatelessWidget {
  final int surahNumber;
  final String arabicName;
  final bool isMakki;
  final String revelationLabel;
  final String verseCountLabel;
  final bool isSelected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const SurahIndexGridTile({
    super.key,
    required this.surahNumber,
    required this.arabicName,
    required this.isMakki,
    required this.revelationLabel,
    required this.verseCountLabel,
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
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
          boxShadow: isSelected || isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    arabicName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isMakki
                                    ? Colors.teal
                                        .withValues(alpha: isDark ? 0.25 : 0.12)
                                    : Colors.indigo.withValues(
                                        alpha: isDark ? 0.25 : 0.12)),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            revelationLabel,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isMakki
                                      ? (isDark
                                          ? Colors.teal.shade200
                                          : Colors.teal.shade700)
                                      : (isDark
                                          ? Colors.indigo.shade200
                                          : Colors.indigo.shade700)),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          verseCountLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : accent.withValues(alpha: isDark ? 0.15 : 0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                '$surahNumber',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
