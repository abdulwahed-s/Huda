import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedFireIcon extends StatefulWidget {
  final int streakCount;
  final double progress;
  final bool isPulsing;
  final double size;

  const AnimatedFireIcon({
    super.key,
    required this.streakCount,
    required this.progress,
    this.isPulsing = false,
    this.size = 24,
  });

  @override
  State<AnimatedFireIcon> createState() => _AnimatedFireIconState();
}

class _AnimatedFireIconState extends State<AnimatedFireIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flickerController;
  late AnimationController _particleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _flickerAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flickerAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flickerController,
      curve: Curves.easeInOut,
    ));

    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_particleController);

    _startContinuousAnimations();
  }

  void _startContinuousAnimations() {
    _flickerController.repeat(reverse: true);

    if (widget.streakCount > 0) {
      _particleController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedFireIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPulsing && !oldWidget.isPulsing) {
      _startPulseAnimation();
    }

    if (widget.streakCount > 0 && oldWidget.streakCount == 0) {
      _particleController.repeat();
    } else if (widget.streakCount == 0 && oldWidget.streakCount > 0) {
      _particleController.stop();
    }
  }

  void _startPulseAnimation() async {
    for (int i = 0; i < 3; i++) {
      await _pulseController.forward();
      await _pulseController.reverse();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Color _getFireColor() {
    if (widget.progress < 1.0) {
      return Colors.white;
    }

    if (widget.streakCount == 0) {
      return Colors.grey[400]!;
    }

    return _getStreakBasedColor(widget.streakCount);
  }

  Color _getStreakBasedColor(int streakCount) {
    if (streakCount == 1) {
      return const Color(0xFFFF6B6B);
    } else if (streakCount <= 2) {
      return const Color(0xFFFF4757);
    } else if (streakCount <= 9) {
      final intensity = (streakCount - 2) / 7;
      return Color.lerp(
        const Color(0xFFFF4757),
        const Color(0xFFFF3742),
        intensity,
      )!;
    } else if (streakCount == 10) {
      return const Color(0xFFFF0000);
    } else if (streakCount <= 20) {
      final intensity = (streakCount - 10) / 10;
      return Color.lerp(
        const Color(0xFFFF0000),
        const Color(0xFF8E44AD),
        intensity,
      )!;
    } else {
      final intensity = math.min((streakCount - 20) / 10, 1.0);
      return Color.lerp(
        const Color(0xFF8E44AD),
        const Color(0xFF3742FA),
        intensity,
      )!;
    }
  }

  double _getFireSize() {
    final baseSize = widget.size;
    final growthFactor = 1.0 + (widget.streakCount * 0.1);
    return baseSize * math.min(growthFactor, 2.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flickerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _flickerController,
        _particleController,
      ]),
      builder: (context, child) {
        final fireColor = _getFireColor();
        final fireSize = _getFireSize();

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.streakCount > 0)
              ...List.generate(6, (index) {
                final angle =
                    (index * math.pi * 2 / 6) + _rotationAnimation.value;
                final radius = fireSize * 0.8;
                final x = math.cos(angle) * radius;
                final y = math.sin(angle) * radius;

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fireColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: fireColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            Transform.scale(
              scale: _pulseAnimation.value * _flickerAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: fireColor.withValues(alpha: 0.5),
                      blurRadius: fireSize * 0.3,
                      spreadRadius: fireSize * 0.1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: fireColor,
                  size: fireSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
