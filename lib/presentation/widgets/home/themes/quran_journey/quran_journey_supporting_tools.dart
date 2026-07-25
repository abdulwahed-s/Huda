import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';
import 'package:vector_graphics/vector_graphics.dart';

class QuranJourneySupportingTools extends StatefulWidget {
  const QuranJourneySupportingTools({
    super.key,
    required this.configuration,
    required this.features,
    required this.isDark,
    this.entranceAnimation,
    this.reveal = 1,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final bool isDark;
  final Animation<double>? entranceAnimation;
  final double reveal;

  @override
  State<QuranJourneySupportingTools> createState() =>
      _QuranJourneySupportingToolsState();
}

class _QuranJourneySupportingToolsState
    extends State<QuranJourneySupportingTools>
    with SingleTickerProviderStateMixin {
  bool _moreExpanded = false;
  late final AnimationController _moreController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _moreController = AnimationController(
      vsync: this,
      duration: QuranJourneyMotion.expansion,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _moreController
        ..stop()
        ..value = _moreExpanded ? 1 : 0;
    }
  }

  void _toggleMore() {
    HapticFeedback.selectionClick();
    setState(() => _moreExpanded = !_moreExpanded);
    if (_reduceMotion) {
      _moreController.value = _moreExpanded ? 1 : 0;
    } else if (_moreExpanded) {
      _moreController.forward();
    } else {
      _moreController.reverse();
    }
  }

  @override
  void dispose() {
    _moreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final feature in widget.features) feature.id: feature};
    List<HomeFeatureDefinition> resolve(List<HomeFeatureId> ids) => ids
        .where((id) => !widget.configuration.hiddenFeatures.contains(id))
        .map((id) => byId[id])
        .whereType<HomeFeatureDefinition>()
        .toList(growable: false);

