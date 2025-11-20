import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class FeedbackFormCard extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final TextEditingController feedbackController;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback submitFeedback;
  final ThemeData theme;
  final AppLocalizations l10n;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final bool isDark;

  const FeedbackFormCard({
    super.key,
    required this.slideAnimation,
    required this.feedbackController,
    required this.focusNode,
    required this.isSubmitting,
    required this.submitFeedback,
    required this.theme,
    required this.l10n,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.feedbackFormTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontFamily: "Amiri",
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.feedbackFormSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
                fontFamily: "Amiri",
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: feedbackController,
              focusNode: focusNode,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.feedbackHintText,
                hintStyle: TextStyle(
                  color: subtitleColor,
                  fontFamily: "Amiri",
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: context.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                counterStyle: TextStyle(
                  color: subtitleColor,
                  fontFamily: "Amiri",
                ),
              ),
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: "Amiri",
                color: textColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                  shadowColor: context.primaryColor.withValues(alpha: 0.3),
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            l10n.feedbackSending,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.feedbackSendButton,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}