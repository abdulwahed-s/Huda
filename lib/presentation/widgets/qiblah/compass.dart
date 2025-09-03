import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/qiblah/compass_ring.dart';
import 'package:huda/presentation/widgets/qiblah/pulsing_effect.dart';

class Compass extends StatelessWidget {
  final QiblahDirection qiblahDirection;
  final double angle;
  final bool isAligned;
  final bool isDark;
  final Animation<double> pulseAnimation;
  final Animation<double> scaleAnimation;

  const Compass({
    super.key,
    required this.qiblahDirection,
    required this.angle,
    required this.isAligned,
    required this.isDark,
    required this.pulseAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CompassRing(isDark: isDark),
          if (isAligned)
            PulsingEffect(isDark: isDark, pulseAnimation: pulseAnimation),
          Positioned(
            top: 20.h,
            child: AnimatedScale(
              scale: isAligned ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SvgPicture.asset(
                'assets/images/maccaicon.svg',
                width: 40.w,
                height: 40.h,
                colorFilter: ColorFilter.mode(
                  isAligned
                      ? (isDark
                          ? context.darkGradientEnd
                          : context.primaryColor)
                      : (isDark ? Colors.white70 : Colors.black54),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          AnimatedScale(
            scale: isAligned ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SvgPicture.asset(
              'assets/images/frame.svg',
              colorFilter: ColorFilter.mode(
                isAligned
                    ? (isDark ? context.darkGradientEnd : context.primaryColor)
                    : (isDark ? Colors.white54 : Colors.black54),
                BlendMode.srcIn,
              ),
              width: 280.w,
              height: 280.h,
            ),
          ),
          AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isAligned ? scaleAnimation.value : 1.0,
                child: Transform.rotate(
                  angle: angle,
                  child: Icon(
                    Icons.navigation,
                    size: 60.w,
                    color: isAligned
                        ? (isDark
                            ? context.darkGradientEnd
                            : context.primaryColor)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 40.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${qiblahDirection.qiblah.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: "Amiri",
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
