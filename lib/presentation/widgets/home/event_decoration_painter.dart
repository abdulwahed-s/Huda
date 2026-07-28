import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class EventDecorationPainter extends CustomPainter {
  final String eventKey;
  final double animValue;
  final Color accentColor;
  final Color glowColor;

  EventDecorationPainter({
    required this.eventKey,
    required this.animValue,
    required this.accentColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    switch (eventKey) {
      case 'ramadan':
        _drawNightSky(canvas, size, 8, 1.0);
      case 'last_ten_ramadan':
        _drawNightSky(canvas, size, 14, 1.3);
      case 'eid_al_fitr':
        _drawLanterns(canvas, size);
      case 'eid_al_adha':
        _drawMountainCrescent(canvas, size);
      case 'day_of_arafah':
        _drawMountainSunrise(canvas, size);
      case 'first_ten_dhul_hijjah':
        _drawGoldenSunrise(canvas, size);
      case 'ashura':
        _drawBlessedRadiance(canvas, size);
      case 'days_of_tashreeq':
        _drawCelebration(canvas, size);
      case 'white_days_fasting':
        _drawFastingMoon(canvas, size);
      case 'monday_thursday_fasting':
        _drawFastingMoon(canvas, size, paired: true);
      case 'white_days_monday_thursday_fasting':
        _drawFastingMoon(canvas, size, paired: true, radiant: true);
    }

    _drawShimmerBand(canvas, size);
    canvas.restore();
  }

  void _drawGlowOrb(
      Canvas canvas, Offset center, double radius, Color color, double alpha) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.4),
          color.withValues(alpha: 0),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCrescent(
      Canvas canvas, Offset center, double radius, Color color, double alpha) {
    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final inner = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + radius * 0.38, center.dy - radius * 0.18),
        radius: radius * 0.82,
      ));
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(crescent, Paint()..color = color.withValues(alpha: alpha));
  }

  void _drawNightSky(
      Canvas canvas, Size size, int starCount, double intensity) {
    final w = size.width;
    final h = size.height;

    _drawGlowOrb(canvas, Offset(w * 0.82, h * 0.22), w * 0.18, glowColor,
        0.12 * intensity);

    final breath = sin(animValue * 2 * pi) * 0.03;
    _drawCrescent(canvas, Offset(w * 0.80, h * 0.24), w * 0.065 * intensity,
        accentColor, 0.55 + breath);

    final stars = _generateStarPositions(starCount, 42);
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      final twinkle = (0.25 + 0.75 * ((sin(animValue * 2 * pi + s[2]) + 1) / 2))
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(w * s[0], h * s[1]),
        s[3] * intensity,
        Paint()..color = accentColor.withValues(alpha: 0.6 * twinkle),
      );
    }

    if (intensity > 1.0) {
      final qadrPulse = (sin(animValue * 2 * pi * 0.7) + 1) / 2;
      _drawGlowOrb(canvas, Offset(w * 0.72, h * 0.14), w * 0.04, accentColor,
          0.25 + 0.2 * qadrPulse);
      canvas.drawCircle(
        Offset(w * 0.72, h * 0.14),
        2.0,
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    }
  }

  void _drawLanterns(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGlowOrb(canvas, Offset(w * 0.85, h * 0.35), w * 0.15, glowColor, 0.08);
    _drawGlowOrb(canvas, Offset(w * 0.70, h * 0.20), w * 0.10, glowColor, 0.06);

    final lanterns = [
      [0.88, 0.25, 12.0, 0.0],
      [0.75, 0.15, 9.0, 1.5],
      [0.92, 0.50, 8.0, 3.0],
    ];

    for (final l in lanterns) {
      final sway = sin(animValue * 2 * pi + l[3]) * 2.5;
      final cx = w * l[0] + sway;
      final cy = h * l[1];
      final s = l[2];

      final linePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(cx, cy - s * 1.8), Offset(cx, cy - s), linePaint);

      final body = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx + s * 0.5, cy - s * 0.3)
        ..lineTo(cx + s * 0.45, cy + s * 0.3)
        ..lineTo(cx + s * 0.2, cy + s * 0.6)
        ..lineTo(cx - s * 0.2, cy + s * 0.6)
        ..lineTo(cx - s * 0.45, cy + s * 0.3)
        ..lineTo(cx - s * 0.5, cy - s * 0.3)
        ..close();

      canvas.drawPath(
          body, Paint()..color = accentColor.withValues(alpha: 0.18));
      canvas.drawPath(
        body,
        Paint()
          ..color = accentColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      _drawGlowOrb(canvas, Offset(cx, cy), s * 1.2, accentColor, 0.10);
    }

    final sparkles = _generateStarPositions(6, 77);
    for (final s in sparkles) {
      final twinkle = (sin(animValue * 2 * pi * 1.5 + s[2]) + 1) / 2;
      _drawDiamond(canvas, Offset(w * s[0], h * s[1]), s[3] * 0.8,
          accentColor.withValues(alpha: 0.4 * twinkle));
    }
  }

  void _drawMountainCrescent(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGlowOrb(canvas, Offset(w * 0.78, h * 0.20), w * 0.12, glowColor, 0.10);

    _drawCrescent(
        canvas, Offset(w * 0.80, h * 0.18), w * 0.04, accentColor, 0.5);

    final mountain = Path()
      ..moveTo(w * 0.55, h)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.78, h * 0.58)
      ..lineTo(w * 0.88, h * 0.35)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
        mountain, Paint()..color = accentColor.withValues(alpha: 0.08));
    canvas.drawPath(
      mountain,
      Paint()
        ..color = accentColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    final stars = _generateStarPositions(5, 33);
    for (final s in stars) {
      final twinkle = (sin(animValue * 2 * pi + s[2]) + 1) / 2;
      canvas.drawCircle(
        Offset(w * s[0], h * s[1] * 0.5),
        s[3] * 0.7,
        Paint()..color = accentColor.withValues(alpha: 0.35 * twinkle),
      );
    }
  }

  void _drawMountainSunrise(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sunPulse = sin(animValue * 2 * pi) * 0.03;
    _drawGlowOrb(canvas, Offset(w * 0.82, h * 0.30), w * 0.22, glowColor,
        0.12 + sunPulse);
    _drawGlowOrb(canvas, Offset(w * 0.82, h * 0.30), w * 0.10, accentColor,
        0.18 + sunPulse);

    canvas.drawCircle(
      Offset(w * 0.82, h * 0.30),
      w * 0.035,
      Paint()..color = accentColor.withValues(alpha: 0.5),
    );

    final rayPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + animValue * 0.3;
      final inner = w * 0.05;
      final outer = w * 0.12;
      canvas.drawLine(
        Offset(w * 0.82 + cos(angle) * inner, h * 0.30 + sin(angle) * inner),
        Offset(w * 0.82 + cos(angle) * outer, h * 0.30 + sin(angle) * outer),
        rayPaint,
      );
    }

    final mountain = Path()
      ..moveTo(w * 0.50, h)
      ..lineTo(w * 0.70, h * 0.45)
      ..lineTo(w * 0.80, h * 0.55)
      ..lineTo(w * 0.92, h * 0.35)
      ..lineTo(w, h * 0.50)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
        mountain, Paint()..color = accentColor.withValues(alpha: 0.07));
  }

  void _drawGoldenSunrise(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pulse = sin(animValue * 2 * pi) * 0.04;
    _drawGlowOrb(
        canvas, Offset(w * 0.88, h * 0.15), w * 0.28, glowColor, 0.10 + pulse);
    _drawGlowOrb(canvas, Offset(w * 0.88, h * 0.15), w * 0.14, accentColor,
        0.15 + pulse);

    canvas.drawCircle(
      Offset(w * 0.88, h * 0.15),
      w * 0.04,
      Paint()..color = accentColor.withValues(alpha: 0.45),
    );

    final rayPaint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i * pi / 6) + animValue * 0.2;
      final innerR = w * 0.06;
      final outerR = w * 0.10 + (i.isEven ? w * 0.03 : 0);
      final alpha = 0.06 + 0.04 * sin(animValue * 2 * pi + i * 0.5);
      rayPaint.color = accentColor.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(w * 0.88 + cos(angle) * innerR, h * 0.15 + sin(angle) * innerR),
        Offset(w * 0.88 + cos(angle) * outerR, h * 0.15 + sin(angle) * outerR),
        rayPaint,
      );
    }
  }

  void _drawBlessedRadiance(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pulse = sin(animValue * 2 * pi) * 0.03;
    _drawGlowOrb(
        canvas, Offset(w * 0.82, h * 0.25), w * 0.20, glowColor, 0.10 + pulse);
    _drawGlowOrb(canvas, Offset(w * 0.82, h * 0.25), w * 0.10, accentColor,
        0.14 + pulse);

    canvas.drawCircle(
      Offset(w * 0.82, h * 0.25),
      w * 0.035,
      Paint()..color = accentColor.withValues(alpha: 0.45),
    );

    final rayPaint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) + animValue * 0.25;
      final innerR = w * 0.055;
      final outerR = w * 0.10 + (i.isEven ? w * 0.025 : 0);
      final alpha = 0.06 + 0.03 * sin(animValue * 2 * pi + i * 0.6);
      rayPaint.color = accentColor.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(w * 0.82 + cos(angle) * innerR, h * 0.25 + sin(angle) * innerR),
        Offset(w * 0.82 + cos(angle) * outerR, h * 0.25 + sin(angle) * outerR),
        rayPaint,
      );
    }

    final stars = _generateStarPositions(6, 91);
    for (final s in stars) {
      final twinkle = (sin(animValue * 2 * pi + s[2]) + 1) / 2;
      canvas.drawCircle(
        Offset(w * s[0], h * s[1]),
        s[3] * 0.7,
        Paint()..color = accentColor.withValues(alpha: 0.35 * twinkle),
      );
    }
  }

  void _drawCelebration(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGlowOrb(canvas, Offset(w * 0.85, h * 0.30), w * 0.14, glowColor, 0.08);
    _drawGlowOrb(
        canvas, Offset(w * 0.70, h * 0.60), w * 0.10, accentColor, 0.06);

    final sparkles = _generateStarPositions(10, 55);
    for (final s in sparkles) {
      final twinkle = (sin(animValue * 2 * pi * 1.3 + s[2]) + 1) / 2;
      _drawDiamond(canvas, Offset(w * s[0], h * s[1]), s[3] * 0.9,
          accentColor.withValues(alpha: 0.35 * twinkle));
    }

    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.85, h * 0.30), width: w * 0.3, height: h * 0.4),
      0,
      pi,
      false,
      arcPaint,
    );
  }

  void _drawFastingMoon(
    Canvas canvas,
    Size size, {
    bool paired = false,
    bool radiant = false,
  }) {
    final w = size.width;
    final h = size.height;
    final intensity = radiant ? 0.16 : 0.11;
    _drawGlowOrb(
      canvas,
      Offset(w * 0.82, h * 0.24),
      w * (radiant ? 0.24 : 0.19),
      glowColor,
      intensity,
    );
    _drawCrescent(
      canvas,
      Offset(w * 0.82, h * 0.24),
      w * 0.055,
      accentColor,
      0.58,
    );

    if (paired) {
      _drawCrescent(
        canvas,
        Offset(w * 0.70, h * 0.38),
        w * 0.032,
        accentColor,
        0.35,
      );
    }

    final stars = _generateStarPositions(radiant ? 8 : 5, paired ? 119 : 103);
    for (final star in stars) {
      final twinkle = (sin(animValue * 2 * pi + star[2]) + 1) / 2;
      canvas.drawCircle(
        Offset(w * star[0], h * star[1]),
        star[3] * 0.65,
        Paint()..color = accentColor.withValues(alpha: 0.22 + twinkle * 0.24),
      );
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.35, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.35, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawShimmerBand(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.4;
    final total = size.width + bandWidth;
    final xPos = animValue * total - bandWidth;

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(xPos, 0),
        Offset(xPos + bandWidth, 0),
        [
          const Color(0x00FFFFFF),
          const Color(0x0DFFFFFF),
          const Color(0x00FFFFFF),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  List<List<double>> _generateStarPositions(int count, int seed) {
    final rng = Random(seed);
    return List.generate(count, (_) {
      return [
        0.58 + rng.nextDouble() * 0.38,
        0.05 + rng.nextDouble() * 0.85,
        rng.nextDouble() * 2 * pi,
        0.8 + rng.nextDouble() * 1.2,
      ];
    });
  }

  @override
  bool shouldRepaint(covariant EventDecorationPainter old) =>
      old.animValue != animValue ||
      old.eventKey != eventKey ||
      old.accentColor != accentColor;
}
