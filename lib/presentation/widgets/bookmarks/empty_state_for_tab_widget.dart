import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class EmptyStateForTabWidget extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const EmptyStateForTabWidget({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

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
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appColors.primary.withValues(alpha: 0.08),
                    appColors.accent.withValues(alpha: 0.03),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: appColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 64.r,
                color: appColors.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? appColors.darkText : appColors.lightText,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: appColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: appColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18.r,
                    color: isDark ? appColors.darkText : appColors.lightText,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.bookmarkTip,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Amiri',
                        color:
                            isDark ? appColors.darkText : appColors.lightText,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
