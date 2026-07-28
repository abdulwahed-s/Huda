import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class HijriAdjustmentDialog extends StatefulWidget {
  const HijriAdjustmentDialog({
    super.key,
    required this.initialChoice,
    required this.canDismiss,
    required this.onSave,
  });

  final HijriAdjustmentChoice? initialChoice;
  final bool canDismiss;
  final Future<void> Function(HijriAdjustmentChoice choice) onSave;

  @override
  State<HijriAdjustmentDialog> createState() => _HijriAdjustmentDialogState();
}

class _HijriAdjustmentDialogState extends State<HijriAdjustmentDialog> {
  static const _manualChoices = <HijriAdjustmentChoice>[
    HijriAdjustmentChoice.minusTwo,
    HijriAdjustmentChoice.minusOne,
    HijriAdjustmentChoice.none,
    HijriAdjustmentChoice.plusOne,
    HijriAdjustmentChoice.plusTwo,
  ];

  HijriAdjustmentChoice? _selectedChoice;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedChoice = widget.initialChoice;
  }

  void _select(HijriAdjustmentChoice choice) {
    if (_isSaving || _selectedChoice == choice) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChoice = choice;
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    final choice = _selectedChoice;
    if (choice == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(choice);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.canDismiss && !_isSaving,
      child: Dialog(
        key: const ValueKey('hijri-adjustment-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, localizations),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizations.hijriAdjustmentDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _AutomaticChoiceCard(
                        selected:
                            _selectedChoice == HijriAdjustmentChoice.automatic,
                        enabled: !_isSaving,
                        onTap: () => _select(HijriAdjustmentChoice.automatic),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        localizations.hijriManualAdjustment,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.hijriManualAdjustmentDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 32) / 5;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final choice in _manualChoices)
                                SizedBox(
                                  width: itemWidth,
                                  child: _ManualChoiceButton(
                                    choice: choice,
                                    selected: _selectedChoice == choice,
                                    enabled: !_isSaving,
                                    onTap: () => _select(choice),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 20,
                                color: colors.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: colors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
                      : colors.surfaceContainerLowest,
                  border: Border(
                    top: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.canDismiss) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(localizations.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: widget.canDismiss ? 1 : 2,
                      child: FilledButton(
                        key: const ValueKey('save-hijri-adjustment'),
                        onPressed: _selectedChoice == null ||
                                _isSaving ||
                                (widget.canDismiss &&
                                    _selectedChoice == widget.initialChoice)
                            ? null
                            : _save,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _isSaving
                              ? SizedBox.square(
                                  key: const ValueKey(
                                    'hijri-adjustment-progress',
                                  ),
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : Text(
                                  widget.canDismiss
                                      ? localizations.save
                                      : localizations.confirm,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.primaryColor,
            context.primaryVariantColor,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              localizations.hijriAdjustmentTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (widget.canDismiss)
            IconButton(
              tooltip: localizations.cancel,
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _AutomaticChoiceCard extends StatelessWidget {
  const _AutomaticChoiceCard({
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final primary = context.primaryColor;

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.09)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? primary
                : colors.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('hijri-adjustment-automatic'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: selected ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.automatic,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          localizations.hijriAutomaticAdjustmentDescription,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? primary : colors.outline,
                    size: 25,
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

class _ManualChoiceButton extends StatelessWidget {
  const _ManualChoiceButton({
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final HijriAdjustmentChoice choice;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = context.primaryColor;

    return Semantics(
      selected: selected,
      button: true,
      label: choice.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? primary : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : colors.outlineVariant,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('hijri-adjustment-${choice.name}'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                choice.label,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
