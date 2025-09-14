import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isDark;

  const EmptyStateWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(40.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appColors.primary.withValues(alpha: 0.1),
                    appColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: appColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 80.r,
                color: appColors.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              AppLocalizations.of(context)!.noBookmarksYet,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? appColors.darkText : appColors.lightText,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                AppLocalizations.of(context)!.startBookmarkingFavoriteVerses,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColors.primary, appColors.accent],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: appColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/homeQuran');
                },
                icon: Icon(Icons.explore_rounded, size: 22.r),
                label: Text(
                  AppLocalizations.of(context)!.browseQuran,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Amiri',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
