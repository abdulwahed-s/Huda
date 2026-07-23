import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/focused_theme_layout.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/classic_home.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today_home.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey_home.dart';

class HomeThemeRenderer extends StatelessWidget {
  const HomeThemeRenderer({
    super.key,
    required this.theme,
    required this.configuration,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.onRetry,
    required this.onCustomize,
  });

  final HomeThemeId theme;
  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final VoidCallback onRetry;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    if (theme == HomeThemeId.prayerToday) {
      return _RendererFrame(
        fullBleed: true,
        child: _animatedTheme(
          context,
          PrayerTodayHome(
            configuration: configuration,
            features: features,
            actions: actions,
            isDark: isDark,
            openLastReadSurah: openLastReadSurah,
            openLastReciterAudio: openLastReciterAudio,
            openLastRadioStation: openLastRadioStation,
            onCustomize: onCustomize,
          ),
        ),
      );
    }

    if (theme == HomeThemeId.quranJourney) {
      return _RendererFrame(
        fullBleed: true,
        child: _animatedTheme(
          context,
          QuranJourneyHome(
            configuration: configuration,
            features: features,
            actions: actions,
            isDark: isDark,
            openLastReadSurah: openLastReadSurah,
            openLastReciterAudio: openLastReciterAudio,
            openLastRadioStation: openLastRadioStation,
            onCustomize: onCustomize,
            onRetry: onRetry,
          ),
        ),
      );
    }

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return _RendererFrame(child: _HomeThemeLoading(theme: theme));
        }
        if (state is HomeError) {
          return _RendererFrame(
            child: _HomeThemeError(message: state.message, onRetry: onRetry),
          );
        }
        final child = ClassicHome(
          configuration: configuration,
          features: features,
          actions: actions,
          isDark: isDark,
          openLastReadSurah: openLastReadSurah,
          openLastReciterAudio: openLastReciterAudio,
          openLastRadioStation: openLastRadioStation,
        );
        return _RendererFrame(child: _animatedTheme(context, child));
      },
    );
  }

  Widget _animatedTheme(BuildContext context, Widget child) {
    if (theme != HomeThemeId.classic) {
      return KeyedSubtree(key: ValueKey(theme), child: child);
    }
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(theme), child: child),
    );
  }
}

class _RendererFrame extends StatelessWidget {
  const _RendererFrame({required this.child, this.fullBleed = false});

  final Widget child;
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    if (fullBleed) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: SizedBox(width: double.infinity, child: child),
      );
    }
    return FocusedThemeContentFrame(child: child);
  }
}

class _HomeThemeLoading extends StatelessWidget {
  const _HomeThemeLoading({required this.theme});

  final HomeThemeId theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = theme != HomeThemeId.classic;
    return Semantics(
      label: AppLocalizations.of(context)!.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonBlock(
            height: focused ? 260.h : 150.h,
            color: scheme.primary.withValues(alpha: focused ? 0.12 : 0.07),
          ),
          SizedBox(height: 18.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  mainAxisExtent: 74.h,
                ),
                itemCount: columns,
                itemBuilder: (_, __) => _SkeletonBlock(
                  height: 74.h,
                  color: scheme.onSurface.withValues(alpha: 0.06),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _HomeThemeError extends StatelessWidget {
  const _HomeThemeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 32.h),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40.sp, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
