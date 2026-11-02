import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Huda's progress indicator: the khatam turning steadily, its second
/// square breathing like a lantern's lattice catching the light, while
/// work runs (changed in `athkar`, owner round 4: eased eighths read as a
/// stutter). It stops when
/// removed (continuous motion only for live state) and rests as a still
/// khatam under reduce motion.
class HudaLampSpinner extends StatefulWidget {
  const HudaLampSpinner({super.key, this.size = 20, this.color});

  final double size;

  /// Defaults to the theme's gilt-tinted ornament color.
  final Color? color;

  @override
  State<HudaLampSpinner> createState() => _HudaLampSpinnerState();
}

class _HudaLampSpinnerState extends State<HudaLampSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ??
        Theme.of(context).extension<HudaTokens>()?.ornament ??
        Theme.of(context).colorScheme.primary;
    // Decorative: what is loading is said by the banner or button around it.
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _LampPainter(t: _controller.value, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  const _LampPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.2;
    final stroke = (size.shortestSide / 12).clamp(1.2, 2.4);
    // One rigid khatam (its squares always 45° apart, so every frame reads
    // as the star) turning at one speed, a full turn per cycle, so the
    // repeat has no seam; the back square breathes twice a turn.
    final turn = t * math.pi * 2;
    final breath = 0.5 + 0.2 * math.sin(t * math.pi * 4);
    final side = r * math.sqrt1_2 * 2;
    for (final (angle, alpha) in [(turn, 1.0), (turn + math.pi / 4, breath)]) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle)
        ..drawRect(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeJoin = StrokeJoin.round
            ..color = color.withValues(alpha: color.a * alpha),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.t != t || old.color != color;
}

/// The lamp: a small disc of the deep chrome holding a gilt mark (the
/// spinner while working, a khatam or an icon otherwise). Leads status
/// banners and lit tiles.
class HudaLamp extends StatelessWidget {
  const HudaLamp({super.key, required this.child, this.size = 40, this.ring});

  final Widget child;
  final double size;

  /// The fine ring's color; defaults to the gilt at half strength.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tokens.chromeGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: ring ?? tokens.gilt.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(color: tokens.gilt, size: size * 0.48),
        child: child,
      ),
    );
  }
}

/// A still khatam in a color, for the lamp's resting and failed marks.
class HudaKhatamMark extends StatelessWidget {
  const HudaKhatamMark({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Ornament(
    size: Size.square(size),
    painter: _KhatamMarkPainter(color: color),
  );
}

class _KhatamMarkPainter extends CustomPainter {
  const _KhatamMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    canvas
      ..drawPath(
        OrnamentGeometry.khatam(c, r),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (size.shortestSide / 12).clamp(1.2, 2.4)
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      )
      ..drawCircle(c, r * 0.18, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_KhatamMarkPainter old) => old.color != color;
}
