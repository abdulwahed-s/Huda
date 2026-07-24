import 'package:flutter/material.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';

List<Widget> buildConfiguredSections({
  required HomeThemeConfiguration configuration,
  required HomeLoaded data,
  required bool isDark,
  required HomeDashboardActions actions,
  bool compact = false,
}) {
  final result = <Widget>[];
  for (final section in configuration.orderedSections) {
    if (configuration.hiddenSections.contains(section)) continue;
    final widget = switch (section) {
      HomeSectionId.dateAndPrayer =>
        HomeDatePrayerSection(isDark: isDark, compact: compact),
      HomeSectionId.prayerSchedule =>
        HomePrayerScheduleSection(isDark: isDark, compact: compact),
      HomeSectionId.dailyAyah => HomeDailyAyahSection(
          ayah: data.dailyAyah,
          isDark: isDark,
          onTap: () => actions.openSurah(
            data.dailyAyah.surahNumber,
            data.dailyAyah.ayahNumber,
          ),
        ),
      HomeSectionId.continueReading => HomeContinueReadingSection(
          data: data,
          isDark: isDark,
          compact: compact,
          onTap: () {
            final summary = data.lastReadSummary;
            if (summary == null) return;
            actions.openSurah(
              summary['surahNumber'] as int,
              summary['ayahNumber'] as int? ?? 1,
            );
          },
        ),
      HomeSectionId.khatmaProgress => HomeKhatmaSection(
          khatma: data.khatma,
          isDark: isDark,
          onTap: () {
            final khatma = data.khatma;
            if (khatma.isActive &&
                khatma.startSurah != null &&
                khatma.startAyah != null) {
              actions.openSurah(khatma.startSurah!, khatma.startAyah!);
            } else {
              actions.openQuran();
            }
          },
        ),
      HomeSectionId.quranTools =>
        HomeQuranToolsSection(isDark: isDark, actions: actions),
    };
    result.add(KeyedSubtree(key: ValueKey(section), child: widget));
  }
  return result;
}
