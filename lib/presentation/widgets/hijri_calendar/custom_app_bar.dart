import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback onTodayPressed;

  const CustomAppBar({
    super.key,
    required this.isDark,
    required this.onTodayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.primaryColor,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20.w,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            AppLocalizations.of(context)!.hijriCalendar,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "Amiri",
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onTodayPressed,
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.today, color: Colors.white, size: 18.w),
          ),
        ),
        SizedBox(width: 6.w),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
