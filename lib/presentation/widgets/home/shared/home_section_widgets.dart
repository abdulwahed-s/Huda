import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/data/models/home/home_dashboard_data.dart';
import 'package:huda/data/models/islamic_event_config.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';
import 'package:huda/presentation/widgets/home/special_event_dialog.dart';
import 'package:huda/presentation/widgets/home/shared/prayer_location_formatter.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'package:intl/intl.dart' as intl;

class HomeDashboardActions {
  const HomeDashboardActions({
    required this.openQuran,
    required this.openPrayerTimes,
    required this.openAudio,
    required this.openRadio,
    required this.openBookmarks,
    required this.openSurah,
  });

  final VoidCallback openQuran;
  final VoidCallback openPrayerTimes;
  final VoidCallback openAudio;
  final VoidCallback openRadio;
  final VoidCallback openBookmarks;
  final void Function(int surah, int ayah) openSurah;
}

abstract final class HomeSpecialEventPreview {
  static const bool enabled = bool.fromEnvironment(
    'HUDA_SPECIAL_EVENT_PREVIEW',
    defaultValue: false,
  );

  static const IslamicEventConfig ramadanFixture = IslamicEventConfig(
    id: 'testing-ramadan',
    eventKey: 'ramadan',
    hijriMonth: 9,
    hijriDayStart: 1,
    hijriDayEnd: 30,
    actionRoute: '',
    iconName: 'nightlight_round',
    priority: 0,
  );
}

typedef ActiveIslamicEventWidgetBuilder = Widget Function(
  BuildContext context,
  IslamicEventPresentation presentation,
  VoidCallback onActivate,
);

class ActiveIslamicEventBuilder extends StatelessWidget {
  const ActiveIslamicEventBuilder({
    super.key,
    required this.isDark,
    required this.builder,
    this.enableVisualTestingFixture = HomeSpecialEventPreview.enabled,
  });

  final bool isDark;
  final ActiveIslamicEventWidgetBuilder builder;
  final bool enableVisualTestingFixture;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IslamicEventCubit, IslamicEventState>(
      builder: (context, state) {
        final event = switch (state) {
          IslamicEventActive(:final event) => event,
          _ when enableVisualTestingFixture =>
            HomeSpecialEventPreview.ramadanFixture,
          _ => null,
        };
        final child = event == null
            ? const SizedBox.shrink(
                key: ValueKey('no-active-islamic-event'),
              )
            : KeyedSubtree(
                key: ValueKey('active-islamic-event-${event.id}'),
                child: Builder(
                  builder: (eventContext) {
                    final presentation = IslamicEventPresentation.resolve(
                      eventContext,
                      event: event,
                      isDark: isDark,
                    );
                    return builder(
                      eventContext,
                      presentation,
                      () {
                        HapticFeedback.lightImpact();
                        showSpecialEventDialog(
                          eventContext,
                          event.eventKey,
                          isDark,
                        );
                      },
                    );
                  },
                ),
              );

        if (MediaQuery.disableAnimationsOf(context)) {
          return SizedBox(
            key: const ValueKey('active-islamic-event-boundary'),
            child: child,
          );
        }

        return AnimatedSize(
          key: const ValueKey('active-islamic-event-boundary'),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 210),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => AnimatedBuilder(
                animation: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
                builder: (context, transitionedChild) {
                  final exiting = animation.status == AnimationStatus.reverse;
                  return IgnorePointer(
                    ignoring: exiting,
                    child: ExcludeSemantics(
                      excluding: exiting,
                      child: transitionedChild!,
                    ),
                  );
                },
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class HomeSpecialEventSection extends StatelessWidget {
  const HomeSpecialEventSection({
    super.key,
    required this.isDark,
    this.compact = false,
    this.margin,
    this.enableVisualTestingFixture = HomeSpecialEventPreview.enabled,
  });

  final bool isDark;
  final bool compact;
  final EdgeInsetsGeometry? margin;
  final bool enableVisualTestingFixture;

  @override
  Widget build(BuildContext context) {
    return ActiveIslamicEventBuilder(
      isDark: isDark,
      enableVisualTestingFixture: enableVisualTestingFixture,
      builder: (context, presentation, onActivate) {
        final card = SpecialEventCard(
          event: presentation.event,
          isDarkMode: isDark,
          onTap: onActivate,
        );
        return Padding(
          padding: margin ?? EdgeInsets.only(bottom: compact ? 10.h : 18.h),
          child: compact
              ? MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(context).scale(1) * 0.9,
                    ),
                  ),
                  child: card,
                )
              : card,
        );
      },
    );
  }
}

class HomeQuranKitFeatureCard extends StatelessWidget {
  const HomeQuranKitFeatureCard({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      expanded: expanded,
      label: l10n.quranKit,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color:
                context.primaryColor.withValues(alpha: expanded ? 0.34 : 0.16),
            width: expanded ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            child: Row(
              children: [
                _InlineQuranKitStack(expanded: expanded, compact: true),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    l10n.quranKit,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.expand_more,
                    size: 19.sp,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeExpandedQuranWorkspace extends StatelessWidget {
  const HomeExpandedQuranWorkspace({
    super.key,
    required this.isDark,
    required this.actions,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    this.showHeader = true,
  });

  final bool isDark;
  final HomeDashboardActions actions;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              const _InlineQuranKitStack(expanded: true, compact: true),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  l10n.quranKit,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
        ],
        QuranExpandedSubGrid(
          isDarkMode: isDark,
          quranLabel: l10n.quran,
          audioLabel: l10n.quranAudio,
          radioLabel: l10n.quranRadio,
          bookmarkLabel: l10n.bookmarks,
          onQuranTap: actions.openQuran,
          onAudioTap: actions.openAudio,
          onRadioTap: actions.openRadio,
          onBookmarkTap: actions.openBookmarks,
          openLastReadSurah: openLastReadSurah,
          openLastReciterAudio: openLastReciterAudio,
          openLastRadioStation: openLastRadioStation,
        ),
      ],
    );
  }
}

class HomeQuranJourneyWorkspace extends StatelessWidget {
  const HomeQuranJourneyWorkspace({
    super.key,
    required this.data,
    required this.isDark,
    required this.actions,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
  });

