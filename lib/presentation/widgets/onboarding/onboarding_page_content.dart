import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/onboarding_data.dart';

class OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPageContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = context.responsive(
      mobile: 240.w,
      tablet: 280.0,
      desktop: 300.0,
    );
    final iconSize = context.responsive(
      mobile: 60.sp,
      tablet: 72.0,
      desktop: 80.0,
    );
    final titleFontSize = context.responsive(
      mobile: 26.sp,
      tablet: 30.0,
      desktop: 32.0,
    );
    final descFontSize = context.responsive(
      mobile: 14.sp,
      tablet: 16.0,
      desktop: 18.0,
    );
    final descMaxWidth = context.responsive(
      mobile: 280.w,
      tablet: 420.0,
      desktop: 460.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            context.responsive(mobile: 24.w, tablet: 32.0, desktop: 32.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.primaryColor.withValues(alpha: 0.15),
                          data.secondaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: data.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            context.responsive(
                                mobile: 18.w, tablet: 22.0, desktop: 24.0),
                          ),
                          decoration: BoxDecoration(
                            color: data.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.icon,
                            size: iconSize,
                            color: data.primaryColor,
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24.h),
          _buildAnimatedTitle(context, data.title, titleFontSize),
          SizedBox(height: 8.h),
          _buildAnimatedDescription(
              context, data.description, descFontSize, descMaxWidth),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle(
      BuildContext context, String title, double fontSize) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDescription(BuildContext context, String description,
      double fontSize, double maxWidth) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}
