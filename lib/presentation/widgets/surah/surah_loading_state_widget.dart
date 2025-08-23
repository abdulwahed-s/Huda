import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class SurahLoadingStateWidget extends StatelessWidget {
  const SurahLoadingStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF0A0A0A), // Pure black
                  const Color(0xFF1A1A1A), // Dark gray
                  const Color(0xFF2A1A2A), // Dark purple-black
                ]
              : [
                  const Color(0xFFFFFDF7),
                  const Color(0xFFFFF9E6),
                  const Color(0xFFFFF5D6),
                ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern loading spinner
            Container(
              width: 45.w,
              height: 45.h,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A) // Dark container
                    : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.accentColor
                            .withValues(alpha: 0.2) // Purple glow
                        : context.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF674B5D),
                  ),
                  strokeWidth: 2.w,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Loading text
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B) // Dark slate
                        .withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0A0A0A).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Text(
                'Loading Surah...',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor // Purple text
                      : context.primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
