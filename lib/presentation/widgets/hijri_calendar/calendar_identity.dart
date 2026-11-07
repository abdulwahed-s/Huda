import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// The calendar's voice: the moon's month. A Hijri date is the moon's age,
/// so the calendar draws it: an engraved moon whose lit part follows the
/// day (a crescent on the 1st, full on the 14th, a waning sliver on the
/// 28th). In Ramadan, 30 moons, one a night. See `design/IDENTITIES.md`.
final calendarIdentity = FeatureIdentity(
  id: 'calendar',
  motif: "The moon's month: an engraved moon in the day's phase",
  count: 30,
  rhythm: IdentityRhythm.sequence,
  material: IdentityMaterial.night,
  headerArt: (style) => CalendarMoonPainter.styled(phase: 0.12, style: style),
);

/// The moon's phase on the night of Hijri [day], from 0 (new) through 0.5
/// (full) to 1: the month starts with the first visible crescent, about a
/// day and a half old.
double moonPhaseForDay(int day) =>
    ((day + 0.5) / 29.53).clamp(0.0, 0.995).toDouble();

/// The lit part of a moon of radius [r] at [center] in [phase]: the limb
/// on the lit side (the right while waxing, as seen from the north) closed
/// by the terminator, an ellipse through the poles.
Path moonLitPath(Offset center, double r, double phase) {
  final waxing = phase <= 0.5;
  final cos = math.cos(2 * math.pi * phase);
  final x = (waxing ? cos : -cos) * r;
  const k = 0.5523;
  final c = center;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..arcTo(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      waxing ? math.pi : -math.pi,
      false,
    )
    ..cubicTo(c.dx + x * k, c.dy + r, c.dx + x, c.dy + r * k, c.dx + x, c.dy)
    ..cubicTo(c.dx + x, c.dy - r * k, c.dx + x * k, c.dy - r, c.dx, c.dy - r)
    ..close();
}

/// A moon in [phase]: a faint earthshine on the dark side, the lit part
/// filled, the limb as a ring. Luminous (a soft halo) on the chrome.
class CalendarMoonPainter extends CustomPainter {
  const CalendarMoonPainter({
    required this.phase,
    required this.lit,
    required this.ring,
    this.shine,
    this.stroke = 1.5,
    this.glow = false,
  });

  /// From an [OrnamentStyle]: the identity art on chrome or a surface.
  factory CalendarMoonPainter.styled({
    required double phase,
    required OrnamentStyle style,
  }) {
    final glow = style.render == OrnamentRender.luminous;
    return CalendarMoonPainter(
      phase: phase,
      lit: style.color.withValues(alpha: style.color.a * (glow ? 0.92 : 0.8)),
      ring: style.color,
      // Earthshine only on the chrome: on a light page a tinted dark side
      // reads brighter than the gilt and the phase looks reversed.
      shine: glow ? style.color.withValues(alpha: style.color.a * 0.16) : null,
      stroke: style.stroke,
      glow: glow,
    );
  }

  final double phase;
  final Color lit;
  final Color ring;
  final Color? shine;
  final double stroke;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - stroke * (glow ? 3 : 1);
    if (r <= 0) return;
    final c = size.center(Offset.zero);
    final disc = Rect.fromCircle(center: c, radius: r);
    if (glow) {
      canvas.drawCircle(
        c,
        r + stroke * 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 5
          ..color = ring.withValues(alpha: ring.a * 0.12),
      );
    }
    final shine = this.shine;
    if (shine != null) canvas.drawOval(disc, Paint()..color = shine);
    canvas.drawPath(moonLitPath(c, r, phase), Paint()..color = lit);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(CalendarMoonPainter old) =>
      old.phase != phase ||
      old.lit != lit ||
      old.ring != ring ||
      old.shine != shine ||
      old.stroke != stroke ||
      old.glow != glow;
}

/// The day's moon. When the day changes it turns to the new phase: the
/// terminator sweeps across (the signature motion, ~700 ms; reduce motion
/// jumps). Decorative: the date beside it is what's read.
class CalendarMoon extends StatelessWidget {
  const CalendarMoon({
    super.key,
    required this.day,
    required this.size,
    this.onChrome = false,
  });

  /// The Hijri day of the month, 1–30.
  final int day;
  final double size;
  final bool onChrome;

  static const duration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = OrnamentStyle.of(context, onChrome: onChrome);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: moonPhaseForDay(day)),
          duration: tokens.motion.of(context, duration),
          curve: Curves.easeInOutCubic,
          builder: (context, phase, _) => CustomPaint(
            size: Size.square(size),
            painter: CalendarMoonPainter.styled(
              phase: phase,
              style: style.copyWith(stroke: tokens.stroke.fine),
            ),
          ),
        ),
      ),
    );
  }
}
