import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class PrayerTodayMotion {
  static const entrance = Duration(milliseconds: 1040);
  static const readiness = Duration(milliseconds: 720);
  static const expansion = Duration(milliseconds: 420);
  static const stateChange = Duration(milliseconds: 240);
  static const interaction = Duration(milliseconds: 170);
  static const countdownTick = Duration(milliseconds: 850);
  static const pulse = Duration(milliseconds: 2400);

  static const entranceCurve = Curves.easeOutCubic;
  static const stateCurve = Curves.easeInOutCubic;

  static double phase(
    double value, {
    required double begin,
    required double end,
    Curve curve = entranceCurve,
  }) {
    if (end <= begin) return value >= end ? 1 : 0;
    final normalized =
        ((value - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
    return curve.transform(normalized);
  }
}

class PrayerTodayMotionReveal extends StatelessWidget {
  const PrayerTodayMotionReveal({
    super.key,
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.secondaryAnimation,
    this.secondaryBegin = 0,
    this.secondaryEnd = 1,
    this.distance = 0,
    this.beginScale = 1,
    this.ignorePointerUntilComplete = true,
  });

  final Animation<double> animation;
  final Animation<double>? secondaryAnimation;
  final double begin;
  final double end;
  final double secondaryBegin;
  final double secondaryEnd;
  final double distance;
  final double beginScale;
  final bool ignorePointerUntilComplete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    Widget reveal(double primaryValue, double secondaryValue) {
      final primary = PrayerTodayMotion.phase(
        primaryValue,
        begin: begin,
        end: end,
      );
      final secondary = secondaryAnimation == null
          ? 1.0
          : PrayerTodayMotion.phase(
              secondaryValue,
              begin: secondaryBegin,
              end: secondaryEnd,
            );
      final value = math.min(primary, secondary);
      final visible = value >= 0.52;
      final scale = beginScale + (1 - beginScale) * value;

      return IgnorePointer(
        ignoring: ignorePointerUntilComplete && value < 0.98,
        child: ExcludeSemantics(
          excluding: !visible,
          child: Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * distance),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final secondary = secondaryAnimation;
        if (secondary == null) return reveal(animation.value, 1);
        return AnimatedBuilder(
          animation: secondary,
          builder: (context, _) => reveal(animation.value, secondary.value),
        );
      },
    );
  }
}
