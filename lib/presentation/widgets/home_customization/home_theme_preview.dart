import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/home/home_preferences.dart';

class HomeThemePreview extends StatelessWidget {
  const HomeThemePreview({super.key, required this.theme});

  final HomeThemeId theme;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        child: RepaintBoundary(
          child: CustomPaint(
            key: ValueKey('home-preview-${theme.name}'),
            painter: _PreviewPainter(
              theme: theme,
              page: Theme.of(context).scaffoldBackgroundColor,
              surface: scheme.surfaceContainerLow,
              outline: scheme.outlineVariant,
              line: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              onSurface: scheme.onSurface.withValues(alpha: 0.7),
              chrome: tokens.chrome,
              chromeEnd: tokens.chromeEnd,
              gilt: tokens.gilt,
              onChrome: tokens.onChrome,
              ornament: tokens.ornament,
              warm: Color.lerp(tokens.chromeEnd, tokens.gilt, 0.55)!,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter({
    required this.theme,
    required this.page,
    required this.surface,
    required this.outline,
    required this.line,
    required this.onSurface,
    required this.chrome,
    required this.chromeEnd,
    required this.gilt,
    required this.onChrome,
    required this.ornament,
    required this.warm,
  });

  final HomeThemeId theme;
  final Color page;
  final Color surface;
  final Color outline;
  final Color line;
  final Color onSurface;
  final Color chrome;
  final Color chromeEnd;
  final Color gilt;
  final Color onChrome;
  final Color ornament;
  final Color warm;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120;
    final sy = size.height / 160;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 120, 160), Paint()..color = page);
    switch (theme) {
      case HomeThemeId.classic:
        _header(canvas);
        _plates(canvas, top: 46, rows: 4);
      case HomeThemeId.prayerToday:
        _dial(canvas);
        _medallions(canvas, top: 118);
      case HomeThemeId.quranJourney:
        _logo(canvas, const Rect.fromLTWH(54, 7, 12, 7), ornament);
        _bookmark(canvas);
        _ayah(canvas);
        _ribbon(canvas);
        _medallions(canvas, top: 126);
    }
    canvas.restore();
  }

