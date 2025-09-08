import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class HeaderBanner extends StatelessWidget {
  final bool isDark;

  const HeaderBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.0.w),
      padding: EdgeInsets.all(20.0.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories,
            size: 32.sp,
            color: context.primaryColor,
          ),
          SizedBox(height: 12.0.h),
          Text(
            AppLocalizations.of(context)!.hadithCollections,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
              fontFamily: 'Amiri',
            ),
          ),
          SizedBox(height: 8.0.h),
          Text(
            AppLocalizations.of(context)!.hadithBanner,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey[600],
              fontFamily: 'Amiri',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

