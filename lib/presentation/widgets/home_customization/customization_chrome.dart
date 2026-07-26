import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomizationEditorTopBar extends StatelessWidget {
  const CustomizationEditorTopBar({
    super.key,
    required this.hasChanges,
    required this.isSaving,
    required this.onClose,
    required this.onApply,
  });

  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onClose;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final barHeight = textScale > 1.6
        ? 88.0
        : textScale > 1.35
            ? 78.0
            : 68.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(
          color: scheme.surface.withValues(alpha: 0.78),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: SizedBox(
                  height: barHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < 430 || textScale > 1.45;
                      final reduceMotion =
                          MediaQuery.disableAnimationsOf(context);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            _RoundChromeButton(
                              key: const ValueKey('customization-close'),
                              tooltip: l10n.close,
                              icon: Icons.close_rounded,
                              onPressed: isSaving ? null : onClose,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: compact
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.customizeHome,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                height: 1.05,
                                              ),
                                        ),
                                        if (hasChanges)
                                          Text(
                                            l10n.unsaved,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: context.primaryColor,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.05,
                                                ),
                                          ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            l10n.customizeHome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        if (hasChanges) ...[
                                          const SizedBox(width: 8),
                                          _UnsavedIndicator(
                                            label: l10n.unsaved,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Semantics(
                              label: isSaving ? l10n.saving : null,
                              button: true,
                              child: FilledButton(
                                key: const ValueKey('customization-apply'),
                                onPressed: isSaving ? null : onApply,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(compact ? 68 : 86, 44),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 13 : 17,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: AnimatedSwitcher(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 160),
                                  child: isSaving
                                      ? Row(
                                          key: const ValueKey('saving'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox.square(
                                              dimension: 17,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (!compact) ...[
                                              const SizedBox(width: 8),
                                              Text(l10n.saving),
                                            ],
                                          ],
                                        )
                                      : Text(
                                          hasChanges
                                              ? l10n.applyChanges
                                              : l10n.done,
                                          key: ValueKey(
                                            hasChanges ? 'apply' : 'done',
                                          ),
                                          maxLines: 1,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomizationEditorDock extends StatelessWidget {
  const CustomizationEditorDock({
    super.key,
    required this.onTheme,
    required this.onReset,
  });

  final VoidCallback onTheme;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Material(
                color: scheme.surface.withValues(alpha: 0.86),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.75),
                  ),
                ),
                child: SizedBox(
                  height: 68,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showResetLabel = constraints.maxWidth >= 360 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.35;
                      return Row(
                        children: [
                          Expanded(
                            child: _DockAction(
                              icon: Icons.space_dashboard_rounded,
                              label: l10n.homeTheme,
                              onTap: onTheme,
                            ),
                          ),
                          _DockDivider(color: scheme.outlineVariant),
                          if (showResetLabel)
                            Expanded(
                              child: _DockAction(
                                icon: Icons.restart_alt_rounded,
                                label: l10n.resetTheme,
                                onTap: onReset,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Tooltip(
                              message: l10n.resetTheme,
                              child: InkResponse(
                                key: const ValueKey('reset-theme-action'),
                                onTap: onReset,
                                radius: 30,
                                child: Semantics(
                                  button: true,
                                  label: l10n.resetTheme,
                                  child: SizedBox(
                                    width: 64,
                                    height: 68,
                                    child: Icon(
                                      Icons.restart_alt_rounded,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomizationSectionHeading extends StatelessWidget {
  const CustomizationSectionHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.visibleCount,
    required this.totalCount,
  });

  final IconData icon;
  final String title;
  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$visibleCount/$totalCount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color ?? context.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsavedIndicator extends StatelessWidget {
  const _UnsavedIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    return Container(
      key: const ValueKey('customization-unsaved-indicator'),
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 9, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _DockDivider extends StatelessWidget {
  const _DockDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: color);
  }
}

class _RoundChromeButton extends StatelessWidget {
  const _RoundChromeButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(42),
          maximumSize: const Size.square(42),
        ),
      ),
    );
  }
}
