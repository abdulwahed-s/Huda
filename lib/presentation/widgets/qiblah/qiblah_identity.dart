import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

final FeatureIdentity qiblahIdentity = FeatureIdentity(
  id: 'qiblah',
  motif:
      'An astrolabe: a graduated limb, a 16-point wind rose, the Kaaba '
      'on the limb and an alidade pointing to it',
  count: 16,
  rhythm: IdentityRhythm.radial,
  material: IdentityMaterial.brass,
  headerArt: (style) => QiblahStateArtPainter(style: style),
);

const double _limbRatio = 0.88;

const double _kaabaRadius = 0.72;

class QiblahFacePainter extends CustomPainter {
  QiblahFacePainter({
    required this.style,
    required this.fill,
    required this.ink,
    required this.muted,
    required this.cardinals,
    required this.letterStyle,
    required this.numeralStyle,
  });

  final OrnamentStyle style;

  final Color fill;

  final Color ink;
  final Color muted;

  final List<String> cardinals;
  final TextStyle letterStyle;
  final TextStyle numeralStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * _limbRatio;
    if (r <= 8) return;
    final stroke = style.stroke;
    final line = style.line;
    final quiet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, stroke * 0.7)
      ..strokeCap = StrokeCap.round
      ..color = style.color.withValues(alpha: style.color.a * 0.55);

    final inner = r * 0.86;
    style.draw(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, inner, line);
    for (var d = 0; d < 360; d += 5) {
      final a = _rad(d);
      final major = d % 30 == 0;
      final mid = d % 10 == 0;
      final length = major ? r * 0.1 : (mid ? r * 0.065 : r * 0.04);
      canvas.drawLine(
        _polar(c, r, a),
        _polar(c, r - length, a),
        major ? line : quiet,
      );
    }

    if (r >= 120) {
      for (var d = 30; d < 360; d += 30) {
        if (d % 90 == 0) continue;
        _text(
          canvas,
          c,
          '$d',
          numeralStyle.copyWith(color: muted),
          r * 0.77,
          d,
        );
      }
    }

    for (final tier in const [3, 2, 1]) {
      for (var i = 0; i < 16; i++) {
        final t = i % 4 == 0 ? 1 : (i % 2 == 0 ? 2 : 3);
        if (t != tier) continue;
        final length = switch (t) {
          1 => r * 0.58,
          2 => r * 0.42,
          _ => r * 0.28,
        };
        final a = _rad(i * 22.5);
        final side = r * (t == 1 ? 0.09 : 0.07);
        final tip = _polar(c, length, a);
        final left = _polar(c, side, a - math.pi / 4);
        final right = _polar(c, side, a + math.pi / 4);
        final kite = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        canvas.drawPath(kite, Paint()..color = fill);
        final half = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(tip.dx, tip.dy)
          ..close();
        canvas.drawPath(
          half,
          style.fill(t == 1 ? 0.42 : (t == 2 ? 0.28 : 0.18)),
        );
        canvas.drawPath(kite, t == 1 ? line : quiet);
      }
    }
    canvas.drawCircle(c, r * 0.07, Paint()..color = fill);
    canvas.drawCircle(c, r * 0.07, line);

    for (var i = 0; i < 4; i++) {
      _text(
        canvas,
        c,
        cardinals[i],
        letterStyle.copyWith(color: i == 0 ? style.color : ink),
        r * 0.72,
        i * 90,
      );
    }
  }

  @override
  bool shouldRepaint(QiblahFacePainter old) =>
      old.style != style ||
      old.fill != fill ||
      old.ink != ink ||
      old.muted != muted ||
      old.letterStyle != letterStyle ||
      old.numeralStyle != numeralStyle ||
      !_sameList(old.cardinals, cardinals);
}

@immutable
class QiblahLockStages {
  const QiblahLockStages(this.t, {this.releasing = false});

  final double t;
  final bool releasing;

  double _span(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  double get warm =>
      releasing ? t : Curves.easeOutCubic.transform(_span(0, 0.35));

  double get click =>
      releasing ? t : Curves.easeOutBack.transform(_span(0, 0.3));

  double get trace =>
      releasing ? t : Curves.easeInOutCubic.transform(_span(0.05, 0.55));

  double get spark => releasing ? 0 : _span(0.48, 0.68);

  double get bloom => releasing ? 0 : _span(0.55, 1);

  static double pulse(double x) => math.sin(math.pi * x);
}

class QiblahAlidadePainter extends CustomPainter {
  QiblahAlidadePainter({
    required this.style,
    required this.rule,
    required this.fill,
    required this.lock,
    this.showRule = true,
  });

  final OrnamentStyle style;

  final Color rule;
  final Color fill;
  final QiblahLockStages lock;
  final bool showRule;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * _limbRatio;
    if (r <= 8) return;
    final gilt = style.color;
    final warm = lock.warm;
    final color = Color.lerp(rule, gilt, warm)!;
    final kaabaCenter = Offset(c.dx, c.dy - r * _kaabaRadius);
    final swell = QiblahLockStages.pulse(lock.bloom);
    final kaaba = r * 0.13 * (1 + 0.16 * swell);

