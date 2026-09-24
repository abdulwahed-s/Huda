import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

abstract final class QuranJourneyVisualStyle {
  static const double ruleWidth = 1;
  static const double innerRuleWidth = 0.75;
  static const double frameInset = 3;
  static const double regionGap = 18;

  static Color ink(BuildContext context) =>
      foreground(context, context.primaryColor);

  static Color foreground(BuildContext context, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return resolveForeground(
      color: color,
      brightness: Theme.of(context).brightness,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
    );
  }

  static Color illumination(BuildContext context) {
    final color = Color.lerp(
      context.accentColor,
      const Color(0xFFC59A46),
      Theme.of(context).brightness == Brightness.dark ? 0.36 : 0.48,
    )!;
    return foreground(context, color);
  }

  static Color rule(BuildContext context, {bool strong = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ink(context).withValues(
      alpha: strong ? (isDark ? 0.40 : 0.18) : (isDark ? 0.25 : 0.105),
    );
  }

  @visibleForTesting
  static Color resolveForeground({
    required Color color,
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
  }) {
    if (brightness != Brightness.dark) return color;

    const minimumContrast = 4.5;
    const maximumBackdropTint = 0.12;
    Color backdropFor(Color candidate) => Color.alphaBlend(
      candidate.withValues(alpha: maximumBackdropTint),
      surface,
    );

    if (_contrastRatio(color, backdropFor(color)) >= minimumContrast) {
      return color;
    }

    var lower = 0.0;
    var upper = 1.0;
    for (var iteration = 0; iteration < 12; iteration++) {
      final amount = (lower + upper) / 2;
      final candidate = Color.lerp(color, onSurface, amount)!;
      if (_contrastRatio(candidate, backdropFor(candidate)) >=
          minimumContrast) {
        upper = amount;
      } else {
        lower = amount;
      }
    }
    return Color.lerp(color, onSurface, upper)!;
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = math.max(firstLuminance, secondLuminance);
    final darker = math.min(firstLuminance, secondLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

class QuranJourneyFramedRegion extends StatelessWidget {
  const QuranJourneyFramedRegion({
    super.key,
    required this.child,
    this.doubleFrame = false,
    this.tint,
    this.tonalStrength = 1,
  });

  final Widget child;
  final bool doubleFrame;
  final Color? tint;
  final double tonalStrength;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regionTint = tint ?? context.primaryColor;
    final background = regionTint.withValues(
      alpha: (isDark ? 0.035 : 0.014) * tonalStrength,
    );
    final inner = doubleFrame
        ? Padding(
            padding: const EdgeInsets.all(QuranJourneyVisualStyle.frameInset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: QuranJourneyVisualStyle.illumination(
                    context,
                  ).withValues(alpha: isDark ? 0.24 : 0.17),
                  width: QuranJourneyVisualStyle.innerRuleWidth,
                ),
              ),
              child: child,
            ),
          )
        : child;

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: QuranJourneyVisualStyle.rule(context, strong: doubleFrame),
            width: QuranJourneyVisualStyle.ruleWidth,
          ),
        ),
        child: inner,
      ),
    );
  }
}

class QuranJourneyDivider extends StatelessWidget {
  const QuranJourneyDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.inset = 9,
    this.strong = false,
  });

  final Axis axis;
  final double inset;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = QuranJourneyVisualStyle.rule(context, strong: strong);
    if (axis == Axis.vertical) {
      return Container(
        width: QuranJourneyVisualStyle.ruleWidth,
        margin: EdgeInsets.symmetric(vertical: inset),
        color: color,
      );
    }
    return Container(
      height: QuranJourneyVisualStyle.ruleWidth,
      margin: EdgeInsetsDirectional.symmetric(horizontal: inset),
      color: color,
    );
  }
}

class QuranJourneySectionBreak extends StatelessWidget {
  const QuranJourneySectionBreak({super.key});

  @override
  Widget build(BuildContext context) {
    final illumination = QuranJourneyVisualStyle.illumination(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 17, 14, 17),
        child: Column(
          children: [
            Container(
              height: QuranJourneyVisualStyle.ruleWidth,
              color: QuranJourneyVisualStyle.rule(context, strong: true),
            ),
            const SizedBox(height: 4),
            Container(
              height: QuranJourneyVisualStyle.innerRuleWidth,
              color: illumination.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.22
                    : 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
