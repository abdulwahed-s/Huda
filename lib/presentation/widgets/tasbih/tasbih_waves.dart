import 'dart:math' as math;

import 'package:flutter/material.dart';

class TasbihWaves extends StatefulWidget {
  const TasbihWaves({super.key});

  @override
  State<TasbihWaves> createState() => _TasbihWavesState();
}

class _TasbihWavesState extends State<TasbihWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 22000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _WavesPainter(_controller.value),
        ),
      ),
    );
  }
}

class _WaveLayer {
  final Color color;
  final double heightFactor;
  final double speed;
  final double amplitude;
  final double wavelengthFactor;

  const _WaveLayer({
    required this.color,
    required this.heightFactor,
    required this.speed,
    required this.amplitude,
    required this.wavelengthFactor,
  });
}

class _WavesPainter extends CustomPainter {
  final double t;

  _WavesPainter(this.t);

  static const List<_WaveLayer> _layers = [
    _WaveLayer(
      color: Color.fromRGBO(255, 255, 255, 0.07),
      heightFactor: 0.30,
      speed: 1.0,
      amplitude: 6,
      wavelengthFactor: 1.0,
    ),
    _WaveLayer(
      color: Color.fromRGBO(255, 255, 255, 0.04),
      heightFactor: 0.55,
      speed: 22 / 14,
      amplitude: 6,
      wavelengthFactor: 1.35,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in _layers) {
      final paint = Paint()
        ..color = layer.color
        ..style = PaintingStyle.fill;

      final baseY = size.height * layer.heightFactor;
      final phase = t * layer.speed * 2 * math.pi;
      final wavelength =
          (size.width / layer.wavelengthFactor).clamp(1.0, double.infinity);

      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, baseY);
      for (double x = 0; x <= size.width; x += 1) {
        final y = baseY +
            layer.amplitude * math.sin((x / wavelength * 2 * math.pi) + phase);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.t != t;
}
