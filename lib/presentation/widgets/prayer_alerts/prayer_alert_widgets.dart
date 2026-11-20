import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerAlertSection extends StatelessWidget {
  const PrayerAlertSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: palette.cardDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: palette.divider,
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.faint,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PrayerSettingRow extends StatelessWidget {
  const PrayerSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
          child: Row(
            children: [
              if (icon != null) ...[
                PrayerAlertIconBadge(icon: icon!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor ?? palette.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (trailing == null && onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.faint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerAlertIconBadge extends StatelessWidget {
  const PrayerAlertIconBadge({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: (color ?? palette.primary).withValues(
          alpha: palette.isDark ? 0.2 : 0.1,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: color ?? palette.primary),
    );
  }
}

class PrayerSwitchRow extends StatelessWidget {
  const PrayerSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  void _change(BuildContext context, bool next) {
    HudaHaptics.selection(context);
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: PrayerSettingRow(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: onChanged == null ? null : () => _change(context, !value),
        trailing: Switch(
          value: value,
          onChanged: onChanged == null ? null : (next) => _change(context, next),
        ),
      ),
    );
  }
}

class PrayerChoiceTile extends StatelessWidget {
  const PrayerChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.unavailable,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  final String? unavailable;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final enabled = onTap != null && unavailable == null;
    final accent = selected ? palette.primary : palette.muted;
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? palette.tint : palette.cardRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Opacity(
              opacity: enabled || selected ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unavailable ?? subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: unavailable == null
                                  ? palette.muted
                                  : palette.warning,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: selected ? palette.primary : palette.faint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrayerStyleChoices extends StatelessWidget {
  const PrayerStyleChoices({
    super.key,
    required this.styles,
    required this.selected,
    required this.onSelected,
    this.unavailable = const {},
    this.leading = const [],
    this.capabilities,
  });

  final List<PrayerAlertStyle> styles;

  final PrayerAlertCapabilities? capabilities;
  final PrayerAlertStyle? selected;
  final ValueChanged<PrayerAlertStyle> onSelected;
  final Map<PrayerAlertStyle, String> unavailable;

  final List<Widget> leading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      ...leading,
      for (final style in styles)
        PrayerChoiceTile(
          key: ValueKey('prayer-alert-style-${style.name}'),
          icon: prayerAlertStyleIcon(style),
          title: l10n.alertStyleOn(style, capabilities),
          subtitle: l10n.alertStyleHintOn(style, capabilities),
          selected: selected == style,
          unavailable: unavailable[style] == null
              ? null
              : l10n.alertWarning(unavailable[style]!),
          onTap: () => onSelected(style),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class PrayerSegmented<T> extends StatelessWidget {
  const PrayerSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Wrap(
      spacing: space.xs,
      runSpacing: space.xs,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(label(option)),
            selected: option == selected,
            showCheckmark: false,
            onSelected: (_) {
              if (option == selected) return;
              HudaHaptics.selection(context);
              onSelected(option);
            },
          ),
      ],
    );
  }
}

class PrayerControlRow extends StatelessWidget {
  const PrayerControlRow({
    super.key,
    required this.title,
    required this.child,
    this.value,
  });

  final String title;
  final String? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class PrayerSaveStatus extends StatelessWidget {
  const PrayerSaveStatus({super.key, required this.controller});

  final PrayerAlertController<Object?> controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final state = controller.saveState;
    final (String? text, Color color, Widget? icon) = switch (state) {
      PrayerAlertSaveState.updating => (
        l10n.prayerAlertSaving,
        palette.muted,
        const SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      ),
      PrayerAlertSaveState.retrying => (
        l10n.prayerAlertRetrying,
        palette.muted,
        const SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      ),
      PrayerAlertSaveState.saved => (
        l10n.prayerAlertSaved,
        palette.success,
        Icon(Icons.check_rounded, size: 14, color: palette.success),
      ),
      PrayerAlertSaveState.failed => (
        l10n.prayerAlertNotSaved,
        palette.error,
        Icon(Icons.error_outline_rounded, size: 14, color: palette.error),
      ),
      PrayerAlertSaveState.idle => (null, palette.muted, null),
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: text == null
            ? const SizedBox.shrink()
            : Row(
                key: ValueKey(state),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?icon,
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class PrayerSaveFailureBanner extends StatelessWidget {
  const PrayerSaveFailureBanner({super.key, required this.controller});

  final PrayerAlertController<Object?> controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final failed = controller.saveState == PrayerAlertSaveState.failed;
    final warning = controller.warning;
    if (!failed && warning == null) return const SizedBox.shrink();
    final color = failed ? palette.error : palette.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: palette.isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    failed
                        ? l10n.alertSaveFailure(controller.failure)
                        : l10n.alertWarning(warning!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (failed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: controller.undo,
                      child: Text(l10n.prayerAlertUndo),
                    ),
                    FilledButton.tonal(
                      key: const ValueKey('prayer-alert-retry'),
                      onPressed: controller.retry,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
