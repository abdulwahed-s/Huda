import 'dart:math';
import 'package:flutter/material.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color patternColor;
  final double tileSize;

  IslamicPatternPainter({
    required this.patternColor,
    this.tileSize = 60.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * tileSize + tileSize / 2;
        final cy = row * tileSize + tileSize / 2;
        _drawEightPointedStar(canvas, paint, cx, cy, tileSize * 0.42);
      }
    }
  }

  void _drawEightPointedStar(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double radius,
  ) {
    final outerRadius = radius;
    final innerRadius = radius * 0.42;
    const points = 8;
    const totalVertices = points * 2;
    final angleStep = pi / points;

    final path = Path();
    for (int i = 0; i < totalVertices; i++) {
      final angle = (i * angleStep) - (pi / 2);
      final r = i.isEven ? outerRadius : innerRadius;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    final connectPaint = Paint()
      ..color = patternColor.withValues(alpha: patternColor.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * angleStep) - (pi / 2);
      final x = cx + outerRadius * cos(angle);
      final y = cy + outerRadius * sin(angle);
      canvas.drawCircle(Offset(x, y), 1.2, connectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.patternColor != patternColor ||
        oldDelegate.tileSize != tileSize;
  }
}
