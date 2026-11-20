import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';

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

  final List<Widget> start;

  final List<Widget> end;

  final double minColumnWidth;
  final double maxWidth;
  final double singleMaxWidth;

  final double bottom;

  final double? gap;

  final ScrollController? controller;

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
