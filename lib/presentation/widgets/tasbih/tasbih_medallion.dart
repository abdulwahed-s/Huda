import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_identity.dart';

const tasbihCounterKey = ValueKey('tasbih-counter');

class TasbihMedallion extends StatefulWidget {
  const TasbihMedallion({
    super.key,
    required this.count,
    required this.dhikrIndex,
    required this.diameter,
    required this.onCount,
  });

  final int count;
  final int dhikrIndex;
  final double diameter;
  final VoidCallback onCount;

  @override
  State<TasbihMedallion> createState() => _TasbihMedallionState();
}

class _TasbihMedallionState extends State<TasbihMedallion>
    with TickerProviderStateMixin {
  late final AnimationController _advance = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _pulse = AnimationController(vsync: this);

  late final AnimationController _step = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  int _stepBead = -1;
  bool _stepBack = false;
  late double _from = tasbihBeadsFilled(widget.count).toDouble();
  late double _to = _from;
  int _pulses = 1;
  bool _down = false;

  @override
  void didUpdateWidget(TasbihMedallion old) {
    super.didUpdateWidget(old);
    if (old.count == widget.count && old.dhikrIndex == widget.dhikrIndex) {
      return;
    }
    final motion = context.tokens.motion;
    final next = tasbihBeadsFilled(widget.count).toDouble();
    final step = widget.count - old.count;
    final switched = old.dhikrIndex != widget.dhikrIndex;
    final animate =
        (switched || step.abs() == 1) &&
        motion.of(context, motion.medium) > Duration.zero;
    if (!animate) {
      _from = _to = next;
      _advance.value = 1;
      return;
    }
    final wrapped = !switched && (step > 0 ? next < _to : next > _to);
    if (wrapped && step < 0) {
      _from = _to = next;
      _advance.value = 1;
    } else {
      _from = wrapped ? 0 : _shown;
      _to = next;
      _advance
        ..duration = motion.medium
        ..forward(from: 0);
    }
    if (!switched && !(wrapped && step < 0)) {
      _stepBack = step < 0;
      _stepBead = (_stepBack ? tasbihBeadsFilled(old.count) : next.toInt()) - 1;
      _step.forward(from: 0);
    }
    if (!switched && step > 0 && widget.count % tasbihBeads == 0) {
      _pulses = widget.count % (tasbihBeads * 3) == 0 ? 2 : 1;
      _pulse
        ..duration = Duration(milliseconds: _pulses == 2 ? 900 : 550)
        ..forward(from: 0);
    }
  }

  double get _shown => lerpDouble(
    _from,
    _to,
    context.tokens.motion.standard.transform(_advance.value),
  )!;

  @override
  void dispose() {
    _advance.dispose();
    _pulse.dispose();
    _step.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final diameter = widget.diameter;
    final count = widget.count;
    final style = OrnamentStyle.of(context, onChrome: true);
    final numeral = context.type.counter.copyWith(
      fontSize: diameter < 240 ? 52 : 72,
      color: scheme.onSurface,
    );

    return Semantics(
      button: true,
      label: '$count',
      hint: tasbihUsesPointer(context)
          ? l10n.tasbihClickToCount
          : l10n.tasbihTapToCount,
      excludeSemantics: true,
      onTap: widget.onCount,
      child: GestureDetector(
        key: tasbihCounterKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onCount,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: tokens.motion.of(context, tokens.motion.short),
          curve: tokens.motion.standard,
          child: SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_advance, _pulse, _step]),
                      builder: (context, _) => CustomPaint(
                        painter: TasbihBeadRingPainter(
                          style: style,
                          empty: tokens.gilt.withValues(alpha: 0.22),
                          filled: _shown,
                          clockwise: !rtl,
                          pulse: _pulse.value,
                          pulses: _pulses,
                          stepBead: _stepBead,
                          step: _step.value,
                          stepBack: _stepBack,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(diameter * 0.2),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: HudaStateSwitcher(
                      stateKey: widget.dhikrIndex,
                      alignment: Alignment.center,
                      sequential: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: HudaNumberRoll(value: count, style: numeral),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
