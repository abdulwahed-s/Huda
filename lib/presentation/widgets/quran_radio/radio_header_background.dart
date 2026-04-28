import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RadioHeaderBackground extends StatelessWidget {
  final String title;
  final int? stationCount;

  const RadioHeaderBackground({
    super.key,
    required this.title,
    this.stationCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            right: 110.r,
            child: Container(
              width: 50.r,
              height: 50.r,
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
              Icons.radio_rounded,
              size: 100.sp,
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
                    title,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (stationCount != null)
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
                          Icon(Icons.radio_rounded,
                              size: 13.sp, color: theme.colorScheme.onPrimary),
                          SizedBox(width: 4.w),
                          Text(
                            '$stationCount',
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