  final HomeLoaded data;
  final bool isDark;
  final HomeDashboardActions actions;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final summary = data.lastReadSummary;
    final hasRead = data.hasLastReadPosition && summary != null;
    final locale = Localizations.localeOf(context).languageCode;
    final surah = hasRead ? summary['surahNumber'] as int : null;
    final ayah = hasRead ? summary['ayahNumber'] as int? ?? 1 : null;
    final audio = data.lastQuranAudio;
    final radio = data.lastRadioStation;
    final resumes = <_JourneyResumeData>[
      _JourneyResumeData(
        icon: Icons.menu_book_outlined,
        title: l10n.continueHome,
        subtitle: hasRead
            ? '${quran.getSurahNameLocalized(surah!, locale)} · ${l10n.ayahNumber(ayah!)}'
            : l10n.noRecentActivityHome,
        active: hasRead,
        color: context.primaryColor,
        onTap: hasRead ? () => openLastReadSurah(summary) : null,
      ),
      _JourneyResumeData(
        icon: Icons.headphones_outlined,
        title: l10n.continueListening,
        subtitle: data.hasLastQuranAudio && audio != null
            ? l10n.resumeReciter(audio.reciterName)
            : l10n.noRecentActivityHome,
        active: data.hasLastQuranAudio && audio != null,
        color: context.primaryVariantColor,
        onTap: data.hasLastQuranAudio && audio != null
            ? () => openLastReciterAudio(audio)
            : null,
      ),
      _JourneyResumeData(
        icon: Icons.radio_outlined,
        title: l10n.continueRadio,
        subtitle: data.hasLastRadioStation && radio != null
            ? radio.stationName
            : l10n.noRecentActivityHome,
        active: data.hasLastRadioStation && radio != null,
        color: context.accentColor,
        onTap: data.hasLastRadioStation && radio != null
            ? () => openLastRadioStation(radio)
            : null,
      ),
    ];
    final actionsData = <(IconData, String, VoidCallback)>[
      (Icons.auto_stories_outlined, l10n.quran, actions.openQuran),
      (Icons.graphic_eq, l10n.quranAudio, actions.openAudio),
      (Icons.podcasts_outlined, l10n.quranRadio, actions.openRadio),
      (Icons.bookmarks_outlined, l10n.bookmarks, actions.openBookmarks),
    ];
    final background = Color.alphaBlend(
      context.primaryColor.withValues(alpha: isDark ? 0.09 : 0.035),
      isDark ? scheme.surface : context.lightSurface,
    );

