import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomRippleAnimation extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Color? centerColor;
  final double amplitude;
  final int rippleCount;
  final Duration duration;

  const CustomRippleAnimation({
    super.key,
    required this.child,
    required this.colors,
    this.centerColor,
    this.amplitude = 20.0,
    this.rippleCount = 3,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<CustomRippleAnimation> createState() => _CustomRippleAnimationState();
}

class _CustomRippleAnimationState extends State<CustomRippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: BlobPainter(
            animation: _controller,
            colors: widget.colors,
            centerColor: widget.centerColor,
            amplitude: widget.amplitude,
            blobCount: widget.rippleCount,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class BlobPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;
  final Color? centerColor;
  final double amplitude;
  final int blobCount;

  BlobPainter({
    required this.animation,
    required this.colors,
    required this.centerColor,
    required this.amplitude,
    required this.blobCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2;

    if (centerColor != null) {
      final centerPaint = Paint()
        ..color = centerColor!
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final centerPath = _createBlobPath(
        center,
        baseRadius * 0.95,
        animation.value,
        8,
        amplitude * 0.15,
        0,
      );
      canvas.drawPath(centerPath, centerPaint);
    }

    for (int i = 0; i < blobCount; i++) {
      final layerProgress = (animation.value + (i / blobCount)) % 1.0;
      final scale = 0.8 + (layerProgress * 0.4);
      final opacity = math.sin(layerProgress * math.pi);

      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final blobPath = _createBlobPath(
        center,
        baseRadius * scale,
        animation.value + (i * 0.3),
        12,
        amplitude,
        i * 1.5,
      );

      canvas.drawPath(blobPath, paint);
    }
  }

  Path _createBlobPath(
    Offset center,
    double radius,
    double animationValue,
    int points,
    double waveAmplitude,
    double rotationOffset,
  ) {
    final path = Path();
    final angleStep = (math.pi * 2) / points;

    for (int i = 0; i <= points; i++) {
      final angle = (i * angleStep) + (rotationOffset * math.pi / 180);

      final wave1 =
          math.sin(animationValue * math.pi * 2 + i * 0.5) * waveAmplitude;
      final wave2 = math.sin(animationValue * math.pi * 4 + i * 0.3) *
          (waveAmplitude * 0.5);
      final wave3 = math.cos(animationValue * math.pi * 3 + i * 0.7) *
          (waveAmplitude * 0.3);

      final distortion = wave1 + wave2 + wave3;
      final currentRadius = radius + distortion;

      final x = center.dx + math.cos(angle) * currentRadius;
      final y = center.dy + math.sin(angle) * currentRadius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final controlAngle = angle - (angleStep / 2);
        final controlWave1 =
            math.sin(animationValue * math.pi * 2 + (i - 0.5) * 0.5) *
                waveAmplitude;
        final controlWave2 =
            math.sin(animationValue * math.pi * 4 + (i - 0.5) * 0.3) *
                (waveAmplitude * 0.5);
        final controlWave3 =
            math.cos(animationValue * math.pi * 3 + (i - 0.5) * 0.7) *
                (waveAmplitude * 0.3);
        final controlDistortion = controlWave1 + controlWave2 + controlWave3;
        final controlRadius = radius + controlDistortion;

        final controlX = center.dx + math.cos(controlAngle) * controlRadius;
        final controlY = center.dy + math.sin(controlAngle) * controlRadius;

        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(BlobPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
