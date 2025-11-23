import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'dart:math' as math;

import 'package:huda/l10n/app_localizations.dart';

class AnimatedListeningWaves extends StatefulWidget {
  final bool isListening;
  final VoidCallback? onTap;

  const AnimatedListeningWaves({
    super.key,
    required this.isListening,
    this.onTap,
  });

  @override
  State<AnimatedListeningWaves> createState() => _AnimatedListeningWavesState();
}

class _AnimatedListeningWavesState extends State<AnimatedListeningWaves>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateFadeAnimation();
  }

  @override
  void didUpdateWidget(AnimatedListeningWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening) {
      _updateFadeAnimation();
    }
  }

  void _updateFadeAnimation() {
    if (widget.isListening) {
      _fadeController.repeat(reverse: true);
    } else {
      _fadeController.stop();
      _fadeController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    final accentColor = context.accentColor;

    return Container(
      height: 150.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0F0F0F),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE8EAF0),
                ],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: WavesPainter(
                  animation: _waveController.value,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  isDark: isDark,
                  isListening: widget.isListening,
                ),
                size: Size.infinite,
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: widget.isListening
                        ? (0.6 + (_fadeController.value * 0.4))
                        : 1.0,
                    child: Text(
                      widget.isListening
                          ? AppLocalizations.of(context)!.listening
                          : AppLocalizations.of(context)!.reciteToReveal,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.isListening
                            ? primaryColor
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WavesPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;
  final bool isListening;

  WavesPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    for (int i = 0; i < 4; i++) {
      final phase = (animation + (i * 0.25)) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1.0 - phase) * (isListening ? 0.3 : 0.15);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            (i % 2 == 0 ? primaryColor : accentColor)
                .withValues(alpha: opacity),
            (i % 2 == 0 ? primaryColor : accentColor)
                .withValues(alpha: opacity * 0.5),
          ],
          stops: const [0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (phase * 3.0);

      canvas.drawCircle(center, radius, paint);
    }

    if (isListening) {
      _drawParticles(canvas, center, maxRadius);
    }
  }

  void _drawParticles(Canvas canvas, Offset center, double maxRadius) {
    final particlePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animation * math.pi * 2);
      final distance =
          maxRadius * 0.6 + (math.sin(animation * math.pi * 4) * 10);
      final particlePos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final particleSize = 2.0 + (math.sin(animation * math.pi * 2 + i) * 1.5);
      canvas.drawCircle(particlePos, particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) {
    return animation != oldDelegate.animation ||
        isListening != oldDelegate.isListening;
  }
}
