import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KhatmaProgressRings extends StatelessWidget {
  final double percentTotal;
  final double percentDaily;
  final double percentPacing;
  final bool isDark;
  final String centerText;

  const KhatmaProgressRings({
    super.key,
    required this.percentTotal,
    required this.percentDaily,
    required this.percentPacing,
    required this.isDark,
    required this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? Colors.white10 : Colors.black12;
    final dimension = 170.r;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: _animatedRing(
        end: percentTotal,
        milliseconds: 1200,
        builder: (total) => _animatedRing(
          end: percentDaily,
          milliseconds: 1400,
          builder: (daily) => _animatedRing(
            end: percentPacing,
            milliseconds: 1600,
            builder: (pacing) => CustomPaint(
              painter: _RingsPainter(
                total: total,
                daily: daily,
                pacing: pacing,
                backgroundColor: backgroundColor,
              ),
              child: Center(
                child: Text(
                  centerText,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedRing({
    required double end,
    required int milliseconds,
    required Widget Function(double value) builder,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: end),
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => builder(value),
    );
  }
}

class _Ring {
  final double radius;
  final double lineWidth;
  final double percent;
  final List<Color> colors;

  const _Ring({
    required this.radius,
    required this.lineWidth,
    required this.percent,
    required this.colors,
  });
}

class _RingsPainter extends CustomPainter {
  final double total;
  final double daily;
  final double pacing;
  final Color backgroundColor;

  _RingsPainter({
    required this.total,
    required this.daily,
    required this.pacing,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rings = <_Ring>[
      _Ring(
        radius: 85.r,
        lineWidth: 16.r,
        percent: total,
        colors: const [Colors.greenAccent, Colors.green],
      ),
      _Ring(
        radius: 67.r,
        lineWidth: 14.r,
        percent: daily,
        colors: const [Colors.orangeAccent, Colors.deepOrange],
      ),
      _Ring(
        radius: 50.r,
        lineWidth: 12.r,
        percent: pacing,
        colors: const [Colors.cyanAccent, Colors.blue],
      ),
    ];

    for (final ring in rings) {
      final arcRadius = ring.radius - ring.lineWidth / 2;
      final rect = Rect.fromCircle(center: center, radius: arcRadius);

      final background = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.lineWidth
        ..strokeCap = StrokeCap.round
        ..color = backgroundColor;
      canvas.drawArc(rect, 0, 2 * math.pi, false, background);

      final percent = ring.percent.clamp(0.0, 1.0);
      if (percent <= 0) continue;

      final foreground = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.lineWidth
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: ring.colors).createShader(rect);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        percent * 2 * math.pi,
        false,
        foreground,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.daily != daily ||
      oldDelegate.pacing != pacing ||
      oldDelegate.backgroundColor != backgroundColor;
}
