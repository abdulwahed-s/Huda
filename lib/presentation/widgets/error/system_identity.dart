import 'dart:math' as math;

import 'package:flutter/material.dart';

class SystemMendLinePainter extends CustomPainter {
  const SystemMendLinePainter({
    required this.color,
    this.drawn = 1,
    this.mended = 0,
    this.glint = -1,
    this.rtl = false,
  });

  final Color color;
  final double drawn;
  final double mended;

  final double glint;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final w = size.width;
    final cy = size.height / 2;
    final stroke = (size.height / 14).clamp(1.2, 2.2);
    final lozenge = (size.height / 4).clamp(4.0, 9.0);
    final start = lozenge * 1.2;
    final end = w - lozenge * 1.2;
    final breakAt = w * 0.46;
    final gap = w * 0.05 * (1 - mended);
    final sink = size.height * 0.22 * (1 - mended);
    final tilt = 0.07 * (1 - mended);

    final line = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;

    void diamond(Offset c, double r) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.7, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r * 0.7, c.dy)
          ..close(),
        fill,
      );
    }

    final d = drawn.clamp(0.0, 1.0);
    final nearEnd = breakAt - gap / 2;
    diamond(Offset(lozenge * 0.7, cy), lozenge * d);
    canvas.drawLine(
      Offset(start, cy),
      Offset(start + (nearEnd - start) * d, cy),
      line,
    );

    canvas.save();
    final pivot = Offset(w - lozenge * 0.7, cy + sink);
    canvas
      ..translate(pivot.dx, pivot.dy)
      ..rotate(-tilt)
      ..translate(-pivot.dx, -pivot.dy);
    final farStart = breakAt + gap / 2;
    diamond(pivot, lozenge * d);
    canvas.drawLine(
      Offset(end, cy + sink),
      Offset(end - (end - farStart) * d, cy + sink),
      line,
    );
    canvas.restore();

    if (mended > 0) {
      final s = Curves.easeOut.transform(mended);
      final glow = Paint()
        ..color = color.withValues(alpha: 0.35 * (1 - (mended - 0.6).abs()))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 3);
      final half = w * 0.03;
      canvas
        ..drawLine(
          Offset(breakAt - half * s, cy),
          Offset(breakAt + half * s, cy),
          line,
        )
        ..drawCircle(Offset(breakAt, cy), stroke * 3, glow);
    }

    if (glint >= 0 && glint <= 1) {
      final x = start + (end - start) * glint;
      final light = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(
              Rect.fromCircle(center: Offset(x, cy), radius: lozenge * 2),
            )
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(Offset(x, cy), lozenge * 2, light);
    }
  }

  @override
  bool shouldRepaint(SystemMendLinePainter old) =>
      old.color != color ||
      old.drawn != drawn ||
      old.mended != mended ||
      old.glint != glint ||
      old.rtl != rtl;
}

class SystemMendLine extends StatefulWidget {
  const SystemMendLine({
    super.key,
    required this.color,
    this.mending = false,
    this.width = 220,
    this.height = 28,
  });

  final Color color;
  final bool mending;
  final double width;
  final double height;

  @override
  State<SystemMendLine> createState() => _SystemMendLineState();
}

class _SystemMendLineState extends State<SystemMendLine>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _mend = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduce) {
      _draw.value = 1;
      _mend.stop();
    } else if (_draw.value == 0 && !_draw.isAnimating) {
      _draw.forward();
    }
    _syncMend();
  }

  @override
  void didUpdateWidget(SystemMendLine old) {
    super.didUpdateWidget(old);
    if (old.mending != widget.mending) _syncMend();
  }

  void _syncMend() {
    if (widget.mending && !_reduce) {
      if (!_mend.isAnimating) _mend.repeat();
    } else {
      _mend
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _mend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_draw, _mend]),
            builder: (context, _) {
              final t = _mend.value;
              final double mended;
              var glint = -1.0;
              if (_reduce) {
                mended = widget.mending ? 1 : 0;
              } else if (!widget.mending) {
                mended = 0;
              } else if (t < 0.4) {
                mended = Curves.easeInOutCubic.transform(t / 0.4);
              } else if (t < 0.8) {
                mended = 1;
                glint = (t - 0.4) / 0.4;
              } else {
                mended = 1 - Curves.easeIn.transform((t - 0.8) / 0.2);
              }
              return CustomPaint(
                painter: SystemMendLinePainter(
                  color: widget.color,
                  drawn: Curves.easeOutCubic.transform(_draw.value),
                  mended: math.max(0, mended),
                  glint: glint,
                  rtl: rtl,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
