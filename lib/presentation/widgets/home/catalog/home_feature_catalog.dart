import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';

class HomeFeatureDefinition {
  const HomeFeatureDefinition({
    required this.id,
    required this.title,
    required this.onTap,
  });

  final HomeFeatureId id;
  final String title;
  final VoidCallback onTap;
}

class HomeFeatureActions {
  const HomeFeatureActions({
    required this.openQuran,
    required this.openQuranKit,
  });

  final VoidCallback openQuran;
  final VoidCallback openQuranKit;
}

class HomeFeatureCatalog {
  const HomeFeatureCatalog._();

  static List<HomeFeatureDefinition> available(
    BuildContext context,
    HomeFeatureActions actions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    void route(String name) => Navigator.pushNamed(context, name);

    return [
      HomeFeatureDefinition(
        id: HomeFeatureId.quran,
        title: l10n.quran,
        onTap: actions.openQuran,
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.quranKit,
        title: l10n.quranKit,
        onTap: actions.openQuranKit,
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.prayerTimes,
        title: l10n.prayerTimes,
        onTap: () => route(AppRoute.prayerTimes),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hadith,
        title: l10n.hadith,
        onTap: () => route(AppRoute.hadith),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.athkar,
        title: l10n.athkar,
        onTap: () => route(AppRoute.athkar),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hijriCalendar,
        title: l10n.hijriCalendar,
        onTap: () => route(AppRoute.hijriCalendar),
      ),
      if (PlatformUtils.isMobile)
        HomeFeatureDefinition(
          id: HomeFeatureId.miqaatLock,
          title: l10n.miqaatLock,
          onTap: () => route(AppRoute.miqaatLock),
        ),
      HomeFeatureDefinition(
        id: HomeFeatureId.books,
        title: l10n.books,
        onTap: () => route(AppRoute.books),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.audios,
        title: l10n.audios,
        onTap: () => route(AppRoute.audios),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hudaAI,
        title: l10n.hudaAI,
        onTap: () => route(AppRoute.hudaAI),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.checklist,
        title: l10n.islamicChecklist,
        onTap: () => route(AppRoute.islamicChecklist),
      ),
      if (PlatformUtils.isMobile)
        HomeFeatureDefinition(
          id: HomeFeatureId.qiblah,
          title: l10n.qiblahDirection,
          onTap: () => route(AppRoute.qiblah),
        ),
      if (!kIsWeb)
        HomeFeatureDefinition(
          id: HomeFeatureId.notifications,
          title: l10n.notifications,
          onTap: () => route(AppRoute.notification),
        ),
      HomeFeatureDefinition(
        id: HomeFeatureId.ramadan,
        title: l10n.ramadan,
        onTap: () => route(AppRoute.ramadan),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.zakat,
        title: l10n.zakatCalculator,
        onTap: () => route(AppRoute.zakatCalculator),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.tasbih,
        title: l10n.tasbih,
        onTap: () => route(AppRoute.tasbih),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.settings,
        title: l10n.settings,
        onTap: () => route(AppRoute.settings),
      ),
      if (PlatformUtils.isMobile || PlatformUtils.isMacOS)
        HomeFeatureDefinition(
          id: HomeFeatureId.widgetManagement,
          title: l10n.widgetManagement,
          onTap: () => route(AppRoute.widgetManagement),
        ),
    ];
  }
}
