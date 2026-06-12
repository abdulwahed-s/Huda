import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';

class AddButton extends StatefulWidget {
  const AddButton({super.key});

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> with TickerProviderStateMixin {
  late final AnimationController _glowController;

  late final AnimationController _pressController;
  late final Animation<double> _press;

  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _press = CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeOutBack,
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pressController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    context.read<TasbihCubit>().increment();
    _rippleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    final primaryDark = context.primaryDarkColor;
    final accent = context.accentColor;
    final primaryLight = context.primaryLightColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final size = (maxSize.isFinite && maxSize > 0 ? maxSize : 240.0)
            .clamp(120.0, 440.0)
            .toDouble();
        final buttonSize = size * 0.78;
        final iconSize = buttonSize * 0.40;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _pressController.forward(),
              onTapUp: (_) => _pressController.reverse(),
              onTapCancel: () => _pressController.reverse(),
              onTap: _handleTap,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _glowController,
                  _press,
                  _rippleController,
                ]),
                builder: (context, _) {
                  final glow =
                      Curves.easeInOut.transform(_glowController.value);
                  final scale = 1 - _press.value * 0.09;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: buttonSize * (1.08 + glow * 0.10),
                        height: buttonSize * (1.08 + glow * 0.10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primary.withValues(alpha: 0.16 + glow * 0.10),
                              accent.withValues(alpha: 0.0),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                      if (_rippleController.value > 0 &&
                          _rippleController.value < 1)
                        CustomPaint(
                          size: Size.square(size),
                          painter: _TapRipplePainter(
                            progress: _rippleController.value,
                            innerRadius: buttonSize / 2,
                            color: primaryLight,
                          ),
                        ),
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.6, 1.0],
                              colors: [
                                primaryDark,
                                primary,
                                accent.withValues(alpha: 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: -2,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: accent.withValues(alpha: 0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: const Alignment(-0.35, -0.45),
                                      radius: 0.95,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 0.65],
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: iconSize,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color:
                                          Colors.black.withValues(alpha: 0.25),
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TapRipplePainter extends CustomPainter {
  final double progress;
  final double innerRadius;
  final Color color;

  _TapRipplePainter({
    required this.progress,
    required this.innerRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 2; i++) {
      final t = (progress - i * 0.22).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      final eased = Curves.easeOut.transform(t);
      final radius = innerRadius + (maxRadius - innerRadius) * eased;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 + 2.5 * (1 - t)
        ..color = color.withValues(alpha: (1 - t) * 0.45);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TapRipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