    final primary = resolve(widget.configuration.primaryFeatures);
    final more = resolve(widget.configuration.viewMoreFeatures);
    if (primary.isEmpty && more.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final moreContent = ColoredBox(
      color: context.primaryColor.withValues(
        alpha: widget.isDark ? 0.035 : 0.014,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(7, 3, 7, 3),
        child: _ToolIndex(
          key: const ValueKey('quran-more-tools'),
          features: more,
          startIndex: primary.length,
          secondary: true,
        ),
      ),
    );

    return KeyedSubtree(
      key: const ValueKey('quran-supporting-boundary'),
      child: _QuranIndexField(
        isDark: widget.isDark,
        reveal: widget.reveal,
        entranceAnimation: widget.entranceAnimation,
        child: KeyedSubtree(
          key: const ValueKey('quran-supporting-tools'),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 3, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IndexHeading(
                  key: const ValueKey('quran-supporting-index-heading'),
                  title: l10n.homeMoreTools,
                  visibleCount: primary.length,
                ),
                if (primary.isNotEmpty)
                  _ToolIndex(
                    features: primary,
                    startIndex: 0,
                  ),
                if (more.isNotEmpty) ...[
                  _ViewMoreIndexControl(
                    expanded: _moreExpanded,
                    count: more.length,
                    onTap: _toggleMore,
                  ),
                  KeyedSubtree(
                    key: const ValueKey('quran-more-tools-expansion'),
                    child: AnimatedBuilder(
                      animation: _moreController,
                      child: moreContent,
                      builder: (context, child) {
                        if (!_moreExpanded && _moreController.isDismissed) {
                          return const SizedBox.shrink(
                            key: ValueKey('quran-more-tools-collapsed'),
                          );
                        }
                        final value = _reduceMotion
                            ? (_moreExpanded ? 1.0 : 0.0)
                            : QuranJourneyMotion.stateCurve.transform(
                                _moreController.value,
                              );
                        final opacity = QuranJourneyMotion.phase(
                          value,
                          begin: 0,
                          end: 0.68,
                        );
                        return ExcludeSemantics(
                          excluding: !_moreExpanded,
                          child: IgnorePointer(
                            ignoring: !_moreExpanded,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: value,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * -5),
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranIndexField extends StatelessWidget {
  const _QuranIndexField({
    required this.isDark,
    required this.reveal,
    required this.entranceAnimation,
    required this.child,
  });

  final bool isDark;
  final double reveal;
  final Animation<double>? entranceAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topField = Color.alphaBlend(
      QuranJourneyVisualStyle.illumination(context).withValues(
        alpha: isDark ? 0.075 : 0.032,
      ),
      scheme.surface,
    );
    final lowerField = Color.alphaBlend(
      context.primaryVariantColor.withValues(
        alpha: isDark ? 0.10 : 0.038,
      ),
      scheme.surface,
    );
    final animation =
        entranceAnimation ?? AlwaysStoppedAnimation<double>(reveal);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            key: const ValueKey('quran-supporting-background'),
            child: CustomPaint(
              painter: _QuranIndexFieldPainter(
                topField: topField,
                lowerField: lowerField,
                ink: context.primaryColor,
                illumination: QuranJourneyVisualStyle.illumination(context),
                isDark: isDark,
                revealAnimation: animation,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              key: ValueKey('quran-supporting-handoff'),
              height: 50,
            ),
            QuranJourneyEntranceReveal(
              key: const ValueKey('quran-supporting-entrance'),
              animation: entranceAnimation,
              progress: reveal,
              begin: 0.80,
              end: 1,
              distance: 5,
              beginScale: 0.997,
              startOpacity: 0.80,
              child: child,
            ),
          ],
        ),
      ],
    );
  }
}

class _IndexHeading extends StatelessWidget {
  const _IndexHeading({
    super.key,
    required this.title,
    required this.visibleCount,
  });

  final String title;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(9, 8, 9, 12),
        child: Row(
          children: [
            Text(
              '${visibleCount.toString().padLeft(2, '0')} /',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranJourneyVisualStyle.illumination(context),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.12,
                    ),
              ),
            ),
            Container(
              width: 46,
              height: 1,
              color: color.withValues(alpha: 0.14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIndex extends StatelessWidget {
  const _ToolIndex({
    super.key,
    required this.features,
    required this.startIndex,
    this.secondary = false,
  });

  final List<HomeFeatureDefinition> features;
  final int startIndex;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = scale > 1.4 || constraints.maxWidth < 430
            ? 1
            : constraints.maxWidth >= 820
                ? 3
                : 2;
        final rowCount = (features.length / columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < rowCount; row++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0)
                        const QuranJourneyDivider(
                          axis: Axis.vertical,
                          inset: 10,
                        ),
                      Expanded(
                        child: row * columns + column < features.length
                            ? _IndexAction(
                                key: ValueKey(
                                  'quran-tool-${features[row * columns + column].id.name}',
                                ),
                                feature: features[row * columns + column],
                                index: startIndex + row * columns + column + 1,
                                secondary: secondary,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IndexAction extends StatefulWidget {
  const _IndexAction({
    super.key,
    required this.feature,
    required this.index,
    required this.secondary,
  });

  final HomeFeatureDefinition feature;
  final int index;
  final bool secondary;

  @override
  State<_IndexAction> createState() => _IndexActionState();
}

class _IndexActionState extends State<_IndexAction> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.feature.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _featureAccent(context, widget.feature.id);
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.feature.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: QuranJourneyPressTransform(
            pressed: _pressed,
            child: AnimatedContainer(
              duration:
                  reduceMotion ? Duration.zero : QuranJourneyMotion.interaction,
              constraints: const BoxConstraints(minHeight: 68),
              decoration: BoxDecoration(
                color: _highlighted
                    ? accent.withValues(alpha: 0.05)
                    : Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: _focused
                        ? accent.withValues(alpha: 0.56)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                  left: BorderSide(
                    color: _focused
                        ? accent.withValues(alpha: 0.56)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                  right: BorderSide(
                    color: _focused
                        ? accent.withValues(alpha: 0.56)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                  bottom: BorderSide(
                    color: _focused
                        ? accent.withValues(alpha: 0.56)
                        : QuranJourneyVisualStyle.rule(context),
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: _activate,
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  overlayColor: WidgetStatePropertyAll(
                    accent.withValues(alpha: 0.045),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      9,
                      11,
                      8,
                      10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 27,
                          child: Text(
                            widget.index.toString().padLeft(2, '0'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: accent.withValues(
                                    alpha: widget.secondary ? 0.58 : 0.78,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _FeatureGlyph(
                          feature: widget.feature,
                          color: accent.withValues(
                            alpha: widget.secondary ? 0.68 : 0.92,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            widget.feature.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: widget.secondary
                                      ? scheme.onSurfaceVariant
                                      : null,
                                  fontWeight: widget.secondary
                                      ? FontWeight.w700
                                      : FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        QuranJourneyDirectionalShift(
                          active: _highlighted,
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            color: accent.withValues(alpha: 0.42),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
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

class _FeatureGlyph extends StatelessWidget {
  const _FeatureGlyph({required this.feature, required this.color});

  final HomeFeatureDefinition feature;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (feature.svgAsset != null) {
      return SvgPicture(
        AssetBytesLoader(feature.svgAsset!),
        width: 21,
        height: 21,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(feature.icon ?? Icons.apps_rounded, color: color, size: 21);
  }
}

class _ViewMoreIndexControl extends StatefulWidget {
  const _ViewMoreIndexControl({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  State<_ViewMoreIndexControl> createState() => _ViewMoreIndexControlState();
}

class _ViewMoreIndexControlState extends State<_ViewMoreIndexControl> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = context.primaryColor;
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = widget.expanded ? l10n.showLess : l10n.viewMore;
    final focusSide = BorderSide(
      color:
          _focused ? illumination.withValues(alpha: 0.72) : Colors.transparent,
      width: QuranJourneyVisualStyle.ruleWidth,
    );
    return Semantics(
      button: true,
      expanded: widget.expanded,
      label: label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: FocusableActionDetector(
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            child: QuranJourneyPressTransform(
              pressed: _pressed,
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : QuranJourneyMotion.interaction,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _highlighted ? 0.045 : 0),
                  border: Border(
                    top: focusSide,
                    left: focusSide,
                    right: focusSide,
                    bottom: _focused
                        ? focusSide
                        : BorderSide(
                            color: QuranJourneyVisualStyle.rule(
                              context,
                              strong: true,
                            ),
                            width: QuranJourneyVisualStyle.ruleWidth,
                          ),
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    key: const ValueKey('quran-view-more-toggle'),
                    onTap: widget.onTap,
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    overlayColor: WidgetStatePropertyAll(
                      color.withValues(alpha: 0.045),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(10, 12, 10, 12),
                      child: Row(
                        children: [
                          Text(
                            '+${widget.count.toString().padLeft(2, '0')}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: illumination,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: QuranJourneyDataTransition(
                              transitionKey: label,
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: widget.expanded ? 0.5 : 0,
                            duration: reduceMotion
                                ? Duration.zero
                                : QuranJourneyMotion.stateChange,
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: color,
                              size: 21,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _QuranIndexFieldPainter extends CustomPainter {
  const _QuranIndexFieldPainter({
    required this.topField,
    required this.lowerField,
    required this.ink,
    required this.illumination,
    required this.isDark,
    required this.revealAnimation,
  }) : super(repaint: revealAnimation);

  final Color topField;
  final Color lowerField;
  final Color ink;
  final Color illumination;
  final bool isDark;
  final Animation<double> revealAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final reveal = revealAnimation.value.clamp(0.0, 1.0);
    final edgeReveal = Curves.easeOutCubic.transform(
      ((reveal - 0.70) / 0.24).clamp(0.0, 1.0),
    );
    if (edgeReveal <= 0) return;

    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    final topEdge = _topEdge(size);
    final field = Path.from(topEdge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      field,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topField.withValues(alpha: edgeReveal),
            lowerField.withValues(alpha: edgeReveal),
          ],
        ).createShader(Offset.zero & size),
    );

    final rule = Paint()
      ..color = ink.withValues(
        alpha: (isDark ? 0.27 : 0.16) * edgeReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.ruleWidth;
    final highlight = Paint()
      ..color = illumination.withValues(
        alpha: (isDark ? 0.31 : 0.22) * edgeReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;

    canvas.drawPath(topEdge, rule);
    canvas
      ..save()
      ..translate(0, 4)
      ..drawPath(topEdge, highlight)
      ..restore();

    final frame = Path()
      ..moveTo(0.5, 40)
      ..lineTo(0.5, size.height - 0.5)
      ..lineTo(size.width - 0.5, size.height - 0.5)
      ..lineTo(size.width - 0.5, 40);
    canvas.drawPath(frame, rule);

    final center = Offset(size.width / 2, 20);
    final registration = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..lineTo(center.dx + 4, center.dy)
      ..lineTo(center.dx, center.dy + 4)
      ..lineTo(center.dx - 4, center.dy)
      ..close();
    canvas.drawPath(
      registration,
      Paint()
        ..color = illumination.withValues(
          alpha: (isDark ? 0.42 : 0.32) * edgeReveal,
        ),
    );
    canvas.restore();
  }

  Path _topEdge(Size size) {
    final center = size.width / 2;
    final highHalf = (size.width * 0.09).clamp(28.0, 86.0);
    final middleHalf = (size.width * 0.23).clamp(74.0, 220.0);
    final lowHalf = (size.width * 0.38).clamp(122.0, 420.0);
    return Path()
      ..moveTo(0, 40)
      ..lineTo(center - lowHalf, 40)
      ..lineTo(center - lowHalf, 34)
      ..lineTo(center - middleHalf, 34)
      ..lineTo(center - middleHalf, 26)
      ..lineTo(center - highHalf, 26)
      ..lineTo(center - highHalf, 14)
      ..lineTo(center + highHalf, 14)
      ..lineTo(center + highHalf, 26)
      ..lineTo(center + middleHalf, 26)
      ..lineTo(center + middleHalf, 34)
      ..lineTo(center + lowHalf, 34)
      ..lineTo(center + lowHalf, 40)
      ..lineTo(size.width, 40);
  }

  @override
  bool shouldRepaint(covariant _QuranIndexFieldPainter oldDelegate) =>
      oldDelegate.topField != topField ||
      oldDelegate.lowerField != lowerField ||
      oldDelegate.ink != ink ||
      oldDelegate.illumination != illumination ||
      oldDelegate.isDark != isDark ||
      oldDelegate.revealAnimation != revealAnimation;
}

Color _featureAccent(BuildContext context, HomeFeatureId id) {
  return switch (id) {
    HomeFeatureId.prayerTimes ||
    HomeFeatureId.hijriCalendar ||
    HomeFeatureId.ramadan ||
    HomeFeatureId.qiblah =>
      context.primaryVariantColor,
    HomeFeatureId.tasbih ||
    HomeFeatureId.checklist ||
    HomeFeatureId.zakat =>
      context.accentColor,
    _ => context.primaryColor,
  };
}
