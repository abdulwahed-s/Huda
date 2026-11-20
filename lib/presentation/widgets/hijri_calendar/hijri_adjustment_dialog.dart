import 'package:flutter/material.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';

Future<void> showHijriAdjustmentSheet(
  BuildContext context, {
  required HijriAdjustmentChoice? initialChoice,
  required Future<void> Function(HijriAdjustmentChoice choice) onSave,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.hijriAdjustmentTitle,
    builder: (_) =>
        HijriAdjustmentSheet(initialChoice: initialChoice, onSave: onSave),
  );
}

class HijriAdjustmentSheet extends StatefulWidget {
  const HijriAdjustmentSheet({
    super.key,
    required this.initialChoice,
    required this.onSave,
  });

  final HijriAdjustmentChoice? initialChoice;
  final Future<void> Function(HijriAdjustmentChoice choice) onSave;

  @override
  State<HijriAdjustmentSheet> createState() => _HijriAdjustmentSheetState();
}

class _HijriAdjustmentSheetState extends State<HijriAdjustmentSheet> {
  static const _manual = <HijriAdjustmentChoice>[
    HijriAdjustmentChoice.minusTwo,
    HijriAdjustmentChoice.minusOne,
    HijriAdjustmentChoice.none,
    HijriAdjustmentChoice.plusOne,
    HijriAdjustmentChoice.plusTwo,
  ];

  late HijriAdjustmentChoice? _choice = widget.initialChoice;
  bool _saving = false;
  bool _failed = false;

  void _select(HijriAdjustmentChoice choice) {
    if (_saving || _choice == choice) return;
    HudaHaptics.selection(context);
    setState(() {
      _choice = choice;
      _failed = false;
    });
  }

  Future<void> _save() async {
    final choice = _choice;
    if (choice == null || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(choice);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final automatic = _choice == HijriAdjustmentChoice.automatic;
    final changed = _choice != null && _choice != widget.initialChoice;

    return Column(
      key: const ValueKey('hijri-adjustment-dialog'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.hijriAdjustmentDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.md),
        _Choice(
          key: const ValueKey('hijri-adjustment-automatic'),
          selected: automatic,
          enabled: !_saving,
          title: l10n.automatic,
          subtitle: l10n.hijriAutomaticAdjustmentDescription,
          onTap: () => _select(HijriAdjustmentChoice.automatic),
        ),
        SizedBox(height: space.xl),
        Text(l10n.hijriManualAdjustment, style: theme.textTheme.titleSmall),
        SizedBox(height: space.xxs),
        Text(
          l10n.hijriManualAdjustmentDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SegmentedButton<HijriAdjustmentChoice>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              for (final choice in _manual)
                ButtonSegment(
                  value: choice,
                  label: Text(
                    choice.label.replaceFirst('-', '−'),
                    key: ValueKey('hijri-adjustment-${choice.name}'),
                  ),
                ),
            ],
            selected: {if (_choice != null && !automatic) _choice!},
            onSelectionChanged: _saving
                ? null
                : (value) {
                    if (value.isNotEmpty) _select(value.first);
                  },
          ),
        ),
        if (_failed) ...[
          SizedBox(height: space.md),
          HudaStatusBanner(
            status: HudaStatus.failed,
            message: l10n.calendarAdjustmentFailed,
          ),
        ],
        SizedBox(height: space.xl),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            key: const ValueKey('save-hijri-adjustment'),
            onPressed: changed && !_saving ? _save : null,
            child: _saving
                ? HudaLampSpinner(size: 20, color: tokens.onChrome)
                : Text(l10n.save),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final radius = BorderRadius.circular(tokens.radius.md);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.short),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
          borderRadius: radius,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? tokens.stroke.fine : tokens.stroke.hairline,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.all(space.md),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 32,
                    child: CustomPaint(
                      painter: CalendarMoonPainter(
                        phase: 0.14,
                        lit: scheme.tertiary,
                        ring: scheme.tertiary,
                      ),
                    ),
                  ),
                  SizedBox(width: space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: space.sm),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HijriAdjustmentPrompt extends StatefulWidget {
  const HijriAdjustmentPrompt({
    super.key,
    required this.onUseAutomatic,
    required this.onAdjust,
  });

  final Future<void> Function() onUseAutomatic;
  final VoidCallback onAdjust;

  @override
  State<HijriAdjustmentPrompt> createState() => _HijriAdjustmentPromptState();
}

class _HijriAdjustmentPromptState extends State<HijriAdjustmentPrompt> {
  bool _saving = false;

  Future<void> _useAutomatic() async {
    setState(() => _saving = true);
    try {
      await widget.onUseAutomatic();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    return HudaCard(
      key: const ValueKey('hijri-adjustment-prompt'),
      padding: EdgeInsets.all(space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HudaLamp(
                size: 40,
                child: SizedBox.square(
                  dimension: 20,
                  child: CustomPaint(
                    painter: CalendarMoonPainter(
                      phase: 0.14,
                      lit: tokens.gilt,
                      ring: tokens.gilt,
                    ),
                  ),
                ),
              ),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.calendarChooseTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: space.xxs),
                    Text(
                      l10n.calendarChooseMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: space.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: space.xs,
            runSpacing: space.xs,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : widget.onAdjust,
                child: Text(l10n.calendarAdjustDays),
              ),
              FilledButton(
                key: const ValueKey('hijri-use-automatic'),
                onPressed: _saving ? null : _useAutomatic,
                child: _saving
                    ? HudaLampSpinner(size: 20, color: tokens.onChrome)
                    : Text(l10n.calendarUseUmmAlQura),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
