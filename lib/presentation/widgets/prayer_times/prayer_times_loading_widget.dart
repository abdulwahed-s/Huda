import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class PrayerTimesLoadingWidget extends StatelessWidget {
  const PrayerTimesLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = context.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: isDark ? 0.72 : 0.62);

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.prayerCountdownLoadingText,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60.r,
                  height: 60.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_searching_rounded,
                          color: primaryColor,
                          size: 27.sp,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(2.r),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: primaryColor,
                          backgroundColor: primaryColor.withValues(alpha: 0.14),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.prayerTimes,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        l10n.prayerCountdownLoadingText,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.32 : 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    color: primaryColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.location,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                      backgroundColor: primaryColor.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            _PrayerTimePreview(
              label: l10n.fajr,
              placeholderWidth: 58.w,
              primaryColor: primaryColor,
              textColor: secondaryText,
            ),
            _PrayerTimePreview(
              label: l10n.dhuhr,
              placeholderWidth: 48.w,
              primaryColor: primaryColor,
              textColor: secondaryText,
            ),
            _PrayerTimePreview(
              label: l10n.maghrib,
              placeholderWidth: 64.w,
              primaryColor: primaryColor,
              textColor: secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimePreview extends StatelessWidget {
  const _PrayerTimePreview({
    required this.label,
    required this.placeholderWidth,
    required this.primaryColor,
    required this.textColor,
  });

  final String label;
  final double placeholderWidth;
  final Color primaryColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: textColor,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Container(
            width: placeholderWidth,
            height: 9.h,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
        ],
      ),
    );
  }
}
