import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_haptics_setting.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:vibration/vibration.dart';

/// Shared motion, built once so features don't write their own controllers
/// for these jobs. Rules in `design/LANGUAGE.md`, "Motion": every piece
/// uses the motion tokens and goes instant under reduce motion.

// Confirm: haptics ---------------------------------------------------------------

/// The only way features vibrate. Phones and tablets only; a feature's own
/// vibration setting is passed as [enabled]. Reduce motion doesn't silence
/// haptics.
abstract final class HudaHaptics {
  /// Whether this device plays haptics at all (phones and tablets): where
  /// Settings offers the app's "Haptic feedback" switch.
  static bool supported(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => true,
        _ => false,
      };

  /// Whether Huda plays haptics here and now: a supported device with the
  /// app's "Haptic feedback" switch on. Show a feature's own vibration
  /// setting (Tasbih's Vibrate) only where it does something.
  static bool available(BuildContext context) => _touch(context);

  // The app's switch silences every level (changed in `settings`).
  static bool _touch(BuildContext context) =>
      HudaHapticsSetting.enabled && supported(context);

  /// Ticks: each count, a picker step.
  static void selection(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.selectionClick());
  }

  /// Confirmations: saved, shared, toggled something that matters.
  static void light(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.lightImpact());
  }

  /// Milestones: 33, qiblah alignment, a completed khatma.
  static void medium(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.mediumImpact());
  }

  /// A counter's tick that is felt without looking (Tasbih, with its
  /// Vibrate setting on): a short 50 ms buzz, firmer than [selection] and
  /// independent of the system's touch-feedback setting. Falls back to
  /// [selection] where the device has no vibrator. Added by `tasbih`.
  static void count(BuildContext context, {bool enabled = true}) {
    if (!enabled || !_touch(context)) return;
    unawaited(() async {
      final vibrator = _hasVibrator ??= await Vibration.hasVibrator();
      if (vibrator) {
        await Vibration.vibrate(duration: 50);
      } else {
        await HapticFeedback.selectionClick();
      }
    }());
  }

  static bool? _hasVibrator;
}

// Confirm: press-in --------------------------------------------------------------

/// A slight press-in (scale 0.98) while a pointer is down, on top of the
/// ink. Built into `HudaCard`; use it for large buttons and tiles.
class HudaPressable extends StatefulWidget {
  const HudaPressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<HudaPressable> createState() => _HudaPressableState();
}

class _HudaPressableState extends State<HudaPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    const motion = HudaMotion();
    final duration = motion.of(context, motion.short);
    final tint = Theme.of(context).colorScheme.primary;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: duration,
        curve: motion.standard,
        // A tinted highlight from the moment of touch (ink in a scroll
        // view waits for the tap timeout).
        child: AnimatedContainer(
          duration: duration,
          curve: motion.standard,
          foregroundDecoration: BoxDecoration(
            color: tint.withValues(alpha: _down ? 0.1 : 0),
            borderRadius: const HudaRadii().card,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Reveal ---------------------------------------------------------------------------

/// Marks a screen whose first screenful reveals once: items in a
/// [HudaReveal] built while the scope is fresh rise and fade in, staggered
/// 30 ms apart (up to 6). Items built later (scrolling, refresh) appear
/// as they are. Put one at the top of a screen, below its route.
class HudaRevealScope extends StatefulWidget {
  const HudaRevealScope({super.key, required this.child});

  final Widget child;

  /// How long after the screen appears items still count as its first
  /// screenful.
  static const window = Duration(milliseconds: 500);

  @override
  State<HudaRevealScope> createState() => _HudaRevealScopeState();
}

class _HudaRevealScopeState extends State<HudaRevealScope> {
  bool _fresh = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(HudaRevealScope.window, () => _fresh = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RevealScope(state: this, child: widget.child);
}

class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.state, required super.child});

  final _HudaRevealScopeState state;

  @override
  bool updateShouldNotify(_RevealScope oldWidget) => false;
}

