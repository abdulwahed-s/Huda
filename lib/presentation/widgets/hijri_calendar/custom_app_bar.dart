import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final bool isTablet;
  final VoidCallback onTodayPressed;
  final VoidCallback onAdjustmentPressed;

  const CustomAppBar({
    super.key,
    required this.isDark,
    required this.isTablet,
    required this.onTodayPressed,
    required this.onAdjustmentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.primaryColor,
      toolbarHeight: isTablet ? 80 : kToolbarHeight,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: isTablet ? 32 : 20.w,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 10.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.hijriCalendar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 24 : 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          key: const ValueKey('hijri-adjustment-action'),
          tooltip: AppLocalizations.of(context)!.hijriAdjustmentAction,
          onPressed: onAdjustmentPressed,
          icon: Container(
            padding: EdgeInsets.all(isTablet ? 12 : 6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: isTablet ? 28 : 18.w,
            ),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.today,
          onPressed: onTodayPressed,
          icon: Container(
            padding: EdgeInsets.all(isTablet ? 12 : 6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.today,
              color: Colors.white,
              size: isTablet ? 28 : 18.w,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 6.w),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isTablet ? 80 : kToolbarHeight);
}
