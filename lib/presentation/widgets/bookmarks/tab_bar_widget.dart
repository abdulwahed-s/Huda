import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class TabBarWidget extends StatelessWidget {
  final bool isDark;
  final TabController tabController;

  const TabBarWidget({
    super.key,
    required this.isDark,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark
            ? appColors.darkCardBackground
            : appColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: appColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[600] : Colors.grey[600],
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          fontFamily: 'Amiri',
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
          fontFamily: 'Amiri',
        ),
        indicator: BoxDecoration(
          color: appColors.primary,
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorPadding: EdgeInsets.all(4.w),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Tooltip(
                message: AppLocalizations.of(context)!.all,
                child: Icon(Icons.apps_rounded, size: 20.r),
              ),
            ),
          ),
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Tooltip(
                message: AppLocalizations.of(context)!.bookmarks,
                child: Icon(Icons.bookmark_rounded, size: 20.r),
              ),
            ),
          ),
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Tooltip(
                message: AppLocalizations.of(context)!.notes,
                child: Icon(Icons.sticky_note_2_rounded, size: 20.r),
              ),
            ),
          ),
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Tooltip(
                message: AppLocalizations.of(context)!.stars,
                child: Icon(Icons.star_rounded, size: 20.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

