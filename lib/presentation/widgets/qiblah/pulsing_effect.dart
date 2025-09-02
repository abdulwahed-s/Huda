import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class PulsingEffect extends StatelessWidget {
  final bool isDark;
  final Animation<double> pulseAnimation;

  const PulsingEffect({
    super.key,
    required this.isDark,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          width: (280 + pulseAnimation.value * 40).w,
          height: (280 + pulseAnimation.value * 40).w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? context.darkGradientEnd : context.primaryColor)
                  .withValues(alpha: 0.3 - pulseAnimation.value * 0.3),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}
