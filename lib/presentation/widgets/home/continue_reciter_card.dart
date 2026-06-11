import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/core/utils/responsive_utils.dart';

class ContinueReciterCard extends StatelessWidget {
  final bool hasLastPlayed;
  final VoidCallback? onTap;
  final String continueText;
  final String noActivityText;
  final String resumeText;
  final String noActivityDescription;
  final List<Color> activeGradient;
  final List<Color> inactiveGradient;

  const ContinueReciterCard({
    super.key,
    required this.hasLastPlayed,
    this.onTap,
    required this.continueText,
    required this.noActivityText,
    required this.resumeText,
    required this.noActivityDescription,
    required this.activeGradient,
    required this.inactiveGradient,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight =
        context.responsive(mobile: 100.h, tablet: 120.h, desktop: 140.h);
    final padding =
        context.responsive(mobile: 12.w, tablet: 16.w, desktop: 20.w);
    final iconPadding =
        context.responsive(mobile: 4.w, tablet: 5.w, desktop: 6.w);
    final iconSize =
        context.responsive(mobile: 12.sp, tablet: 14.sp, desktop: 16.sp);
    final titleSize =
        context.responsive(mobile: 13.sp, tablet: 16.sp, desktop: 19.sp);
    final subtitleSize =
        context.responsive(mobile: 10.sp, tablet: 12.sp, desktop: 14.sp);

    return SizedBox(
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasLastPlayed ? activeGradient : inactiveGradient,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Stack(
              children: [
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasLastPlayed ? Icons.headphones : Icons.history,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 20.h, padding, padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hasLastPlayed ? continueText : noActivityText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: "Amiri",
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        hasLastPlayed ? resumeText : noActivityDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: "Amiri",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
