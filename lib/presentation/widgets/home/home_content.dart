import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/continue_reading_card.dart';
import 'package:huda/presentation/widgets/home/feature_grid.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/utils/responsive_utils.dart';

class HomeContent extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback refreshHomeData;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final bool isDarkMode;

  const HomeContent({
    super.key,
    required this.animationController,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.refreshHomeData,
    required this.openLastReadSurah,
    required this.isDarkMode,
  });

  List<FeatureItem> _getFeatures(BuildContext context) {
    return [
      FeatureItem(
        title: AppLocalizations.of(context)!.quran,
        svgAsset: 'assets/images/quranicon.svg',
        onTap: () async {
          await Navigator.pushNamed(context, '/homeQuran');
          refreshHomeData();
        },
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.prayerTimes,
        svgAsset: 'assets/images/prayertimeicon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.prayerTimes),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.hadith,
        svgAsset: 'assets/images/hadithsicon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.hadith),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.athkar,
        svgAsset: 'assets/images/athkaricon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.athkar),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.hijriCalendar,
        svgAsset: 'assets/images/hijricalendaricon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.hijriCalendar),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.books,
        svgAsset: 'assets/images/booksicon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.books),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.hudaAI,
        icon: Icons.auto_awesome,
        onTap: () => Navigator.pushNamed(context, AppRoute.hudaAI),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.islamicChecklist,
        icon: Icons.checklist,
        onTap: () => Navigator.pushNamed(context, AppRoute.islamicChecklist),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.qiblahDirection,
        svgAsset: 'assets/images/qiblahicon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.qiblah),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.notifications,
        icon: Icons.notifications,
        onTap: () => Navigator.pushNamed(context, AppRoute.notification),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.zakatCalculator,
        svgAsset: 'assets/images/zakat.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.zakatCalculator),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.tasbih,
        svgAsset: 'assets/images/tasbihicon.svg',
        onTap: () => Navigator.pushNamed(context, AppRoute.tasbih),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.bookmarks,
        icon: Icons.bookmark,
        onTap: () => Navigator.pushNamed(context, AppRoute.bookmarks),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.settings,
        icon: Icons.settings,
        onTap: () => Navigator.pushNamed(context, AppRoute.settings),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.widgetManagement,
        icon: Icons.widgets,
        onTap: () => Navigator.pushNamed(context, AppRoute.widgetManagement),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, homeState) {
                        final HomeLoaded? loaded =
                            homeState is HomeLoaded ? homeState : null;
                        final bool hasLastRead =
                            loaded?.hasLastReadPosition ?? false;
                        final VoidCallback? onTap = hasLastRead
                            ? () => openLastReadSurah(loaded!.lastReadSummary!)
                            : null;

                        return ContinueReadingCard(
                          hasLastRead: hasLastRead,
                          onTap: onTap,
                          continueText:
                              AppLocalizations.of(context)!.continueHome,
                          noActivityText: AppLocalizations.of(context)!
                              .noRecentActivityHome,
                          resumeText:
                              AppLocalizations.of(context)!.resumeReading,
                          noActivityDescription: AppLocalizations.of(context)!
                              .noRecentActivityDescription,
                        );
                      },
                    ),
                    SizedBox(
                      height: context.responsive(
                        mobile: 16.h,
                        tablet: 20.h,
                        desktop: 24.h,
                      ),
                    ),
                    FeatureGrid(
                      isDarkMode: isDarkMode,
                      features: _getFeatures(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
