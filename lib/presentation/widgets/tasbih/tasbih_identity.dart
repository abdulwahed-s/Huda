import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

const int tasbihBeads = 33;

final FeatureIdentity tasbihIdentity = FeatureIdentity(
  id: 'tasbih',
  motif: 'A strand of 33 prayer beads around the count',
  count: tasbihBeads,
  rhythm: IdentityRhythm.radial,
  material: IdentityMaterial.stone,
  headerArt: (style) => TasbihBeadRingPainter(
    style: style,
    empty: style.color.withValues(alpha: style.color.a * 0.35),
    filled: 11,
    clockwise: true,
  ),
  emptyArt: (style) => TasbihBeadRingPainter(
    style: style,
    empty: style.color.withValues(alpha: style.color.a * 0.45),
    filled: 0,
    clockwise: true,
  ),
);

int tasbihBeadsFilled(int count) =>
    count <= 0 ? 0 : (count - 1) % tasbihBeads + 1;

class TasbihBeadRingPainter extends CustomPainter {
  const TasbihBeadRingPainter({
    required this.style,
    required this.empty,
    required this.filled,
    required this.clockwise,
    this.pulse = 0,
    this.pulses = 1,
    this.stepBead = -1,
    this.step = 0,
    this.stepBack = false,
  });

  final OrnamentStyle style;
  final Color empty;
  final double filled;
  final bool clockwise;
  final double pulse;
  final int pulses;
  final int stepBead;
  final double step;
  final bool stepBack;

  static const double strand = 0.86;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.shortestSide / 2;
    final ringRadius = half * strand;
    final bead = ringRadius * math.sin(math.pi / tasbihBeads) * 0.78;
    if (bead <= 0) return;
    final luminous = style.render == OrnamentRender.luminous;

    canvas.drawCircle(
      c,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.stroke * 0.8
        ..color = empty,
    );

    final points = OrnamentGeometry.ring(
      c,
      ringRadius,
      tasbihBeads + 1,
      clockwise: clockwise,
    );
    final open = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.stroke
      ..color = empty.withValues(alpha: math.min(1, empty.a * 2.2));
    final moving = step > 0 && step < 1;
    for (var i = 1; i < points.length; i++) {
      final done = (filled - (i - 1)).clamp(0.0, 1.0);
      final arc = moving && i - 1 == stepBead ? math.sin(math.pi * step) : 0.0;
      final sink = stepBack ? bead * 0.9 * arc : 0.0;
      final p = points[i] + (c - points[i]) * (sink / ringRadius);
      final r = bead * (1 + (stepBack ? -0.22 : 0.42) * arc);
      if (done > 0) {
        if (luminous) {
          canvas.drawCircle(
            p,
            r * (1.7 + 0.5 * arc),
            style.fill((0.16 + (stepBack ? 0 : 0.18) * arc) * done),
          );
        }
        canvas.drawCircle(p, r, style.fill(done));
      }
      if (done < 1) canvas.drawCircle(p, r, open);
      if (moving && i - 1 == stepBead && !stepBack) {
        final t = Curves.easeOutCubic.transform(step);
        canvas.drawCircle(
          p,
          bead * (1.2 + 1.6 * t),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.stroke * (1.4 - t)
            ..color = style.color.withValues(
              alpha: style.color.a * 0.7 * (1 - t),
            ),
        );
      }
    }

    final imam = Rect.fromCenter(
      center: points.first,
      width: bead * 1.5,
      height: bead * 2.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(imam, Radius.circular(bead)),
      style.fill(),
    );

    if (pulse > 0 && pulse < 1) {
      for (var k = 0; k < pulses; k++) {
        final t = ((pulse - k * 0.25) / (1 - (pulses - 1) * 0.25)).clamp(
          0.0,
          1.0,
        );
        if (t <= 0 || t >= 1) continue;
        final eased = Curves.easeOutCubic.transform(t);
        final r = ringRadius + (half * 1.12 - ringRadius) * eased;
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.stroke * (1 + 4 * (1 - t))
            ..color = style.color.withValues(alpha: style.color.a * (1 - t)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(TasbihBeadRingPainter old) =>
      old.style != style ||
      old.empty != empty ||
      old.filled != filled ||
      old.clockwise != clockwise ||
      old.pulse != pulse ||
      old.pulses != pulses ||
      old.stepBead != stepBead ||
      old.step != step ||
      old.stepBack != stepBack;
}

bool tasbihUsesPointer(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };

Color tasbihOverlaySurface(BuildContext context) => Color.alphaBlend(
  context.tokens.onChrome.withValues(alpha: 0.06),
  context.tokens.chromeEnd,
);
