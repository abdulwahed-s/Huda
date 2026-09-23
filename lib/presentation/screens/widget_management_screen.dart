import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/widget_management/prayer_widget_tab.dart';
import 'package:huda/presentation/widgets/widget_management/quran_verse_widget_tab.dart';

class WidgetManagementScreen extends StatelessWidget {
  const WidgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          toolbarHeight: 60.h,
          title: Text(
            l10n.homeScreenWidgetManagement,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60.h),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 10.h),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(12.r),
                indicator: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: primary,
                unselectedLabelColor: colorScheme.onPrimary.withValues(
                  alpha: 0.78,
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
                tabs: [
                  _ManagementTab(
                    icon: Icons.menu_book_rounded,
                    label: l10n.quranVerseWidget,
                  ),
                  _ManagementTab(
                    icon: Icons.access_time_rounded,
                    label: l10n.prayerTimesWidget,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            QuranVerseWidgetTab(isDark: isDark),
            PrayerWidgetTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _ManagementTab extends StatelessWidget {
  const _ManagementTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Tab(
    height: 48.h,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18.sp),
        SizedBox(width: 7.w),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
