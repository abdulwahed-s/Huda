import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/classic_feature_card_metrics.dart';

typedef ClassicFeatureIconBuilder =
    Widget Function(ClassicFeatureCardMetrics metrics);

class ClassicFeatureCardContent extends StatelessWidget {
  const ClassicFeatureCardContent({
    super.key,
    required this.title,
    required this.titleColor,
    required this.iconBuilder,
  });

  final String title;
  final Color titleColor;
  final ClassicFeatureIconBuilder iconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = ClassicFeatureCardMetrics.resolve(constraints);
        final isSingleWord = !title.trim().contains(' ');
        final displayTitle = isSingleWord ? title : balancedTwoLineTitle(title);
        final iconTop = constraints.maxHeight * 0.13;
        final iconExtent = metrics.iconSize + metrics.iconPadding * 2;
        final titleTop = math.max(
          constraints.maxHeight * (isSingleWord ? 0.735 : 0.70),
          iconTop + iconExtent + metrics.contentGap,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: iconTop,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: iconBuilder(metrics),
              ),
            ),
            Positioned(
              top: titleTop,
              bottom: metrics.outerPadding,
              left: metrics.outerPadding,
              right: metrics.outerPadding,
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth - metrics.outerPadding * 2,
                    child: Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      maxLines: isSingleWord ? 1 : 2,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: metrics.fontSize,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String balancedTwoLineTitle(String title) {
  final words = title.trim().split(RegExp(r'\s+'));
  if (words.length < 2) return title.trim();

  var bestSplit = 1;
  var bestDifference = double.infinity;
  for (var split = 1; split < words.length; split++) {
    final firstLength = words.take(split).join(' ').length;
    final secondLength = words.skip(split).join(' ').length;
    final difference = (firstLength - secondLength).abs().toDouble();
    if (difference < bestDifference) {
      bestDifference = difference;
      bestSplit = split;
    }
  }

  return '${words.take(bestSplit).join(' ')}\n'
      '${words.skip(bestSplit).join(' ')}';
}
