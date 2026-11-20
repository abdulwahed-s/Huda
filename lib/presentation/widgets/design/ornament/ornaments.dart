import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornament_geometry.dart';

export 'ornament_geometry.dart';

@immutable
class OrnamentStyle {
  const OrnamentStyle({
    required this.color,
    required this.render,
    this.stroke = 1,
  });

  factory OrnamentStyle.of(
    BuildContext context, {
    bool quiet = false,
    bool onChrome = false,
  }) {
    final tokens = context.tokens;
    return OrnamentStyle(
      color: onChrome
          ? tokens.gilt
          : quiet
          ? tokens.ornamentQuiet
          : tokens.ornament,
      render: onChrome ? OrnamentRender.luminous : OrnamentRender.line,
      stroke: quiet ? tokens.stroke.hairline : tokens.stroke.fine,
    );
  }

  final Color color;
  final OrnamentRender render;
  final double stroke;

  OrnamentStyle copyWith({
    Color? color,
    double? stroke,
    OrnamentRender? render,
  }) => OrnamentStyle(
    color: color ?? this.color,
    render: render ?? this.render,
    stroke: stroke ?? this.stroke,
  );

  Paint get line => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  Paint fill([double alpha = 1]) => Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: color.a * alpha);

  void draw(Canvas canvas, Path path, {bool closed = true}) {
    switch (render) {
      case OrnamentRender.line:
        canvas.drawPath(path, line);
      case OrnamentRender.filled:
        if (closed) {
          canvas.drawPath(path, fill());
        } else {
          canvas.drawPath(path, line..strokeWidth = stroke * 1.6);
        }
      case OrnamentRender.luminous:
        canvas
          ..drawPath(
            path,
            line
              ..strokeWidth = stroke * 5
              ..color = color.withValues(alpha: color.a * 0.12),
          )
          ..drawPath(path, line);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OrnamentStyle &&
      other.color == color &&
      other.render == render &&
      other.stroke == stroke;

  @override
  int get hashCode => Object.hash(color, render, stroke);
}

class Ornament extends StatelessWidget {
  const Ornament({
    super.key,
    required this.painter,
    this.size = Size.infinite,
    this.semanticLabel,
  });

  final CustomPainter painter;
  final Size size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      child: CustomPaint(painter: painter, size: size),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: label, image: true, child: paint);
  }
}

class RosettePainter extends CustomPainter {
  const RosettePainter({
    required this.style,
    this.count = 8,
    this.rings = 2,
    this.rotation = 0,
  });

  final OrnamentStyle style;
  final int count;
  final int rings;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - style.stroke * 3;
    if (r <= 0) return;
    final turn = -math.pi / 2 + rotation;
    if (style.render == OrnamentRender.filled) {
      canvas.drawCircle(c, r, style.fill(0.35));
      canvas.drawPath(
        OrnamentGeometry.star(
          c,
          r * 0.92,
          points: count,
          innerRatio: 0.62,
          rotation: turn,
        ),
        style.fill(0.7),
      );
      canvas.drawPath(
        OrnamentGeometry.petals(
          c,
          r * 0.6,
          count: count,
          rotation: turn + math.pi / count,
        ),
        style.fill(),
      );
      return;
    }
    for (var i = 0; i < rings; i++) {
      final ring = Path()
        ..addOval(Rect.fromCircle(center: c, radius: r * (1 - i * 0.1)));
      style.draw(canvas, ring);
    }
    style.draw(
      canvas,
      OrnamentGeometry.star(
        c,
        r * 0.86,
        points: count,
        innerRatio: 0.6,
        rotation: turn,
      ),
    );
    style.draw(
      canvas,
      OrnamentGeometry.petals(
        c,
        r * 0.56,
        count: count,
        rotation: turn + math.pi / count,
      ),
    );
    style.draw(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.12)),
    );
  }

  @override
  bool shouldRepaint(RosettePainter old) =>
      old.style != style ||
      old.count != count ||
      old.rings != rings ||
      old.rotation != rotation;
}

class StarFieldPainter extends CustomPainter {
  const StarFieldPainter({required this.style, this.module = 48, this.fade});

  final OrnamentStyle style;
  final double module;

