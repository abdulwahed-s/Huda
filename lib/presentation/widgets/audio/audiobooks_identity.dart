import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

final FeatureIdentity audiobooksIdentity = FeatureIdentity(
  id: 'audiobooks',
  motif:
      'A woven ribbon: two threads plaited over and under, an eye per '
      'chapter, ending in a tassel; recordings as woven swatches',
  count: 2,
  rhythm: IdentityRhythm.sequence,
  material: IdentityMaterial.thread,
  headerArt: (style) => AudiobookHangingRibbonsPainter(style: style),
);

Color audiobookCloth(BuildContext context, int seed) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final shades = [
    tokens.chrome,
    Color.lerp(tokens.chrome, scheme.primary, 0.32)!,
    Color.lerp(tokens.chrome, tokens.gilt, 0.22)!,
    Color.lerp(tokens.chromeEnd, scheme.primary, 0.16)!,
  ];
  var color = shades[seed.abs() % shades.length];
  for (var i = 0; i < 12 && color.computeLuminance() > 0.05; i++) {
    color = Color.lerp(color, const Color(0xFF000000), 0.12)!;
  }
  return color;
}

@immutable
class RibbonWindow {
  const RibbonWindow({required this.eyes, required this.start});

  final int eyes;
  final double start;

  factory RibbonWindow.fit({
    required double length,
    required int chapters,
    required double current,
    double minEye = 22,
    int maxEyes = 14,
  }) {
    final room = math.max(3, math.min(maxEyes, (length / minEye).floor()));
    if (chapters <= room) {
      final eyes = chapters + 2 <= room ? chapters + 2 : room;
      return RibbonWindow(eyes: eyes, start: -(eyes - chapters) / 2);
    }
    final start = (current - (room - 1) / 2).clamp(0.0, chapters - room + 0.0);
    return RibbonWindow(eyes: room, start: start);
  }
}

class AudiobookRibbonPainter extends CustomPainter {
  const AudiobookRibbonPainter({
    required this.style,
    required this.window,
    required this.chapters,
    this.heard = 0,
    this.current,
    this.weave = 1,
    this.fill,
    this.ring,
    this.fadeEnds = true,
    this.rtl = false,
  });

  final OrnamentStyle style;
  final RibbonWindow window;
  final int chapters;
  final double heard;
  final int? current;
  final double weave;

  final Color? fill;

