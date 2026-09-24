import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/shared/andalusian_ornament_geometry.dart';

class AndalusianStarCrossPatternPainter extends CustomPainter {
  const AndalusianStarCrossPatternPainter({
    required this.primary,
    required this.accent,
    required this.isDark,
    this.bandHeight,
  });

  final Color primary;
  final Color accent;
  final bool isDark;

  final double? bandHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final requestedBandHeight = bandHeight;
    final field = requestedBandHeight == null
        ? Offset.zero & size
        : Rect.fromLTWH(
            0,
            math.max(0, size.height - requestedBandHeight),
            size.width,
            math.min(size.height, requestedBandHeight),
          );
    if (field.isEmpty) return;

    final module = requestedBandHeight == null
        ? (size.shortestSide * 0.29).clamp(30.0, 48.0).toDouble()
        : (size.width >= 720 ? 44.0 : 36.0);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 1.05 : 0.9
      ..strokeJoin = StrokeJoin.miter
      ..color = primary.withValues(alpha: isDark ? 0.18 : 0.115);
    final starFill = Paint()
      ..style = PaintingStyle.fill
      ..color = primary.withValues(alpha: isDark ? 0.045 : 0.026);
    final crossFill = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: isDark ? 0.055 : 0.032);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 0.75 : 0.65
      ..strokeJoin = StrokeJoin.miter
      ..color = accent.withValues(alpha: isDark ? 0.2 : 0.13);

    AndalusianOrnamentGeometry.drawStarAndCrossField(
      canvas,
      field,
      module: module,
      starStroke: edgePaint,
      crossStroke: accentPaint,
      starFill: starFill,
      crossFill: crossFill,
    );

    if (requestedBandHeight != null) {
      final rulePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = LinearGradient(
          colors: [
            primary.withValues(alpha: 0),
            primary.withValues(alpha: isDark ? 0.14 : 0.085),
            primary.withValues(alpha: isDark ? 0.14 : 0.085),
            primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.12, 0.88, 1],
        ).createShader(field);
      canvas.drawLine(
        Offset(field.left, field.bottom - 1.5),
        Offset(field.right, field.bottom - 1.5),
        rulePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AndalusianStarCrossPatternPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.isDark != isDark ||
        oldDelegate.bandHeight != bandHeight;
  }
}
