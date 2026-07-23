import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_theme_renderer.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.animationController,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.refreshHomeData,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.openSurah,
    required this.onCustomize,
    required this.isDarkMode,
  });

  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback refreshHomeData;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final void Function(int surah, int ayah) openSurah;
  final VoidCallback onCustomize;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    Widget defaultEntrance(Widget child) {
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    }

    return SliverToBoxAdapter(
      child: BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
        builder: (context, customizationState) {
          if (customizationState is! HomeCustomizationReady) {
            return defaultEntrance(
              Padding(
                padding: EdgeInsets.all(20.w),
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final actions = HomeDashboardActions(
            openQuran: () async {
              await Navigator.pushNamed(context, AppRoute.homeQuran);
              refreshHomeData();
            },
            openPrayerTimes: () =>
                Navigator.pushNamed(context, AppRoute.prayerTimes),
            openAudio: () => Navigator.pushNamed(context, AppRoute.quranAudio),
            openRadio: () async {
              await Navigator.pushNamed(context, AppRoute.quranRadio);
              if (context.mounted) {
                await context.read<QuranRadioCubit>().saveCurrentStation();
                refreshHomeData();
              }
            },
            openBookmarks: () =>
                Navigator.pushNamed(context, AppRoute.bookmarks),
            openSurah: openSurah,
          );
          final featureActions = HomeFeatureActions(
            openQuran: actions.openQuran,
            openQuranKit: () => _showQuranKit(context, actions),
          );
          final preferences = customizationState.preferences;
          final prayerToday =
              preferences.selectedTheme == HomeThemeId.prayerToday;
          final quranJourney =
              preferences.selectedTheme == HomeThemeId.quranJourney;
          final focusedTheme = preferences.selectedTheme != HomeThemeId.classic;
          final content = Padding(
            padding: prayerToday || quranJourney
                ? EdgeInsets.only(bottom: 20.h)
                : EdgeInsets.all(20.w),
            child: HomeThemeRenderer(
              theme: preferences.selectedTheme,
              configuration:
                  preferences.configurationFor(preferences.selectedTheme),
              features: HomeFeatureCatalog.available(context, featureActions),
              actions: actions,
              isDark: isDarkMode,
              openLastReadSurah: openLastReadSurah,
              openLastReciterAudio: openLastReciterAudio,
              openLastRadioStation: openLastRadioStation,
              onRetry: refreshHomeData,
              onCustomize: onCustomize,
            ),
          );
          return focusedTheme ? content : defaultEntrance(content);
        },
      ),
    );
  }

  void _showQuranKit(BuildContext context, HomeDashboardActions actions) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          child: HomeQuranToolsSection(
            isDark: Theme.of(sheetContext).brightness == Brightness.dark,
            actions: actions,
          ),
        ),
      ),
    );
  }
}
