import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class TranslationSection extends StatelessWidget {
  final String translatedText;
  final ColorScheme colorScheme;

  const TranslationSection({
    super.key,
    required this.translatedText,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.translate,
                  color: colorScheme.primary,
                  size: 16.w,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.translation,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            translatedText,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15.sp,
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
