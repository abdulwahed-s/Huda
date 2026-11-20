import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';

class QiblahCalibrationCard extends StatefulWidget {
  const QiblahCalibrationCard({super.key});

  @override
  State<QiblahCalibrationCard> createState() => _QiblahCalibrationCardState();
}

class _QiblahCalibrationCardState extends State<QiblahCalibrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _trace = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _trace
        ..stop()
        ..value = 0.3;
    } else if (!_trace.isAnimating) {
      _trace.repeat();
    }
  }

  @override
  void dispose() {
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final gilt = tokens.gilt;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: EdgeInsets.all(space.md),
        decoration: BoxDecoration(
          color: tokens.onChrome.withValues(alpha: 0.06),
          borderRadius: tokens.radius.card,
          border: Border.all(
            color: gilt.withValues(alpha: 0.32),
            width: tokens.stroke.hairline,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 56,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _trace,
                    builder: (context, _) => CustomPaint(
                      painter: _FigureEightPainter(
                        progress: _trace.value,
                        color: gilt,
                        stroke: tokens.stroke.fine,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calibrateCompass,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.onChrome,
                    ),
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    l10n.calibrateCompassInstruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.onChromeMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  _FigureEightPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  Offset _at(double t, Offset c, double a, double b) =>
      Offset(c.dx + a * math.cos(t), c.dy + b * math.sin(t) * math.cos(t));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = size.width * 0.4;
    final b = size.height * 0.36;
    final guide = Path();
    for (var i = 0; i <= 80; i++) {
      final p = _at(i / 80 * 2 * math.pi, c, a, b);
      i == 0 ? guide.moveTo(p.dx, p.dy) : guide.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      guide,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.3),
    );
    final head = progress * 2 * math.pi;
    const steps = 24;
    for (var i = 0; i < steps; i++) {
      final f = (i + 1) / steps;
      final t0 = head - 0.4 * 2 * math.pi * (1 - i / steps);
      final t1 = head - 0.4 * 2 * math.pi * (1 - f);
      canvas.drawLine(
        _at(t0, c, a, b),
        _at(t1, c, a, b),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke * (1 + f)
          ..color = color.withValues(alpha: f * f),
      );
    }
    final p = _at(head, c, a, b);
    canvas
      ..drawCircle(
        p,
        stroke * 4,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(p, stroke * 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