  final AlignmentGeometry? fade;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fade = this.fade?.resolve(TextDirection.ltr);
    if (fade != null) {
      canvas.saveLayer(rect, Paint());
    }
    canvas.save();
    canvas.clipRect(rect);
    final cols = (size.width / module).ceil() + 1;
    final rows = (size.height / module).ceil() + 1;
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        final center = Offset(x * module, y * module);
        style.draw(canvas, OrnamentGeometry.khatam(center, module * 0.36));
        final cross = center + Offset(module / 2, module / 2);
        style.draw(
          canvas,
          OrnamentGeometry.polygon(cross, module * 0.16, sides: 4, rotation: 0),
        );
      }
    }
    canvas.restore();
    if (fade != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: Alignment(-fade.x, -fade.y),
            end: fade,
            colors: const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter old) =>
      old.style != style || old.module != module || old.fade != fade;
}

enum CornerMark { none, square, star }

class RuledFramePainter extends CustomPainter {
  const RuledFramePainter({
    required this.style,
    this.rules = const [0, 4, 12],
    this.corners = CornerMark.square,
  });

  final OrnamentStyle style;
  final List<double> rules;
  final CornerMark corners;

  @override
  void paint(Canvas canvas, Size size) {
    final half = style.stroke / 2;
    final paint = style.line;
    for (var i = 0; i < rules.length; i++) {
      final rect = (Offset.zero & size).deflate(rules[i] + half);
      canvas.drawRect(
        rect,
        paint
          ..strokeWidth = i == rules.length - 1
              ? style.stroke
              : style.stroke * 0.7,
      );
    }
    if (corners == CornerMark.none || rules.isEmpty) return;
    final inner = (Offset.zero & size).deflate(rules.last + half);
    final s = math.max(
      6.0,
      (rules.last - (rules.length > 1 ? rules[rules.length - 2] : 0)) * 0.7,
    );
    for (final corner in [
      inner.topLeft,
      inner.topRight,
      inner.bottomLeft,
      inner.bottomRight,
    ]) {
      if (corners == CornerMark.star) {
        canvas.drawPath(OrnamentGeometry.khatam(corner, s * 1.5), style.fill());
      } else {
        canvas.drawPath(
          OrnamentGeometry.polygon(corner, s, sides: 4, rotation: 0),
          style.fill(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RuledFramePainter old) =>
      old.style != style || old.corners != corners || old.rules != rules;
}

class RuleBandPainter extends CustomPainter {
  const RuleBandPainter({
    required this.style,
    required this.textDirection,
    this.medallionAt = 0.5,
    this.points = 8,
  });

  final OrnamentStyle style;
  final TextDirection textDirection;
  final double medallionAt;
  final int points;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final at = textDirection == TextDirection.rtl
        ? 1 - medallionAt
        : medallionAt;
    final cx = size.width * at;
    final r = size.height / 2 - style.stroke;
    final gap = r + 6;
    final paint = style.line;
    for (final dy in [-2.0, 2.0]) {
      canvas
        ..drawLine(
          Offset(0, y + dy),
          Offset(math.max(0, cx - gap), y + dy),
          paint,
        )
        ..drawLine(
          Offset(math.min(size.width, cx + gap), y + dy),
          Offset(size.width, y + dy),
          paint,
        );
    }
    style.draw(
      canvas,
      OrnamentGeometry.star(Offset(cx, y), r, points: points, innerRatio: 0.55),
    );
    canvas.drawCircle(Offset(cx, y), r * 0.22, style.fill());
  }

  @override
  bool shouldRepaint(RuleBandPainter old) =>
      old.style != style ||
      old.medallionAt != medallionAt ||
      old.textDirection != textDirection ||
      old.points != points;
}

class ArchPainter extends CustomPainter {
  const ArchPainter({
    required this.style,
    this.pointed = true,
    this.outlines = 2,
    this.gap = 8,
  });

  final OrnamentStyle style;
  final bool pointed;
  final int outlines;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < outlines; i++) {
      final rect = Rect.fromLTRB(
        i * gap + style.stroke,
        i * gap + style.stroke,
        size.width - i * gap - style.stroke,
        size.height + 1,
      );
      final path = pointed
          ? OrnamentGeometry.pointedArch(rect)
          : OrnamentGeometry.roundArch(rect);
      if (style.render == OrnamentRender.filled) {
        canvas.drawPath(path, style.fill(i == 0 ? 0.5 : 1));
      } else {
        style.draw(canvas, path);
      }
    }
  }

  @override
  bool shouldRepaint(ArchPainter old) =>
      old.style != style ||
      old.pointed != pointed ||
      old.outlines != outlines ||
      old.gap != gap;
}

class ShamsaPainter extends CustomPainter {
  const ShamsaPainter({required this.style, this.rays = 24, this.star = 8});