    if (showRule) {
      final width = math.max(3.0, r * 0.045);
      final tip = r * _kaabaRadius - r * 0.13 * 0.95;
      final arm = Path()
        ..moveTo(c.dx - width, c.dy)
        ..lineTo(c.dx - width * 0.45, c.dy - tip + width * 2.2)
        ..lineTo(c.dx, c.dy - tip)
        ..lineTo(c.dx + width * 0.45, c.dy - tip + width * 2.2)
        ..lineTo(c.dx + width, c.dy)
        ..close();
      final tail = Rect.fromLTRB(
        c.dx - width * 0.7,
        c.dy,
        c.dx + width * 0.7,
        c.dy + r * 0.44,
      );
      final paint = Paint()..color = color;
      if (warm > 0) {
        canvas.drawPath(
          arm,
          Paint()
            ..color = gilt.withValues(alpha: 0.22 * warm)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.2),
        );
      }
      canvas
        ..drawPath(arm, paint)
        ..drawRect(tail, Paint()..color = color.withValues(alpha: 0.55));
      for (final at in [-r * 0.36, r * 0.3]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx, c.dy + at),
              width: width * 4.2,
              height: width * 0.9,
            ),
            Radius.circular(width * 0.3),
          ),
          paint,
        );
      }
      canvas
        ..drawCircle(c, width * 1.5, Paint()..color = fill)
        ..drawCircle(
          c,
          width * 1.5,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.stroke,
        )
        ..drawCircle(c, width * 0.55, Paint()..color = gilt);
    }

    final light = 0.26 * warm + 0.22 * swell;
    if (light > 0) {
      canvas.drawCircle(
        kaabaCenter,
        kaaba * (1.6 + 0.5 * swell),
        Paint()
          ..color = gilt.withValues(alpha: light)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, kaaba * 0.7),
      );
    }
    if (swell > 0) {
      final reach = Curves.easeOutCubic.transform(lock.bloom);
      final rays = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, style.stroke * 0.9)
        ..color = gilt.withValues(alpha: 0.55 * swell);
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8;
        final long = i.isEven;
        final from = kaaba * 1.35;
        final to = kaaba * (1.45 + (long ? 0.6 : 0.35) * reach);
        canvas.drawLine(
          _polar(kaabaCenter, from, a),
          _polar(kaabaCenter, to, a),
          rays,
        );
      }
    }

    canvas
      ..drawCircle(kaabaCenter, kaaba * 1.05, Paint()..color = fill)
      ..drawCircle(
        kaabaCenter,
        kaaba * 1.05,
        style.line..color = gilt.withValues(alpha: 0.5 + 0.5 * warm),
      );
    final cube = Rect.fromCenter(
      center: kaabaCenter,
      width: kaaba * 1.1,
      height: kaaba * 1.1,
    );
    final body = Color.lerp(
      Color.lerp(fill, Colors.black, 0.55)!,
      Color.lerp(fill, gilt, 0.25)!,
      warm,
    )!;
    canvas
      ..drawRect(cube, Paint()..color = body)
      ..drawRect(cube, style.line..color = gilt)
      ..drawLine(
        Offset(cube.left, cube.top + cube.height * 0.3),
        Offset(cube.right, cube.top + cube.height * 0.3),
        Paint()
          ..color = gilt
          ..strokeWidth = math.max(1.5, cube.height * 0.12),
      )
      ..drawRect(
        Rect.fromLTWH(
          cube.left + cube.width * 0.6,
          cube.top + cube.height * 0.55,
          cube.width * 0.2,
          cube.height * 0.45,
        ),
        Paint()..color = gilt.withValues(alpha: 0.85),
      );
  }

  @override
  bool shouldRepaint(QiblahAlidadePainter old) =>
      old.style != style ||
      old.rule != rule ||
      old.fill != fill ||
      old.lock.t != lock.t ||
      old.lock.releasing != lock.releasing ||
      old.showRule != showRule;
}

class QiblahIndexPainter extends CustomPainter {
  QiblahIndexPainter({
    required this.style,
    required this.lock,
    required this.tolerance,
    this.showIndex = true,
  });

  final OrnamentStyle style;
  final QiblahLockStages lock;

  final double tolerance;
  final bool showIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final r = outer * _limbRatio;
    if (r <= 8) return;
    final band = outer - r;
    final ring = r + band * 0.42;
    final gilt = style.color;
    final warm = lock.warm;
    final trace = lock.trace;

