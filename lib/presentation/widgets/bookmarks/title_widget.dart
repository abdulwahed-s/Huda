import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class TitleWidget extends StatelessWidget {
  final bool isDark;

  const TitleWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: appColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.bookmark_border,
            size: 24.r,
            color: appColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          AppLocalizations.of(context)!.myBookmarks,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? appColors.darkText : appColors.lightText,
            fontFamily: 'Amiri',
          ),
        ),
      ],
    );
  }
}
