import 'package:flutter/widgets.dart';

abstract final class QuranAyahFlash {
  static const Duration duration = Duration(milliseconds: 2000);

  static final Animatable<double> _pulse = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 250,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.2,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 350,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.2,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 300,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 500),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 600,
    ),
  ]);

  static final Animatable<double> _steady = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 98),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
  ]);

  static Animation<double> drive(
    BuildContext context,
    AnimationController controller,
  ) => controller.drive(
    MediaQuery.disableAnimationsOf(context) ? _steady : _pulse,
  );

  static AnimationController controller(TickerProvider vsync) =>
      AnimationController(vsync: vsync, duration: duration);
}
