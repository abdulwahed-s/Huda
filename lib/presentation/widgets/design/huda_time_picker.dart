import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:intl/intl.dart' as intl;

/// Huda's time picker, on the shared sheet presenter: a bottom sheet on
/// phones, a dialog from medium width, fold-aware. Returns the chosen time,
/// or null when dismissed.
///
/// [title] says what the time is for ("Sahur Alarm", "Start time"); it
/// defaults to the platform's "Select time". [daily] is for times that come
/// back every day (reminders, alarms): the sheet then says when the chosen
/// time next comes ("Tomorrow at 4:00 AM · in 7 h 12 min"), read from
/// [clock].
Future<TimeOfDay?> showHudaTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? title,
  bool daily = false,
  DateTime Function() clock = DateTime.now,
}) {
  return showHudaSheet<TimeOfDay>(
    context: context,
    title: title ?? MaterialLocalizations.of(context).timePickerDialHelpText,
    maxDialogWidth: 420,
    builder: (context) =>
        _TimePickerSheet(initialTime: initialTime, clock: daily ? clock : null),
  );
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initialTime, this.clock});

  final TimeOfDay initialTime;

  /// Set for daily times: the hint says when the time next comes.
  final DateTime Function()? clock;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late TimeOfDay _time = widget.initialTime;

  void _done() => Navigator.of(context).pop(_time);

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final short = MediaQuery.sizeOf(context).height < 560;
    final picker = HudaTimePicker(
      initialTime: widget.initialTime,
      onChanged: (time) => setState(() => _time = time),
      // Keyboards type straight into the hour; touch shows no ring.
      autofocus: !HudaHaptics.available(context),
      visibleItems: short ? 3 : 5,
    );
    final done = FilledButton(
      key: const ValueKey('huda-time-picker-done'),
      onPressed: _done,
      child: Text(AppLocalizations.of(context)!.done),
    );
    final clock = widget.clock;
    final hint = clock == null ? null : HudaNextTime(time: _time, clock: clock);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _done,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _done,
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HudaDayPath(time: _time, height: short ? 36 : 56),
          SizedBox(height: short ? space.xs : space.md),
          // Short windows (phone landscape): Done beside the wheels, so it
          // stays on screen without scrolling.
          if (short)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: picker),
                SizedBox(width: space.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hint != null) ...[hint, SizedBox(height: space.sm)],
                      done,
                    ],
                  ),
                ),
              ],
            )
          else ...[
            picker,
            SizedBox(height: space.xl),
            // When it next comes, beside Done: read just before confirming.
            Row(
              children: [
                Expanded(child: hint ?? const SizedBox.shrink()),
                SizedBox(width: space.md),
                done,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Which of the picker's wheels.
enum _Part { hour, minute, period }

/// The picker itself, to embed where a time is chosen inline: an hour and
/// a minute wheel, and AM/PM when the locale counts in twelve hours, behind
/// one lit band (the Lantern window) that holds the chosen time.
///
/// Drag or flick a wheel, tap a neighbour, scroll with a mouse, or use the
/// keyboard: arrows step, digits type (07 then 30), A and P pick the half
/// of the day. Hours roll on past 12 into the other half of the day, as on
/// a clock. Each step ticks (`selection`). Screen readers get each wheel as
/// an adjustable value.
class HudaTimePicker extends StatefulWidget {
  const HudaTimePicker({
    super.key,
    required this.initialTime,
    required this.onChanged,
    this.autofocus = false,
    this.visibleItems = 5,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;
  final bool autofocus;

  /// Rows shown per wheel: 5, or 3 where height is short.
  final int visibleItems;

  @override
  State<HudaTimePicker> createState() => _HudaTimePickerState();
}

class _HudaTimePickerState extends State<HudaTimePicker> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;
  late final _hours = FixedExtentScrollController(initialItem: _hour);
  late final _minutes = FixedExtentScrollController(initialItem: _minute);
  late final _period = FixedExtentScrollController(
    initialItem: _hour >= 12 ? 1 : 0,
  );
  final _focus = {
    for (final part in _Part.values) part: FocusNode(debugLabel: part.name),
  };
  _Part? _highlighted;

  /// Set while the picker moves a wheel itself, so that move neither ticks
  /// nor pushes back.
  bool _quiet = false;
  bool _periodMoving = false;

  String _typed = '';
  _Part? _typedPart;
  Timer? _typedTimer;

  @override
  void dispose() {
    _typedTimer?.cancel();
    _hours.dispose();
    _minutes.dispose();
    _period.dispose();
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _twelveHour {
    final format = _format(context);
    return format == TimeOfDayFormat.h_colon_mm_space_a ||
        format == TimeOfDayFormat.a_space_h_colon_mm;
  }

  static TimeOfDayFormat _format(BuildContext context) =>
      MaterialLocalizations.of(context).timeOfDayFormat(
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  FixedExtentScrollController _controller(_Part part) => switch (part) {
    _Part.hour => _hours,
    _Part.minute => _minutes,
    _Part.period => _period,
  };

  Duration get _step =>
      context.tokens.motion.of(context, context.tokens.motion.short);

  void _changed() {
    setState(() {});
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  void _tick() {
    if (!_quiet) HudaHaptics.selection(context);
  }

  void _onHour(int item) {
    final hour = item % 24;
    if (hour == _hour) return;
    _hour = hour;
    _tick();
    _syncPeriod();
    _changed();
  }

  void _onMinute(int item) {
    final minute = item % 60;
    if (minute == _minute) return;
    _minute = minute;
    _tick();
    _changed();
  }

  void _onPeriod(int item) {
    if (_periodMoving) return;
    final pm = item == 1;
    if ((_hour >= 12) == pm) return;
    _tick();
    // The hour wheel reads the same twelve hours later: jump, unseen.
    _quiet = true;
    _hours.jumpToItem(_hours.selectedItem + (pm ? 12 : -12));
    _quiet = false;
  }

  /// Rolling the hours past 12 turns the day's half over, as on a clock.
  void _syncPeriod() {
    if (!_twelveHour || !_period.hasClients || _periodMoving) return;
    final target = _hour >= 12 ? 1 : 0;
    if (_period.selectedItem == target) return;
    _periodMoving = true;
    _moveTo(_period, target).whenComplete(() {
      _periodMoving = false;
      if (mounted) _syncPeriod();
    });
  }

  Future<void> _moveTo(FixedExtentScrollController controller, int item) {
    if (!controller.hasClients) return Future.value();
    final duration = _step;
    if (duration == Duration.zero) {
      controller.jumpToItem(item);
      return Future.value();
    }
    return controller.animateToItem(
      item,
      duration: duration,
      curve: context.tokens.motion.standard,
    );
  }

  void _stepBy(_Part part, int delta) {
    final controller = _controller(part);
    if (!controller.hasClients) return;
    var target = controller.selectedItem + delta;
    if (part == _Part.period) target = target.clamp(0, 1);
    _moveTo(controller, target);
  }

  /// The item nearest [current] that shows [value] on a wheel of [length].
  static int _nearest(int current, int value, int length) {
    var target = current - current % length + value;
    if (target - current > length / 2) target -= length;
    if (current - target > length / 2) target += length;
    return target;
  }

  void _setHour(int hour) =>
      _moveTo(_hours, _nearest(_hours.selectedItem, hour, 24));

  void _setPeriod(bool pm) {
    if (!_twelveHour) return;
    _moveTo(_period, pm ? 1 : 0);
  }

  /// Typed digits: "7" or "07" sets the hour, then the minute takes the
  /// next two.
  void _type(_Part part, int digit) {
    if (part == _Part.period) return;
    if (_typedPart != part) _typed = '';
    _typedPart = part;
    _typedTimer?.cancel();
    _typedTimer = Timer(const Duration(milliseconds: 1500), () => _typed = '');
    final twelve = _twelveHour;
    final max = part == _Part.minute ? 59 : (twelve ? 12 : 23);
    var typed = '$_typed$digit';
    if (int.parse(typed) > max || typed.length > 2) typed = '$digit';
    final value = int.parse(typed);
    _typed = typed;
    if (part == _Part.hour) {
      if (!twelve) {
        _setHour(value);
      } else if (value > 0) {
        _setHour(value % 12 + (_hour >= 12 ? 12 : 0));
      }
    } else {
      _moveTo(_minutes, _nearest(_minutes.selectedItem, value, 60));
    }
    // Done when no further digit could follow.
    if (typed.length == 2 || value * 10 > max) {
      _typed = '';
      final next = part == _Part.hour
          ? _Part.minute
          : (twelve ? _Part.period : null);
      if (next != null) _focus[next]!.requestFocus();
    }
  }

  KeyEventResult _onKey(_Part part, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _stepBy(part, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _stepBy(part, 1);
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char == null || char.isEmpty) return KeyEventResult.ignored;
    final digit = int.tryParse(char);
    if (digit != null) {
      _type(part, digit);
      return KeyEventResult.handled;
    }
    // The first letter of the locale's AM or PM ("a", "p"; "ص", "م").
    final localizations = MaterialLocalizations.of(context);
    final lower = char.toLowerCase();
    bool starts(String label) =>
        label.isNotEmpty && label.toLowerCase().startsWith(lower);
    if (_twelveHour && starts(localizations.anteMeridiemAbbreviation)) {
      _setPeriod(false);
      return KeyEventResult.handled;
    }
    if (_twelveHour && starts(localizations.postMeridiemAbbreviation)) {
      _setPeriod(true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final format = _format(context);
    final twelve = _twelveHour;
    // The numerals clamp at 1.6×, like chrome titles: inside the band they
    // must stay whole.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6);
    final digits = theme.textTheme.displaySmall!.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.1,
    );
    final words = theme.textTheme.titleLarge!;
    final extent = math.max(48.0, scaler.scale(digits.fontSize!) * 1.5);

    String hourLabel(int item) => localizations.formatHour(
      TimeOfDay(hour: item % 24, minute: 0),
      alwaysUse24HourFormat: use24,
    );
    String minuteLabel(int item) =>
        localizations.formatMinute(TimeOfDay(hour: 0, minute: item % 60));
    String periodLabel(int item) => item == 0
        ? localizations.anteMeridiemAbbreviation
        : localizations.postMeridiemAbbreviation;

    double widest(Iterable<String> labels, TextStyle style) {
      var width = 0.0;
      for (final label in labels) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        width = math.max(width, painter.width);
        painter.dispose();
      }
      return width;
    }

    final pad = tokens.space.md;
    final hourWidth = widest(List.generate(24, hourLabel), digits) + pad * 2;
    final minuteWidth = widest(['00', minuteLabel(48)], digits) + pad * 2;
    final periodWidth = twelve
        ? widest([periodLabel(0), periodLabel(1)], words) + pad * 2
        : 0.0;
    final separator = switch (format) {
      TimeOfDayFormat.HH_dot_mm => '.',
      TimeOfDayFormat.frenchCanadian => 'h',
      _ => ':',
    };

    Widget wheel(
      _Part part, {
      required double width,
      required String Function(int) label,
      required TextStyle style,
      required ValueChanged<int> onChanged,
      required String semanticsLabel,
      int? count,
    }) {
      final controller = _controller(part);
      final current = switch (part) {
        _Part.hour => _hour,
        _Part.minute => _minute,
        _Part.period => _hour >= 12 ? 1 : 0,
      };
      return _Wheel(
        key: ValueKey('huda-time-picker-${part.name}'),
        controller: controller,
        focusNode: _focus[part]!,
        autofocus: widget.autofocus && part == _Part.hour,
        width: width,
        extent: extent,
        visible: widget.visibleItems,
        count: count,
        label: label,
        style: style,
        scaler: scaler,
        highlighted: _highlighted == part,
        onHighlight: (on) => setState(
          () => _highlighted = on
              ? part
              : (_highlighted == part ? null : _highlighted),
        ),
        onSelected: onChanged,
        onKey: (event) => _onKey(part, event),
        onStep: (delta) => _stepBy(part, delta),
        onTapItem: (item) => _moveTo(controller, item),
        semanticsLabel: semanticsLabel,
        semanticsValue: label(current),
        increasedValue: part == _Part.period
            ? (current == 0 ? label(1) : null)
            : label(current + 1),
        decreasedValue: part == _Part.period
            ? (current == 1 ? label(0) : null)
            : label(current - 1),
      );
    }

    final hourMinute = Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        wheel(
          _Part.hour,
          width: hourWidth,
          label: hourLabel,
          style: digits,
          onChanged: _onHour,
          semanticsLabel: localizations.timePickerHourLabel,
        ),
        ExcludeSemantics(
          child: Text(
            separator,
            textScaler: scaler,
            style: digits.copyWith(color: tokens.onChrome),
          ),
        ),
        wheel(
          _Part.minute,
          width: minuteWidth,
          label: minuteLabel,
          style: digits,
          onChanged: _onMinute,
          semanticsLabel: localizations.timePickerMinuteLabel,
        ),
      ],
    );
    final period = twelve
        ? wheel(
            _Part.period,
            width: periodWidth,
            label: periodLabel,
            style: words,
            onChanged: _onPeriod,
            semanticsLabel:
                '${localizations.anteMeridiemAbbreviation} / '
                '${localizations.postMeridiemAbbreviation}',
            count: 2,
          )
        : null;
    final periodFirst = format == TimeOfDayFormat.a_space_h_colon_mm;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (period != null && periodFirst) period,
        hourMinute,
        if (period != null && !periodFirst) period,
      ],
    );

    // The Lantern window: one lit band across every wheel, carrying the
    // engraving, that holds the chosen time.
    final band = DecoratedBox(
      decoration: ShapeDecoration(
        color: tokens.lit,
        shape: HudaLanternBorder(
          radius: tokens.radius.md,
          engraving: tokens.onChrome.withValues(alpha: 0.24),
        ),
      ),
    );

    final picker = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              height: extent,
              width: double.infinity,
              child: band,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
          child: row,
        ),
      ],
    );

    // Very narrow windows at large text: the whole picker scales down
    // rather than clip.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: picker),
      ),
    );
  }
}

