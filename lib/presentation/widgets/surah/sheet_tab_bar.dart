import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/platform_utils.dart';

class SurahSheetTabBar extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final String surahsLabel;
  final String khatmaLabel;
  final String settingsLabel;
  final String memorizationLabel;

  const SurahSheetTabBar({
    super.key,
    required this.isDark,
    required this.accent,
    required this.surahsLabel,
    required this.khatmaLabel,
    required this.settingsLabel,
    required this.memorizationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 6.h),
          child: TabBar(
            labelColor: accent,
            unselectedLabelColor: isDark ? Colors.white30 : Colors.black38,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: isDark ? 0.22 : 0.14),
                  accent.withValues(alpha: isDark ? 0.12 : 0.07),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.30 : 0.20),
                width: 1,
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
            labelStyle: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 20.sp),
                text: surahsLabel,
              ),
              Tab(
                icon: Icon(Icons.auto_stories_rounded, size: 20.sp),
                text: khatmaLabel,
              ),
              Tab(
                icon: Icon(Icons.tune_rounded, size: 20.sp),
                text: settingsLabel,
              ),
              if (!PlatformUtils.isLinux)
                Tab(
                  icon: Icon(Icons.psychology_rounded, size: 20.sp),
                  text: memorizationLabel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
