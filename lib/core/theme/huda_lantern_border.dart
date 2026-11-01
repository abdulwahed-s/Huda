import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The Lantern control shape: a rounded rectangle that can carry an
/// engraving, a small six-petal rosette in the trailing-bottom corner cut
/// by the edge, with faint rings around it like contour lines (owner round
/// 4). Lit
/// buttons wear it; quiet controls don't. An [OutlinedBorder], so buttons
/// can use it as their shape. [innerColor] draws an optional inner line.
///
/// The engraving is painted over the button, so it stays faint and small
/// (within 60% of the height of the corner, at most a third of the width)
/// and the label always wins.
class HudaLanternBorder extends OutlinedBorder {
  const HudaLanternBorder({
    super.side,
    this.radius = 12,
    this.innerColor,
    this.innerInset = 3,
    this.engraving,
  });

  final double radius;

  /// The inner line's color; null draws none.
  final Color? innerColor;
  final double innerInset;

  /// The engraving's color (keep it faint); null draws none.
  final Color? engraving;

  RRect _outer(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_outer(rect).deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_outer(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawRRect(
        _outer(rect).deflate(side.strokeInset - side.strokeOffset / 2),
        side.toPaint(),
      );
    }
    final engraving = this.engraving;
    if (engraving != null) {
      _engrave(canvas, rect, engraving, textDirection ?? TextDirection.ltr);
    }
    final inner = innerColor;
    if (inner == null || rect.shortestSide < innerInset * 4) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(innerInset + 0.5),
        Radius.circular((radius - innerInset).clamp(0, radius)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = inner,
    );
  }

  void _engrave(Canvas canvas, Rect rect, Color color, TextDirection dir) {
    if (rect.height < 32 || rect.width < 48) return;
    final h = rect.height;
    // Kept in the corner, clear of the label: never past 60% of the height
    // or a third of the width from the corner.
    final reach = math.min(rect.width / 3, h * 0.6);
    // Just outside the trailing-bottom corner, so about a third of the
    // rosette shows.
    final center = dir == TextDirection.rtl
        ? Offset(rect.left + h * 0.04, rect.bottom + h * 0.02)
        : Offset(rect.right - h * 0.04, rect.bottom + h * 0.02);
    canvas
      ..save()
      ..clipRRect(_outer(rect));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Two contour rings, the outer one fainter.
    for (final (r, alpha) in [(reach * 0.78, 0.8), (reach, 0.5)]) {
      line.color = color.withValues(alpha: color.a * alpha);
      canvas.drawCircle(center, r, line);
    }
    // The rosette: six petals (a hexafoil, so it never reads as Athkar's
    // 8-fold rosette) around a small eye.
    final petal = reach * 0.6;
    line.color = color;
    final petals = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + math.pi / 6;
      final dirV = Offset(math.cos(a), math.sin(a));
      final tip = center + dirV * petal;
      final side = Offset(-math.sin(a), math.cos(a)) * petal * 0.3;
      final mid = center + dirV * petal * 0.52;
      petals
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(mid.dx + side.dx, mid.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          mid.dx - side.dx,
          mid.dy - side.dy,
          center.dx,
          center.dy,
        );
    }
    canvas
      ..drawPath(petals, line)
      ..drawCircle(center, petal * 0.2, line)
      ..restore();
  }

  @override
  HudaLanternBorder copyWith({BorderSide? side}) => HudaLanternBorder(
    side: side ?? this.side,
    radius: radius,
    innerColor: innerColor,
    innerInset: innerInset,
    engraving: engraving,
  );

  @override
  ShapeBorder scale(double t) => HudaLanternBorder(
    side: side.scale(t),
    radius: radius * t,
    innerColor: innerColor,
    innerInset: innerInset * t,
    engraving: engraving,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is HudaLanternBorder) {
      return HudaLanternBorder(
        side: BorderSide.lerp(a.side, side, t),
        radius: radius,
        innerColor: Color.lerp(a.innerColor, innerColor, t),
        innerInset: innerInset,
        engraving: Color.lerp(a.engraving, engraving, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  bool operator ==(Object other) =>
      other is HudaLanternBorder &&
      other.side == side &&
      other.radius == radius &&
      other.innerColor == innerColor &&
      other.innerInset == innerInset &&
      other.engraving == engraving;

  @override
  int get hashCode =>
      Object.hash(side, radius, innerColor, innerInset, engraving);
}