  final OrnamentStyle style;
  final int rays;
  final int star;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - style.stroke * 3;
    if (r <= 0) return;
    style.draw(
      canvas,
      OrnamentGeometry.star(c, r, points: rays, innerRatio: 0.78),
    );
    style.draw(
      canvas,
      OrnamentGeometry.star(c, r * 0.66, points: rays ~/ 2, innerRatio: 0.9),
    );
    style.draw(canvas, OrnamentGeometry.star(c, r * 0.4, points: star));
    canvas.drawCircle(c, r * 0.1, style.fill());
  }

  @override
  bool shouldRepaint(ShamsaPainter old) =>
      old.style != style || old.rays != rays || old.star != star;
}

class CartouchePainter extends CustomPainter {
  const CartouchePainter({required this.style, this.fill});

  final OrnamentStyle style;

  final Color? fill;

  static Path shape(Rect rect) {
    final h = rect.height;
    final lobe = h * 0.5;
    final mid = rect.center.dy;
    return Path()
      ..moveTo(rect.left + lobe, rect.top)
      ..lineTo(rect.right - lobe, rect.top)
      ..cubicTo(
        rect.right - lobe * 0.35,
        rect.top,
        rect.right - lobe * 0.6,
        mid,
        rect.right,
        mid,
      )
      ..cubicTo(
        rect.right - lobe * 0.6,
        mid,
        rect.right - lobe * 0.35,
        rect.bottom,
        rect.right - lobe,
        rect.bottom,
      )
      ..lineTo(rect.left + lobe, rect.bottom)
      ..cubicTo(
        rect.left + lobe * 0.35,
        rect.bottom,
        rect.left + lobe * 0.6,
        mid,
        rect.left,
        mid,
      )
      ..cubicTo(
        rect.left + lobe * 0.6,
        mid,
        rect.left + lobe * 0.35,
        rect.top,
        rect.left + lobe,
        rect.top,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = (Offset.zero & size).deflate(style.stroke);
    final path = shape(outer);
    final fill = this.fill;
    if (fill != null) canvas.drawPath(path, Paint()..color = fill);
    style.draw(canvas, path);
    style.draw(canvas, shape(outer.deflate(4)));
  }

  @override
  bool shouldRepaint(CartouchePainter old) =>
      old.style != style || old.fill != fill;
}

class ArabesqueBorderPainter extends CustomPainter {
  const ArabesqueBorderPainter({required this.style, this.module = 24});

  final OrnamentStyle style;
  final double module;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    if (h <= 0 || size.width <= 0) return;
    final mid = h / 2;
    final amp = h / 2 - style.stroke * 2;
    final count = (size.width / module).ceil();
    final step = size.width / math.max(1, count);
    final up = Path()..moveTo(0, mid);
    final down = Path()..moveTo(0, mid);
    for (var i = 0; i < count; i++) {
      final x0 = i * step;
      final dir = i.isEven ? -1 : 1;
      up.cubicTo(
        x0 + step * 0.35,
        mid + dir * amp,
        x0 + step * 0.65,
        mid + dir * amp,
        x0 + step,
        mid,
      );
      down.cubicTo(
        x0 + step * 0.35,
        mid - dir * amp,
        x0 + step * 0.65,
        mid - dir * amp,
        x0 + step,
        mid,
      );
    }
    style.draw(canvas, up, closed: false);
    style.draw(canvas, down, closed: false);
    for (var i = 0; i < count; i++) {
      final eye = Offset(i * step + step / 2, mid);
      canvas.drawPath(
        OrnamentGeometry.star(eye, amp * 0.32, points: 4, innerRatio: 0.45),
        style.fill(),
      );
    }
  }

  @override
  bool shouldRepaint(ArabesqueBorderPainter old) =>
      old.style != style || old.module != module;
}
