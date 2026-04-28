import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/l10n/app_localizations.dart';

class RecitersHeaderBackground extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  final int reciterCount;

  const RecitersHeaderBackground({
    super.key,
    required this.theme,
    required this.l10n,
    required this.reciterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(
                theme.colorScheme.primary, theme.colorScheme.secondary, 0.5)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40.r,
            right: -40.r,
            child: Container(
              width: 180.r,
              height: 180.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50.r,
            left: -60.r,
            child: Container(
              width: 220.r,
              height: 220.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: 50.r,
            right: 120.r,
            child: Container(
              width: 55.r,
              height: 55.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 16.h,
            child: Icon(
              Icons.headphones_rounded,
              size: 90.sp,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.09),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.quranAudio,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (reciterCount > 0)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            size: 13.sp,
                            color: theme.colorScheme.onPrimary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '$reciterCount',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
