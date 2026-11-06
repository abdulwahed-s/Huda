import 'package:flutter/widgets.dart';

/// "It's here": when the reader opens at an ayah found by search, that
/// ayah lights, dims, lights again and fades, about two seconds, once. The
/// scrolling reader tints the ayah's block; the Mushaf tints the ayah's
/// lines on the page image. Both read the level (0–1) from [drive].
///
/// Under reduce motion the ayah is lit steadily for the same time, then
/// cleared: no blinking.
abstract final class QuranAyahFlash {
  static const Duration duration = Duration(milliseconds: 2000);

  /// Lit, dimmed, lit and held, faded.
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

  /// Reduce motion: lit throughout the run, dark at rest on either end.
  static final Animatable<double> _steady = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 98),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
  ]);

  /// The level over [controller]'s run (`duration` long, 0 → 1).
  static Animation<double> drive(
    BuildContext context,
    AnimationController controller,
  ) => controller.drive(
    MediaQuery.disableAnimationsOf(context) ? _steady : _pulse,
  );

  /// A controller for [duration]. Both ends read level 0, so a controller
  /// at rest or finished leaves the ayah as it was.
  static AnimationController controller(TickerProvider vsync) =>
      AnimationController(vsync: vsync, duration: duration);
}
