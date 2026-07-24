import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_quran_kit.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PrayerSupportingTools extends StatefulWidget {
  const PrayerSupportingTools({
    super.key,
    required this.configuration,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    this.entranceAnimation,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final Animation<double>? entranceAnimation;

  @override
  State<PrayerSupportingTools> createState() => _PrayerSupportingToolsState();
}

class _PrayerSupportingToolsState extends State<PrayerSupportingTools> {
  static const _completeAnimation = AlwaysStoppedAnimation<double>(1);

  bool _moreExpanded = false;
  bool _quranExpanded = false;

  void _toggleQuranKit() {
    HapticFeedback.lightImpact();
    setState(() => _quranExpanded = !_quranExpanded);
  }

  void _toggleMore({required bool quranLivesInMore}) {
    HapticFeedback.selectionClick();
    setState(() {
      _moreExpanded = !_moreExpanded;
      if (!_moreExpanded && quranLivesInMore) _quranExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final feature in widget.features) feature.id: feature};
    List<HomeFeatureDefinition> resolve(List<HomeFeatureId> ids) {
      return ids
          .where((id) => !widget.configuration.hiddenFeatures.contains(id))
          .map((id) => byId[id])
          .whereType<HomeFeatureDefinition>()
          .toList(growable: false);
    }

    final primary = resolve(widget.configuration.primaryFeatures);
    final more = resolve(widget.configuration.viewMoreFeatures);
    final quranInPrimary = primary.any(_isQuranKit);
    final quranInMore = more.any(_isQuranKit);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entrance = widget.entranceAnimation ?? _completeAnimation;

    if (primary.isEmpty && more.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrayerTodayMotionReveal(
          key: const ValueKey('prayer-tools-heading-reveal'),
          animation: entrance,
          begin: 0.56,
          end: 0.74,
          distance: 5,
          child: _ToolSectionHeading(
            title: l10n.homeMoreTools,
            visibleCount: primary.length,
          ),
        ),
        if (primary.isNotEmpty) ...[
          const SizedBox(height: 14),
          PrayerTodayMotionReveal(
            key: const ValueKey('prayer-tools-primary-reveal'),
            animation: entrance,
            begin: 0.62,
            end: 0.88,
            distance: 8,
            beginScale: 0.995,
            child: _PrayerToolGrid(
              features: primary,
              quranExpanded: _quranExpanded,
              onQuranTap: _toggleQuranKit,
              quranWorkspace: quranInPrimary ? _buildQuranWorkspace() : null,
            ),
          ),
        ],
        if (more.isNotEmpty) ...[
          const SizedBox(height: 16),
          PrayerTodayMotionReveal(
            key: const ValueKey('prayer-tools-more-trigger-reveal'),
            animation: entrance,
            begin: 0.72,
            end: 0.94,
            distance: 5,
            child: Align(
              alignment: AlignmentDirectional.center,
              child: _ViewMorePill(
                expanded: _moreExpanded,
                count: more.length,
                onTap: () => _toggleMore(quranLivesInMore: quranInMore),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration:
                  reduceMotion ? Duration.zero : PrayerTodayMotion.expansion,
              curve: PrayerTodayMotion.entranceCurve,
              alignment: Alignment.topCenter,
              child: _moreExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          const _ExpandingThread(),
                          const SizedBox(height: 13),
                          _PrayerToolGrid(
                            key: const ValueKey('prayer-more-tools'),
                            features: more,
                            secondary: true,
                            quranExpanded: _quranExpanded,
                            onQuranTap: _toggleQuranKit,
                            quranWorkspace:
                                quranInMore ? _buildQuranWorkspace() : null,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('prayer-more-tools-collapsed'),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuranWorkspace() {
    return PrayerQuranKitWorkspace(
      isDark: widget.isDark,
      actions: widget.actions,
      openLastReadSurah: widget.openLastReadSurah,
      openLastReciterAudio: widget.openLastReciterAudio,
      openLastRadioStation: widget.openLastRadioStation,
      onCollapse: _toggleQuranKit,
    );
  }

  static bool _isQuranKit(HomeFeatureDefinition feature) =>
      feature.id == HomeFeatureId.quranKit;
}

class _ToolSectionHeading extends StatelessWidget {
  const _ToolSectionHeading({required this.title, required this.visibleCount});

  final String title;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 26,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.primaryColor, context.accentColor],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$visibleCount',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _PrayerToolGrid extends StatelessWidget {
  const _PrayerToolGrid({
    super.key,
    required this.features,
    required this.quranExpanded,
    required this.onQuranTap,
    required this.quranWorkspace,
    this.secondary = false,
  });

  final List<HomeFeatureDefinition> features;
  final bool quranExpanded;
  final VoidCallback onQuranTap;
  final Widget? quranWorkspace;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 610
                ? 3
                : 2;
        final extent = secondary
            ? (scale > 1.5 ? 102.0 : 78.0)
            : (scale > 1.5 ? 132.0 : 108.0);
        final rowCount = (features.length / columns).ceil();
        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: 11),
              _ToolRow(
                features: features,
                startIndex: rowIndex * columns,
                columns: columns,
                extent: extent,
                secondary: secondary,
                animateTiles: secondary,
                quranExpanded: quranExpanded,
                onQuranTap: onQuranTap,
              ),
              if (quranWorkspace != null &&
                  _rowContainsQuranKit(
                    features,
                    start: rowIndex * columns,
                    columns: columns,
                  ))
                _QuranWorkspaceReveal(
                  visible: quranExpanded,
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                  child: quranWorkspace!,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.features,
    required this.startIndex,
    required this.columns,
    required this.extent,
    required this.secondary,
    required this.animateTiles,
    required this.quranExpanded,
    required this.onQuranTap,
  });

  final List<HomeFeatureDefinition> features;
  final int startIndex;
  final int columns;
  final double extent;
  final bool secondary;
  final bool animateTiles;
  final bool quranExpanded;
  final VoidCallback onQuranTap;

  @override
  Widget build(BuildContext context) {
    final endIndex = math.min(startIndex + columns, features.length);
    final rowFeatures = features.sublist(startIndex, endIndex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) const SizedBox(width: 11),
          Expanded(
            child: index < rowFeatures.length
                ? SizedBox(
                    height: extent,
                    child: _buildTile(rowFeatures[index], startIndex + index),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildTile(HomeFeatureDefinition feature, int index) {
    final tile = _PrayerToolTile(
      key: ValueKey('prayer-tool-${feature.id.name}'),
      feature: feature,
      secondary: secondary,
      expanded: feature.id == HomeFeatureId.quranKit && quranExpanded,
      onTap: feature.id == HomeFeatureId.quranKit ? onQuranTap : feature.onTap,
    );
    if (!animateTiles) return tile;
    return _ToolEntrance(index: index, child: tile);
  }
}

bool _rowContainsQuranKit(
  List<HomeFeatureDefinition> features, {
  required int start,
  required int columns,
}) {
  final end = math.min(start + columns, features.length);
  for (var index = start; index < end; index++) {
    if (features[index].id == HomeFeatureId.quranKit) return true;
  }
  return false;
}

class _PrayerToolTile extends StatefulWidget {
  const _PrayerToolTile({
    super.key,
    required this.feature,
    required this.secondary,
    required this.expanded,
    required this.onTap,
  });

  final HomeFeatureDefinition feature;
  final bool secondary;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_PrayerToolTile> createState() => _PrayerToolTileState();
}

class _PrayerToolTileState extends State<_PrayerToolTile> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _featureAccent(context, widget.feature.id);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(widget.secondary ? 18 : 23);
    return Semantics(
      button: true,
      expanded:
          widget.feature.id == HomeFeatureId.quranKit ? widget.expanded : null,
      label: widget.feature.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _active = true),
        onExit: (_) => setState(() => _active = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _active = value),
          child: AnimatedScale(
            scale: _active && !reduceMotion ? 1.018 : 1,
            duration:
                reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
            curve: PrayerTodayMotion.entranceCurve,
            child: AnimatedContainer(
              duration:
                  reduceMotion ? Duration.zero : PrayerTodayMotion.stateChange,
              transform: Matrix4.translationValues(
                0,
                _active && !reduceMotion ? -3 : 0,
                0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    Color.alphaBlend(
                      accent.withValues(
                        alpha: widget.expanded
                            ? 0.13
                            : _active
                                ? 0.09
                                : 0.045,
                      ),
                      scheme.surface,
                    ),
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.015),
                      scheme.surface,
                    ),
                  ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: accent.withValues(
                    alpha: widget.expanded
                        ? 0.34
                        : _active
                            ? 0.22
                            : 0.11,
                  ),
                ),
                boxShadow: _active && !reduceMotion
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : const [],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (widget.feature.id != HomeFeatureId.quranKit) {
                      HapticFeedback.selectionClick();
                    }
                    widget.onTap();
                  },
                  onHighlightChanged: (value) =>
                      setState(() => _active = value),
                  overlayColor: WidgetStatePropertyAll(
                    accent.withValues(alpha: 0.07),
                  ),
                  child: widget.secondary
                      ? _SecondaryToolContent(
                          feature: widget.feature,
                          accent: accent,
                          expanded: widget.expanded,
                        )
                      : _PrimaryToolContent(
                          feature: widget.feature,
                          accent: accent,
                          expanded: widget.expanded,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryToolContent extends StatelessWidget {
  const _PrimaryToolContent({
    required this.feature,
    required this.accent,
    required this.expanded,
  });

  final HomeFeatureDefinition feature;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final quranKit = feature.id == HomeFeatureId.quranKit;
    return Stack(
      children: [
        PositionedDirectional(
          end: -16,
          top: -18,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.035),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.095),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: quranKit
                        ? _QuranToolStack(accent: accent, expanded: expanded)
                        : _FeatureGlyph(feature: feature, color: accent),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : PrayerTodayMotion.stateChange,
                    curve: PrayerTodayMotion.stateCurve,
                    child: Icon(
                      quranKit
                          ? Icons.expand_more_rounded
                          : Icons.arrow_outward_rounded,
                      color: accent.withValues(alpha: 0.62),
                      size: 19,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                feature.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryToolContent extends StatelessWidget {
  const _SecondaryToolContent({
    required this.feature,
    required this.accent,
    required this.expanded,
  });

  final HomeFeatureDefinition feature;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final quranKit = feature.id == HomeFeatureId.quranKit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.085),
              shape: BoxShape.circle,
            ),
            child: quranKit
                ? _QuranToolStack(accent: accent, expanded: expanded)
                : _FeatureGlyph(feature: feature, color: accent, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              feature.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
            ),
          ),
          if (quranKit)
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : PrayerTodayMotion.stateChange,
              curve: PrayerTodayMotion.stateCurve,
              child: Icon(Icons.expand_more_rounded, color: accent, size: 18),
            ),
        ],
      ),
    );
  }
}

class _QuranToolStack extends StatelessWidget {
  const _QuranToolStack({required this.accent, required this.expanded});

  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: expanded ? 0.90 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : PrayerTodayMotion.stateChange,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(3, 2),
            child: Transform.rotate(
              angle: 0.08,
              child: Icon(Icons.menu_book_outlined, color: accent, size: 19),
            ),
          ),
          Icon(Icons.auto_stories_rounded, color: accent, size: 20),
        ],
      ),
    );
  }
}

