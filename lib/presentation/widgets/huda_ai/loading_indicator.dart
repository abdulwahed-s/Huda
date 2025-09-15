import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';

class LoadingIndicator extends StatelessWidget {
  final bool isDark;
  final AppLocalizations appLocalizations;

  const LoadingIndicator({
    super.key,
    required this.isDark,
    required this.appLocalizations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizations.hudaAIThinking,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        !isDark ? Theme.of(context).primaryColor : Colors.white,
                    fontFamily: 'Amiri',
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  appLocalizations.analyzingQuestion,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? context.darkText.withValues(alpha: 0.6)
                        : context.lightText.withValues(alpha: 0.6),
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 20.h,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