  final Color? ring;
  final bool fadeEnds;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || window.eyes <= 0) return;
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final fade = fadeEnds;
    if (fade) canvas.saveLayer(Offset.zero & size, Paint());
    _paintRibbon(canvas, size);
    if (fade) {
      final edge = math.min(size.width * 0.14, 48.0) / size.width;
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            colors: const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: [0, edge, 1 - edge, 1],
          ).createShader(Offset.zero & size),
      );
      canvas.restore();
    }
  }

  void _paintRibbon(Canvas canvas, Size size) {
    final length = size.width;
    final mid = size.height / 2;
    final step = length / window.eyes;
    final band = math.min(size.height * 0.15, step * 0.24).clamp(1.2, 9.0);
    final swing = math.min(size.height * 0.36, step * 0.5);
    final flat = band >= 3.2;
    final reach = (length + step) * weave.clamp(0.0, 1.0);
    final first = window.start.floor() - 1;
    final last = (window.start + window.eyes).ceil() + 1;
    final fillColor = fill ?? style.color;
    final ringColor = ring ?? style.color;

    for (var i = first; i < last; i++) {
      final x0 = (i - window.start) * step;
      final x1 = x0 + step;
      if (x1 < 0 || x0 > length || x0 > reach) continue;
      final chapter = i >= 0 && i < chapters;
      final alpha = chapter ? 1.0 : 0.32;
      final overA = i.isEven;
      final sign = i.isEven ? 1.0 : -1.0;
      double y(double t, bool a) =>
          mid + (a ? 1 : -1) * sign * math.sin(math.pi * t) * swing;

      if (chapter) {
        final heardPart = (heard - i).clamp(0.0, 1.0);
        final woven = ((reach - x1) / step).clamp(0.0, 1.0);
        final eye = _eyePath(x0, step, mid, swing, band);
        if (heardPart > 0 && woven > 0) {
          canvas.save();
          canvas.clipRect(
            Rect.fromLTRB(x0, 0, x0 + step * heardPart, size.height),
          );
          canvas.drawPath(
            eye,
            Paint()
              ..color = fillColor.withValues(alpha: fillColor.a * 0.82 * woven),
          );
          canvas.restore();
        }
        if (i == current && woven > 0) {
          canvas.drawPath(
            eye,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = style.stroke * 1.4
              ..strokeJoin = StrokeJoin.round
              ..color = ringColor.withValues(alpha: ringColor.a * woven),
          );
          final tick = Paint()
            ..strokeWidth = style.stroke * 1.4
            ..strokeCap = StrokeCap.round
            ..color = ringColor.withValues(alpha: ringColor.a * woven);
          final cx = x0 + step / 2;
          final below = mid + swing + band;
          final room = size.height - below;
          if (room > 3) {
            canvas.drawLine(
              Offset(cx, below + room * 0.25),
              Offset(cx, below + room * 0.8),
              tick,
            );
          }
        }
      }

      final gap = (band * 1.1 / step).clamp(0.0, 0.22);
      for (final a in [true, false]) {
        final overHere = a == overA;
        final from = overHere ? 0.0 : gap;
        final to = overHere ? 1 - gap : 1.0;
        final end = ((reach - x0) / step).clamp(0.0, 1.0);
        final stop = math.min(to, end);
        if (stop <= from) continue;
        final center = <Offset>[];
        const samples = 14;
        for (var s = 0; s <= samples; s++) {
          final t = from + (stop - from) * s / samples;
          center.add(Offset(x0 + t * step, y(t, a)));
        }
        _thread(canvas, center, band, flat, alpha);
      }
    }
  }

  Path _eyePath(double x0, double step, double mid, double swing, double band) {
    final path = Path();
    const samples = 16;
    final inset = band / 2 + style.stroke;
    final top = <Offset>[];
    for (var s = 0; s <= samples; s++) {
      final t = s / samples;
      final h = math.max(0.0, math.sin(math.pi * t) * swing - inset);
      top.add(Offset(x0 + t * step, mid - h));
    }
    path.moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in top.reversed) {
      path.lineTo(p.dx, mid + (mid - p.dy));
    }
    return path..close();
  }

  void _thread(
    Canvas canvas,
    List<Offset> center,
    double band,
    bool flat,
    double alpha,
  ) {
    final color = style.color.withValues(alpha: style.color.a * alpha);
    final s = style.copyWith(color: color);
    if (!flat) {
      s.draw(canvas, Path()..addPolygon(center, false), closed: false);
      return;
    }
    final left = <Offset>[];
    final right = <Offset>[];
    for (var k = 0; k < center.length; k++) {
      final a = center[math.max(0, k - 1)];
      final b = center[math.min(center.length - 1, k + 1)];
      final d = b - a;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final n = Offset(-d.dy / len, d.dx / len) * (band / 2);
      left.add(center[k] + n);
      right.add(center[k] - n);
    }
    final body = Path()..addPolygon([...left, ...right.reversed], true);
    canvas.drawPath(
      body,
      Paint()..color = color.withValues(alpha: color.a * 0.14),
    );
    s.draw(canvas, Path()..addPolygon(left, false), closed: false);
    s.draw(canvas, Path()..addPolygon(right, false), closed: false);
  }

  @override
  bool shouldRepaint(AudiobookRibbonPainter old) =>
      old.style != style ||
      old.window.eyes != window.eyes ||
      old.window.start != window.start ||
      old.chapters != chapters ||
      old.heard != heard ||
      old.current != current ||
      old.weave != weave ||
      old.fill != fill ||
      old.ring != ring ||
      old.fadeEnds != fadeEnds ||
      old.rtl != rtl;
}

class AudiobookClothPainter extends CustomPainter {
  const AudiobookClothPainter({
    required this.cloth,
    required this.thread,
    required this.variant,
    this.radius = 12,
  });

  final Color cloth;

  final Color thread;
  final int variant;
  final double radius;

  static const double fringe = 0.1;

  static const (double, double) ribbonBand = (0.25, 0.65);

