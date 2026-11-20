import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_haptics_setting.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:vibration/vibration.dart';



abstract final class HudaHaptics {
  static bool supported(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => true,
        _ => false,
      };

  static bool available(BuildContext context) => _touch(context);

  static bool _touch(BuildContext context) =>
      HudaHapticsSetting.enabled && supported(context);

  static void selection(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.selectionClick());
  }

  static void light(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.lightImpact());
  }

  static void medium(BuildContext context, {bool enabled = true}) {
    if (enabled && _touch(context)) unawaited(HapticFeedback.mediumImpact());
  }

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


class HudaRevealScope extends StatefulWidget {
  const HudaRevealScope({super.key, required this.child});

  final Widget child;

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


class HudaStateSwitcher extends StatelessWidget {
  const HudaStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.sequential = false,
  });

  final Object stateKey;
  final Widget child;
  final AlignmentGeometry alignment;

  final bool sequential;

  @override
  Widget build(BuildContext context) {
    final motion = const HudaMotion();
    final duration = motion.of(context, motion.medium);
    if (duration == Duration.zero) {
      return KeyedSubtree(key: ValueKey(stateKey), child: child);
    }
    return AnimatedSize(
      duration: duration,
      curve: motion.standard,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
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
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < chars.length; i++)
            ClipRect(
              child: AnimatedSwitcher(
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
