import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hijri_date_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/checklist_identity.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';

bool checklistIsToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

/// The inlaid star, animated: it fills from empty to [progress] as it
/// appears (900 ms), fills on to each new value (500 ms), and when
/// [complete] turns true the heart sets and one glint runs across it
/// (about 1.2 s with the last fill). Reduce motion: the end state.
class ChecklistStar extends StatefulWidget {
  const ChecklistStar({
    super.key,
    required this.progress,
    required this.complete,
    required this.size,
    this.semanticsLabel,
  });

  final double progress;
  final bool complete;
  final double size;
  final String? semanticsLabel;

  @override
  State<ChecklistStar> createState() => _ChecklistStarState();
}

class _ChecklistStarState extends State<ChecklistStar>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this);
  late final AnimationController _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _glint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// The celebration: the star swells and settles, light pools behind it
  /// and inlaid lozenges fly from its tips.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  double _from = 0;
  double _to = 0;
  bool _started = false;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  double get _shown =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_fill.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _to = widget.progress;
    if (_still) {
      _fill.value = 1;
      _heart.value = widget.complete ? 1 : 0;
      return;
    }
    _fill.duration = const Duration(milliseconds: 900);
    _fill.forward(from: 0).whenCompleteOrCancel(() {
      // A day that's already done shows its heart set, without the glint.
      if (mounted && widget.complete) _heart.forward();
    });
  }

  @override
  void didUpdateWidget(ChecklistStar old) {
    super.didUpdateWidget(old);
    if (old.progress == widget.progress && old.complete == widget.complete) {
      return;
    }
    final celebrate = widget.complete && !old.complete;
    if (!widget.complete) {
      _heart.value = 0;
      _glint.value = 0;
      _burst.value = 0;
    }
    _from = _shown;
    _to = widget.progress;
    if (_still) {
      _fill.value = 1;
      _heart.value = widget.complete ? 1 : 0;
      return;
    }
    _fill.duration = const Duration(milliseconds: 500);
    _fill.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted || !celebrate || !widget.complete) return;
      _burst.forward(from: 0);
      _heart.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted && widget.complete) _glint.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    _heart.dispose();
    _glint.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inlay = ChecklistInlay.of(context);
    final direction = Directionality.of(context);
    return Semantics(
      image: true,
      label: widget.semanticsLabel,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fill, _heart, _glint, _burst]),
            builder: (context, _) {
              final t = _burst.value;
              // A breath as the heart sets: up 7% and back by 45%.
              final swell = t > 0 && t < 0.45
                  ? 1 + 0.07 * math.sin(math.pi * t / 0.45)
                  : 1.0;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: ChecklistBurstPainter(
                      inlay: inlay,
                      t: t,
                      behind: true,
                      textDirection: direction,
                    ),
                  ),
                  Transform.scale(
                    scale: swell,
                    child: CustomPaint(
                      painter: ChecklistStarPainter(
                        inlay: inlay,
                        progress: _shown,
                        heart: _heart.value,
                        glint: _glint.value,
                        textDirection: direction,
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: ChecklistBurstPainter(
                      inlay: inlay,
                      t: t,
                      behind: false,
                      textDirection: direction,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The day being shown: ‹ weekday, Hijri and Gregorian date › (the arrows
/// follow reading direction). "Today" above the weekday when it is.
class ChecklistDateRow extends StatelessWidget {
  const ChecklistDateRow({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = CalendarFormat.of(context);
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final hijri = hijriDateFromDateTime(date);
    final today = checklistIsToday(date);
    final dateStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        IconButton(
          key: const ValueKey('checklist-previous'),
          tooltip: l10n.checklistPreviousDay,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        SizedBox(width: space.xs),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                if (today)
                  HudaEyebrow(l10n.today)
                else
                  // Keeps the row's height, so the arrows don't move.
                  ExcludeSemantics(
                    child: Opacity(opacity: 0, child: HudaEyebrow(l10n.today)),
                  ),
                Text(
                  format.weekday(date),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('${format.hijriDate(hijri)} · ', style: dateStyle),
                    Text(format.gregorianDate(date), style: dateStyle),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: space.xs),
        IconButton(
          key: const ValueKey('checklist-next'),
          tooltip: l10n.checklistNextDay,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// The day card: the inlaid star beside how many items are done, and on
/// today the streak as a path of small stars ending at today's; a
/// blessing once the day is complete; on other days, why they can't be
/// checked. An inlaid band runs along its top edge.
class ChecklistDayCard extends StatelessWidget {
  const ChecklistDayCard({
    super.key,
    required this.date,
    required this.done,
    required this.total,
    required this.streak,
    this.large = false,
  });

  final DateTime date;
  final int done;
  final int total;

  /// The run of complete days, today included once it's complete.
  final int streak;

  /// A bigger star, for the overview pane.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final inlay = ChecklistInlay.of(context);
    final today = checklistIsToday(date);
    final complete = total > 0 && done >= total;
    final progress = total == 0 ? 0.0 : done / total;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final messages = [
      l10n.congratsMessage1,
      l10n.congratsMessage2,
      l10n.congratsMessage3,
      l10n.congratsMessage4,
      l10n.congratsMessage5,
      l10n.congratsMessage6,
      l10n.congratsMessage7,
      l10n.congratsMessage8,
      l10n.congratsMessage9,
      l10n.congratsMessage10,
      l10n.congratsMessage11,
      l10n.congratsMessage12,
      l10n.congratsMessage13,
    ];
    final headline = complete
        ? l10n.checklistAllDone
        : l10n.checklistDoneOf(done, total);

    // The card never changes size as items are checked, the day
    // completes or another day is shown: every slot lays out all the
    // texts it can hold and shows one (see [_Slot]).
    Widget text(TextAlign align, CrossAxisAlignment cross) {
      final at = cross == CrossAxisAlignment.center
          ? AlignmentDirectional.topCenter
          : AlignmentDirectional.topStart;
      final headlineStyle = theme.textTheme.headlineSmall;
      final blessingStyle = theme.textTheme.bodyLarge?.copyWith(
        color: tokens.ornament,
      );
      final noteStyle = theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      final past = date.isBefore(DateTime.now());

      // Today: the blessing once complete, then the streak's path.
      final todayDetails = Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: space.xxs),
          _Slot(
            alignment: at,
            shown: complete && today ? messages.length : -1,
            variants: [
              for (final message in messages)
                Text(message, textAlign: align, style: blessingStyle),
              _RiseIn(
                key: ValueKey('blessing-$complete'),
                child: Text(
                  messages[streak % messages.length],
                  textAlign: align,
                  style: blessingStyle,
                ),
              ),
            ],
          ),
          SizedBox(height: space.sm),
          _Path(
            streak: streak,
            complete: complete,
            progress: progress,
            align: align,
            alignment: at,
          ),
        ],
      );
      // Other days: why they can't be checked.
      final otherDetails = Padding(
        padding: EdgeInsets.only(top: space.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              past ? Icons.history_rounded : Icons.schedule_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: space.xs),
            Flexible(
              child: Text(
                past ? l10n.checklistPastNote : l10n.checklistFutureNote,
                style: noteStyle,
              ),
            ),
          ],
        ),
      );

      return Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          HudaEyebrow(l10n.dailyProgress),
          SizedBox(height: space.xxs),
          _Slot(
            alignment: at,
            shown: complete ? 1 : 0,
            variants: [
              Text(
                l10n.checklistDoneOf(done, total),
                textAlign: align,
                style: headlineStyle,
              ),
              Text(
                l10n.checklistAllDone,
                textAlign: align,
                style: headlineStyle,
              ),
              // The longest count, so 9 → 10 doesn't rewrap.
              Text(
                l10n.checklistDoneOf(total, total),
                textAlign: align,
                style: headlineStyle,
              ),
            ],
          ),
          _Slot(
            alignment: at,
            shown: today ? 0 : 1,
            variants: [todayDetails, otherDetails],
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: tokens.radius.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: tokens.radius.card,
        child: Stack(
          children: [
            // The inlaid frame runs round all four sides, inside the card.
            Positioned.fill(
              child: Ornament(
                painter: ChecklistInlayFramePainter(inlay: inlay),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ChecklistInlayFramePainter.clearance() + space.sm,
                ChecklistInlayFramePainter.clearance() + space.sm,
                ChecklistInlayFramePainter.clearance() + space.sm,
                ChecklistInlayFramePainter.clearance() + space.md,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // The overview pane stacks a large star over the text;
                  // elsewhere the star sits beside it while the text keeps
                  // about 160 of width.
                  final beside =
                      !large && width >= 270 * math.max(1, scale * 0.85);
                  final star = large
                      ? (width * 0.62).clamp(112.0, 232.0)
                      : (width * 0.3).clamp(88.0, 168.0);
                  final starWidget = ChecklistStar(
                    // A new day starts from an empty star.
                    key: ValueKey(
                      'star-${date.year}-${date.month}-${date.day}',
                    ),
                    progress: progress,
                    complete: complete,
                    size: star,
                    semanticsLabel: headline,
                  );
                  if (!beside) {
                    return Column(
                      children: [
                        starWidget,
                        SizedBox(height: space.md),
                        text(TextAlign.center, CrossAxisAlignment.center),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      starWidget,
                      SizedBox(width: space.lg),
                      Expanded(
                        child: text(TextAlign.start, CrossAxisAlignment.start),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The streak's path of small stars with its label.
class _Path extends StatelessWidget {
  const _Path({
    required this.streak,
    required this.complete,
    required this.progress,
    required this.align,
    required this.alignment,
  });

  final int streak;
  final bool complete;
  final double progress;
  final TextAlign align;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    // Days already in the run before today.
    final past = complete ? math.max(0, streak - 1) : streak;
    final label = streak > 0
        ? l10n.checklistStreak(streak)
        : l10n.checklistStreakStart;
    final centered = align == TextAlign.center;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const pitch = 26.0;
              final slots = math.min(
                7,
                math.max(1, (constraints.maxWidth / pitch).floor()),
              );
              final shown = math.min(past + 1, slots);
              return TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: context.tokens.motion.of(
                  context,
                  const Duration(milliseconds: 500),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, today, _) => CustomPaint(
                  size: Size(shown * pitch, 20),
                  painter: ChecklistPathPainter(
                    inlay: ChecklistInlay.of(context),
                    past: past,
                    today: complete ? 1 : today,
                    slots: shown,
                    textDirection: Directionality.of(context),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: space.xxs),
          // Room for the label after today completes (one more day).
          _Slot(
            alignment: alignment,
            shown: 0,
            variants: [
              for (final text in [
                label,
                l10n.checklistStreakStart,
                l10n.checklistStreak(streak + 1),
              ])
                Text(
                  text,
                  textAlign: align,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The blessing rises a little and brightens in as the heart sets (a beat
/// after the day completes). Reduce motion: there at once.
class _RiseIn extends StatefulWidget {
  const _RiseIn({super.key, required this.child});

  final Widget child;

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    // Waits for the last point to fill, then rises.
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
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
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(_curve),
      child: widget.child,
    ),
  );
}

/// Lays out every one of [variants] in the same place and shows the one at
/// [shown] (none when it's out of range), cross-fading on a change. The
/// slot is as big as its biggest variant, so swapping texts never resizes
/// what's around it. Hidden variants are invisible to touch and to screen
/// readers.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.variants,
    required this.shown,
    this.alignment = AlignmentDirectional.topStart,
  });

  final List<Widget> variants;
  final int shown;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final duration = tokens.motion.of(context, tokens.motion.medium);
    return Stack(
      alignment: alignment,
      children: [
        for (var i = 0; i < variants.length; i++)
          IgnorePointer(
            ignoring: i != shown,
            child: ExcludeSemantics(
              excluding: i != shown,
              child: AnimatedOpacity(
                opacity: i == shown ? 1 : 0,
                duration: duration,
                curve: tokens.motion.standard,
                child: variants[i],
              ),
            ),
          ),
      ],
    );
  }
}
