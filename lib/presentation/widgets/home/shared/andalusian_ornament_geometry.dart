import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class AndalusianOrnamentGeometry {
  static const double silverRatioConjugate = 0.41421356237309503;

  static void drawStarAndCrossField(
    Canvas canvas,
    Rect field, {
    required double module,
    required Paint starStroke,
    required Paint crossStroke,
    Paint? starFill,
    Paint? crossFill,
  }) {
    final originX =
        field.center.dx - ((field.width / 2 / module).floor() * module);
    final originY =
        field.center.dy - ((field.height / 2 / module).floor() * module);
    final startColumn = ((field.left - originX) / module).floor() - 1;
    final endColumn = ((field.right - originX) / module).ceil() + 1;
    final startRow = ((field.top - originY) / module).floor() - 1;
    final endRow = ((field.bottom - originY) / module).ceil() + 1;

    canvas.save();
    canvas.clipRect(field);
    for (var row = startRow; row <= endRow; row++) {
      for (var column = startColumn; column <= endColumn; column++) {
        final starCenter = Offset(
          originX + column * module,
          originY + row * module,
        );
        final star = eightPointStar(starCenter, module * 0.405);
        if (starFill != null) canvas.drawPath(star, starFill);
        canvas.drawPath(star, starStroke);

        final cross = crossTile(
          starCenter + Offset(module / 2, module / 2),
          module * 0.295,
          module * 0.19,
        );
        if (crossFill != null) canvas.drawPath(cross, crossFill);
        canvas.drawPath(cross, crossStroke);
      }
    }
    canvas.restore();
  }

  static void drawEightfoldRosette(
    Canvas canvas,
    Offset center,
    double radius, {
    required Paint primary,
    Paint? secondary,
    double progress = 1,
  }) {
    if (radius <= 0 || progress <= 0) return;
    final value = progress.clamp(0.0, 1.0);
    final second = secondary ?? primary;
    final outer = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(outer, -math.pi / 2, math.pi * 2 * value, false, primary);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      math.pi / 2,
      -math.pi * 2 * value,
      false,
      second,
    );
    if (value >= 0.35) {
      canvas.drawPath(eightPointStar(center, radius * 0.84), second);
    }
    if (value >= 0.58) {
      canvas.drawCircle(center, radius * 0.19, primary);
    }
  }

  static void drawInterlacedPolygonChain(
    Canvas canvas,
    Rect band, {
    required Paint primary,
    required Paint secondary,
    double progress = 1,
  }) {
    if (band.isEmpty || progress <= 0) return;
    final value = progress.clamp(0.0, 1.0);
    final radius = math.min(band.height * 0.42, 11.0);
    final step = radius * 2.1;
    final centerY = band.center.dy;
    final visibleRight = band.left + band.width * value;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(band.left, band.top, visibleRight, band.bottom),
    );
    for (var x = band.left - step; x <= band.right + step; x += step) {
      final index = ((x - band.left) / step).round();
      final center = Offset(x, centerY);
      final polygon = regularPolygon(
        center,
        radius,
        8,
        index.isEven ? math.pi / 8 : 0,
      );
      canvas.drawPath(polygon, index.isEven ? primary : secondary);
      final next = Offset(x + step, centerY);
      canvas.drawLine(
        center + const Offset(0, -1),
        next + const Offset(0, 1),
        index.isEven ? secondary : primary,
      );
    }
    canvas.restore();
  }

  static void drawVegetalFrieze(
    Canvas canvas,
    Rect band, {
    required Paint vine,
    required Paint leaf,
    double progress = 1,
  }) {
    if (band.isEmpty || progress <= 0) return;
    final value = progress.clamp(0.0, 1.0);
    final visibleRight = band.left + band.width * value;
    final centerY = band.center.dy;
    final module = math.max(26.0, band.height * 1.8);
    final leafHeight = math.min(band.height * 0.42, 7.0);
    final leafWidth = leafHeight * 0.78;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(band.left, band.top, visibleRight, band.bottom),
    );
    canvas.drawLine(
      Offset(band.left, centerY),
      Offset(band.right, centerY),
      vine,
    );

    for (var x = band.left + module * 0.5; x < band.right; x += module) {
      for (final direction in const [-1.0, 1.0]) {
        final base = Offset(x, centerY);
        final tip = Offset(x, centerY + leafHeight * direction);
        final leafPath = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            x - leafWidth,
            centerY + leafHeight * 0.38 * direction,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            x + leafWidth,
            centerY + leafHeight * 0.38 * direction,
            base.dx,
            base.dy,
          )
          ..close();
        canvas
          ..drawPath(leafPath, leaf)
          ..drawLine(base, tip, vine);
      }

      final leftTip = Offset(x - module * 0.28, centerY);
      final rightTip = Offset(x + module * 0.28, centerY);
      final sideLeaves = Path()
        ..moveTo(x, centerY)
        ..quadraticBezierTo(
          x - module * 0.18,
          centerY - leafHeight * 0.46,
          leftTip.dx,
          leftTip.dy,
        )
        ..moveTo(x, centerY)
        ..quadraticBezierTo(
          x + module * 0.18,
          centerY + leafHeight * 0.46,
          rightTip.dx,
          rightTip.dy,
        );
      canvas.drawPath(sideLeaves, leaf);
    }
    canvas.restore();
  }

  static void drawSebkaField(
    Canvas canvas,
    Rect field, {
    required double module,
    required Paint primary,
    required Paint secondary,
  }) {
    if (field.isEmpty) return;
    final rise = module * 0.72;
    canvas.save();
    canvas.clipRect(field);
    for (
      var x = field.left - field.height;
      x < field.right + field.height;
      x += module
    ) {
      canvas
        ..drawLine(
          Offset(x, field.bottom),
          Offset(x + field.height / rise * module, field.top),
          primary,
        )
        ..drawLine(
          Offset(x, field.top),
          Offset(x + field.height / rise * module, field.bottom),
          secondary,
        );
    }
    canvas.restore();
  }

  static Path horseshoeArch(Rect bay) {
    final centerX = bay.center.dx;
    final radius = bay.width * 0.5;
    final springY = bay.top + radius * 0.92;
    final returnInset = radius * 0.16;
    return Path()
      ..moveTo(bay.left + returnInset, bay.bottom)
      ..lineTo(bay.left + returnInset, springY + radius * 0.34)
      ..cubicTo(
        bay.left - radius * 0.03,
        springY - radius * 0.30,
        centerX - radius * 0.23,
        bay.top + radius * 0.16,
        centerX,
        bay.top,
      )
      ..cubicTo(
        centerX + radius * 0.23,
        bay.top + radius * 0.16,
        bay.right + radius * 0.03,
        springY - radius * 0.30,
        bay.right - returnInset,
        springY + radius * 0.34,
      )
      ..lineTo(bay.right - returnInset, bay.bottom);
  }

  static Path lambrequinEdge(
    Size size, {
    required double baseline,
    required double depth,
    double? lobeWidth,
  }) {
    final width = lobeWidth ?? 42.0;
    final count = math.max(1, (size.width / width).ceil());
    final step = size.width / count;
    final path = Path()..moveTo(0, baseline);
    for (var index = 0; index < count; index++) {
      final left = index * step;
      final center = left + step / 2;
      final right = left + step;
      path
        ..cubicTo(
          left + step * 0.16,
          baseline,
          center - step * 0.20,
          baseline + depth * 0.48,
          center,
          baseline + depth,
        )
        ..cubicTo(
          center + step * 0.20,
          baseline + depth * 0.48,
          right - step * 0.16,
          baseline,
          right,
          baseline,
        );
    }
    return path;
  }

  static void drawAtauriqueSpray(
    Canvas canvas,
    Offset root, {
    required double width,
    required double height,
    required Paint vine,
    required Paint leaf,
    bool upward = true,
  }) {
    final direction = upward ? -1.0 : 1.0;
    for (final mirror in const [-1.0, 1.0]) {
      final tip = root + Offset(width * mirror, height * direction);
      final stem = Path()
        ..moveTo(root.dx, root.dy)
        ..cubicTo(
          root.dx + width * 0.16 * mirror,
          root.dy + height * 0.48 * direction,
          root.dx + width * 0.70 * mirror,
          root.dy + height * 0.52 * direction,
          tip.dx,
          tip.dy,
        );
      canvas.drawPath(stem, vine);
      _drawPalmetteLeaf(
        canvas,
        root + Offset(width * 0.42 * mirror, height * 0.54 * direction),
        width * 0.29,
        height * 0.23,
        mirror,
        direction,
        leaf,
      );
      _drawPalmetteLeaf(
        canvas,
        root + Offset(width * 0.72 * mirror, height * 0.73 * direction),
        width * 0.24,
        height * 0.20,
        -mirror,
        direction,
        leaf,
      );
    }
  }

  static Path eightPointStar(Offset center, double outerRadius) {
    final path = Path();
    final innerRadius = outerRadius * silverRatioConjugate;
    for (var index = 0; index < 16; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + index * math.pi / 8;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path crossTile(Offset center, double arm, double neck) {
    final points = <Offset>[
      Offset(-neck, -arm),
      Offset(neck, -arm),
      Offset(neck, -neck),
      Offset(arm, -neck),
      Offset(arm, neck),
      Offset(neck, neck),
      Offset(neck, arm),
      Offset(-neck, arm),
      Offset(-neck, neck),
      Offset(-arm, neck),
      Offset(-arm, -neck),
      Offset(-neck, -neck),
    ];
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = center + points[index];
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path regularPolygon(
    Offset center,
    double radius,
    int sides,
    double startAngle,
  ) {
    final path = Path();
    for (var index = 0; index < sides; index++) {
      final angle = startAngle + index * math.pi * 2 / sides;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static void _drawPalmetteLeaf(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double horizontalDirection,
    double verticalDirection,
    Paint paint,
  ) {
    final tip =
        center +
        Offset(width * horizontalDirection, height * verticalDirection);
    final normal = Offset(
      height * 0.28 * verticalDirection,
      -width * 0.28 * horizontalDirection,
    );
    final leafPath = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx + normal.dx,
        center.dy + normal.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        center.dx - normal.dx,
        center.dy - normal.dy,
        center.dx,
        center.dy,
      )
      ..close();
    canvas
      ..drawPath(leafPath, paint)
      ..drawLine(center, tip, paint);
  }
}
