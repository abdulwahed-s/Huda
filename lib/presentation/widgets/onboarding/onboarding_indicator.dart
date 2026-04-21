import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/onboarding_data.dart';

class OnboardingIndicator extends StatelessWidget {
  final bool isActive;
  final OnboardingData data;

  const OnboardingIndicator({
    super.key,
    required this.isActive,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
            horizontal:
                context.responsive(mobile: 6.w, tablet: 4.0, desktop: 4.0),
          ),
          height: context.responsive(mobile: 8.h, tablet: 8.0, desktop: 8.0),
          width: isActive
              ? context.responsive(mobile: 32.w, tablet: 28.0, desktop: 28.0)
              : context.responsive(mobile: 8.w, tablet: 8.0, desktop: 8.0),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      data.primaryColor,
                      data.secondaryColor,
                    ],
                  )
                : null,
            color: isActive ? null : data.primaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: data.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
