import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/feature_card.dart';
import 'package:huda/presentation/widgets/home/feature_grid.dart';

typedef ClassicFeatureGridBuilder = Widget Function(Widget trailingCard);

class ClassicViewMoreCollection extends StatefulWidget {
  const ClassicViewMoreCollection({
    super.key,
    required this.features,
    required this.isDarkMode,
    required this.primaryItemCount,
    required this.gridBuilder,
  });

  final List<HomeFeatureDefinition> features;
  final bool isDarkMode;
  final int primaryItemCount;
  final ClassicFeatureGridBuilder gridBuilder;

  @override
  State<ClassicViewMoreCollection> createState() =>
      _ClassicViewMoreCollectionState();
}

class _ClassicViewMoreCollectionState extends State<ClassicViewMoreCollection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final LayerLink _anchorLink = LayerLink();
  final FocusNode _anchorFocusNode = FocusNode(
    debugLabel: 'Classic View More anchor',
  );
  final Map<HomeFeatureId, FocusNode> _featureFocusNodes = {};

  bool _expanded = false;
  bool _disableAnimations = false;
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  Duration get _motionDuration {
    final extra = math.min(widget.features.length * 12, 120);
    return Duration(milliseconds: 480 + extra);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _motionDuration,
      value: 0,
    );
    _syncFeatureFocusNodes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
    if (disableAnimations) {
      _controller.value = _expanded ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(covariant ClassicViewMoreCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _motionDuration;
    _syncFeatureFocusNodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _anchorFocusNode.dispose();
    for (final focusNode in _featureFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncFeatureFocusNodes() {
    final currentIds = widget.features.map((feature) => feature.id).toSet();
    final removedIds = _featureFocusNodes.keys
        .where((featureId) => !currentIds.contains(featureId))
        .toList();
    for (final featureId in removedIds) {
      _featureFocusNodes.remove(featureId)?.dispose();
    }
    for (final feature in widget.features) {
      _featureFocusNodes.putIfAbsent(
        feature.id,
        () => FocusNode(
          debugLabel: 'Classic View More ${feature.id.name}',
        ),
      );
    }
  }

  void _toggle() {
    final nextExpanded = !_expanded;
    if (!nextExpanded &&
        _featureFocusNodes.values.any((focusNode) => focusNode.hasFocus) &&
        !_anchorFocusNode.hasFocus) {
      _anchorFocusNode.requestFocus();
    }

    HapticFeedback.selectionClick();
    setState(() => _expanded = nextExpanded);

    final target = nextExpanded ? 1.0 : 0.0;
    if (_disableAnimations) {
      _controller.value = target;
      return;
    }

    final distance = (target - _controller.value).abs();
    final milliseconds = math.max(
      120,
      (_motionDuration.inMilliseconds * distance).round(),
    );
    _controller.animateTo(
      target,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = FeatureGridLayout.resolve(
          context,
          constraints.maxWidth,
        );
        final primaryGrid = widget.gridBuilder(
          CompositedTransformTarget(
            key: const ValueKey('classic-view-more-grid-target'),
            link: _anchorLink,
            child: const SizedBox.expand(),
          ),
        );
        return AnimatedBuilder(
          animation: _controller,
          child: primaryGrid,
          builder: (context, child) => _buildLayout(
            context,
            layout,
            child!,
          ),
        );
      },
    );
  }

  Widget _buildLayout(
    BuildContext context,
    FeatureGridLayout layout,
    Widget primaryGrid,
  ) {
    final direction = Directionality.of(context);
    final anchorSlot = widget.primaryItemCount;
    final absoluteAnchorRect = layout.rectForSlot(anchorSlot, direction);
    final anchorRect = absoluteAnchorRect.shift(
      Offset(0, -absoluteAnchorRect.top),
    );
    final destinations = <Rect>[
      for (var index = 0; index < widget.features.length; index++)
        layout
            .rectForSlot(
              anchorSlot + index + 1,
              direction,
            )
            .shift(
              Offset(0, -absoluteAnchorRect.top),
            ),
    ];
    final destinationSlots = <int>[
      for (var index = 0; index < widget.features.length; index++)
        anchorSlot + index + 1,
    ];
    final maxDistance = destinationSlots.fold<double>(
      0,
      (current, slot) => math.max(
        current,
        _slotDistance(slot, anchorSlot, layout.columnCount),
      ),
    );

    var layerHeight = layout.cardHeight;
    final positionedCards = <Widget>[];
    for (var index = widget.features.length - 1; index >= 0; index--) {
      final progress = _cardProgress(
        _controller.value,
        destinationSlots[index],
        anchorSlot,
        layout.columnCount,
        maxDistance,
      );
      final origin = anchorRect.shift(
        _stackOffset(index, direction, layout.columnCount),
      );
      final rect = Rect.lerp(origin, destinations[index], progress)!;
      layerHeight = math.max(layerHeight, rect.bottom);
      positionedCards.add(
        Positioned.fromRect(
          key: ValueKey(
            'classic-view-more-position-${widget.features[index].id.name}',
          ),
          rect: rect,
          child: _buildFeatureCard(
            context,
            widget.features[index],
            index,
            progress,
            direction,
          ),
        ),
      );
    }
    final expansionExtent = math.max(0.0, layerHeight - layout.cardHeight);

    return Stack(
      key: const ValueKey('classic-view-more-stack'),
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            primaryGrid,
            SizedBox(height: expansionExtent),
          ],
        ),
        Positioned.fill(
          child: CompositedTransformFollower(
            link: _anchorLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(-anchorRect.left, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: layout.availableWidth,
                height: layerHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: positionedCards,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CompositedTransformFollower(
            link: _anchorLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.topLeft,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: layout.cardWidth,
                height: layout.cardHeight,
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: _buildAnchor(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    HomeFeatureDefinition feature,
    int index,
    double progress,
    TextDirection direction,
  ) {
    final depth = math.min(index, 2) + 1;
    final directionSign = direction == TextDirection.ltr ? 1.0 : -1.0;
    final rotation = (1 - progress) * directionSign * depth * 0.006;
    final scale = lerpDouble(0.965 - depth * 0.006, 1, progress)!;
    final interactive = _expanded && progress >= 0.999;
    final stackEmphasis = 1 - progress;

    return FocusTraversalOrder(
      order: NumericFocusOrder(index + 1),
      child: IgnorePointer(
        ignoring: !interactive,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(
                      alpha: 0.1 * stackEmphasis,
                    ),
                    blurRadius: 7 + 4 * stackEmphasis,
                    offset: Offset(0, 2 + depth.toDouble()),
                  ),
                ],
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: context.primaryColor.withValues(
                      alpha: 0.28 * stackEmphasis,
                    ),
                    width: 1.1,
                  ),
                ),
                child: FeatureCard(
                  key: ValueKey(
                    'classic-view-more-card-${feature.id.name}',
                  ),
                  title: feature.title,
                  svgAsset: feature.svgAsset,
                  icon: feature.icon,
                  onTap: feature.onTap,
                  isDarkMode: widget.isDarkMode,
                  index: index,
                  animateEntrance: false,
                  enabled: interactive,
                  focusNode: _featureFocusNodes[feature.id],
                  semanticsSortKey: OrdinalSortKey(
                    index + 1,
                    name: 'classic-view-more',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnchor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = _controller.value;
    final labelProgress = const Interval(
      0.18,
      0.62,
      curve: Curves.easeInOutCubic,
    ).transform(progress);
    final unfoldCompression = math.sin(math.pi * progress) * 0.025;
    final interactionCompression = _pressed ? 0.025 : 0.0;
    final scale = 1 - unfoldCompression - interactionCompression;
    final active = _hovered || _focused || _pressed || progress > 0;
    final primary = context.primaryColor;
    final iconSize =
        context.responsive(mobile: 32.sp, tablet: 50.sp, desktop: 64.sp);
    final paddingSize =
        context.responsive(mobile: 12.w, tablet: 20.w, desktop: 24.w);
    final fontSize =
        context.responsive(mobile: 12.sp, tablet: 16.sp, desktop: 20.sp);
    final currentLabel = _expanded ? l10n.showLess : l10n.viewMore;

    return Semantics(
      key: const ValueKey('classic-view-more-anchor'),
      container: true,
      button: true,
      enabled: true,
      expanded: _expanded,
      label: currentLabel,
      onTap: _toggle,
      sortKey: const OrdinalSortKey(0, name: 'classic-view-more'),
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDarkMode
                      ? [
                          const Color(0xFF2B2F3A),
                          const Color(0xFF1E2230),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF8FAFF),
                        ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: active
                      ? primary.withValues(alpha: 0.38)
                      : (widget.isDarkMode ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                  width: active ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? primary.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.09),
                    blurRadius: active ? 15 : 11,
                    offset: Offset(0, active ? 5 : 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  focusNode: _anchorFocusNode,
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: _toggle,
                  onFocusChange: (value) => setState(() => _focused = value),
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                        ? primary.withValues(alpha: 0.13)
                        : states.contains(WidgetState.hovered) ||
                                states.contains(WidgetState.focused)
                            ? primary.withValues(alpha: 0.07)
                            : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: 0,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: EdgeInsets.all(paddingSize),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: iconSize,
                                  color: widget.isDarkMode
                                      ? context.primaryLightColor
                                      : primary,
                                ),
                              ),
                              PositionedDirectional(
                                top: -5.h,
                                end: -7.w,
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: 22.w,
                                    minHeight: 22.w,
                                  ),
                                  alignment: Alignment.center,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.w),
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(11.r),
                                    border: Border.all(
                                      color: widget.isDarkMode
                                          ? const Color(0xFF1E2230)
                                          : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.features.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: fontSize * 1.3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (labelProgress < 1)
                                        Opacity(
                                          opacity: 1 - labelProgress,
                                          child: Text(
                                            l10n.viewMore,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: _labelStyle(
                                              fontSize,
                                              widget.isDarkMode,
                                            ),
                                          ),
                                        ),
                                      if (labelProgress > 0)
                                        Opacity(
                                          opacity: labelProgress,
                                          child: Text(
                                            l10n.showLess,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: _labelStyle(
                                              fontSize,
                                              widget.isDarkMode,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Transform.rotate(
                                  angle: math.pi * progress,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    size: 19.sp,
                                    color: widget.isDarkMode
                                        ? context.primaryLightColor
                                        : primary,
                                  ),
                                ),
                              ],
                            ),
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

  TextStyle _labelStyle(double fontSize, bool isDarkMode) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: isDarkMode ? Colors.white : Colors.black.withValues(alpha: 0.86),
      height: 1.2,
    );
  }

  double _cardProgress(
    double timeline,
    int destinationSlot,
    int anchorSlot,
    int columns,
    double maxDistance,
  ) {
    if (_disableAnimations) return _expanded ? 1 : 0;
    final distance = _slotDistance(destinationSlot, anchorSlot, columns);
    final normalizedDistance = maxDistance == 0 ? 0 : distance / maxDistance;
    final start = 0.025 + normalizedDistance * 0.15;
    final local = ((timeline - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  double _slotDistance(int slot, int anchorSlot, int columns) {
    final rowDistance = slot ~/ columns - anchorSlot ~/ columns;
    final columnDistance = slot % columns - anchorSlot % columns;
    return math.sqrt(
      rowDistance * rowDistance + columnDistance * columnDistance * 0.55,
    );
  }

  Offset _stackOffset(
    int index,
    TextDirection direction,
    int columns,
  ) {
    final depth = math.min(index, 2) + 1;
    final horizontalDirection = direction == TextDirection.ltr ? 1.0 : -1.0;
    return Offset(
      columns == 1 ? 0 : horizontalDirection * depth * 2.2,
      depth * 2.4,
    );
  }
}