/// One wheel: a looping list of numbers (or AM and PM) that snaps to an
/// item. Items fade with their distance from the band and take the warm
/// text inside it.
class _Wheel extends StatelessWidget {
  const _Wheel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.width,
    required this.extent,
    required this.visible,
    required this.count,
    required this.label,
    required this.style,
    required this.scaler,
    required this.highlighted,
    required this.onHighlight,
    required this.onSelected,
    required this.onKey,
    required this.onStep,
    required this.onTapItem,
    required this.semanticsLabel,
    required this.semanticsValue,
    required this.increasedValue,
    required this.decreasedValue,
  });

  final FixedExtentScrollController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final double width;
  final double extent;
  final int visible;

  /// Null loops forever (hours, minutes); a count stops at the ends.
  final int? count;
  final String Function(int item) label;
  final TextStyle style;
  final TextScaler scaler;
  final bool highlighted;
  final ValueChanged<bool> onHighlight;
  final ValueChanged<int> onSelected;
  final KeyEventResult Function(KeyEvent event) onKey;
  final ValueChanged<int> onStep;
  final ValueChanged<int> onTapItem;
  final String semanticsLabel;
  final String semanticsValue;
  final String? increasedValue;
  final String? decreasedValue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final height = extent * visible;

    Widget? item(BuildContext context, int index) {
      if (count != null && (index < 0 || index >= count!)) return null;
      return _WheelItem(
        controller: controller,
        index: index,
        extent: extent,
        text: label(index),
        style: style,
        scaler: scaler,
        inside: tokens.onChrome,
        outside: scheme.onSurfaceVariant,
        onTap: () => onTapItem(index),
        onStep: onStep,
      );
    }

    final list = ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: extent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.8,
      perspective: 0.002,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: item,
      ),
    );

    // The focused wheel (keyboard only) gets a warm ring inside the band.
    final ring = IgnorePointer(
      child: AnimatedOpacity(
        opacity: highlighted ? 1 : 0,
        duration: tokens.motion.of(context, tokens.motion.short),
        child: Center(
          child: Container(
            height: extent - 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radius.sm),
              border: Border.all(
                color: tokens.onChrome.withValues(alpha: 0.7),
                width: tokens.stroke.fine,
              ),
            ),
          ),
        ),
      ),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => onKey(event),
      child: FocusableActionDetector(
        focusNode: focusNode,
        autofocus: autofocus,
        onShowFocusHighlight: onHighlight,
        mouseCursor: SystemMouseCursors.resizeUpDown,
        child: Semantics(
          label: semanticsLabel,
          value: semanticsValue,
          increasedValue: increasedValue,
          decreasedValue: decreasedValue,
          onIncrease: increasedValue == null ? null : () => onStep(1),
          onDecrease: decreasedValue == null ? null : () => onStep(-1),
          child: ExcludeSemantics(
            child: SizedBox(
              width: width,
              height: height,
              child: ShaderMask(
                // The wheel's ends fade into the page.
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xFF000000),
                    Color(0xFF000000),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.28, 0.72, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Stack(children: [list, ring]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelItem extends StatefulWidget {
  const _WheelItem({
    required this.controller,
    required this.index,
    required this.extent,
    required this.text,
    required this.style,
    required this.scaler,
    required this.inside,
    required this.outside,
    required this.onTap,
    required this.onStep,
  });

  final FixedExtentScrollController controller;
  final int index;
  final double extent;
  final String text;
  final TextStyle style;
  final TextScaler scaler;
  final Color inside;
  final Color outside;
  final VoidCallback onTap;
  final ValueChanged<int> onStep;

  @override
  State<_WheelItem> createState() => _WheelItemState();
}

class _WheelItemState extends State<_WheelItem> {
  /// Small scroll deltas (touchpads) add up to one step.
  double _scrolled = 0;

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // Taken before the wheel's own scrolling, which would stop between
    // items: one notch, one step.
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final dy = (event as PointerScrollEvent).scrollDelta.dy;
      if (dy == 0) return;
      if (_scrolled.sign != dy.sign) _scrolled = 0;
      _scrolled += dy;
      if (_scrolled.abs() >= 20) {
        widget.onStep(_scrolled > 0 ? 1 : -1);
        _scrolled = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final offset = controller.hasClients
                ? controller.offset
                : controller.initialItem * widget.extent;
            final distance = (widget.index - offset / widget.extent).abs();
            // Warm inside the band, the page's text outside, fading out
            // toward the wheel's ends.
            final warmth = ((distance - 0.3) / 0.4).clamp(0.0, 1.0);
            final fade = (1 - (distance - 0.5).clamp(0.0, 2.0) * 0.4);
            final color = Color.lerp(
              widget.inside,
              widget.outside,
              warmth,
            )!.withValues(alpha: fade.clamp(0.2, 1.0));
            return Center(
              child: Text(
                widget.text,
                maxLines: 1,
                textScaler: widget.scaler,
                style: widget.style.copyWith(color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The picker's voice: a day's path over the horizon, with the sun (by
/// day) or a crescent (by night) where the chosen time falls, so 4:00
/// before dawn never reads like 4:00 in the afternoon. It follows the
/// wheels, glides the short way round midnight, and runs with the reading
/// direction. Decorative: the wheels say the time.
class HudaDayPath extends StatefulWidget {
  const HudaDayPath({super.key, required this.time, this.height = 56});

  final TimeOfDay time;
  final double height;

  @override
  State<HudaDayPath> createState() => _HudaDayPathState();
}

class _HudaDayPathState extends State<HudaDayPath> {
  /// Minutes since the first midnight, unwrapped, so the mark glides the
  /// short way across midnight instead of running back across the day.
  late double _target = _minutes(widget.time).toDouble();

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  void didUpdateWidget(HudaDayPath old) {
    super.didUpdateWidget(old);
    if (old.time == widget.time) return;
    final now = _target % 1440;
    var delta = _minutes(widget.time) - now;
    if (delta > 720) delta -= 1440;
    if (delta < -720) delta += 1440;
    _target += delta;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _target),
          duration: tokens.motion.of(context, tokens.motion.medium),
          curve: tokens.motion.standard,
          builder: (context, minutes, _) => CustomPaint(
            size: Size.fromHeight(widget.height),
            painter: _DayPathPainter(
              day: (minutes % 1440) / 1440,
              rtl: Directionality.of(context) == TextDirection.rtl,
              path: tokens.ornament,
              quiet: tokens.ornamentQuiet,
              horizon: scheme.outlineVariant,
              sun: scheme.tertiary,
              moon: scheme.onSurfaceVariant,
              stroke: tokens.stroke.fine,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPathPainter extends CustomPainter {
  _DayPathPainter({
    required this.day,
    required this.rtl,
    required this.path,
    required this.quiet,
    required this.horizon,
    required this.sun,
    required this.moon,
    required this.stroke,
  });

  /// The chosen time as a fraction of the day (0 = midnight).
  final double day;
  final bool rtl;
  final Color path;
  final Color quiet;
  final Color horizon;
  final Color sun;
  final Color moon;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final mark = math.max(5.0, h * 0.11);
    // Room for the mark at either end and at the top and bottom.
    final left = mark * 2;
    final width = size.width - left * 2;
    final mid = h * 0.6;
    final rise = mid - mark * 1.6;
    final fall = (h - mid) - mark * 1.2;

    double x(double t) => left + (rtl ? 1 - t : t) * width;
    double height(double t) => -math.cos(2 * math.pi * t);
    double y(double t) {
      final s = height(t);
      return mid - s * (s > 0 ? rise : fall);
    }

    // The lines go on their own layer, so the mark can clear a gap in them
    // whatever the background (a sheet, a tinted option).
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = horizon
        ..strokeWidth = 1,
    );

    // The whole day in the quiet line, then the hours above the horizon
    // (sunrise at 6 to sunset at 18) in the ornament's.
    Path curve(double from, double to) {
      final curve = Path()..moveTo(x(from), y(from));
      const steps = 96;
      for (var i = 1; i <= steps; i++) {
        final t = from + (to - from) * i / steps;
        curve.lineTo(x(t), y(t));
      }
      return curve;
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curve(0, 1), line..color = quiet);
    canvas.drawPath(curve(0.25, 0.75), line..color = path);

    // Sunrise, noon and sunset as small studs.
    final stud = Paint()..color = path;
    for (final t in const [0.25, 0.5, 0.75]) {
      canvas.drawCircle(Offset(x(t), y(t)), stroke * 1.4, stud);
    }

    final at = Offset(x(day), y(day));
    canvas.drawCircle(at, mark * 1.9, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    if (height(day) >= 0) {
      canvas.drawCircle(
        at,
        mark * 2.1,
        Paint()..color = sun.withValues(alpha: 0.14),
      );
      final rays = Paint()
        ..color = sun
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(at + d * mark * 1.35, at + d * mark * 1.75, rays);
      }
      canvas.drawCircle(at, mark, Paint()..color = sun);
    } else {
      // A crescent: the disc less a disc shifted toward the day's end.
      final shift = Offset((rtl ? -1 : 1) * mark * 0.55, -mark * 0.25);
      final crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: at, radius: mark)),
        Path()
          ..addOval(Rect.fromCircle(center: at + shift, radius: mark * 0.85)),
      );
      canvas.drawPath(crescent, Paint()..color = moon);
    }
  }

  @override
  bool shouldRepaint(_DayPathPainter old) =>
      old.day != day ||
      old.rtl != rtl ||
      old.path != path ||
      old.quiet != quiet ||
      old.horizon != horizon ||
      old.sun != sun ||
      old.moon != moon ||
      old.stroke != stroke;
}

/// How long until something fires, as on the Reminders page: "in 2 h
/// 40 min", "in 3 h", "in 25 min", in the locale's digits.
String hudaTimeUntil(BuildContext context, int minutes) {
  final l10n = AppLocalizations.of(context)!;
  final digits = intl.NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  );
  String n(int value) => digits.format(value);
  if (minutes < 60) return l10n.remindersInMinutes(n(minutes));
  if (minutes % 60 == 0) return l10n.remindersInHours(n(minutes ~/ 60));
  return l10n.remindersInHoursMinutes(n(minutes ~/ 60), n(minutes % 60));
}

/// When a daily [time] next comes after [now]: "Today at 6:00 PM · in 2 h
/// 40 min" or "Tomorrow at 4:00 AM · in 7 h 12 min". A time equal to now
/// is tomorrow's.
String hudaNextTimeLabel(BuildContext context, TimeOfDay time, DateTime now) {
  final l10n = AppLocalizations.of(context)!;
  var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  final today = next.isAfter(now);
  if (!today) {
    next = DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
  }
  final spoken = MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final when = today
      ? l10n.remindersNextToday(spoken)
      : l10n.remindersNextTomorrow(spoken);
  final left = (next.difference(now).inSeconds + 59) ~/ 60;
  // A no-break space keeps the dot with the day when the line wraps.
  return '$when\u00A0· ${hudaTimeUntil(context, left)}';
}

/// The line under a daily time: when it next comes. It keeps up with the
/// clock while it shows (every 20 s), and follows the wheels as they turn.
class HudaNextTime extends StatefulWidget {
  const HudaNextTime({
    super.key,
    required this.time,
    this.clock = DateTime.now,
    this.textAlign,
  });

  final TimeOfDay time;
  final DateTime Function() clock;
  final TextAlign? textAlign;

  @override
  State<HudaNextTime> createState() => _HudaNextTimeState();
}

class _HudaNextTimeState extends State<HudaNextTime> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 20),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      hudaNextTimeLabel(context, widget.time, widget.clock()),
      key: const ValueKey('huda-time-picker-next'),
      textAlign: widget.textAlign,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
