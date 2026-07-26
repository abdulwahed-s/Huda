import 'package:flutter/material.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';

String homeThemeName(BuildContext context, HomeThemeId theme) {
  final l10n = AppLocalizations.of(context)!;
  return switch (theme) {
    HomeThemeId.classic => l10n.themeClassic,
    HomeThemeId.prayerToday => l10n.themePrayerToday,
    HomeThemeId.quranJourney => l10n.themeQuranJourney,
  };
}

String homeThemeDescription(BuildContext context, HomeThemeId theme) {
  final l10n = AppLocalizations.of(context)!;
  return switch (theme) {
    HomeThemeId.classic => l10n.themeClassicDescription,
    HomeThemeId.prayerToday => l10n.themePrayerTodayDescription,
    HomeThemeId.quranJourney => l10n.themeQuranJourneyDescription,
  };
}

IconData homeThemeIcon(HomeThemeId theme) => switch (theme) {
      HomeThemeId.classic => Icons.grid_view_rounded,
      HomeThemeId.prayerToday => Icons.mosque_rounded,
      HomeThemeId.quranJourney => Icons.auto_stories_rounded,
    };

String homeSectionName(BuildContext context, HomeSectionId section) {
  final l10n = AppLocalizations.of(context)!;
  return switch (section) {
    HomeSectionId.dateAndPrayer => l10n.sectionDateAndPrayer,
    HomeSectionId.prayerSchedule => l10n.sectionPrayerSchedule,
    HomeSectionId.dailyAyah => l10n.sectionDailyAyah,
    HomeSectionId.continueReading => l10n.sectionContinueReading,
    HomeSectionId.khatmaProgress => l10n.sectionKhatmaProgress,
    HomeSectionId.quranTools => l10n.sectionQuranTools,
  };
}

IconData homeSectionIcon(HomeSectionId section) => switch (section) {
      HomeSectionId.dateAndPrayer => Icons.today_rounded,
      HomeSectionId.prayerSchedule => Icons.schedule_rounded,
      HomeSectionId.dailyAyah => Icons.format_quote_rounded,
      HomeSectionId.continueReading => Icons.menu_book_rounded,
      HomeSectionId.khatmaProgress => Icons.donut_large_rounded,
      HomeSectionId.quranTools => Icons.auto_stories_rounded,
    };
