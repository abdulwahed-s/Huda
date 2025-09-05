import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/onboarding_data.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_indicator.dart';

class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final List<OnboardingData> onboardingPages;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onboardingPages,
    required this.onPreviousPressed,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageIndicators(context),
          SizedBox(height: 24.h),
          _buildNavigationButtons(context),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => OnboardingIndicator(
          isActive: index == currentPage,
          data: onboardingPages[index],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      children: [
        if (currentPage > 0) _buildPreviousButton(context),
        if (currentPage > 0) SizedBox(width: 16.w),
        _buildNextButton(context),
      ],
    );
  }

  Widget _buildPreviousButton(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: onboardingPages[currentPage]
                .primaryColor
                .withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: TextButton(
          onPressed: onPreviousPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios_rounded,
                size: 16.sp,
                color: onboardingPages[currentPage].primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.previous,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: onboardingPages[currentPage].primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              onboardingPages[currentPage].primaryColor,
              onboardingPages[currentPage].secondaryColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: onboardingPages[currentPage]
                  .primaryColor
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onNextPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentPage == totalPages - 1
                    ? AppLocalizations.of(context)!.getStarted
                    : AppLocalizations.of(context)!.next,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                currentPage == totalPages - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
