import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/ramadan/ramadan_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';

/// Ramadan's 30 moons, one a night in its phase: a fasted night's moon is
/// lit gilt, a missed one ringed in the error tone, an unmarked one a quiet
/// outline; nights still to come are faint and can't be marked. Tap a
/// night to mark it. As the card opens the fasted moons light in turn.
///
/// Outside Ramadan the card tracks the last Ramadan (its missed fasts are
/// made up before the next) and can fold to its header. It starts open
/// once anything is marked; with nothing marked it starts folded, with a
/// line saying what it is for, so a first visit isn't a page of last
/// year's moons. Opening or folding it by hand is remembered
/// ([nightsOpen], [onNightsOpen]). During Ramadan it's always open.
class RamadanNightsCard extends StatefulWidget {
  const RamadanNightsCard({
    super.key,
    required this.ramadanDays,
    required this.fastedCount,
    required this.missedCount,
    required this.currentDay,
    required this.isRamadan,
    required this.hijriYear,
    required this.onSetStatus,
    this.nightsOpen,
    this.onNightsOpen,
    this.clock,
  });

  final List<RamadanDayInfo> ramadanDays;
  final int fastedCount;
  final int missedCount;
  final int currentDay;
  final bool isRamadan;
  final int hijriYear;
  final void Function(int dayNumber, String status) onSetStatus;

  /// The person's own choice to open or fold the nights outside Ramadan;
  /// null until they make one.
  final bool? nightsOpen;
  final ValueChanged<bool>? onNightsOpen;
  final DateTime Function()? clock;

  @override
  State<RamadanNightsCard> createState() => _RamadanNightsCardState();
}

