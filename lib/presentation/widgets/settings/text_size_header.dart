import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class TextSizeHeader extends StatelessWidget {
  final bool isDark;

  const TextSizeHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.format_size_rounded,
            color: context.primaryColor,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.textSize,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Amiri",
                  color: isDark ? context.darkText : context.lightText,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                AppLocalizations.of(context)!
                    .adjustTextSizeForBetterReadability,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: "Amiri",
                  color: isDark
                      ? context.darkText.withValues(alpha: 0.7)
                      : context.lightText.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