class _FeatureGlyph extends StatelessWidget {
  const _FeatureGlyph({
    required this.feature,
    required this.color,
    this.size = 21,
  });

  final HomeFeatureDefinition feature;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (feature.svgAsset == null) {
      return Icon(feature.icon ?? Icons.apps_rounded, color: color, size: size);
    }
    return SvgPicture(
      AssetBytesLoader(feature.svgAsset!),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _ViewMorePill extends StatelessWidget {
  const _ViewMorePill({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = context.primaryColor;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final label = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
      child: Text(
        expanded ? l10n.showLess : l10n.viewMore,
        key: ValueKey(expanded),
        maxLines: largeText ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
    return Semantics(
      button: true,
      expanded: expanded,
      label: '${expanded ? l10n.showLess : l10n.viewMore}, $count',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        width: largeText ? double.infinity : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration:
                  reduceMotion ? Duration.zero : PrayerTodayMotion.stateChange,
              curve: PrayerTodayMotion.entranceCurve,
              padding: const EdgeInsets.fromLTRB(13, 8, 9, 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: expanded ? 0.105 : 0.055),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: accent.withValues(alpha: expanded ? 0.25 : 0.11),
                ),
              ),
              child: Row(
                mainAxisSize: largeText ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (largeText) Expanded(child: label) else label,
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.125 : 0,
                    duration: reduceMotion
                        ? Duration.zero
                        : PrayerTodayMotion.expansion,
                    curve: PrayerTodayMotion.stateCurve,
                    child: Icon(Icons.add_rounded, color: accent, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranWorkspaceReveal extends StatelessWidget {
  const _QuranWorkspaceReveal({
    required this.visible,
    required this.reduceMotion,
    required this.child,
  });

  final bool visible;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: reduceMotion ? Duration.zero : PrayerTodayMotion.expansion,
        curve: PrayerTodayMotion.entranceCurve,
        alignment: Alignment.topCenter,
        child: visible
            ? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: child,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ExpandingThread extends StatelessWidget {
  const _ExpandingThread();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  context.primaryColor.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.42),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolEntrance extends StatelessWidget {
  const _ToolEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(
              milliseconds:
                  PrayerTodayMotion.stateChange.inMilliseconds + index * 36,
            ),
      curve: PrayerTodayMotion.entranceCurve,
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

Color _featureAccent(BuildContext context, HomeFeatureId id) {
  return switch (id.index % 4) {
    0 => context.primaryColor,
    1 => context.primaryVariantColor,
    2 => context.accentColor,
    _ => context.primaryDarkColor,
  };
}
