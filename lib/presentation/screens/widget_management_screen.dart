import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/widget_management/prayer_widget_tab.dart';
import 'package:huda/presentation/widgets/widget_management/quran_verse_widget_tab.dart';

class WidgetManagementScreen extends StatelessWidget {
  const WidgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            l10n.homeScreenWidgetManagement,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.h),
            child: Container(
              color: primary,
              child: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.menu_book_rounded),
                    text: l10n.quranVerseWidget,
                  ),
                  Tab(
                    icon: const Icon(Icons.access_time_rounded),
                    text: l10n.prayerTimesWidget,
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