/// One item of a screen's first screenful. [index] staggers it; items past
/// the sixth, items built after the scope's window, and everything under
/// reduce motion appear without motion.
class HudaReveal extends StatefulWidget {
  const HudaReveal({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  static const _stagger = Duration(milliseconds: 30);
  static const _maxStaggered = 6;

  @override
  State<HudaReveal> createState() => _HudaRevealState();
}

class _HudaRevealState extends State<HudaReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final scope = context.getInheritedWidgetOfExactType<_RevealScope>()?.state;
    final motion = const HudaMotion();
    final animate =
        scope != null &&
        scope._fresh &&
        !MediaQuery.disableAnimationsOf(context);
    if (!animate) return;
    // Items past the sixth arrive with the sixth, never before the first.
    final delay = HudaReveal._stagger * _slot;
    _controller
      ..duration = motion.medium + delay
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _slot => math.min(widget.index, HudaReveal._maxStaggered - 1);

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration?.inMicroseconds ?? 1;
    final delay = (HudaReveal._stagger * _slot).inMicroseconds;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        math.min(0.9, delay / math.max(1, total)),
        1,
        curve: const HudaMotion().standard,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

// Reveal: state changes --------------------------------------------------------

/// Cross-fades between states (loading, empty, error, offline, content)
/// when [stateKey] changes, and animates the size change.
class HudaStateSwitcher extends StatelessWidget {
  const HudaStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.sequential = false,
  });

  /// Changes when the state changes (the state's type or an enum value).
  final Object stateKey;
  final Widget child;
  final AlignmentGeometry alignment;

  /// Fades the old child out before the new one fades in, instead of
  /// cross-fading, so text (Arabic above all) never sits on top of text.
  final bool sequential;

  @override
  Widget build(BuildContext context) {
    final motion = const HudaMotion();
    final duration = motion.of(context, motion.medium);
    // Reduce motion: swap instantly. A zero-length AnimatedSize finishes
    // inside its own layout, which Flutter rejects.
    if (duration == Duration.zero) {
      return KeyedSubtree(key: ValueKey(stateKey), child: child);
    }
    return AnimatedSize(
      duration: duration,
      curve: motion.standard,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
        // Sequential: the old child is gone by half time (it runs in
        // reverse), the new one fades in over the second half.
        switchInCurve: sequential
            ? Interval(0.5, 1, curve: motion.standard)
            : motion.standard,
        switchOutCurve: sequential
            ? Interval(0.5, 1, curve: motion.standard)
            : motion.standard,
        layoutBuilder: (current, previous) =>
            Stack(alignment: alignment, children: [...previous, ?current]),
        child: KeyedSubtree(key: ValueKey(stateKey), child: child),
      ),
    );
  }
}

/// [HudaStateSwitcher] for slivers (a state below a landing header). Slivers
/// can't overlap, so the old state (a skeleton) dims to half, the new one
/// takes its place and brightens from half: the page is never blank.
class SliverHudaStateSwitcher extends StatefulWidget {
  const SliverHudaStateSwitcher({
    super.key,
    required this.stateKey,
    required this.sliver,
  });

  final Object stateKey;
  final Widget sliver;

  @override
  State<SliverHudaStateSwitcher> createState() =>
      _SliverHudaStateSwitcherState();
}