  @override
  void paint(Canvas canvas, Size size) {
    final clothHeight = size.height * (1 - fringe);
    final rect = Rect.fromLTWH(0, 0, size.width, clothHeight);
    final r = math.min(radius, size.shortestSide / 6);
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: Radius.circular(r / 3),
      bottomRight: Radius.circular(r / 3),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(cloth, thread, 0.06)!, cloth],
        ).createShader(rect),
    );
    canvas.drawRRect(
      shape.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = thread.withValues(alpha: 0.3),
    );
    canvas.save();
    canvas.clipRRect(shape);
    final warp = Paint()
      ..strokeWidth = 1
      ..color = thread.withValues(alpha: 0.06);
    final pitch = math.max(4.0, size.width / 60);
    for (var x = pitch / 2; x < size.width; x += pitch) {
      canvas.drawLine(Offset(x, 0), Offset(x, clothHeight), warp);
    }
    final unit = clothHeight / 100;
    for (final y in [clothHeight * 0.13, clothHeight * 0.85]) {
      _border(canvas, size.width, y, unit);
    }
    canvas.restore();
    final fringeTop = clothHeight;
    final fringeLength = size.height - clothHeight;
    final line = Paint()
      ..strokeWidth = math.max(1, size.width / 260)
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(cloth, thread, 0.55)!;
    final group = math.max(10.0, size.width / 14);
    for (var x = group / 2; x < size.width - group / 4; x += group) {
      for (var k = -1; k <= 1; k++) {
        final top = Offset(x, fringeTop);
        final bottom = Offset(
          x + k * group * 0.16,
          fringeTop + fringeLength * 0.92,
        );
        canvas.drawLine(top, bottom, line);
      }
      canvas.drawCircle(
        Offset(x, fringeTop + fringeLength * 0.18),
        line.strokeWidth * 1.3,
        Paint()..color = line.color,
      );
    }
  }

  void _border(Canvas canvas, double width, double y, double unit) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit * 0.9)
      ..strokeJoin = StrokeJoin.round
      ..color = thread.withValues(alpha: 0.42);
    final h = unit * 3.4;
    switch (variant % 3) {
      case 0:
        final path = Path();
        final w = h * 1.6;
        for (var x = -w; x < width + w; x += w) {
          path
            ..moveTo(x, y - h / 2)
            ..lineTo(x + w / 2, y + h / 2)
            ..lineTo(x + w, y - h / 2);
        }
        canvas.drawPath(path, paint);
      case 1:
        final w = h * 1.8;
        canvas
          ..drawLine(Offset(0, y - h), Offset(width, y - h), paint)
          ..drawLine(Offset(0, y + h), Offset(width, y + h), paint);
        for (var x = w / 2; x < width; x += w) {
          canvas.drawPath(
            Path()
              ..moveTo(x, y - h * 0.55)
              ..lineTo(x + h * 0.55, y)
              ..lineTo(x, y + h * 0.55)
              ..lineTo(x - h * 0.55, y)
              ..close(),
            paint,
          );
        }
      default:
        canvas
          ..drawLine(
            Offset(0, y - h * 0.45),
            Offset(width, y - h * 0.45),
            paint,
          )
          ..drawLine(
            Offset(0, y + h * 0.45),
            Offset(width, y + h * 0.45),
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(AudiobookClothPainter old) =>
      old.cloth != cloth ||
      old.thread != thread ||
      old.variant != variant ||
      old.radius != radius;
}

class AudiobookHangingRibbonsPainter extends CustomPainter {
  const AudiobookHangingRibbonsPainter({required this.style, this.draw})
    : super(repaint: draw);

  final OrnamentStyle style;
  final Animation<double>? draw;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = (draw?.value ?? 1).clamp(0.0, 1.0);
    double at(double start, double length) =>
        Curves.easeOutCubic.transform(((t - start) / length).clamp(0.0, 1.0));
    final width = math.min(size.width * 0.26, size.height * 0.2);
    for (final (i, (x, length, eyes, heard)) in [
      (0.3, 0.86, 5, 2.6),
      (0.7, 0.62, 3, 1.0),
    ].indexed) {
      final unrolled = at(i * 0.16, 0.6);
      if (unrolled <= 0) continue;
      final full = size.height * length;
      canvas.save();
      if (unrolled < 1) {
        canvas.clipRect(
          Rect.fromLTRB(0, -style.stroke, size.width, full * unrolled),
        );
      }
      _hanging(
        canvas,
        Offset(size.width * x, 0),
        full,
        width,
        eyes,
        heard * at(0.55 + i * 0.1, 0.35),
      );
      canvas.restore();
    }
  }

  void _hanging(
    Canvas canvas,
    Offset top,
    double length,
    double width,
    int eyes,
    double heard,
  ) {
    final tassel = width * 1.9;
    final ribbon = length - tassel;
    if (ribbon <= 0) return;
    canvas.save();
    canvas
      ..translate(top.dx + width / 2, top.dy)
      ..rotate(math.pi / 2);
    AudiobookRibbonPainter(
      style: style,
      window: RibbonWindow(eyes: eyes, start: 0),
      chapters: eyes,
      heard: heard,
      fill: style.color,
      fadeEnds: false,
    ).paint(canvas, Size(ribbon, width));
    canvas.restore();
    final knotTop = top + Offset(0, ribbon);
    final knot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: knotTop + Offset(0, width * 0.32),
        width: width * 0.46,
        height: width * 0.5,
      ),
      Radius.circular(width * 0.14),
    );
    style.draw(canvas, Path()..addRRect(knot));
    final wrap = knotTop + Offset(0, width * 0.32);
    style.draw(
      canvas,
      Path()
        ..moveTo(wrap.dx - width * 0.23, wrap.dy)
        ..lineTo(wrap.dx + width * 0.23, wrap.dy),
      closed: false,
    );
    final from = knotTop + Offset(0, width * 0.58);
    for (var k = -2; k <= 2; k++) {
      final end = from + Offset(k * width * 0.16, tassel - width * 0.62);
      style.draw(
        canvas,
        Path()
          ..moveTo(from.dx + k * width * 0.05, from.dy)
          ..quadraticBezierTo(
            from.dx + k * width * 0.12,
            from.dy + (end.dy - from.dy) * 0.5,
            end.dx,
            end.dy,
          ),
        closed: false,
      );
    }
  }

  @override
  bool shouldRepaint(AudiobookHangingRibbonsPainter old) =>
      old.style != style || old.draw != draw;
}
