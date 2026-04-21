import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/onboarding_data.dart';
import 'package:huda/l10n/app_localizations.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final OnboardingData currentPageData;
  final VoidCallback onSkipPressed;

  const OnboardingTopBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.currentPageData,
    required this.onSkipPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        context.responsive(mobile: 20.w, tablet: 20.0, desktop: 20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  context.responsive(mobile: 12.w, tablet: 14.0, desktop: 14.0),
              vertical:
                  context.responsive(mobile: 6.h, tablet: 8.0, desktop: 8.0),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  currentPageData.primaryColor.withValues(alpha: 0.1),
                  currentPageData.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: currentPageData.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: context.responsive(
                    mobile: 13.sp, tablet: 15.0, desktop: 15.0),
                color: currentPageData.primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildSkipButton(context),
        ],
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSkipPressed,
          borderRadius: BorderRadius.circular(25.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  context.responsive(mobile: 18.w, tablet: 20.0, desktop: 20.0),
              vertical:
                  context.responsive(mobile: 10.h, tablet: 12.0, desktop: 12.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.skip,
                  style: TextStyle(
                    fontSize: context.responsive(
                        mobile: 13.sp, tablet: 15.0, desktop: 15.0),
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: context.responsive(
                      mobile: 14.sp, tablet: 16.0, desktop: 16.0),
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