class _RamadanNightsCardState extends State<RamadanNightsCard>
    with SingleTickerProviderStateMixin {
  // Made up front: a card that never unfolds would otherwise first make it
  // in dispose, where the ticker can't look up its ancestors.
  late final AnimationController _open;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  bool get _foldable => !widget.isRamadan && widget.onNightsOpen != null;

  bool get _marked => widget.fastedCount + widget.missedCount > 0;

  bool get _showsNights => !_foldable || (widget.nightsOpen ?? _marked);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _light();
  }

  @override
  void didUpdateWidget(RamadanNightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _light();
  }

  /// The fasted moons light in turn the first time the nights show.
  void _light() {
    if (!_showsNights || _open.isAnimating || _open.value > 0) return;
    final tokens = context.tokens;
    if (tokens.motion.of(context, tokens.motion.long) == Duration.zero) {
      _open.value = 1;
    } else {
      _open.forward();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  bool _editable(RamadanDayInfo day) {
    final now = widget.clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      day.gregorianDate.year,
      day.gregorianDate.month,
      day.gregorianDate.day,
    );
    return !date.isAfter(today);
  }

  void _set(RamadanDayInfo day, String status) {
    if (status == day.status) return;
    widget.onSetStatus(day.dayNumber, status);
    final fasted =
        widget.fastedCount +
        (status == 'fasted' ? 1 : 0) -
        (day.status == 'fasted' ? 1 : 0);
    if (status == 'fasted' && fasted == widget.ramadanDays.length) {
      HudaHaptics.medium(context);
    } else {
      HudaHaptics.light(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final days = widget.ramadanDays;
    final showsNights = _showsNights;

    return HudaCard(
      padding: EdgeInsets.all(space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HudaEyebrow(
                      l10n.ramadanYearLabel(format.number(widget.hijriYear)),
                    ),
                    Text(
                      l10n.ramadanYourFasts,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('ramadan-about-qadhaa'),
                tooltip: l10n.qadhaaInfoTitle,
                onPressed: () => showQadhaaAboutSheet(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
              // Folded with nothing marked, "Mark your fasts" opens it: one
              // way in, not two.
              if (_foldable && (showsNights || _marked))
                IconButton(
                  key: const ValueKey('ramadan-nights-toggle'),
                  tooltip: showsNights
                      ? l10n.ramadanHideDays
                      : l10n.ramadanShowDays,
                  onPressed: () => widget.onNightsOpen!(!showsNights),
                  icon: AnimatedRotation(
                    turns: showsNights ? 0.5 : 0,
                    duration: tokens.motion.of(context, tokens.motion.medium),
                    curve: tokens.motion.standard,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ),
            ],
          ),
          SizedBox(height: space.sm),
          // Nothing marked outside Ramadan: what the card is for, in place
          // of counts that would all be zero.
          if (_foldable && !_marked)
            Text(
              l10n.ramadanNightsIntro,
              key: const ValueKey('ramadan-nights-intro'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: space.lg,
              runSpacing: space.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Count(
                  count: widget.fastedCount,
                  label: l10n.fastedStatus,
                  icon: Icons.check_rounded,
                  color: scheme.tertiary,
                ),
                _Count(
                  count: widget.missedCount,
                  label: l10n.missedStatus,
                  icon: Icons.close_rounded,
                  color: scheme.error,
                ),
                Text(
                  l10n.ramadanToMakeUp(widget.missedCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          HudaAnimatedSize(
            child: showsNights
                ? Padding(
                    padding: EdgeInsets.only(top: space.md),
                    child: _nights(days),
                  )
                : !_marked
                ? Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: EdgeInsets.only(top: space.xs),
                      child: TextButton.icon(
                        key: const ValueKey('ramadan-mark-fasts'),
                        onPressed: () => widget.onNightsOpen!(true),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(l10n.ramadanMarkFasts),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _nights(List<RamadanDayInfo> days) {
    final space = context.tokens.space;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final minTile = 50 * scale;
          final columns = width / 10 >= minTile
              ? 10
              : width / 6 >= minTile
              ? 6
              : 5;
          final gap = space.xxs;
          final tile = (width - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < days.length; i++)
                SizedBox(
                  width: tile,
                  child: AnimatedBuilder(
                    animation: _open,
                    builder: (context, _) {
                      final start = i / days.length * 0.6;
                      final opened = Curves.easeOutCubic.transform(
                        ((_open.value - start) / 0.4).clamp(0.0, 1.0),
                      );
                      return _Night(
                        moon: (tile * 0.5).clamp(26.0, 48.0),
                        key: ValueKey('ramadan-night-${days[i].dayNumber}'),
                        day: days[i],
                        today:
                            widget.isRamadan &&
                            days[i].dayNumber == widget.currentDay,
                        editable: _editable(days[i]),
                        opened: opened,
                        onSet: (status) => _set(days[i], status),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = CalendarFormat.of(context);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          HudaNumberRoll(
            value: count,
            format: format.number,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// One night: its number, its moon and its mark.
class _Night extends StatelessWidget {
  const _Night({
    super.key,
    required this.day,
    required this.today,
    required this.editable,
    required this.opened,
    required this.onSet,
    required this.moon,
  });

  /// The moon's size: it grows with the tile on wide windows.
  final double moon;
  final RamadanDayInfo day;
  final bool today;
  final bool editable;

  /// The opening light-up, 0 → 1.
  final double opened;
  final ValueChanged<String> onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final format = CalendarFormat.of(context);
    final status = day.status;
    final statusLabel = switch (status) {
      'fasted' => l10n.fastedStatus,
      'missed' => l10n.missedStatus,
      _ => l10n.ramadanNotMarked,
    };
    final label =
        '${l10n.ramadanDayLabel(day.dayNumber)}, '
        '${format.weekday(day.gregorianDate)} '
        '${format.gregorianDate(day.gregorianDate)}, $statusLabel';
    final radius = BorderRadius.circular(tokens.radius.md);

    final tile = Opacity(
      opacity: editable ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: today ? scheme.primary : Colors.transparent,
            width: tokens.stroke.fine,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              format.number(day.dayNumber),
              style: theme.textTheme.labelMedium?.copyWith(
                color: today ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(end: status == 'fasted' ? 1 : 0),
              duration: tokens.motion.of(
                context,
                const Duration(milliseconds: 500),
              ),
              curve: Curves.easeOutCubic,
              builder: (context, light, _) {
                final lit = light * opened;
                final missed = status == 'missed';
                final quiet = editable
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.14)
                    : scheme.outlineVariant;
                return SizedBox.square(
                  dimension: moon,
                  child: CustomPaint(
                    painter: CalendarMoonPainter(
                      phase: moonPhaseForDay(day.dayNumber),
                      lit: missed
                          ? scheme.error.withValues(alpha: 0.25)
                          : Color.lerp(quiet, scheme.tertiary, lit)!,
                      ring: missed
                          ? scheme.error
                          : Color.lerp(
                              editable ? scheme.outline : scheme.outlineVariant,
                              scheme.tertiary,
                              lit,
                            )!,
                      stroke: tokens.stroke.fine,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 16,
              child: switch (status) {
                'fasted' => Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: scheme.tertiary,
                ),
                'missed' => Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                _ => null,
              },
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: label,
      button: editable,
      excludeSemantics: true,
      child: PopupMenuButton<String>(
        enabled: editable,
        tooltip: '',
        position: PopupMenuPosition.under,
        onSelected: onSet,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'fasted',
            child: ListTile(
              leading: Icon(Icons.check_rounded, color: scheme.tertiary),
              title: Text(l10n.fastedStatus),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'missed',
            child: ListTile(
              leading: Icon(Icons.close_rounded, color: scheme.error),
              title: Text(l10n.missedStatus),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (status != 'unknown')
            PopupMenuItem(
              value: 'unknown',
              child: ListTile(
                leading: const Icon(Icons.remove_circle_outline_rounded),
                title: Text(l10n.ramadanClearDay),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
        child: ClipRRect(borderRadius: radius, child: tile),
      ),
    );
  }
}

/// About making up missed fasts, in Huda's sheet.
Future<void> showQadhaaAboutSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.qadhaaInfoTitle,
    maxDialogWidth: 600,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final space = context.tokens.space;
      Widget section(String title, List<Widget> body) => Padding(
        padding: EdgeInsets.only(bottom: space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            SizedBox(height: space.xxs),
            ...body,
          ],
        ),
      );
      Text body(String text) => Text(text, style: theme.textTheme.bodyMedium);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section(l10n.qadhaaInfoQ1Title, [body(l10n.qadhaaInfoQ1Body)]),
          section(l10n.qadhaaInfoQ2Title, [
            body(l10n.qadhaaInfoQ2Body1),
            SizedBox(height: space.xs),
            Container(
              padding: EdgeInsets.all(space.md),
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.tokens.radius.md),
                border: BorderDirectional(
                  start: BorderSide(
                    color: scheme.tertiary,
                    width: context.tokens.stroke.bold,
                  ),
                ),
              ),
              child: Text(
                l10n.qadhaaInfoQ2Verse,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: space.xs),
            body(l10n.qadhaaInfoQ2Body2),
          ]),
          section(l10n.qadhaaInfoQ3Title, [body(l10n.qadhaaInfoQ3Body)]),
          section(l10n.qadhaaInfoQ4Title, [
            body(l10n.qadhaaInfoQ4Body1),
            SizedBox(height: space.xs),
            body(l10n.qadhaaInfoQ4Body2),
          ]),
        ],
      );
    },
  );
}
