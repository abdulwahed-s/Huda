import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class FeedbackPrivacyCard extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final AppLocalizations l10n;
  final Color textColor;
  final Color subtitleColor;

  const FeedbackPrivacyCard({
    super.key,
    required this.slideAnimation,
    required this.l10n,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: context.primaryExtraLightColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.primaryLightColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.privacy_tip_rounded,
                color: context.primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedbackPrivacyTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: "Amiri",
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.feedbackPrivacyDescription,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: subtitleColor,
                      height: 1.4,
                      fontFamily: "Amiri",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}