import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class QuranJourneyMotion {
  static const entrance = Duration(milliseconds: 980);
  static const paletteSettling = Duration(milliseconds: 240);
  static const stateChange = Duration(milliseconds: 320);
  static const expansion = Duration(milliseconds: 390);
  static const interaction = Duration(milliseconds: 150);

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

class QuranJourneyEntranceReveal extends StatelessWidget {
  const QuranJourneyEntranceReveal({
    super.key,
    required this.begin,
    required this.end,
    required this.child,
    this.animation,
    this.progress = 1,
    this.distance = 6,
    this.axis = Axis.vertical,
    this.directional = false,
    this.beginScale = 0.992,
    this.startOpacity = 0.72,
    this.alignment = Alignment.topCenter,
  });

  final Animation<double>? animation;
  final double progress;
  final double begin;
  final double end;
  final double distance;
  final Axis axis;
  final bool directional;
  final double beginScale;
  final double startOpacity;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget reveal(double rawValue) {
      final value = reduceMotion
          ? 1.0
          : QuranJourneyMotion.phase(
              rawValue,
              begin: begin,
              end: end,
            );
      final textDirection = Directionality.of(context);
      final readingSign = textDirection == TextDirection.rtl ? -1.0 : 1.0;
      final travel = (1 - value) * distance;
      final offset = axis == Axis.horizontal
          ? Offset(directional ? travel * readingSign : travel, 0)
          : Offset(0, travel);
      final scale = beginScale + (1 - beginScale) * value;
      final opacity = startOpacity + (1 - startOpacity) * value;

      return ClipRect(
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              alignment: alignment,
              child: child,
            ),
          ),
        ),
      );
    }

    final entrance = animation;
    if (entrance == null || reduceMotion) return reveal(progress);
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, _) => reveal(entrance.value),
    );
  }
}

class QuranJourneyDataTransition extends StatelessWidget {
  const QuranJourneyDataTransition({
    super.key,
    required this.transitionKey,
    required this.child,
    this.axis = Axis.horizontal,
    this.alignment = AlignmentDirectional.centerStart,
    this.excludeSemantics = false,
  });

  final Object transitionKey;
  final Widget child;
  final Axis axis;
  final AlignmentGeometry alignment;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final duration =
        reduceMotion ? Duration.zero : QuranJourneyMotion.stateChange;
    final visual = excludeSemantics ? ExcludeSemantics(child: child) : child;
    final keyedVisual = KeyedSubtree(
      key: ValueKey<Object>(transitionKey),
      child: visual,
    );
    if (reduceMotion) return keyedVisual;

    return AnimatedSize(
      duration: duration,
      curve: QuranJourneyMotion.stateCurve,
      alignment: alignment,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: QuranJourneyMotion.entranceCurve,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: alignment,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final begin = axis == Axis.horizontal
                ? Offset(0.035 * direction, 0)
                : const Offset(0, 0.12);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: begin, end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            );
          },
          child: keyedVisual,
        ),
      ),
    );
  }
}

class QuranJourneyPressTransform extends StatelessWidget {
  const QuranJourneyPressTransform({
    super.key,
    required this.pressed,
    required this.child,
    this.alignment = Alignment.center,
  });

  final bool pressed;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : QuranJourneyMotion.interaction;
    return AnimatedSlide(
      offset: pressed ? const Offset(0, 0.012) : Offset.zero,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: pressed ? 0.988 : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class QuranJourneyDirectionalShift extends StatelessWidget {
  const QuranJourneyDirectionalShift({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return AnimatedSlide(
      offset: active ? Offset(0.08 * direction, 0) : Offset.zero,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : QuranJourneyMotion.interaction,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

double quranJourneyProgressValue({
  required double from,
  required double to,
  required double localProgress,
  required double entranceProgress,
}) {
  final local = from + (to - from) * localProgress;
  return math.max(0, math.min(1, local * entranceProgress));
}
