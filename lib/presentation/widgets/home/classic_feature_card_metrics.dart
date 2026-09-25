import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Sizes classic-home card content from the tile itself, not the full window.
///
/// The classic home is capped at a fixed content width. Screen-relative values
/// such as `.w` and `.sp` can therefore keep growing while a six-column tile
/// does not, which makes the icon consume the space reserved for its label.
class ClassicFeatureCardMetrics {
  const ClassicFeatureCardMetrics({
    required this.outerPadding,
    required this.iconSize,
    required this.iconPadding,
    required this.fontSize,
    required this.contentGap,
  });

  factory ClassicFeatureCardMetrics.resolve(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth && constraints.maxWidth > 0
        ? constraints.maxWidth
        : 160.0;
    final height = constraints.hasBoundedHeight && constraints.maxHeight > 0
        ? constraints.maxHeight
        : width / 0.65;
    final basis = math.min(width, height);

    return ClassicFeatureCardMetrics(
      outerPadding: (basis * 0.07).clamp(6.0, 16.0),
      iconSize: (basis * 0.25).clamp(22.0, 48.0),
      iconPadding: (basis * 0.07).clamp(5.0, 13.0),
      fontSize: (basis * 0.085).clamp(10.0, 17.0),
      contentGap: (basis * 0.055).clamp(5.0, 11.0),
    );
  }

  final double outerPadding;
  final double iconSize;
  final double iconPadding;
  final double fontSize;
  final double contentGap;

  /// Upper-bound estimate for a two-line label, used by layout tests.
  double get twoLineContentHeight =>
      outerPadding * 2 +
      iconPadding * 2 +
      iconSize +
      contentGap +
      fontSize * 2.4;
}