  void _logo(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.height * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.3)),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.4, rect.bottom),
      Offset(rect.left + rect.width * 0.4, rect.top + rect.height * 0.45),
      paint,
    );
  }

  void _header(Canvas canvas) {
    const band = Rect.fromLTWH(0, 0, 120, 38);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [chrome, chromeEnd],
        ).createShader(band),
    );
    canvas.drawCircle(
      const Offset(20, 26),
      12,
      Paint()..color = gilt.withValues(alpha: 0.12),
    );
    _logo(canvas, const Rect.fromLTWH(8, 20, 24, 13), gilt);
  }

  void _plates(Canvas canvas, {required double top, required int rows}) {
    const columns = 4;
    const gap = 6.0;
    const side = (120 - 16 - gap * (columns - 1)) / columns;
    var n = 0;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final x = 8 + column * (side + gap);
        final y = top + row * (side + 10);
        if (y + side > 158) return;
        _plate(canvas, Rect.fromLTWH(x, y, side, side), n++);
        _bar(
          canvas,
          Rect.fromLTWH(x + side * 0.18, y + side + 3, side * 0.64, 2.2),
          line,
        );
      }
    }
  }

  void _plate(Canvas canvas, Rect rect, int n) {
    final side = rect.width;
    final plate = RRect.fromRectAndRadius(rect, Radius.circular(side * 0.16));
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [chrome, chromeEnd],
        ).createShader(rect),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..color = gilt.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    final mark = Paint()
      ..color = gilt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final c = rect.center;
    switch (n % 4) {
      case 0:
        canvas.drawCircle(c, side * 0.24, mark);
      case 1:
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: side * 0.24),
          -1.2,
          3.6,
          false,
          mark,
        );
      case 2:
        canvas.drawPath(_star(c, side * 0.26), mark);
      default:
        canvas.drawRect(
          Rect.fromCenter(center: c, width: side * 0.42, height: side * 0.32),
          mark,
        );
    }
  }

  void _dial(Canvas canvas) {
    const hero = Rect.fromLTWH(0, 0, 120, 108);
    canvas.drawRect(
      hero,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [chrome, chromeEnd],
        ).createShader(hero),
    );
    _logo(canvas, const Rect.fromLTWH(54, 6, 12, 7), gilt);
    const c = Offset(60, 58);
    const r = 30.0;
    final ring = Paint()
      ..color = gilt.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawCircle(c, r + 5, ring);
    canvas.drawLine(
      const Offset(24, 58),
      const Offset(96, 58),
      ring..color = gilt.withValues(alpha: 0.5),
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      math.pi * 0.8,
      math.pi * 0.95,
      false,
      Paint()
        ..color = gilt
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      math.pi * 1.75,
      math.pi * 0.45,
      false,
      Paint()
        ..color = gilt.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    Offset at(double a) => c + Offset(math.cos(a), math.sin(a)) * r;
    for (final a in const [0.8, 1.5]) {
      canvas.drawCircle(at(math.pi * a), 1.6, Paint()..color = gilt);
    }
    canvas.drawCircle(at(math.pi * 1.86), 2.6, Paint()..color = chrome);
    canvas.drawCircle(
      at(math.pi * 1.86),
      2.6,
      Paint()
        ..color = gilt
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.drawCircle(at(math.pi * 1.75), 3.4, Paint()..color = onChrome);
    _bar(canvas, const Rect.fromLTWH(52, 38, 16, 1.8), gilt);
    _bar(canvas, const Rect.fromLTWH(48, 43, 24, 6), onChrome);
    _bar(canvas, const Rect.fromLTWH(51, 51, 18, 2.6), gilt);
    _bar(
      canvas,
      const Rect.fromLTWH(50, 63, 20, 3.4),
      onChrome.withValues(alpha: 0.8),
    );
    for (var i = 0; i < 5; i++) {
      final x = 12 + i * 20.0;
      _bar(
        canvas,
        Rect.fromLTWH(x, 96, 16, 2.6),
        i == 2 ? gilt : onChrome.withValues(alpha: 0.75),
      );
    }
    _bar(canvas, const Rect.fromLTWH(56, 100.5, 8, 1.2), gilt);
  }

  void _medallions(Canvas canvas, {required double top}) {
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 3; i++) {
        final c = Offset(24 + i * 36.0, top + 7 + row * 22);
        canvas.drawCircle(
          c,
          7.5,
          Paint()
            ..shader = RadialGradient(
              colors: [chromeEnd, chrome],
            ).createShader(Rect.fromCircle(center: c, radius: 7.5)),
        );
        canvas.drawCircle(
          c,
          7.5,
          Paint()
            ..color = gilt.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
        canvas.drawCircle(
          c,
          2.6,
          Paint()
            ..color = gilt
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        _bar(canvas, Rect.fromLTWH(c.dx - 7, c.dy + 10, 14, 1.8), line);
      }
    }
  }

  void _bookmark(Canvas canvas) {
    final card = RRect.fromLTRBR(8, 22, 112, 48, const Radius.circular(4));
    canvas.drawRRect(
      card,
      Paint()
        ..shader = LinearGradient(
          colors: [chrome, chromeEnd],
        ).createShader(card.outerRect),
    );
    canvas.drawPath(
      Path()
        ..moveTo(14, 22)
        ..lineTo(19, 22)
        ..lineTo(19, 34)
        ..lineTo(16.5, 31.5)
        ..lineTo(14, 34)
        ..close(),
      Paint()..color = gilt,
    );
    _bar(canvas, const Rect.fromLTWH(25, 27, 18, 1.8), gilt);
    _bar(canvas, const Rect.fromLTWH(25, 31, 34, 3.4), onChrome);
    _bar(
      canvas,
      const Rect.fromLTWH(25, 36.5, 26, 1.8),
      onChrome.withValues(alpha: 0.5),
    );
    canvas.drawCircle(const Offset(102, 32), 5, Paint()..color = onChrome);
    _bar(
      canvas,
      const Rect.fromLTWH(25, 42.5, 80, 0.8),
      onChrome.withValues(alpha: 0.3),
    );
    _bar(canvas, const Rect.fromLTWH(25, 42.5, 38, 0.9), gilt);
  }

  void _ayah(Canvas canvas) {
    final card = RRect.fromLTRBR(8, 54, 112, 88, const Radius.circular(4));
    canvas.drawRRect(card, Paint()..color = surface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = ornament.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    _bar(canvas, const Rect.fromLTWH(14, 59, 20, 1.8), ornament);
    _bar(canvas, const Rect.fromLTWH(86, 59, 20, 1.8), line);
    _bar(canvas, const Rect.fromLTWH(18, 67, 84, 3), onSurface);
    _bar(canvas, const Rect.fromLTWH(34, 76, 46, 3), onSurface);
    canvas.drawCircle(
      const Offset(28, 77.5),
      2.6,
      Paint()
        ..color = ornament
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _ribbon(Canvas canvas) {
    final card = RRect.fromLTRBR(8, 94, 112, 118, const Radius.circular(4));
    canvas.drawRRect(card, Paint()..color = surface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    _bar(canvas, const Rect.fromLTWH(14, 98.5, 20, 1.8), ornament);
    _bar(canvas, const Rect.fromLTWH(14, 102.5, 30, 2.8), onSurface);
    _bar(canvas, const Rect.fromLTWH(96, 99, 10, 5), ornament);
    for (var i = 0; i < 15; i++) {
      final x = 14 + i * 6.4;
      final today = i == 6;
      _bar(
        canvas,
        Rect.fromLTWH(x, today ? 109 : 110, 4.6, today ? 4.4 : 2.4),
        i <= 6 ? ornament : line,
      );
    }
  }

  Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 14; i++) {
      final a = -1.5708 + i * 3.14159 / 7;
      final d = i.isEven ? r : r * 0.48;
      final p = c + Offset(d * _cos(a), d * _sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static double _cos(double a) => Offset.fromDirection(a).dx;
  static double _sin(double a) => Offset.fromDirection(a).dy;

  void _bar(Canvas canvas, Rect rect, Color color) => canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.theme != theme ||
      old.page != page ||
      old.chrome != chrome ||
      old.gilt != gilt ||
      old.surface != surface;
}
