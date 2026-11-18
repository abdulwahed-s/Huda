import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// The page of a settings-like screen (Settings, Feedback): one scroll view
/// holding one readable column, or two columns side by side once both get
/// at least [minColumnWidth] (× the text scale, up to 2×).
///
/// Two columns split exactly at a vertical fold (each column on its own
/// side of the crease or the half-open band); otherwise they share
/// [maxWidth], centered. Both layouts take the bottom and side insets
/// inside the scroll view, so the page runs edge to edge.
class SettingsColumns extends StatelessWidget {
  const SettingsColumns({
    super.key,
    required this.start,
    required this.end,
    this.minColumnWidth = 320,
    this.maxWidth = 1120,
    this.singleMaxWidth = 680,
    this.bottom = 0,
    this.gap,
    this.controller,
  });

  /// The first column (and the top of the single column).
  final List<Widget> start;

  /// The second column (and the rest of the single column).
  final List<Widget> end;

  final double minColumnWidth;
  final double maxWidth;
  final double singleMaxWidth;

  /// Extra end padding (a pinned bar's height laid over the page).
  final double bottom;

  /// Space between [start] and [end] in one column; defaults to
  /// `space.xl` (a section gap).
  final double? gap;

  final ScrollController? controller;

  /// Whether the page shows two columns at this width, fold and text scale
  /// (side by side; tabletop stacks them on either side of the band).
  static bool showsTwo(
    BuildContext context,
    double width, {
    double minColumnWidth = 320,
  }) {
    if (TabletopSplit.applies(context)) return true;
    final space = context.tokens.space;
    final scale = math.min(MediaQuery.textScalerOf(context).scale(16) / 16, 2);
    final fold = FoldInfo.of(context);
    final min = minColumnWidth * math.max(1, scale);
    if (fold.splitsHorizontally) {
      final gutter = space.gutter(width);
      return fold.bounds.left - gutter * 2 >= min &&
          width - fold.bounds.right - gutter * 2 >= min;
    }
    final gutter = space.gutter(width);
    return (width - gutter * 2 - space.xl) / 2 >= min;
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = space.gutter(width);
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, space.lg, gutter, space.xxl + bottom),
        );
        Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );

        // Tabletop: nothing may cross the half-open band, so the first
        // column scrolls in the top half and the rest in the bottom half.
        if (TabletopSplit.applies(context)) {
          Widget half(List<Widget> children) => Builder(
            builder: (context) => SingleChildScrollView(
              padding: context.scrollPadding(
                EdgeInsets.fromLTRB(gutter, space.md, gutter, space.md),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: singleMaxWidth),
                  child: column(children),
                ),
              ),
            ),
          );
          return SettingsTabletop(top: half(start), bottom: half(end));
        }

        if (!showsTwo(context, width, minColumnWidth: minColumnWidth)) {
          return SingleChildScrollView(
            controller: controller,
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: singleMaxWidth),
                child: column([
                  ...start,
                  SizedBox(height: gap ?? space.xl),
                  ...end,
                ]),
              ),
            ),
          );
        }

        final fold = FoldInfo.of(context);
        final Widget row;
        if (fold.splitsHorizontally) {
          // Split at the crease: each column keeps a gutter from it.
          final insets = MediaQuery.paddingOf(context);
          final startWidth = fold.bounds.left - insets.left - gutter * 2;
          final endWidth =
              width - fold.bounds.right - insets.right - gutter * 2;
          row = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: startWidth, child: column(start)),
              SizedBox(width: fold.bounds.width + gutter * 2),
              SizedBox(width: endWidth, child: column(end)),
            ],
          );
        } else {
          row = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: column(start)),
                  SizedBox(width: space.xl),
                  Expanded(child: column(end)),
                ],
              ),
            ),
          );
        }
        return SingleChildScrollView(
          controller: controller,
          padding: padding,
          child: row,
        );
      },
    );
  }
}

/// Tabletop posture for a page under an app bar: [top] above the
/// half-open band and [bottom] below it, each with its own `MediaQuery`
/// (size, its own edge's inset, no display features). Unlike
/// `TabletopSplit`, which assumes it starts at the window's top, it finds
/// where it sits after its first layout and splits at the band from there.
class SettingsTabletop extends StatefulWidget {
  const SettingsTabletop({super.key, required this.top, required this.bottom});

  final Widget top;
  final Widget bottom;

  @override
  State<SettingsTabletop> createState() => _SettingsTabletopState();
}

class _SettingsTabletopState extends State<SettingsTabletop> {
  double _origin = 0;

  void _measure(_) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero).dy;
    if ((origin - _origin).abs() > 0.5) setState(() => _origin = origin);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final fold = FoldInfo.of(context);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final topHeight = math.max(0.0, fold.start - _origin);
    MediaQueryData half(double height, {required bool upper}) => media.copyWith(
      size: Size(width, height),
      padding: upper
          ? media.padding.copyWith(bottom: 0)
          : media.padding.copyWith(top: 0),
      viewPadding: upper
          ? media.viewPadding.copyWith(bottom: 0)
          : media.viewPadding.copyWith(top: 0),
      displayFeatures: const [],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          SizedBox(
            height: topHeight,
            child: MediaQuery(
              data: half(topHeight, upper: true),
              child: widget.top,
            ),
          ),
          SizedBox(height: fold.end - fold.start),
          Expanded(
            child: MediaQuery(
              data: half(
                math.max(
                  0.0,
                  constraints.maxHeight - topHeight - (fold.end - fold.start),
                ),
                upper: false,
              ),
              child: widget.bottom,
            ),
          ),
        ],
      ),
    );
  }
}
