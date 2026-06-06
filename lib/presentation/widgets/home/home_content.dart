import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/feature_grid.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';
import 'package:huda/presentation/widgets/home/special_event_dialog.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/core/routes/app_route.dart';

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
        title: AppLocalizations.of(context)!.prayerTimes,
        svgAsset: 'assets/images/prayertimeicon.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.prayerTimes),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.hadith,
        svgAsset: 'assets/images/hadithsicon.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.hadith),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.athkar,
        svgAsset: 'assets/images/athkaricon.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.athkar),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.hijriCalendar,
        svgAsset: 'assets/images/hijricalendaricon.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.hijriCalendar),
      ),
      if (PlatformUtils.isMobile)
        FeatureItem(
          title: AppLocalizations.of(context)!.miqaatLock,
          svgAsset: 'assets/images/miqaatlock.svg.vec',
          onTap: () => Navigator.pushNamed(context, AppRoute.miqaatLock),
        ),
      FeatureItem(
        title: AppLocalizations.of(context)!.books,
        svgAsset: 'assets/images/booksicon.svg.vec',
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
      if (PlatformUtils.isMobile)
        FeatureItem(
          title: AppLocalizations.of(context)!.qiblahDirection,
          svgAsset: 'assets/images/qiblahicon.svg.vec',
          onTap: () => Navigator.pushNamed(context, AppRoute.qiblah),
        ),
      if (!kIsWeb && !PlatformUtils.isLinux)
        FeatureItem(
          title: AppLocalizations.of(context)!.notifications,
          icon: Icons.notifications,
          onTap: () => Navigator.pushNamed(context, AppRoute.notification),
        ),
      FeatureItem(
        title: AppLocalizations.of(context)!.ramadan,
        svgAsset: 'assets/images/ramadan.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.ramadan),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.zakatCalculator,
        svgAsset: 'assets/images/zakat.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.zakatCalculator),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.tasbih,
        svgAsset: 'assets/images/tasbihicon.svg.vec',
        onTap: () => Navigator.pushNamed(context, AppRoute.tasbih),
      ),
      FeatureItem(
        title: AppLocalizations.of(context)!.settings,
        icon: Icons.settings,
        onTap: () => Navigator.pushNamed(context, AppRoute.settings),
      ),
      if (PlatformUtils.isMobile)
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
                    BlocBuilder<IslamicEventCubit, IslamicEventState>(
                      builder: (context, eventState) {
                        if (eventState is! IslamicEventActive) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: context.responsive(
                              mobile: 16.h,
                              tablet: 20.h,
                              desktop: 24.h,
                            ),
                          ),
                          child: SpecialEventCard(
                            event: eventState.event,
                            isDarkMode: isDarkMode,
                            onTap: () => showSpecialEventDialog(
                              context,
                              eventState.event.eventKey,
                              isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                    FeatureGrid(
                      isDarkMode: isDarkMode,
                      features: _getFeatures(context),
                      openLastReadSurah: openLastReadSurah,
                      quranStackCard: QuranFeatureStackCard(
                        isDarkMode: isDarkMode,
                        index: 0,
                        stackLabel: AppLocalizations.of(context)!.quranKit,
                        quranLabel: AppLocalizations.of(context)!.quran,
                        audioLabel: AppLocalizations.of(context)!.quranAudio,
                        radioLabel: AppLocalizations.of(context)!.quranRadio,
                        bookmarkLabel: AppLocalizations.of(context)!.bookmarks,
                        onQuranTap: () async {
                          await Navigator.pushNamed(context, '/homeQuran');
                          refreshHomeData();
                        },
                        onAudioTap: () =>
                            Navigator.pushNamed(context, AppRoute.quranAudio),
                        onRadioTap: () =>
                            Navigator.pushNamed(context, AppRoute.quranRadio),
                        onBookmarkTap: () =>
                            Navigator.pushNamed(context, AppRoute.bookmarks),
                      ),
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
