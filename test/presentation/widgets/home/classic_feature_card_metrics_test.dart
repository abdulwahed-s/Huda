import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/presentation/widgets/home/classic_feature_card_metrics.dart';

void main() {
  group('ClassicFeatureCardMetrics', () {
    test('two-line content fits supported classic-grid tile sizes', () {
      const tileSizes = <Size>[
        Size(72, 96),
        Size(109, 145),
        Size(163, 217),
        Size(250, 333),
      ];

      for (final size in tileSizes) {
        final metrics = ClassicFeatureCardMetrics.resolve(
          BoxConstraints.tight(size),
        );

        expect(
          metrics.twoLineContentHeight,
          lessThanOrEqualTo(size.height),
          reason: 'Content should fit a ${size.width}x${size.height} tile',
        );
      }
    });

    test('content stops growing once the tile reaches desktop size', () {
      final standard = ClassicFeatureCardMetrics.resolve(
        const BoxConstraints.tightFor(width: 240, height: 320),
      );
      final veryLarge = ClassicFeatureCardMetrics.resolve(
        const BoxConstraints.tightFor(width: 640, height: 800),
      );

      expect(standard.iconSize, veryLarge.iconSize);
      expect(standard.iconPadding, veryLarge.iconPadding);
      expect(standard.fontSize, veryLarge.fontSize);
      expect(standard.outerPadding, veryLarge.outerPadding);
    });

    test('unbounded expanded cards use a finite width-based fallback', () {
      final metrics = ClassicFeatureCardMetrics.resolve(
        const BoxConstraints(maxWidth: 300),
      );

      expect(metrics.iconSize.isFinite, isTrue);
      expect(metrics.twoLineContentHeight.isFinite, isTrue);
      expect(metrics.iconSize, lessThanOrEqualTo(48));
    });
  });
}
