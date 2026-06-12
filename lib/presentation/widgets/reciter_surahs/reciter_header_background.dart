import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/reciter_model.dart';

class ReciterHeaderBackground extends StatelessWidget {
  final Reciter reciter;
  final Moshaf moshaf;
  final int surahCount;
  final ThemeData theme;

  const ReciterHeaderBackground({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.surahCount,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final name = reciter.name.toString();
    final initial = name.isNotEmpty ? name[0] : 'R';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(
                theme.colorScheme.primary, theme.colorScheme.secondary, 0.55)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40.r,
            right: -40.r,
            child: Container(
              width: 160.r,
              height: 160.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -35.r,
            left: -55.r,
            child: Container(
              width: 210.r,
              height: 210.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 40.r,
            right: 100.r,
            child: Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 16.h),
              child: Row(
                children: [
                  Container(
                    width: 66.r,
                    height: 66.r,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            theme.colorScheme.onPrimary.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reciter.name.toString(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          moshaf.name.toString(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.library_music_rounded,
                                size: 12.sp,
                                color: theme.colorScheme.onPrimary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$surahCount',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
