import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/checklist_item.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The groups, in the order the day runs.
const checklistGroupOrder = [
  ChecklistItemType.prayer,
  ChecklistItemType.quran,
  ChecklistItemType.athkar,
  ChecklistItemType.custom,
];

String checklistGroupName(AppLocalizations l10n, ChecklistItemType type) =>
    switch (type) {
      ChecklistItemType.prayer => l10n.checklistGroupPrayers,
      ChecklistItemType.quran => l10n.checklistGroupQuran,
      ChecklistItemType.athkar => l10n.checklistGroupAthkar,
      ChecklistItemType.custom => l10n.checklistGroupOther,
    };

String checklistFrequencyName(
  AppLocalizations l10n,
  RepetitionFrequency frequency,
) => switch (frequency) {
  RepetitionFrequency.daily => l10n.frequencyDaily,
  RepetitionFrequency.every2Days => l10n.frequencyEvery2Days,
  RepetitionFrequency.every3Days => l10n.frequencyEvery3Days,
  RepetitionFrequency.every4Days => l10n.frequencyEvery4Days,
  RepetitionFrequency.every5Days => l10n.frequencyEvery5Days,
  RepetitionFrequency.every6Days => l10n.frequencyEvery6Days,
  RepetitionFrequency.weekly => l10n.frequencyWeekly,
};

/// The day's items in their groups (Prayers, Quran, Athkar, Other), each a
/// card of rows under a header with its count. In [columns] 2, Prayers
/// sit beside the rest.
class ChecklistGroups extends StatelessWidget {
  const ChecklistGroups({
    super.key,
    required this.items,
    required this.completed,
    required this.editable,
    required this.onToggle,
    required this.onRemove,
    this.columns = 1,
    this.revealFrom = 0,
  });

  final List<ChecklistItem> items;
  final Map<String, bool> completed;

  /// Today: rows check, custom items can be removed.
  final bool editable;
  final void Function(ChecklistItem item, bool done) onToggle;
  final void Function(ChecklistItem item) onRemove;
  final int columns;
  final int revealFrom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final groups = [
      for (final type in checklistGroupOrder)
        if (items.any((item) => item.type == type))
          (type, items.where((item) => item.type == type).toList()),
    ];

    Widget group(int index, ChecklistItemType type, List<ChecklistItem> rows) {
      final done = rows.where((item) => completed[item.id] == true).length;
      return HudaReveal(
        index: revealFrom + index,
        child: Padding(
          padding: EdgeInsets.only(bottom: space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HudaSectionHeader(
                checklistGroupName(l10n, type),
                trailing: Text(
                  '$done/${rows.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              HudaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: space.md + 48,
                          endIndent: space.md,
                        ),
                      ChecklistRow(
                        key: ValueKey('checklist-row-${rows[i].id}'),
                        item: rows[i],
                        done: completed[rows[i].id] == true,
                        editable: editable,
                        onToggle: (done) => onToggle(rows[i], done),
                        onRemove: editable && !rows[i].isDefault
                            ? () => onRemove(rows[i])
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (columns < 2 || groups.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groups.length; i++)
            group(i, groups[i].$1, groups[i].$2),
        ],
      );
    }
    // The first group (usually the five prayers) beside the others.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: group(0, groups.first.$1, groups.first.$2)),
        SizedBox(width: space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 1; i < groups.length; i++)
                group(i, groups[i].$1, groups[i].$2),
            ],
          ),
        ),
      ],
    );
  }
}

/// One item: the tick, its name and (when it doesn't repeat daily) how
/// often it comes, and for custom items on today a Remove button. The
/// whole row toggles; only today's rows can.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.item,
    required this.done,
    required this.editable,
    required this.onToggle,
    this.onRemove,
  });

  final ChecklistItem item;
  final bool done;
  final bool editable;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final onRemove = this.onRemove;
    final repeats = item.frequency != RepetitionFrequency.daily;
    final toggle = MergeSemantics(
      child: Semantics(
        checked: done,
        enabled: editable,
        child: InkWell(
          onTap: editable ? () => onToggle(!done) : null,
          borderRadius: BorderRadius.circular(tokens.radius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: space.md,
                end: space.sm,
                top: space.xs,
                bottom: space.xs,
              ),
              child: Row(
                children: [
                  ChecklistTick(done: done, enabled: editable),
                  SizedBox(width: space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: tokens.motion.of(
                            context,
                            tokens.motion.short,
                          ),
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: done
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                          child: Text(item.title),
                        ),
                        if (repeats)
                          Text(
                            checklistFrequencyName(l10n, item.frequency),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          Expanded(child: toggle),
          if (onRemove != null)
            Padding(
              padding: EdgeInsetsDirectional.only(end: space.xxs),
              child: IconButton(
                key: ValueKey('checklist-remove-${item.id}'),
                tooltip: l10n.remove,
                onPressed: onRemove,
                color: theme.colorScheme.onSurfaceVariant,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/// The check box: an open square (3:1) that lights and draws its check
/// when the item is done.
class ChecklistTick extends StatelessWidget {
  const ChecklistTick({super.key, required this.done, this.enabled = true});

  final bool done;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final off = scheme.onSurfaceVariant.withValues(alpha: enabled ? 1 : 0.6);
    return AnimatedContainer(
      duration: duration,
      curve: tokens.motion.standard,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? tokens.lit : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(
          color: done ? tokens.lit : off,
          width: done ? 0 : tokens.stroke.fine,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: done ? 1 : 0),
        duration: done
            ? tokens.motion.of(context, tokens.motion.medium)
            : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _CheckPainter(progress: t, color: tokens.onChrome),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final a = Offset(size.width * 0.25, size.height * 0.53);
    final b = Offset(size.width * 0.43, size.height * 0.7);
    final c = Offset(size.width * 0.76, size.height * 0.33);
    final first = (b - a).distance;
    final total = first + (c - b).distance;
    final drawn = total * progress;
    final path = Path()..moveTo(a.dx, a.dy);
    if (drawn <= first) {
      final p = Offset.lerp(a, b, drawn / first)!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(b.dx, b.dy);
      final p = Offset.lerp(b, c, (drawn - first) / (total - first))!;
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

/// The page while the checklist loads, in the shape of what's coming.
class ChecklistSkeleton extends StatelessWidget {
  const ChecklistSkeleton({super.key, this.card = true, this.rows = true});

  final bool card;
  final bool rows;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final body = Theme.of(context).textTheme.bodyLarge;
    return HudaSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (card) ...[
            const HudaSkeletonLines(lines: 2),
            SizedBox(height: space.md),
            HudaCard(
              child: Row(
                children: [
                  const HudaSkeletonBlock(
                    width: 104,
                    height: 104,
                    circle: true,
                  ),
                  SizedBox(width: space.lg),
                  const Expanded(child: HudaSkeletonLines(lines: 3)),
                ],
              ),
            ),
            SizedBox(height: space.xl),
          ],
          if (rows)
            for (var group = 0; group < 2; group++) ...[
              SizedBox(
                width: 96,
                child: HudaSkeletonLines(lines: 1, style: body),
              ),
              SizedBox(height: space.xs),
              HudaCard(
                child: Column(
                  children: [
                    for (var i = 0; i < math.max(2, 5 - group * 2); i++)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: space.xs),
                        child: Row(
                          children: [
                            const HudaSkeletonBlock(width: 26, height: 26),
                            SizedBox(width: space.md),
                            Expanded(
                              child: HudaSkeletonLines(lines: 1, style: body),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: space.lg),
            ],
        ],
      ),
    );
  }
}
