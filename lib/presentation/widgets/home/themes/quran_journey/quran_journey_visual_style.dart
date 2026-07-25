import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

abstract final class QuranJourneyVisualStyle {
  static const double ruleWidth = 1;
  static const double innerRuleWidth = 0.75;
  static const double frameInset = 3;
  static const double regionGap = 18;

  static Color illumination(BuildContext context) => Color.lerp(
        context.accentColor,
        const Color(0xFFC59A46),
        Theme.of(context).brightness == Brightness.dark ? 0.36 : 0.48,
      )!;

  static Color rule(BuildContext context, {bool strong = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return context.primaryColor.withValues(
      alpha: strong ? (isDark ? 0.30 : 0.18) : (isDark ? 0.18 : 0.105),
    );
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
            padding: const EdgeInsets.all(
              QuranJourneyVisualStyle.frameInset,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: QuranJourneyVisualStyle.illumination(context)
                      .withValues(alpha: isDark ? 0.24 : 0.17),
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
