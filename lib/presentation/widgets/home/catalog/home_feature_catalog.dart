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
    this.svgAsset,
    this.icon,
  });

  final HomeFeatureId id;
  final String title;
  final String? svgAsset;
  final IconData? icon;
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
        svgAsset: 'assets/images/quranicon.svg.vec',
        onTap: actions.openQuran,
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.quranKit,
        title: l10n.quranKit,
        svgAsset: 'assets/images/qurancard.svg.vec',
        onTap: actions.openQuranKit,
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.prayerTimes,
        title: l10n.prayerTimes,
        svgAsset: 'assets/images/prayertimeicon.svg.vec',
        onTap: () => route(AppRoute.prayerTimes),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hadith,
        title: l10n.hadith,
        svgAsset: 'assets/images/hadithsicon.svg.vec',
        onTap: () => route(AppRoute.hadith),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.athkar,
        title: l10n.athkar,
        svgAsset: 'assets/images/athkaricon.svg.vec',
        onTap: () => route(AppRoute.athkar),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hijriCalendar,
        title: l10n.hijriCalendar,
        svgAsset: 'assets/images/hijricalendaricon.svg.vec',
        onTap: () => route(AppRoute.hijriCalendar),
      ),
      if (PlatformUtils.isMobile)
        HomeFeatureDefinition(
          id: HomeFeatureId.miqaatLock,
          title: l10n.miqaatLock,
          svgAsset: 'assets/images/miqaatlock.svg.vec',
          onTap: () => route(AppRoute.miqaatLock),
        ),
      HomeFeatureDefinition(
        id: HomeFeatureId.books,
        title: l10n.books,
        svgAsset: 'assets/images/booksicon.svg.vec',
        onTap: () => route(AppRoute.books),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.audios,
        title: l10n.audios,
        svgAsset: 'assets/images/audio.svg.vec',
        onTap: () => route(AppRoute.audios),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.hudaAI,
        title: l10n.hudaAI,
        icon: Icons.auto_awesome,
        onTap: () => route(AppRoute.hudaAI),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.checklist,
        title: l10n.islamicChecklist,
        icon: Icons.checklist,
        onTap: () => route(AppRoute.islamicChecklist),
      ),
      if (PlatformUtils.isMobile)
        HomeFeatureDefinition(
          id: HomeFeatureId.qiblah,
          title: l10n.qiblahDirection,
          svgAsset: 'assets/images/qiblahicon.svg.vec',
          onTap: () => route(AppRoute.qiblah),
        ),
      if (!kIsWeb && !PlatformUtils.isLinux)
        HomeFeatureDefinition(
          id: HomeFeatureId.notifications,
          title: l10n.notifications,
          icon: Icons.notifications,
          onTap: () => route(AppRoute.notification),
        ),
      HomeFeatureDefinition(
        id: HomeFeatureId.ramadan,
        title: l10n.ramadan,
        svgAsset: 'assets/images/ramadan.svg.vec',
        onTap: () => route(AppRoute.ramadan),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.zakat,
        title: l10n.zakatCalculator,
        svgAsset: 'assets/images/zakat.svg.vec',
        onTap: () => route(AppRoute.zakatCalculator),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.tasbih,
        title: l10n.tasbih,
        svgAsset: 'assets/images/tasbihicon.svg.vec',
        onTap: () => route(AppRoute.tasbih),
      ),
      HomeFeatureDefinition(
        id: HomeFeatureId.settings,
        title: l10n.settings,
        icon: Icons.settings,
        onTap: () => route(AppRoute.settings),
      ),
      if (PlatformUtils.isMobile)
        HomeFeatureDefinition(
          id: HomeFeatureId.widgetManagement,
          title: l10n.widgetManagement,
          icon: Icons.widgets,
          onTap: () => route(AppRoute.widgetManagement),
        ),
    ];
  }
}
