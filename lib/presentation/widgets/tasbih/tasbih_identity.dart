import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Beads on one strand: a round of tasbih.
const int tasbihBeads = 33;

/// Tasbih's voice (see `design/IDENTITIES.md`): a strand of 33 prayer
/// beads around the count, polished stone that glows as it's counted.
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
  // Empty states: a strand waiting to be counted, the imam bead lit.
  emptyArt: (style) => TasbihBeadRingPainter(
    style: style,
    empty: style.color.withValues(alpha: style.color.a * 0.45),
    filled: 0,
    clockwise: true,
  ),
);

/// How many beads of the strand are counted for [count]: a finished round
/// stays full until the next tap starts the next one.
int tasbihBeadsFilled(int count) =>
    count <= 0 ? 0 : (count - 1) % tasbihBeads + 1;

/// A strand of [tasbihBeads] beads; [filled] of them are counted (a
/// fraction lights the next bead as it advances). Runs counter-clockwise
/// when not [clockwise] (RTL). The taller imam bead at the top is where
/// the strand starts.
///
/// [pulse] (0–1) sends a ring outward from the strand when a round
/// completes; [pulses] is 2 at the end of a full tasbih (99).
///
/// [stepBead] is the bead a count just moved (0-based), and [step] (0–1)
/// its little motion: counted, it swells and throws off a spark; taken
/// back ([stepBack]), it dips and dims.
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

  /// The strand's radius as a share of the half side; the rest is room
  /// for the glow and the pulse.
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
      // The bead a count just moved swells (counted) or dips (taken back)
      // and settles. Taken back, it also sinks a little toward the centre.
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
      // A counted bead throws off a spark: a fine ring that widens and
      // fades.
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

    // The imam bead.
    final imam = Rect.fromCenter(
      center: points.first,
      width: bead * 1.5,
      height: bead * 2.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(imam, Radius.circular(bead)),
      style.fill(),
    );

    // A completed round: rings leave the strand and fade.
    if (pulse > 0 && pulse < 1) {
      for (var k = 0; k < pulses; k++) {
        final t = ((pulse - k * 0.25) / (1 - (pulses - 1) * 0.25)).clamp(
          0.0,
          1.0,
        );
        if (t <= 0 || t >= 1) continue;
        final eased = Curves.easeOutCubic.transform(t);
        // It leaves the medallion's box a little (nothing clips it) and fades
        // before it reaches the words above.
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

/// Whether this window is used with a mouse and keyboard.
bool tasbihUsesPointer(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };

/// Tasbih's sheet and dialog surface: a step up from the night page, in
/// its hue.
Color tasbihOverlaySurface(BuildContext context) => Color.alphaBlend(
  context.tokens.onChrome.withValues(alpha: 0.06),
  context.tokens.chromeEnd,
);
