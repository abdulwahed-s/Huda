import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/home/home_preferences.dart';

enum HomeThemePreviewDetail { compact, expanded }

class HomeThemePreview extends StatelessWidget {
  const HomeThemePreview({
    super.key,
    required this.theme,
    this.detail = HomeThemePreviewDetail.compact,
    this.configuration,
  });

  final HomeThemeId theme;
  final HomeThemePreviewDetail detail;
  final HomeThemeConfiguration? configuration;

  @override
  Widget build(BuildContext context) {
    final resolved = configuration ?? HomeThemeDefaults.configuration(theme);
    final scheme = Theme.of(context).colorScheme;
    final radius = detail == HomeThemePreviewDetail.expanded ? 22.0 : 14.0;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.82),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: KeyedSubtree(
              key: ValueKey(
                'home-theme-preview-${theme.name}-${detail.name}',
              ),
              child: switch (theme) {
                HomeThemeId.classic => _ClassicPreview(
                    configuration: resolved,
                    detail: detail,
                  ),
                HomeThemeId.prayerToday => _PrayerTodayPreview(
                    configuration: resolved,
                    detail: detail,
                  ),
                HomeThemeId.quranJourney => _QuranJourneyPreview(
                    configuration: resolved,
                    detail: detail,
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicPreview extends StatelessWidget {
  const _ClassicPreview({
    required this.configuration,
    required this.detail,
  });

  final HomeThemeConfiguration configuration;
  final HomeThemePreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = context.primaryColor;
    final accent = context.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visiblePrimary = configuration.primaryFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .toList(growable: false);
    final visibleMore = configuration.viewMoreFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final unit = math.min(width, height);
        final headerHeight = height * 0.22;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                key: const ValueKey('classic-preview-background'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        primary.withValues(alpha: isDark ? 0.13 : 0.065),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        accent.withValues(alpha: isDark ? 0.045 : 0.025),
                        scheme.surface,
                      ),
                      scheme.surface,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('classic-preview-geometry'),
                painter: _ClassicGeometryPainter(
                  primary: primary,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.055,
              end: width * 0.055,
              top: height * 0.045,
              height: headerHeight,
              child: KeyedSubtree(
                key: const ValueKey('classic-preview-header'),
                child: Row(
                  children: [
                    _PreviewAppMark(
                      color: primary,
                      size: headerHeight * 0.66,
                      layered: false,
                    ),
                    SizedBox(width: width * 0.035),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _InkLine(
                          width: width * 0.17,
                          height: math.max(2, unit * 0.025),
                          color: scheme.onSurface,
                          radius: 99,
                        ),
                      ),
                    ),
                    _TuneMark(
                      color: primary,
                      width: width *
                          (detail == HomeThemePreviewDetail.expanded
                              ? 0.18
                              : 0.16),
                      height: headerHeight * 0.58,
                      showLine: detail == HomeThemePreviewDetail.expanded,
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.06,
              end: width * 0.06,
              top: height * 0.31,
              bottom: height * 0.075,
              child: _ClassicFeatureGrid(
                primary: primary,
                surface: scheme.surface,
                onSurface: scheme.onSurface,
                visiblePrimary: visiblePrimary,
                visibleMore: visibleMore,
                detail: detail,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassicFeatureGrid extends StatelessWidget {
  const _ClassicFeatureGrid({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.visiblePrimary,
    required this.visibleMore,
    required this.detail,
  });

  final Color primary;
  final Color surface;
  final Color onSurface;
  final List<HomeFeatureId> visiblePrimary;
  final List<HomeFeatureId> visibleMore;
  final HomeThemePreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = detail == HomeThemePreviewDetail.expanded ? 5 : 4;
        const rows = 2;
        final hasMore = visibleMore.isNotEmpty;
        final capacity = columns * rows;
        final primaryCapacity = capacity - (hasMore ? 1 : 0);
        final shownPrimary = visiblePrimary.take(primaryCapacity).toList();
        final cells = <Widget>[
          for (final id in shownPrimary)
            _ClassicFeatureCell(
              key: id == HomeFeatureId.quranKit
                  ? const ValueKey('classic-preview-quran-stack')
                  : ValueKey('classic-preview-feature-${id.name}'),
              primary: primary,
              surface: surface,
              onSurface: onSurface,
              quranStack: id == HomeFeatureId.quranKit,
            ),
          if (hasMore)
            _ClassicViewMoreCell(
              key: const ValueKey('classic-preview-view-more-stack'),
              primary: primary,
              surface: surface,
            ),
        ];
        final gap = math.max(3.0, constraints.maxWidth * 0.018);
        return GridView.count(
          key: const ValueKey('classic-preview-grid'),
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: (constraints.maxWidth - gap * (columns - 1)) /
              columns /
              ((constraints.maxHeight - gap) / rows),
          children: cells,
        );
      },
    );
  }
}

class _ClassicFeatureCell extends StatelessWidget {
  const _ClassicFeatureCell({
    super.key,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.quranStack,
  });

  final Color primary;
  final Color surface;
  final Color onSurface;
  final bool quranStack;

  @override
  Widget build(BuildContext context) {
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          primary.withValues(alpha: 0.035),
          surface,
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: primary.withValues(alpha: 0.13)),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.34,
          heightFactor: 0.34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
    if (!quranStack) return tile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          start: 3,
          end: -2,
          top: -3,
          bottom: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        Positioned.fill(child: tile),
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: FractionallySizedBox(
            widthFactor: 0.42,
            heightFactor: 0.12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassicViewMoreCell extends StatelessWidget {
  const _ClassicViewMoreCell({
    super.key,
    required this.primary,
    required this.surface,
  });

  final Color primary;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var offset = 2; offset >= 1; offset--)
          PositionedDirectional(
            start: offset * 2.0,
            end: -offset * 2.0,
            top: -offset * 3.0,
            bottom: offset * 2.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  primary.withValues(alpha: 0.07 + offset * 0.02),
                  surface,
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: primary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                primary.withValues(alpha: 0.11),
                surface,
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: primary.withValues(alpha: 0.24)),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primary,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerTodayPreview extends StatelessWidget {
  const _PrayerTodayPreview({
    required this.configuration,
    required this.detail,
  });

  final HomeThemeConfiguration configuration;
  final HomeThemePreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = context.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visiblePrimary = configuration.primaryFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .length;
    final visibleMore = configuration.viewMoreFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final unit = math.min(width, height);
        final canvasBottom = height * 0.79;
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: scheme.surface)),
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('prayer-preview-atmosphere'),
                painter: _PrayerAtmospherePreviewPainter(
                  primary: primary,
                  primaryDark: context.primaryDarkColor,
                  isDark: isDark,
                  surface: scheme.surface,
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.055,
              end: width * 0.055,
              top: height * 0.035,
              height: height * 0.16,
              child: KeyedSubtree(
                key: const ValueKey('prayer-preview-header'),
                child: Row(
                  children: [
                    _PreviewAppMark(
                      color: Colors.white,
                      size: height * 0.105,
                      layered: false,
                      onDark: true,
                    ),
                    SizedBox(width: width * 0.025),
                    _InkLine(
                      width: width * 0.13,
                      height: math.max(2, unit * 0.02),
                      color: Colors.white,
                      radius: 99,
                    ),
                    const Spacer(),
                    _TuneMark(
                      color: Colors.white,
                      width: height * 0.105,
                      height: height * 0.105,
                      showLine: false,
                      onDark: true,
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.14,
              end: width * 0.14,
              top: height * 0.20,
              height: height * 0.055,
              child: KeyedSubtree(
                key: const ValueKey('prayer-preview-date-context'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ContextDash(width: width * 0.16),
                    SizedBox(width: width * 0.035),
                    _ContextDash(width: width * 0.13),
                    if (detail == HomeThemePreviewDetail.expanded) ...[
                      SizedBox(width: width * 0.035),
                      _ContextDash(width: width * 0.11),
                    ],
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.065,
              top: height * 0.29,
              width: width * 0.44,
              height: height * 0.42,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    key: const ValueKey('prayer-preview-countdown'),
                    painter: _CountdownPreviewPainter(),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.46,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InkLine(
                              width: double.infinity,
                              height: math.max(2, unit * 0.026),
                              color: Colors.white,
                              radius: 99,
                            ),
                            SizedBox(height: height * 0.028),
                            _InkLine(
                              width: double.infinity,
                              height: math.max(1.5, unit * 0.016),
                              color: Colors.white,
                              opacity: 0.45,
                              radius: 99,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.54,
              end: width * 0.06,
              top: height * 0.31,
              height: height * 0.37,
              child: _PrayerSchedulePreview(
                key: const ValueKey('prayer-preview-schedule'),
                primary: primary,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: canvasBottom - height * 0.08,
              height: height * 0.18,
              child: CustomPaint(
                key: const ValueKey('prayer-preview-handoff'),
                painter: _PrayerHandoffPreviewPainter(
                  color: scheme.surface,
                  line: primary.withValues(alpha: isDark ? 0.24 : 0.15),
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.075,
              end: width * 0.075,
              bottom: height * 0.055,
              height: height * 0.12,
              child: _ToolCueRow(
                key: const ValueKey('prayer-preview-tools'),
                count: visiblePrimary.clamp(0, 4),
                hasMore: visibleMore > 0,
                color: primary,
                surface: scheme.surface,
                squared: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrayerSchedulePreview extends StatelessWidget {
  const _PrayerSchedulePreview({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < 5; index++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: index == 2 ? 0.17 : 0.065,
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: index == 2 ? 0.24 : 0.07,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _InkLine(
                      width: double.infinity,
                      height: 2,
                      color: Colors.white,
                      opacity: index == 2 ? 0.75 : 0.42,
                      radius: 99,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InkLine(
                    width: 13,
                    height: 2,
                    color: index == 2 ? primary : Colors.white,
                    opacity: index == 2 ? 0.95 : 0.46,
                    radius: 99,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuranJourneyPreview extends StatelessWidget {
  const _QuranJourneyPreview({
    required this.configuration,
    required this.detail,
  });

  final HomeThemeConfiguration configuration;
  final HomeThemePreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = context.primaryColor;
    final illumination = Color.lerp(
      context.accentColor,
      const Color(0xFFC59A46),
      Theme.of(context).brightness == Brightness.dark ? 0.36 : 0.48,
    )!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyVisible =
        configuration.orderedSections.contains(HomeSectionId.dailyAyah) &&
            !configuration.hiddenSections.contains(HomeSectionId.dailyAyah);
    final khatmaVisible = configuration.orderedSections
            .contains(HomeSectionId.khatmaProgress) &&
        !configuration.hiddenSections.contains(HomeSectionId.khatmaProgress);
    final primaryCount = configuration.primaryFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .length;
    final moreCount = configuration.viewMoreFeatures
        .where((id) => !configuration.hiddenFeatures.contains(id))
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final unit = math.min(width, height);
        final headerBottom = height * 0.20;
        final ayahTop = height * 0.23;
        final ayahHeight = dailyVisible ? height * 0.22 : 0.0;
        final readingTop = dailyVisible ? height * 0.49 : height * 0.28;
        final readingHeight = dailyVisible ? height * 0.24 : height * 0.43;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                key: const ValueKey('quran-preview-paper'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        primary.withValues(alpha: isDark ? 0.10 : 0.035),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        illumination.withValues(
                          alpha: isDark ? 0.055 : 0.028,
                        ),
                        scheme.surface,
                      ),
                      scheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('quran-preview-manuscript-details'),
                painter: _ManuscriptPreviewPainter(
                  ink: primary,
                  illumination: illumination,
                  isDark: isDark,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.055,
              end: width * 0.055,
              top: height * 0.035,
              height: height * 0.14,
              child: KeyedSubtree(
                key: const ValueKey('quran-preview-header'),
                child: Row(
                  children: [
                    _PreviewAppMark(
                      color: primary,
                      size: height * 0.10,
                      layered: true,
                    ),
                    SizedBox(width: width * 0.03),
                    _InkLine(
                      width: width * 0.14,
                      height: math.max(2, unit * 0.021),
                      color: scheme.onSurface,
                      radius: 99,
                    ),
                    const Spacer(),
                    _TuneMark(
                      color: primary,
                      width: height * 0.10,
                      height: height * 0.10,
                      showLine: false,
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.06,
              end: width * 0.06,
              top: headerBottom,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.75),
                      illumination.withValues(alpha: 0.48),
                      illumination.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            if (dailyVisible)
              PositionedDirectional(
                start: width * 0.07,
                end: width * 0.07,
                top: ayahTop,
                height: ayahHeight,
                child: _AyahPreviewRegion(
                  key: const ValueKey('quran-preview-ayah'),
                  primary: primary,
                  illumination: illumination,
                  surface: scheme.surface,
                ),
              ),
            PositionedDirectional(
              start: width * 0.07,
              end: width * 0.07,
              top: readingTop,
              height: readingHeight,
              child: _ReadingPreviewRegion(
                key: const ValueKey('quran-preview-reading'),
                primary: primary,
                illumination: illumination,
                surface: scheme.surface,
                onSurface: scheme.onSurface,
                khatmaVisible: khatmaVisible,
              ),
            ),
            PositionedDirectional(
              start: width * 0.09,
              end: width * 0.09,
              top: height * 0.76,
              height: height * 0.09,
              child: _QuranShortcutRail(
                key: const ValueKey('quran-preview-shortcuts'),
                primary: primary,
                surface: scheme.surface,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: height * 0.84,
              height: height * 0.06,
              child: CustomPaint(
                key: const ValueKey('quran-preview-handoff'),
                painter: _QuranHandoffPreviewPainter(
                  color: primary,
                  illumination: illumination,
                ),
              ),
            ),
            PositionedDirectional(
              start: width * 0.08,
              end: width * 0.08,
              bottom: height * 0.035,
              height: height * 0.07,
              child: _ToolCueRow(
                key: const ValueKey('quran-preview-supporting-tools'),
                count: primaryCount.clamp(0, 5),
                hasMore: moreCount > 0,
                color: primary,
                surface: scheme.surface,
                squared: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AyahPreviewRegion extends StatelessWidget {
  const _AyahPreviewRegion({
    super.key,
    required this.primary,
    required this.illumination,
    required this.surface,
  });

  final Color primary;
  final Color illumination;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          illumination.withValues(alpha: 0.045),
          surface,
        ),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: illumination.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(7, 5, 7, 5),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: illumination),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InkLine(
                        width: double.infinity,
                        height: 2.5,
                        color: primary,
                        opacity: 0.70,
                        radius: 0,
                      ),
                      const SizedBox(height: 5),
                      FractionallySizedBox(
                        widthFactor: 0.72,
                        alignment: AlignmentDirectional.centerEnd,
                        child: _InkLine(
                          width: double.infinity,
                          height: 2,
                          color: primary,
                          opacity: 0.42,
                          radius: 0,
                        ),
                      ),
                    ],
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

class _ReadingPreviewRegion extends StatelessWidget {
  const _ReadingPreviewRegion({
    super.key,
    required this.primary,
    required this.illumination,
    required this.surface,
    required this.onSurface,
    required this.khatmaVisible,
  });

  final Color primary;
  final Color illumination;
  final Color surface;
  final Color onSurface;
  final bool khatmaVisible;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 240,
        height: 72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.018),
            border: Border.all(color: primary.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: illumination.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: khatmaVisible ? 5 : 1,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InkLine(
                            width: 28,
                            height: 2,
                            color: primary,
                            opacity: 0.60,
                            radius: 0,
                          ),
                          const SizedBox(height: 6),
                          _InkLine(
                            width: 45,
                            height: 4,
                            color: onSurface,
                            opacity: 0.72,
                            radius: 0,
                          ),
                          const Spacer(),
                          FractionallySizedBox(
                            widthFactor: 0.62,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(2),
                                ),
                              ),
                              child: const SizedBox(height: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (khatmaVisible) ...[
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: primary.withValues(alpha: 0.18),
                    ),
                    Expanded(
                      flex: 3,
                      child: KeyedSubtree(
                        key: const ValueKey('quran-preview-khatma'),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.route_rounded,
                                size: 10,
                                color: illumination,
                              ),
                              const SizedBox(height: 5),
                              _InkLine(
                                width: double.infinity,
                                height: 2,
                                color: primary,
                                opacity: 0.48,
                                radius: 0,
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  value: 0.64,
                                  backgroundColor:
                                      primary.withValues(alpha: 0.10),
                                  valueColor:
                                      AlwaysStoppedAnimation(illumination),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranShortcutRail extends StatelessWidget {
  const _QuranShortcutRail({
    super.key,
    required this.primary,
    required this.surface,
  });

  final Color primary;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: index == 0
                    ? primary.withValues(alpha: 0.12)
                    : surface.withValues(alpha: 0.72),
                border: Border.all(
                  color: primary.withValues(alpha: index == 0 ? 0.26 : 0.13),
                ),
              ),
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: index == 0 ? 0.8 : 0.42),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          if (index != 3) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

class _ToolCueRow extends StatelessWidget {
  const _ToolCueRow({
    super.key,
    required this.count,
    required this.hasMore,
    required this.color,
    required this.surface,
    required this.squared,
  });

  final int count;
  final bool hasMore;
  final Color color;
  final Color surface;
  final bool squared;

  @override
  Widget build(BuildContext context) {
    final shown = count.clamp(0, 5);
    if (shown == 0 && !hasMore) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.10)),
          borderRadius: squared ? null : BorderRadius.circular(6),
        ),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < shown; index++) ...[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  color.withValues(alpha: index == 0 ? 0.075 : 0.035),
                  surface,
                ),
                border: Border.all(color: color.withValues(alpha: 0.12)),
                borderRadius: squared ? null : BorderRadius.circular(5),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.48),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
        ],
        if (hasMore)
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: 2,
                  end: -1,
                  top: -2,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.055),
                      borderRadius: squared ? null : BorderRadius.circular(5),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        color.withValues(alpha: 0.10),
                        surface,
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.20)),
                      borderRadius: squared ? null : BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 10,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PreviewAppMark extends StatelessWidget {
  const _PreviewAppMark({
    required this.color,
    required this.size,
    required this.layered,
    this.onDark = false,
  });

  final Color color;
  final double size;
  final bool layered;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final mark = DecoratedBox(
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Center(
        child: Icon(
          Icons.brightness_5_rounded,
          size: size * 0.52,
          color: color.withValues(alpha: onDark ? 0.92 : 0.78),
        ),
      ),
    );
    if (!layered) return SizedBox.square(dimension: size, child: mark);
    return SizedBox(
      width: size * 1.16,
      height: size * 1.10,
      child: Stack(
        children: [
          PositionedDirectional(
            start: size * 0.16,
            top: size * 0.12,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(size * 0.27),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: SizedBox.square(dimension: size, child: mark),
          ),
        ],
      ),
    );
  }
}

class _TuneMark extends StatelessWidget {
  const _TuneMark({
    required this.color,
    required this.width,
    required this.height,
    required this.showLine,
    this.onDark = false,
  });

  final Color color;
  final double width;
  final double height;
  final bool showLine;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: showLine
          ? EdgeInsets.symmetric(horizontal: math.min(5, width * 0.08))
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDark ? 0.10 : 0.075),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: showLine
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, color: color, size: height * 0.48),
                const SizedBox(width: 4),
                Flexible(
                  child: _InkLine(
                    width: double.infinity,
                    height: 2,
                    color: color,
                    opacity: 0.55,
                    radius: 99,
                  ),
                ),
              ],
            )
          : Center(
              child: Icon(
                Icons.tune_rounded,
                color: color,
                size: height * 0.48,
              ),
            ),
    );
  }
}

class _ContextDash extends StatelessWidget {
  const _ContextDash({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Center(
        child: Container(
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.48),
        ),
      ),
    );
  }
}

class _InkLine extends StatelessWidget {
  const _InkLine({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
    this.opacity = 0.72,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ClassicGeometryPainter extends CustomPainter {
  const _ClassicGeometryPainter({
    required this.primary,
    required this.accent,
    required this.isDark,
  });

  final Color primary;
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, size.shortestSide * 0.004)
      ..color = primary.withValues(alpha: isDark ? 0.11 : 0.07);
    final center = Offset(size.width * 0.86, size.height * 0.16);
    final radius = size.shortestSide * 0.17;
    for (var turn = 0; turn < 2; turn++) {
      final path = Path();
      for (var point = 0; point <= 8; point++) {
        final angle = point * math.pi / 4 + turn * math.pi / 8;
        final next = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        point == 0
            ? path.moveTo(next.dx, next.dy)
            : path.lineTo(next.dx, next.dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.92),
      size.shortestSide * 0.11,
      paint..color = accent.withValues(alpha: isDark ? 0.06 : 0.035),
    );
  }

  @override
  bool shouldRepaint(covariant _ClassicGeometryPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      accent != oldDelegate.accent ||
      isDark != oldDelegate.isDark;
}

class _PrayerAtmospherePreviewPainter extends CustomPainter {
  const _PrayerAtmospherePreviewPainter({
    required this.primary,
    required this.primaryDark,
    required this.isDark,
    required this.surface,
  });

  final Color primary;
  final Color primaryDark;
  final bool isDark;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.82);
    final colors = isDark
        ? [
            Color.lerp(primaryDark, const Color(0xFF06131B), 0.42)!,
            Color.lerp(primary, const Color(0xFF102B34), 0.54)!,
          ]
        : [primaryDark, Color.lerp(primary, primaryDark, 0.35)!];
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(canvasRect);
    canvas.drawRect(canvasRect, background);

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, size.shortestSide * 0.0038)
      ..color = Colors.white.withValues(alpha: 0.075);
    final center = Offset(size.width * 0.5, size.height * 0.40);
    final radius = size.shortestSide * 0.34;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      ink,
    );
    for (var index = 0; index < 5; index++) {
      final x = size.width * (0.08 + index * 0.21);
      canvas.drawLine(
        Offset(x, size.height * 0.28),
        Offset(x + size.width * 0.08, size.height * 0.62),
        ink..color = Colors.white.withValues(alpha: 0.035),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerAtmospherePreviewPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      primaryDark != oldDelegate.primaryDark ||
      isDark != oldDelegate.isDark ||
      surface != oldDelegate.surface;
}

class _CountdownPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.43;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, size.shortestSide * 0.055)
      ..color = Colors.white.withValues(alpha: 0.16);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = track.strokeWidth
      ..color = const Color(0xFFF3D58A).withValues(alpha: 0.92);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.32, false, progress);
    canvas.drawCircle(
      center,
      radius * 0.76,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPreviewPainter oldDelegate) => false;
}

class _PrayerHandoffPreviewPainter extends CustomPainter {
  const _PrayerHandoffPreviewPainter({required this.color, required this.line});

  final Color color;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.40)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.05,
        size.width * 0.34,
        size.height * 0.74,
        size.width * 0.52,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.10,
        size.width * 0.84,
        size.height * 0.63,
        size.width,
        size.height * 0.30,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PrayerHandoffPreviewPainter oldDelegate) =>
      color != oldDelegate.color || line != oldDelegate.line;
}

class _ManuscriptPreviewPainter extends CustomPainter {
  const _ManuscriptPreviewPainter({
    required this.ink,
    required this.illumination,
    required this.isDark,
    required this.textDirection,
  });

  final Color ink;
  final Color illumination;
  final bool isDark;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: isDark ? 0.18 : 0.10);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = illumination.withValues(alpha: isDark ? 0.22 : 0.16);
    canvas.drawRect(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      outer,
    );
    canvas.drawRect(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      inner,
    );
    final marginX = textDirection == TextDirection.rtl
        ? size.width * 0.93
        : size.width * 0.07;
    canvas.drawLine(
      Offset(marginX, size.height * 0.23),
      Offset(marginX, size.height * 0.83),
      inner,
    );
    for (var index = 0; index < 3; index++) {
      final y = size.height * (0.29 + index * 0.18);
      canvas.drawCircle(
        Offset(marginX, y),
        size.shortestSide * 0.012,
        outer,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPreviewPainter oldDelegate) =>
      ink != oldDelegate.ink ||
      illumination != oldDelegate.illumination ||
      isDark != oldDelegate.isDark ||
      textDirection != oldDelegate.textDirection;
}

class _QuranHandoffPreviewPainter extends CustomPainter {
  const _QuranHandoffPreviewPainter({
    required this.color,
    required this.illumination,
  });

  final Color color;
  final Color illumination;

  @override
  void paint(Canvas canvas, Size size) {
    final strong = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..strokeWidth = 1;
    final light = Paint()
      ..color = illumination.withValues(alpha: 0.20)
      ..strokeWidth = 0.75;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.32),
      Offset(size.width * 0.44, size.height * 0.32),
      strong,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.32),
      Offset(size.width * 0.92, size.height * 0.32),
      strong,
    );
    final diamond = Path()
      ..moveTo(size.width * 0.50, size.height * 0.05)
      ..lineTo(size.width * 0.54, size.height * 0.32)
      ..lineTo(size.width * 0.50, size.height * 0.59)
      ..lineTo(size.width * 0.46, size.height * 0.32)
      ..close();
    canvas.drawPath(diamond, light..style = PaintingStyle.stroke);
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.68),
      Offset(size.width * 0.84, size.height * 0.68),
      light,
    );
  }

  @override
  bool shouldRepaint(covariant _QuranHandoffPreviewPainter oldDelegate) =>
      color != oldDelegate.color || illumination != oldDelegate.illumination;
}