    return Container(
      key: const ValueKey('quran-journey-workspace'),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: isDark ? 0.26 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.primaryColor, context.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(Icons.auto_stories, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.themeQuranJourney,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      l10n.quranTools,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _JourneyResumeLayout(resumes: resumes),
          SizedBox(height: 18.h),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.65)),
          SizedBox(height: 12.h),
          _JourneyActionLayout(actions: actionsData),
        ],
      ),
    );
  }
}

class _JourneyResumeData {
  const _JourneyResumeData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final Color color;
  final VoidCallback? onTap;
}

class _JourneyResumeLayout extends StatelessWidget {
  const _JourneyResumeLayout({required this.resumes});

  final List<_JourneyResumeData> resumes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.35;
        if (!horizontal) {
          return Column(
            children: [
              for (var index = 0; index < resumes.length; index++) ...[
                if (index > 0) SizedBox(height: 10.h),
                _JourneyEntrance(
                  index: index,
                  child: _JourneyResumeCard(data: resumes[index]),
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < resumes.length; index++) ...[
              if (index > 0) SizedBox(width: 12.w),
              Expanded(
                child: _JourneyEntrance(
                  index: index,
                  child: _JourneyResumeCard(data: resumes[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _JourneyResumeCard extends StatelessWidget {
  const _JourneyResumeCard({required this.data});

  final _JourneyResumeData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: data.active,
      enabled: data.active,
      label: data.title,
      child: Material(
        color: Color.alphaBlend(
          data.color.withValues(alpha: data.active ? 0.12 : 0.045),
          scheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
          side: BorderSide(
            color: data.color.withValues(alpha: data.active ? 0.24 : 0.10),
          ),
        ),
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(data.icon, color: data.color, size: 21.sp),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.64),
                              height: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),
                if (data.active)
                  Icon(Icons.arrow_forward, size: 18.sp, color: data.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyActionLayout extends StatelessWidget {
  const _JourneyActionLayout({required this.actions});

  final List<(IconData, String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.4
            ? 4
            : 2;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            mainAxisExtent: scale > 1.5 ? 104.h : 88.h,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _JourneyEntrance(
            index: index + 3,
            child: _JourneyActionCard(
              icon: actions[index].$1,
              label: actions[index].$2,
              onTap: actions[index].$3,
            ),
          ),
        );
      },
    );
  }
}

class _JourneyActionCard extends StatelessWidget {
  const _JourneyActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color.withValues(alpha: 0.07),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(color: color.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyEntrance extends StatelessWidget {
  const _JourneyEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: disableAnimations ? 1 : 0, end: 1),
      duration: disableAnimations
          ? Duration.zero
          : Duration(milliseconds: 260 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _InlineQuranKitStack extends StatelessWidget {
  const _InlineQuranKitStack({required this.expanded, this.compact = false});

  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: expanded ? 0.94 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      child: SizedBox(
        width: compact ? 42.w : 58.w,
        height: compact ? 40.w : 52.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 2; index >= 0; index--)
              PositionedDirectional(
                start: (index * (compact ? 2 : 3)).w,
                top: (index * (compact ? 1.4 : 2)).h,
                child: Transform.rotate(
                  angle: (index + 1) * 0.018,
                  child: Container(
                    width: compact ? 35.w : 46.w,
                    height: compact ? 35.w : 46.w,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Theme.of(context).colorScheme.surface,
                        context.primaryColor,
                        0.10 + index * 0.05,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.primaryColor
                            .withValues(alpha: 0.16 + index * 0.04),
                      ),
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              start: 0,
              top: 0,
              child: Container(
                width: compact ? 35.w : 46.w,
                height: compact ? 35.w : 46.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: context.primaryColor,
                  size: compact ? 18.sp : 23.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePrayerOverviewSection extends StatelessWidget {
  const HomePrayerOverviewSection({
    super.key,
    required this.isDark,
    required this.onOpenPrayerTimes,
  });

  final bool isDark;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is PrayerTimesLoaded) {
          return StreamBuilder<NextPrayerCountdown>(
            stream: context.read<PrayerTimesCubit>().getNextPrayerCountdown(),
            builder: (context, snapshot) => _LoadedPrayerOverview(
              state: state,
              countdown: snapshot.data,
              isDark: isDark,
            ),
          );
        }
        if (state is PrayerTimesInitial || state is PrayerTimesLoading) {
          return const _PrayerOverviewLoading();
        }

        final l10n = AppLocalizations.of(context)!;
        final (IconData, String) details = switch (state) {
          PrayerTimesLocationDenied() => (
              Icons.location_off_outlined,
              l10n.locationPermissionDenied,
            ),
          PrayerTimesLocationPermanentlyDenied() => (
              Icons.location_off_outlined,
              l10n.locationPermissionPermanentlyDenied,
            ),
          PrayerTimesLocationServiceDisabled() => (
              Icons.location_disabled_outlined,
              l10n.locationServicesDisabled,
            ),
          PrayerTimesError(:final message) => (
              Icons.error_outline,
              message,
            ),
          _ => (
              Icons.add_location_alt_outlined,
              l10n.prayerSetupRequired,
            ),
        };
        return _PrayerOverviewUnavailable(
          icon: details.$1,
          message: details.$2,
          onOpenPrayerTimes: onOpenPrayerTimes,
          isDark: isDark,
        );
      },
    );
  }
}

class _LoadedPrayerOverview extends StatelessWidget {
  const _LoadedPrayerOverview({
    required this.state,
    required this.countdown,
    required this.isDark,
  });

  final PrayerTimesLoaded state;
  final NextPrayerCountdown? countdown;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final hijri = HijriCalendar.fromDate(now);
    final hijriText =
        '${hijri.hDay} ${_hijriMonth(context, hijri.hMonth)} ${hijri.hYear}';
    final entries = <(String, DateTime?, String)>[
      (l10n.fajr, state.prayerTimes.fajr, 'fajr'),
      (l10n.sunrise, state.prayerTimes.sunrise, 'sunrise'),
      (l10n.dhuhr, state.prayerTimes.dhuhr, 'dhuhr'),
      (l10n.asr, state.prayerTimes.asr, 'asr'),
      (l10n.maghrib, state.prayerTimes.maghrib, 'maghrib'),
      (l10n.isha, state.prayerTimes.isha, 'isha'),
    ];
    final location = prayerLocationLabel(context, state);
    final gradient = isDark
        ? [context.darkGradientMid, context.primaryDarkColor]
        : [
            context.primaryColor,
            Color.lerp(context.primaryColor, context.primaryLightColor, 0.72)!,
          ];

    return Semantics(
      container: true,
      label: l10n.prayerTimes,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: isDark ? 0.18 : 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final split = constraints.maxWidth >= 720 && textScale <= 1.35;
                final summary = _PrayerOverviewSummary(
                  gregorian: intl.DateFormat.yMMMMEEEEd(locale).format(now),
                  hijri: hijriText,
                  location: location,
                  countdown: countdown,
                );
                final schedule = _PrayerScheduleGrid(
                  entries: entries,
                  locale: locale,
                  offsets: state.offsets,
                  nextPrayerName: countdown?.prayerName,
                );
                if (!split) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      SizedBox(height: 18.h),
                      schedule,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: summary),
                    SizedBox(width: 22.w),
                    Expanded(flex: 7, child: schedule),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerOverviewSummary extends StatelessWidget {
  const _PrayerOverviewSummary({
    required this.gregorian,
    required this.hijri,
    required this.location,
    required this.countdown,
  });

  final String gregorian;
  final String hijri;
  final String? location;
  final NextPrayerCountdown? countdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = countdown;
    final duration = value == null
        ? Duration.zero
        : value.isPastPrayer
            ? Duration(seconds: value.secondsPassed)
            : value.duration;
    final countdownText = _formatDuration(duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: const Icon(Icons.mosque_outlined, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.themePrayerToday,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    gregorian,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.25,
                        ),
                  ),
                  Text(
                    hijri,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (location != null) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 17.sp, color: Colors.white70),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 22.h),
        Text(
          value?.prayerName ?? l10n.nextPrayerCountDown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 2.h),
        Semantics(
          label: l10n.nextPrayerCountDown,
          value: countdownText,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value?.isPastPrayer == true ? '+$countdownText' : countdownText,
              maxLines: 1,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerScheduleGrid extends StatelessWidget {
  const _PrayerScheduleGrid({
    required this.entries,
    required this.locale,
    required this.offsets,
    required this.nextPrayerName,
  });

  final List<(String, DateTime?, String)> entries;
  final String locale;
  final Map<String, int> offsets;
  final String? nextPrayerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  color: Colors.white, size: 20),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.prayerTimes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final columns = constraints.maxWidth >= 560 && scale <= 1.2
                  ? 6
                  : constraints.maxWidth >= 290 && scale <= 1.6
                      ? 3
                      : 2;
              final rowHeight = scale > 1.4 ? 86.h : 72.h;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                  mainAxisExtent: rowHeight,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final highlighted = nextPrayerName != null &&
                      entry.$1.toLowerCase() == nextPrayerName!.toLowerCase();
                  return _PrayerTimeTile(
                    name: entry.$1,
                    time: _formatPrayerTime(
                      locale,
                      entry.$2,
                      offsets[entry.$3] ?? 0,
                    ),
                    highlighted: highlighted,
                    muted: entry.$3 == 'sunrise',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeTile extends StatelessWidget {
  const _PrayerTimeTile({
    required this.name,
    required this.time,
    required this.highlighted,
    required this.muted,
  });

  final String name;
  final String time;
  final bool highlighted;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? context.primaryDarkColor : Colors.white;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.white.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: muted ? 0.06 : 0.09),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color:
              highlighted ? Colors.white : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      foreground.withValues(alpha: highlighted ? 0.82 : 0.76),
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerOverviewUnavailable extends StatelessWidget {
  const _PrayerOverviewUnavailable({
    required this.icon,
    required this.message,
    required this.onOpenPrayerTimes,
    required this.isDark,
  });

  final IconData icon;
  final String message;
  final VoidCallback onOpenPrayerTimes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconTile = Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Icon(icon, color: context.primaryColor),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.themePrayerToday,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 4.h),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 10.h),
        FilledButton.icon(
          onPressed: onOpenPrayerTimes,
          icon: const Icon(Icons.location_on_outlined),
          label: Text(l10n.setUpPrayerTimes),
        ),
      ],
    );
    return _SectionSurface(
      isDark: isDark,
      padding: 20.w,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.5;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconTile,
                SizedBox(height: 14.h),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconTile,
              SizedBox(width: 14.w),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _PrayerOverviewLoading extends StatelessWidget {
  const _PrayerOverviewLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
        );
    return Semantics(
      label: AppLocalizations.of(context)!.loading,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(180.w, 24.h),
            SizedBox(height: 12.h),
            bar(230.w, 16.h),
            SizedBox(height: 26.h),
            bar(210.w, 46.h),
            SizedBox(height: 18.h),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomeDatePrayerSection extends StatelessWidget {
  const HomeDatePrayerSection({
    super.key,
    required this.isDark,
    this.compact = false,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final hijri = HijriCalendar.fromDate(now);
    final hijriText =
        '${hijri.hDay} ${_hijriMonth(context, hijri.hMonth)} ${hijri.hYear}';

    return Container(
      padding: EdgeInsets.all(compact ? 14.w : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.primaryColor,
            Color.lerp(context.primaryColor, context.primaryLightColor, 0.7)!,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: compact
          ? Row(
              children: [
                Expanded(
                  child: _DateText(
                    gregorian: intl.DateFormat.MMMEd(locale).format(now),
                    hijri: hijriText,
                    compact: true,
                  ),
                ),
                SizedBox(width: 12.w),
                const Flexible(child: _PrayerCountdown(compact: true)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.gregorianDate,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                SizedBox(height: 3.h),
                _DateText(
                  gregorian: intl.DateFormat.yMMMMEEEEd(locale).format(now),
                  hijri: hijriText,
                ),
                Divider(height: 28.h, color: Colors.white24),
                const _PrayerCountdown(),
              ],
            ),
    );
  }
}

class _DateText extends StatelessWidget {
  const _DateText({
    required this.gregorian,
    required this.hijri,
    this.compact = false,
  });

  final String gregorian;
  final String hijri;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gregorian,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 14.sp : 20.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          hijri,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: compact ? 11.sp : 14.sp,
          ),
        ),
      ],
    );
  }
}

class _PrayerCountdown extends StatelessWidget {
  const _PrayerCountdown({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is PrayerTimesNeedsSetup || state is PrayerTimesError) {
          return Semantics(
            button: true,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoute.prayerTimes),
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        compact
                            ? l10n.setUpPrayerTimes
                            : l10n.prayerSetupRequired,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 11.sp : 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is! PrayerTimesLoaded) {
          return const LinearProgressIndicator(color: Colors.white);
        }

        return StreamBuilder<NextPrayerCountdown>(
          stream: context.read<PrayerTimesCubit>().getNextPrayerCountdown(),
          builder: (context, snapshot) {
            final value = snapshot.data;
            final countdown = value == null
                ? '-${_formatDuration(Duration.zero)}'
                : value.isPastPrayer
                    ? '+${_formatDuration(
                        Duration(seconds: value.secondsPassed),
                      )}'
                    : '-${_formatDuration(value.duration)}';
            return Row(
              children: [
                Icon(Icons.schedule,
                    color: Colors.white, size: compact ? 18 : 24),
                SizedBox(width: 9.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value?.prayerName ?? l10n.nextPrayerCountDown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: compact ? 10.sp : 13.sp,
                        ),
                      ),
                      Text(
                        countdown,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 15.sp : 26.sp,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class HomePrayerScheduleSection extends StatelessWidget {
  const HomePrayerScheduleSection({
    super.key,
    required this.isDark,
    this.compact = false,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is! PrayerTimesLoaded) return const SizedBox.shrink();
        final times = state.prayerTimes;
        final entries = <(String, DateTime?, String)>[
          (l10n.fajr, times.fajr, 'fajr'),
          (l10n.sunrise, times.sunrise, 'sunrise'),
          (l10n.dhuhr, times.dhuhr, 'dhuhr'),
          (l10n.asr, times.asr, 'asr'),
          (l10n.maghrib, times.maghrib, 'maghrib'),
          (l10n.isha, times.isha, 'isha'),
        ];
        final locale = Localizations.localeOf(context).toString();
        return _SectionSurface(
          isDark: isDark,
          padding: compact ? 10.w : 16.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                _SectionTitle(
                  icon: Icons.mosque_outlined,
                  title: l10n.prayerTimes,
                ),
                SizedBox(height: 14.h),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: compact ? 86.w : 104.w,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Column(
                            children: [
                              Text(
                                entry.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 11.sp : 13.sp,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _formatPrayerTime(
                                  locale,
                                  entry.$2,
                                  state.offsets[entry.$3] ?? 0,
                                ),
                                style: TextStyle(
                                  fontSize: compact ? 12.sp : 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeDailyAyahSection extends StatelessWidget {
  const HomeDailyAyahSection({
    super.key,
    required this.ayah,
    required this.isDark,
    required this.onTap,
  });

  final DailyAyah ayah;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return _SectionSurface(
      isDark: isDark,
      padding: 20.w,
      color: Color.alphaBlend(
        context.primaryColor.withValues(alpha: isDark ? 0.12 : 0.035),
        isDark ? Theme.of(context).colorScheme.surface : context.lightSurface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(icon: Icons.auto_stories, title: l10n.todaysAyah),
            SizedBox(height: 16.h),
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'uthmanic',
                fontSize: 24.sp,
                height: 1.85,
                color: Color.lerp(
                  Theme.of(context).colorScheme.onSurface,
                  context.primaryColor,
                  isDark ? 0.2 : 0.28,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${quran.getSurahNameLocalized(ayah.surahNumber, locale)} · ${l10n.ayahNumber(ayah.ayahNumber)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.arrow_forward,
                    size: 17.sp, color: context.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContinueReadingSection extends StatelessWidget {
  const HomeContinueReadingSection({
    super.key,
    required this.data,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  final HomeLoaded data;
  final bool isDark;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = data.lastReadSummary;
    final hasRead = data.hasLastReadPosition && summary != null;
    final surah = hasRead ? summary['surahNumber'] as int : null;
    final ayah = hasRead ? summary['ayahNumber'] as int : null;
    final locale = Localizations.localeOf(context).languageCode;
    return _SectionSurface(
      isDark: isDark,
      padding: compact ? 12.w : 16.w,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: context.primaryColor.withValues(alpha: 0.12),
          child: Icon(Icons.menu_book, color: context.primaryColor),
        ),
        title: Text(
          l10n.continueHome,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          hasRead
              ? '${quran.getSurahNameLocalized(surah!, locale)} · ${l10n.ayahNumber(ayah!)}'
              : l10n.noRecentActivityDescription,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: hasRead ? onTap : null,
      ),
    );
  }
}

class HomeKhatmaSection extends StatelessWidget {
  const HomeKhatmaSection({
    super.key,
    required this.khatma,
    required this.isDark,
    required this.onTap,
  });

  final KhatmaSnapshot khatma;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionSurface(
      isDark: isDark,
      padding: 16.w,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            SizedBox(
              width: 54.w,
              height: 54.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: khatma.progress,
                    strokeWidth: 6,
                    color: context.primaryColor,
                    backgroundColor:
                        context.primaryColor.withValues(alpha: 0.12),
                  ),
                  Center(
                    child: Text(
                      '${(khatma.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.khatmaProgress,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    khatma.isActive
                        ? l10n.khatmaDayOf(
                            (khatma.currentDay + 1).clamp(1, khatma.totalDays),
                            khatma.totalDays,
                          )
                        : l10n.noActiveKhatma,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class HomeQuranToolsSection extends StatelessWidget {
  const HomeQuranToolsSection({
    super.key,
    required this.isDark,
    required this.actions,
  });

  final bool isDark;
  final HomeDashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.menu_book, l10n.quran, actions.openQuran),
      (Icons.headphones, l10n.quranAudio, actions.openAudio),
      (Icons.radio, l10n.quranRadio, actions.openRadio),
      (Icons.bookmark, l10n.bookmarks, actions.openBookmarks),
    ];
    return _SectionSurface(
      isDark: isDark,
      padding: 16.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.auto_stories, title: l10n.quranTools),
          SizedBox(height: 12.h),
          Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) SizedBox(width: 8.w),
                Expanded(
                  child: _ToolButton(
                    icon: items[index].$1,
                    label: items[index].$2,
                    onTap: items[index].$3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.primaryColor, size: 23.sp),
              SizedBox(height: 5.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.isDark,
    required this.child,
    required this.padding,
    this.color,
  });

  final bool isDark;
  final Widget child;
  final double padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ??
          (isDark
              ? Color.alphaBlend(
                  context.primaryColor.withValues(alpha: 0.035),
                  Theme.of(context).colorScheme.surface,
                )
              : Theme.of(context).colorScheme.surface),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: context.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatPrayerTime(String locale, DateTime? time, int offset) {
  if (time == null) return '--:--';
  return intl.DateFormat.jm(locale).format(time.add(Duration(minutes: offset)));
}

String _hijriMonth(BuildContext context, int month) {
  final l10n = AppLocalizations.of(context)!;
  return [
    l10n.muharram,
    l10n.safar,
    l10n.rabiAlAwwal,
    l10n.rabiAlThani,
    l10n.jumadaAlAwwal,
    l10n.jumadaAlThani,
    l10n.rajab,
    l10n.shaban,
    l10n.ramadan,
    l10n.shawwal,
    l10n.dhuAlQidah,
    l10n.dhuAlHijjah,
  ][month - 1];
}
