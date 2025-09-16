import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class FeedbackHeroCard extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final ThemeData theme;
  final AppLocalizations l10n;

  const FeedbackHeroCard({
    super.key,
    required this.slideAnimation,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(28.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryDarkColor,
              context.primaryColor,
              context.primaryLightColor,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(35.r),
              ),
              child: Icon(
                Icons.feedback_rounded,
                color: Colors.white,
                size: 35.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.feedbackHeroTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Amiri",
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.feedbackHeroSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
                fontFamily: "Amiri",
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}