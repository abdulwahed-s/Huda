import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class CalibrationBanner extends StatefulWidget {
  final bool show;
  final bool isDark;

  const CalibrationBanner({
    super.key,
    required this.show,
    required this.isDark,
  });

  @override
  State<CalibrationBanner> createState() => _CalibrationBannerState();
}

class _CalibrationBannerState extends State<CalibrationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    if (widget.show) _controller.repeat();
  }

  @override
  void didUpdateWidget(CalibrationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.show && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
    final surface = isDark ? const Color(0xFF1C1A14) : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: !widget.show
          ? const SizedBox(width: double.infinity)
          : _EntranceTransition(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                          accent.withValues(alpha: isDark ? 0.10 : 0.07),
                          surface),
                      surface.withValues(alpha: isDark ? 0.92 : 0.96),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.18),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _IllustrationBadge(
                      controller: _controller,
                      accent: accent,
                      isDark: isDark,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.calibrateCompass,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: isDark
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade900,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            AppLocalizations.of(context)!
                                .calibrateCompassInstruction,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              color:
                                  isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.66),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EntranceTransition extends StatelessWidget {
  final Widget child;

  const _EntranceTransition({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _IllustrationBadge extends StatelessWidget {
  final AnimationController controller;
  final Color accent;
  final bool isDark;

  const _IllustrationBadge({
    required this.controller,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [
            accent.withValues(alpha: isDark ? 0.28 : 0.20),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => CustomPaint(
            size: Size(56.w, 56.w),
            painter: _FigureEightPainter(
              progress: controller.value,
              accent: accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _FigureEightPainter({required this.progress, required this.accent});

  Offset _pointAt(double t, double cx, double cy, double a, double b) {
    return Offset(
      cx + a * math.cos(t),
      cy + b * math.sin(t) * math.cos(t),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final a = size.width * 0.32;
    final b = size.height * 0.30;
    final stroke = size.shortestSide * 0.055;

    final guide = Path();
    const guideSteps = 80;
    for (var i = 0; i <= guideSteps; i++) {
      final t = (i / guideSteps) * 2 * math.pi;
      final p = _pointAt(t, cx, cy, a, b);
      i == 0 ? guide.moveTo(p.dx, p.dy) : guide.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      guide,
      Paint()
        ..color = accent.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    final headT = progress * 2 * math.pi;
    const trailSpan = 0.42;
    const trailSteps = 28;
    for (var i = 0; i < trailSteps; i++) {
      final f0 = i / trailSteps;
      final f1 = (i + 1) / trailSteps;
      final t0 = headT - trailSpan * 2 * math.pi * (1 - f0);
      final t1 = headT - trailSpan * 2 * math.pi * (1 - f1);
      final p0 = _pointAt(t0, cx, cy, a, b);
      final p1 = _pointAt(t1, cx, cy, a, b);
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = accent.withValues(alpha: f1 * f1)
          ..strokeWidth = stroke * (0.6 + 0.6 * f1)
          ..strokeCap = StrokeCap.round,
      );
    }

    final head = _pointAt(headT, cx, cy, a, b);
    canvas.drawCircle(
      head,
      stroke * 2.4,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(head, stroke * 1.15, Paint()..color = accent);
    canvas.drawCircle(
      head,
      stroke * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) =>
      old.progress != progress || old.accent != accent;
}
