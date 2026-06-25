import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_progress_rings.dart';
import 'package:huda/presentation/widgets/khatma/khatma_icon_list_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_legend_item.dart';
import 'package:huda/presentation/widgets/khatma/khatma_reminder_section.dart';
import 'package:huda/presentation/widgets/khatma/khatma_stat_item.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaActiveView extends StatelessWidget {
  final TextDirection textDirection;
  final int dayIndex;
  final int planDays;
  final double percentTotal;
  final double percentDaily;
  final double percentPacing;
  final int daysRemaining;
  final int totalPagesRead;
  final int pagesRemaining;
  final String relativeDay;
  final String startSurahLabel;
  final String endSurahLabel;
  final String yesterdayLabel;
  final bool reminderEnabled;
  final String formattedReminderTime;
  final VoidCallback onMarkDone;
  final VoidCallback onAllWirds;
  final VoidCallback onDelete;
  final VoidCallback onNavigateToStart;
  final VoidCallback onNavigateToEnd;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onPickReminderTime;

  const KhatmaActiveView({
    super.key,
    required this.textDirection,
    required this.dayIndex,
    required this.planDays,
    required this.percentTotal,
    required this.percentDaily,
    required this.percentPacing,
    required this.daysRemaining,
    required this.totalPagesRead,
    required this.pagesRemaining,
    required this.relativeDay,
    required this.startSurahLabel,
    required this.endSurahLabel,
    required this.yesterdayLabel,
    required this.reminderEnabled,
    required this.formattedReminderTime,
    required this.onMarkDone,
    required this.onAllWirds,
    required this.onDelete,
    required this.onNavigateToStart,
    required this.onNavigateToEnd,
    required this.onToggleReminder,
    required this.onPickReminderTime,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: textDirection,
      child: ListView(
        padding: EdgeInsets.only(
          top: 6.h,
          bottom: 18.h + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          KhatmaTopTitle(
            title: l10n.khatmaStatsTitle,
            textDirection: textDirection,
          ),
          _ProgressBanner(
            dayIndex: dayIndex,
            planDays: planDays,
            percentTotal: percentTotal,
            accent: accent,
          ),
          SizedBox(height: 4.h),
          _ConcentricRingsCard(
            percentTotal: percentTotal,
            percentDaily: percentDaily,
            percentPacing: percentPacing,
            daysRemaining: daysRemaining,
            totalPagesRead: totalPagesRead,
            pagesRemaining: pagesRemaining,
            accent: accent,
          ),
          SizedBox(height: 16.h),
          _TodayWirdHeader(
            dayIndex: dayIndex,
            relativeDay: relativeDay,
            accent: accent,
          ),
          _TodayWirdCard(
            startSurahLabel: startSurahLabel,
            endSurahLabel: endSurahLabel,
            yesterdayLabel: yesterdayLabel,
            accent: accent,
            onMarkDone: onMarkDone,
            onNavigateToStart: onNavigateToStart,
            onNavigateToEnd: onNavigateToEnd,
          ),
          SizedBox(height: 10.h),
          KhatmaReminderSection(
            reminderEnabled: reminderEnabled,
            formattedTime: formattedReminderTime,
            textDirection: textDirection,
            onToggleReminder: onToggleReminder,
            onPickTime: onPickReminderTime,
          ),
          SizedBox(height: 10.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaIconListTile(
                  icon: Icons.format_list_numbered_rounded,
                  iconColor: Colors.indigo,
                  title: l10n.khatmaAllWirds,
                  subtitle: l10n.khatmaViewAllWirds,
                  textDirection: textDirection,
                  onTap: onAllWirds,
                ),
                Divider(height: 1, indent: 62.w),
                KhatmaIconListTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.red,
                  title: l10n.khatmaDeleteTitle,
                  subtitle: l10n.khatmaDeleteSubtitle,
                  textDirection: textDirection,
                  titleColor: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int dayIndex;
  final int planDays;
  final double percentTotal;
  final Color accent;

  const _ProgressBanner({
    required this.dayIndex,
    required this.planDays,
    required this.percentTotal,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0.6)
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.khatmaDayOf(dayIndex, planDays),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: percentTotal,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              '${(percentTotal * 100).toInt()}%',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentricRingsCard extends StatelessWidget {
  final double percentTotal;
  final double percentDaily;
  final double percentPacing;
  final int daysRemaining;
  final int totalPagesRead;
  final int pagesRemaining;
  final Color accent;

  const _ConcentricRingsCard({
    required this.percentTotal,
    required this.percentDaily,
    required this.percentPacing,
    required this.daysRemaining,
    required this.totalPagesRead,
    required this.pagesRemaining,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return KhatmaCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
        child: Column(
          children: [
            KhatmaProgressRings(
              percentTotal: percentTotal,
              percentDaily: percentDaily,
              percentPacing: percentPacing,
              isDark: isDark,
              centerText: '${(percentTotal * 100).toInt()}%',
            ),
            SizedBox(height: 20.h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14.w,
              runSpacing: 8.h,
              children: [
                KhatmaLegendItem(
                    color: Colors.green,
                    label: l10n.khatmaLegendKhatma,
                    value: '${(percentTotal * 100).toInt()}%'),
                KhatmaLegendItem(
                    color: Colors.deepOrange,
                    label: l10n.today,
                    value: percentDaily >= 1.0
                        ? l10n.khatmaWirdCompleted
                        : l10n.khatmaWirdInProgress),
                KhatmaLegendItem(
                    color: Colors.blue,
                    label: l10n.khatmaCommitment,
                    value: '${(percentPacing * 100).toInt()}%'),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KhatmaStatItem(
                    title: l10n.khatmaDaysRemaining,
                    value: '$daysRemaining',
                    icon: Icons.calendar_today_rounded),
                Container(
                    width: 1,
                    height: 44.h,
                    color: isDark ? Colors.white10 : Colors.black12),
                KhatmaStatItem(
                    title: l10n.khatmaPagesRead,
                    value: '$totalPagesRead',
                    icon: Icons.menu_book_rounded),
                Container(
                    width: 1,
                    height: 44.h,
                    color: isDark ? Colors.white10 : Colors.black12),
                KhatmaStatItem(
                    title: l10n.khatmaPagesRemaining,
                    value: '$pagesRemaining',
                    color: accent,
                    icon: Icons.hourglass_bottom_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayWirdHeader extends StatelessWidget {
  final int dayIndex;
  final String relativeDay;
  final Color accent;

  const _TodayWirdHeader({
    required this.dayIndex,
    required this.relativeDay,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded, size: 13.sp, color: accent),
                SizedBox(width: 4.w),
                Text(
                  l10n.khatmaDailyWirdOf(dayIndex + 1),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                      color: accent),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            relativeDay,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayWirdCard extends StatelessWidget {
  final String startSurahLabel;
  final String endSurahLabel;
  final String yesterdayLabel;
  final Color accent;
  final VoidCallback onMarkDone;
  final VoidCallback onNavigateToStart;
  final VoidCallback onNavigateToEnd;

  const _TodayWirdCard({
    required this.startSurahLabel,
    required this.endSurahLabel,
    required this.yesterdayLabel,
    required this.accent,
    required this.onMarkDone,
    required this.onNavigateToStart,
    required this.onNavigateToEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return KhatmaCard(
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onNavigateToStart,
                  borderRadius: BorderRadius.circular(4.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                    child: Text(
                      startSurahLabel,
                      style: TextStyle(
                        height: 1.5,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onNavigateToEnd,
                  borderRadius: BorderRadius.circular(4.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                    child: Text(
                      endSurahLabel,
                      style: TextStyle(
                        height: 1.5,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              yesterdayLabel,
              style: TextStyle(
                height: 1.5,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? context.primaryColor : context.primaryDarkColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: onMarkDone,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  l10n.khatmaMarkDone,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
