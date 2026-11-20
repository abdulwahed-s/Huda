import 'dart:math' as math;

import 'package:flutter/painting.dart';

abstract final class OrnamentGeometry {
  static Path star(
    Offset center,
    double radius, {
    int points = 8,
    double innerRatio = 0.5,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    final step = math.pi / points;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * innerRatio;
      final a = rotation + i * step;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path khatam(Offset center, double radius, {double rotation = 0}) =>
      star(
        center,
        radius,
        points: 8,
        innerRatio: math.cos(math.pi / 4) / math.cos(math.pi / 8),
        rotation: rotation - math.pi / 2,
      );

  static Path polygon(
    Offset center,
    double radius, {
    int sides = 8,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = rotation + i * 2 * math.pi / sides;
      final p = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path petals(
    Offset center,
    double radius, {
    int count = 8,
    double width = 0.36,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final a = rotation + i * 2 * math.pi / count;
      final tip = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      final side = a + math.pi / 2;
      final mid =
          center +
          Offset(math.cos(a) * radius * 0.5, math.sin(a) * radius * 0.5);
      final bulge =
          Offset(math.cos(side), math.sin(side)) * radius * width * 0.5;
      path
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          mid.dx + bulge.dx,
          mid.dy + bulge.dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          mid.dx - bulge.dx,
          mid.dy - bulge.dy,
          center.dx,
          center.dy,
        )
        ..close();
    }
    return path;
  }

  static Path pointedArch(Rect bounds, {double springRatio = 0.62}) {
    final w = bounds.width;
    final spring = bounds.bottom - bounds.height * springRatio;
    final apex = Offset(bounds.center.dx, bounds.top);
    final rise = spring - bounds.top;
    return Path()
      ..moveTo(bounds.left, bounds.bottom)
      ..lineTo(bounds.left, spring)
      ..cubicTo(
        bounds.left,
        spring - rise * 0.55,
        apex.dx - w * 0.16,
        apex.dy + rise * 0.18,
        apex.dx,
        apex.dy,
      )
      ..cubicTo(
        apex.dx + w * 0.16,
        apex.dy + rise * 0.18,
        bounds.right,
        spring - rise * 0.55,
        bounds.right,
        spring,
      )
      ..lineTo(bounds.right, bounds.bottom)
      ..close();
  }

  static Path roundArch(Rect bounds) {
    final r = bounds.width / 2;
    return Path()
      ..moveTo(bounds.left, bounds.bottom)
      ..lineTo(bounds.left, bounds.top + r)
      ..arcToPoint(
        Offset(bounds.right, bounds.top + r),
        radius: Radius.circular(r),
      )
      ..lineTo(bounds.right, bounds.bottom)
      ..close();
  }

  static List<Offset> ring(
    Offset center,
    double radius,
    int count, {
    bool clockwise = true,
  }) => [
    for (var i = 0; i < count; i++)
      center +
          Offset(
            math.cos(
                  -math.pi / 2 + (clockwise ? 1 : -1) * i * 2 * math.pi / count,
                ) *
                radius,
            math.sin(
                  -math.pi / 2 + (clockwise ? 1 : -1) * i * 2 * math.pi / count,
                ) *
                radius,
          ),
  ];
}