    if (trace > 0) {
      final sweep = math.pi * trace;
      final rect = Rect.fromCircle(center: c, radius: ring);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = style.stroke * 5
        ..color = gilt.withValues(alpha: 0.16);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = style.stroke * 1.4
        ..color = gilt;
      for (final p in [glow, paint]) {
        canvas
          ..drawArc(rect, -math.pi / 2, sweep, false, p)
          ..drawArc(rect, -math.pi / 2, -sweep, false, p);
      }
      if (trace < 1) {
        for (final a in [sweep, -sweep]) {
          canvas.drawCircle(
            _polar(c, ring, a),
            style.stroke * 2.6,
            Paint()
              ..color = gilt.withValues(alpha: 0.55)
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                style.stroke * 2,
              ),
          );
        }
      }
    }

    final spark = lock.spark;
    if (spark > 0 && spark < 1) {
      final at = Offset(c.dx, c.dy + ring);
      final strength = QiblahLockStages.pulse(spark);
      final reach = band * (0.35 + 0.6 * Curves.easeOutCubic.transform(spark));
      canvas.drawCircle(
        at,
        band * 0.5,
        Paint()
          ..color = gilt.withValues(alpha: 0.3 * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, band * 0.4),
      );
      final rays = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = style.stroke * 1.2
        ..color = gilt.withValues(alpha: 0.8 * strength);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4 * spark;
        canvas.drawLine(
          at,
          Offset(at.dx + reach * math.cos(a), at.dy + reach * math.sin(a)),
          rays,
        );
      }
    }
    if (!showIndex) return;

    final quiet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = style.stroke
      ..color = gilt.withValues(alpha: 0.6 + 0.4 * warm);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: ring),
      -math.pi / 2 - _rad(tolerance),
      _rad(tolerance * 2),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = style.stroke
        ..color = gilt.withValues(alpha: 0.35 + 0.65 * warm),
    );
    for (final d in [-tolerance, tolerance]) {
      final a = _rad(d);
      canvas.drawLine(
        _polar(c, ring - band * 0.22, a),
        _polar(c, ring + band * 0.22, a),
        quiet,
      );
    }

    final w = math.max(6.0, band * 0.42);
    final drop = band * 0.16 * lock.click;
    final tip = Offset(c.dx, c.dy - r - band * 0.08 + drop);
    final base = c.dy - outer + band * 0.08 + drop;
    final index = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - w / 2, base)
      ..lineTo(tip.dx + w / 2, base)
      ..close();
    if (warm > 0) {
      canvas.drawPath(
        index,
        Paint()
          ..color = gilt.withValues(alpha: 0.45 * warm)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.5),
      );
    }
    canvas.drawPath(index, Paint()..color = gilt);
  }

  @override
  bool shouldRepaint(QiblahIndexPainter old) =>
      old.style != style ||
      old.lock.t != lock.t ||
      old.lock.releasing != lock.releasing ||
      old.tolerance != tolerance ||
      old.showIndex != showIndex;
}

class QiblahStateArtPainter extends CustomPainter {
  const QiblahStateArtPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - style.stroke * 3;
    if (r <= 4) return;
    style.draw(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r * 0.86, style.line);
    for (var d = 0; d < 360; d += 30) {
      final a = _rad(d);
      canvas.drawLine(_polar(c, r, a), _polar(c, r * 0.9, a), style.line);
    }
    for (var i = 0; i < 8; i++) {
      final major = i.isEven;
      final a = _rad(i * 45);
      final length = r * (major ? 0.62 : 0.4);
      final side = r * 0.08;
      final tip = _polar(c, length, a);
      final left = _polar(c, side, a - math.pi / 4);
      final right = _polar(c, side, a + math.pi / 4);
      final kite = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      style.draw(canvas, kite);
    }
    final cube = Rect.fromCenter(
      center: Offset(c.dx, c.dy - r * 0.72),
      width: r * 0.16,
      height: r * 0.16,
    );
    canvas
      ..drawRect(cube, style.fill(0.5))
      ..drawRect(cube, style.line);
  }

  @override
  bool shouldRepaint(QiblahStateArtPainter old) => old.style != style;
}

class QiblahDialColors {
  const QiblahDialColors({
    required this.gilt,
    required this.fill,
    required this.ink,
    required this.muted,
  });

  factory QiblahDialColors.of(BuildContext context) {
    final tokens = context.tokens;
    return QiblahDialColors(
      gilt: tokens.gilt,
      fill: tokens.chrome,
      ink: tokens.onChrome,
      muted: tokens.onChromeMuted,
    );
  }

  final Color gilt;
  final Color fill;
  final Color ink;
  final Color muted;
}

double _rad(num degrees) => degrees * math.pi / 180;

Offset _polar(Offset c, double radius, double a) =>
    Offset(c.dx + radius * math.sin(a), c.dy - radius * math.cos(a));

void _text(
  Canvas canvas,
  Offset c,
  String text,
  TextStyle style,
  double radius,
  int degrees,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout();
  canvas
    ..save()
    ..translate(c.dx, c.dy)
    ..rotate(_rad(degrees))
    ..translate(0, -radius);
  painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  canvas.restore();
  painter.dispose();
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
