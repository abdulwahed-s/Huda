import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// Caps reading text at a comfortable measure and centers it.
/// See `design/RESPONSIVE.md` ("Reading text never runs wider than…").
///
/// With a half-open fold it keeps the content to the trailing side of the
/// fold instead of centering it across. A flat fold is one screen, so the
/// content centers across it (the iPhone Duo and Android report it as a
/// zero-width line). Fixed layouts (states, counters) pass [avoidFlatFolds]
/// to also stay off a flat fold with a width: a hinge between two screens,
/// where nothing can be drawn. That assumes the box is centered in the
/// window, as page content is.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = measure,
    this.alignment = Alignment.topCenter,
    this.avoidFlatFolds = false,
  });

  /// About 70 characters of Latin body text.
  static const double measure = 680;

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final bool avoidFlatFolds;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final avoid = fold.isHalfOpened || (avoidFlatFolds && fold.avoided);
    final capped = Align(
      alignment: alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
    if (!fold.splitsHorizontally || !avoid) return capped;
    final window = MediaQuery.sizeOf(context).width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite) return capped;
        // Where the fold falls in this box, assuming the box is centered.
        final offset = (window - width) / 2;
        final start = fold.start - offset;
        final end = fold.end - offset;
        if (end <= 0 || start >= width) return capped;
        // Centered in the trailing side.
        return Padding(
          padding: rtl
              ? EdgeInsets.only(right: width - start)
              : EdgeInsets.only(left: end),
          child: Align(
            alignment: alignment,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Two panes side by side when there's room or a vertical fold, one pane
/// otherwise.
///
/// Place it edge to edge across the window: with a fold it splits exactly
/// at the fold (50/50 on a centered fold; a flat fold, which has no width,
/// gets the divider on the crease), and it hands each pane only its
/// own side's safe-area inset, so `SafeArea` inside a pane works on the
/// iPhone Duo's one-sided insets. Inside a pane, `MediaQuery.sizeOf` is the
/// pane, so nested layout decisions see the space they really get.
class AdaptivePanes extends StatefulWidget {
  const AdaptivePanes({
    super.key,
    required this.primary,
    this.secondary,
    this.twoPaneMinWidth = 840,
    this.primaryFraction = 0.38,
    this.minPrimaryWidth = 320,
    this.maxPrimaryWidth = 440,
    this.divider,
  });

  /// The leading pane (the list), and the only one on narrow windows.
  final Widget primary;

  /// The trailing pane (the detail). Null keeps one pane at any width.
  final Widget? secondary;

  final double twoPaneMinWidth;
  final double primaryFraction;
  final double minPrimaryWidth;
  final double maxPrimaryWidth;

  /// Drawn between the panes when there's no fold. Defaults to a hairline.
  final Widget? divider;

  /// Whether [AdaptivePanes] shows two panes at this width and fold.
  static bool showsTwoPanes(
    double width,
    FoldInfo fold, {
    double twoPaneMinWidth = 840,
  }) => width >= twoPaneMinWidth || (fold.splitsHorizontally && width >= 600);

  @override
  State<AdaptivePanes> createState() => _AdaptivePanesState();
}

class _AdaptivePanesState extends State<AdaptivePanes> {
  // Continue: the leading pane keeps its state (scroll position, input)
  // when the window folds, unfolds or resizes between one and two panes.
  final _primaryKey = GlobalKey(debugLabel: 'AdaptivePanes.primary');

  Widget get primary => KeyedSubtree(key: _primaryKey, child: widget.primary);
  Widget? get secondary => widget.secondary;
  double get twoPaneMinWidth => widget.twoPaneMinWidth;
  double get primaryFraction => widget.primaryFraction;
  double get minPrimaryWidth => widget.minPrimaryWidth;
  double get maxPrimaryWidth => widget.maxPrimaryWidth;
  Widget? get divider => widget.divider;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    final fold = FoldInfo.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (secondary == null ||
            !AdaptivePanes.showsTwoPanes(
              width,
              fold,
              twoPaneMinWidth: twoPaneMinWidth,
            )) {
          return primary;
        }
        final window = MediaQuery.sizeOf(context);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Laid out physically, left to right: the fold is a physical
        // position, and in RTL the leading (primary) pane is the right one.
        final Widget gap;
        final double leftWidth;
        final double gapWidth;
        final hairline =
            divider ??
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            );
        if (fold.splitsHorizontally && (width - window.width).abs() < 1) {
          if (fold.end > fold.start) {
            // A half-open fold or a hinge: nothing in its band.
            leftWidth = fold.start;
            gapWidth = fold.end - fold.start;
            gap = SizedBox(width: gapWidth);
          } else {
            // A flat fold is a line: the divider sits on the crease.
            gapWidth = 1;
            leftWidth = fold.start - 0.5;
            gap = hairline;
          }
        } else {
          final leading = (width * primaryFraction)
              .clamp(
                minPrimaryWidth,
                math.max(minPrimaryWidth, maxPrimaryWidth),
              )
              .toDouble();
          gapWidth = 1;
          leftWidth = rtl ? width - leading - gapWidth : leading;
          gap = hairline;
        }
        final rightWidth = math.max(0.0, width - leftWidth - gapWidth);

        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftWidth,
              child: _pane(
                context,
                rtl ? _PaneEntrance(child: secondary) : primary,
                leftWidth,
                keepLeft: true,
              ),
            ),
            gap,
            SizedBox(
              width: rightWidth,
              child: _pane(
                context,
                rtl ? primary : _PaneEntrance(child: secondary),
                rightWidth,
                keepLeft: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pane(
    BuildContext context,
    Widget child,
    double width, {
    required bool keepLeft,
  }) {
    final data = MediaQuery.of(context);
    EdgeInsets side(EdgeInsets insets) =>
        keepLeft ? insets.copyWith(right: 0) : insets.copyWith(left: 0);
    return MediaQuery(
      data: data.copyWith(
        size: Size(width, data.size.height),
        padding: side(data.padding),
        viewPadding: side(data.viewPadding),
        viewInsets: side(data.viewInsets),
        displayFeatures: const [],
      ),
      child: child,
    );
  }
}

/// Column counts for grids. See `design/RESPONSIVE.md`: grids prefer an
/// even number of columns whenever a fold exists, even when flat.
abstract final class AdaptiveGrid {
  /// A minimum tile width that grows with the text scale, but half as fast:
  /// tiles widen so names don't break, without collapsing a two-column
  /// tablet to one column at 150%.
  static double tileWidth(BuildContext context, double base) {
    final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    return (base * (1 + (scale - 1) * 0.5)).clamp(base, base * 1.6);
  }

  static int columns({
    required double width,
    required double minTileWidth,
    double spacing = 0,
    int maxColumns = 6,
    bool preferEven = false,
  }) {
    var count = ((width + spacing) / (minTileWidth + spacing)).floor();
    count = count.clamp(1, maxColumns);
    if (preferEven && count.isOdd && count > 1) count -= 1;
    return count;
  }
}

/// A grid of equal-height rows whose column count follows the space, for
/// tiles whose height depends on their text (it grows with text scale,
/// unlike `SliverGrid`'s fixed aspect ratio).
///
/// With a vertical fold it uses an even column count, so the middle gap
/// falls on the crease and no tile crosses it, and widens that gap by the
/// fold's width (a half-open band or a hinge; a flat fold has none). That
/// assumes the grid is centered in the window (equal start and end
/// padding), as page grids are.
class SliverAdaptiveGrid extends StatelessWidget {
  const SliverAdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.minTileWidth,
    this.spacing = 16,
    this.maxColumns = 6,
    this.equalHeights = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  /// Rows stretch tiles to the tallest one (measured with intrinsics). Turn
  /// it off for tiles whose controls don't report intrinsic heights well
  /// (sliders, wrapped chips); rows then align tiles at the top.
  final bool equalHeights;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final foldGap = fold.splitsHorizontally ? fold.end - fold.start : 0.0;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = AdaptiveGrid.columns(
          width: constraints.crossAxisExtent - foldGap,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: maxColumns,
          preferEven: fold.hasFold,
        );
        final middle = columns.isEven && fold.splitsHorizontally
            ? columns ~/ 2
            : -1;
        final rows = (itemCount / columns).ceil();
        return SliverList.builder(
          itemCount: rows,
          itemBuilder: (context, row) {
            final cells = <Widget>[];
            for (var column = 0; column < columns; column++) {
              if (column > 0) {
                cells.add(
                  SizedBox(
                    width: column == middle ? spacing + foldGap : spacing,
                  ),
                );
              }
              final index = row * columns + column;
              cells.add(
                Expanded(
                  child: index < itemCount
                      ? itemBuilder(context, index)
                      : const SizedBox.shrink(),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : spacing),
              child: equalHeights
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: cells,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cells,
                    ),
            );
          },
        );
      },
    );
  }
}

/// Continue: the second pane slides in from the trailing side and fades
/// when it appears (unfolding, widening the window).
class _PaneEntrance extends StatefulWidget {
  const _PaneEntrance({required this.child});

  final Widget child;

  @override
  State<_PaneEntrance> createState() => _PaneEntranceState();
}

class _PaneEntranceState extends State<_PaneEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final motion = const HudaMotion();
      final duration = motion.of(context, motion.medium);
      if (duration == Duration.zero) return;
      _controller
        ..duration = duration
        ..forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: const HudaMotion().emphasized,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: Offset(rtl ? -0.06 : 0.06, 0),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