class _SliverHudaStateSwitcherState extends State<SliverHudaStateSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  late Widget _shown = widget.sliver;
  int _run = 0;

  @override
  void didUpdateWidget(SliverHudaStateSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stateKey == widget.stateKey) {
      if (!_controller.isAnimating) _shown = widget.sliver;
      return;
    }
    const motion = HudaMotion();
    final half = motion.of(context, motion.medium) ~/ 2;
    if (half == Duration.zero) {
      _shown = widget.sliver;
      return;
    }
    final run = ++_run;
    _controller.duration = half;
    _controller.animateTo(0.5).then((_) {
      if (!mounted || run != _run) return;
      setState(() => _shown = widget.sliver);
      _controller.animateTo(1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SliverFadeTransition(
    opacity: CurvedAnimation(
      parent: _controller,
      curve: const HudaMotion().standard,
    ),
    sliver: _shown,
  );
}

// Confirm: number roll ---------------------------------------------------------

/// A number that rolls digit by digit when it changes, with tabular
/// figures, so counters, countdowns and totals don't jump. Only the digits
/// that change move: up when the value grows, down when it shrinks.
/// [format] turns the value into text (locale digits, grouping).
class HudaNumberRoll extends StatefulWidget {
  const HudaNumberRoll({
    super.key,
    required this.value,
    this.style,
    this.format,
    this.semanticsLabel,
  });

  final int value;
  final TextStyle? style;
  final String Function(int value)? format;

  /// Read out instead of the digits; defaults to the formatted value.
  final String? semanticsLabel;

  @override
  State<HudaNumberRoll> createState() => _HudaNumberRollState();
}

class _HudaNumberRollState extends State<HudaNumberRoll> {
  int _direction = 1;

  @override
  void didUpdateWidget(HudaNumberRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _direction = widget.value >= oldWidget.value ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = const HudaMotion();
    final text = widget.format?.call(widget.value) ?? '${widget.value}';
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final chars = text.characters.toList();
    final direction = _direction;
    return Semantics(
      label: widget.semanticsLabel ?? text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Digits read left to right in every script Huda uses.
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < chars.length; i++)
            ClipRect(
              child: AnimatedSwitcher(
                // Keyed from the end, so a digit keeps its place as the
                // number grows (9 → 10 rolls only the new digits).
                key: ValueKey(chars.length - i),
                duration: motion.of(context, motion.short),
                switchInCurve: motion.standard,
                switchOutCurve: motion.standard,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey('${chars[i]}$i');
                  final offset = Tween(
                    begin: Offset(0, (incoming ? 1.0 : -1.0) * direction),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Text(
                  chars[i],
                  key: ValueKey('${chars[i]}$i'),
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Orient: card to page --------------------------------------------------------

/// Opens [builder]'s page growing out of the tapped card: the page is
/// revealed from the card's rectangle and corner radius to the full
/// screen, never scaled (scaling text is expensive to raster). Pass the
/// card's own `BuildContext`.
Future<T?> pushFromCard<T>(BuildContext cardContext, WidgetBuilder builder) {
  final box = cardContext.findRenderObject() as RenderBox?;
  final navigator = Navigator.of(cardContext);
  final themes = InheritedTheme.capture(
    from: cardContext,
    to: navigator.context,
  );
  final origin = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  const motion = HudaMotion();
  final duration = motion.of(cardContext, motion.long);
  return navigator.push<T>(
    PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      // Like sheets and dialogs, the page keeps the opener's themes.
      pageBuilder: (context, _, _) => themes.wrap(builder(context)),
      transitionsBuilder: (context, animation, _, child) {
        if (origin == null) {
          return FadeTransition(opacity: animation, child: child);
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: motion.emphasized,
          reverseCurve: motion.emphasized.flipped,
        );
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            final screen = Offset.zero & MediaQuery.sizeOf(context);
            final t = curved.value;
            final rect = Rect.lerp(origin, screen, t)!;
            final radius = const HudaRadii().lg * (1 - t);
            return ClipRRect(
              clipper: _RectClipper(rect, radius),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.12, 0.45),
                ),
                child: child,
              ),
            );
          },
        );
      },
    ),
  );
}

class _RectClipper extends CustomClipper<RRect> {
  const _RectClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool shouldReclip(_RectClipper old) =>
      old.rect != rect || old.radius != radius;
}

// Continue: size --------------------------------------------------------------

/// Eases its child's size changes (`medium`, `standard`). Under reduce
/// motion it lays the child out directly: a zero-length `AnimatedSize`
/// throws "mutated in its own performLayout" (found by `tasbih`). Added by
/// `settings`.
class HudaAnimatedSize extends StatelessWidget {
  const HudaAnimatedSize({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    const motion = HudaMotion();
    final duration = motion.of(context, motion.medium);
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: motion.standard,
      alignment: alignment,
      child: child,
    );
  }
}

// Reveal: landing art -----------------------------------------------------------

/// Plays a landing header's art in once: [builder] gets an animation from
/// 0 to 1 (eased with [curve]; pass `Curves.linear` when the painter eases
/// its own pieces in turn) to pass to the art's painter, which
/// draws itself partly until it ends. Every landing header's art arrives
/// this way and then rests (`design/LANGUAGE.md`, "Motion"). Under reduce
/// motion it's complete from the first frame. Added by the landing-art
/// pass (books, audiobooks, Quran audio and radio).
class HudaDrawIn extends StatefulWidget {
  const HudaDrawIn({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  final Widget Function(BuildContext context, Animation<double> draw) builder;
  final Duration duration;
  final Curve curve;

  @override
  State<HudaDrawIn> createState() => _HudaDrawInState();
}

class _HudaDrawInState extends State<HudaDrawIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (const HudaMotion().of(context, widget.duration) == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _draw);
}
