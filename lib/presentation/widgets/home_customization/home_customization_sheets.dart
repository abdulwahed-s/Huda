import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/home_customization/home_theme_preview.dart';

Future<void> showHomeThemePicker(BuildContext context) {
  final cubit = context.read<HomeCustomizationCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 920),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _HomeThemePickerSheet(),
    ),
  );
}

class _HomeThemePickerSheet extends StatelessWidget {
  const _HomeThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
      builder: (context, state) {
        if (state is! HomeCustomizationReady) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final selected = state.draft.selectedTheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeading(
                icon: Icons.space_dashboard_rounded,
                title: l10n.homeTheme,
                subtitle: homeThemeDescription(context, selected),
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720 &&
                      MediaQuery.textScalerOf(context).scale(1) <= 1.35;
                  final choices = [
                    for (final theme in HomeThemeId.values)
                      _ThemeChoice(
                        theme: theme,
                        configuration: state.draft.configurationFor(theme),
                        selected: theme == selected,
                        wide: wide,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context
                              .read<HomeCustomizationCubit>()
                              .selectTheme(theme);
                        },
                      ),
                  ];
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0;
                            index < choices.length;
                            index++) ...[
                          Expanded(child: choices[index]),
                          if (index != choices.length - 1)
                            const SizedBox(width: 14),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var index = 0; index < choices.length; index++) ...[
                        choices[index],
                        if (index != choices.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.theme,
    required this.configuration,
    required this.selected,
    required this.wide,
    required this.onTap,
  });

  final HomeThemeId theme;
  final HomeThemeConfiguration configuration;
  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final name = homeThemeName(context, theme);
    final description = homeThemeDescription(context, theme);
    final preview = HomeThemePreview(
      key: ValueKey('theme-picker-preview-${theme.name}'),
      theme: theme,
      configuration: configuration,
    );
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          textAlign: wide ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          textAlign: wide ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
        ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '$name. $description',
      excludeSemantics: true,
      child: AnimatedContainer(
        key: ValueKey('theme-picker-choice-${theme.name}'),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.09)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(1);
                      final stack = wide ||
                          constraints.maxWidth < 370 ||
                          textScale > 1.35;
                      if (stack) {
                        return Column(
                          children: [
                            SizedBox(height: wide ? 126 : 132, child: preview),
                            const SizedBox(height: 12),
                            copy,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 132, height: 92, child: preview),
                          const SizedBox(width: 14),
                          Expanded(child: copy),
                        ],
                      );
                    },
                  ),
                ),
                if (selected)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      key: ValueKey('theme-picker-selected-${theme.name}'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
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

class _SheetHeading extends StatelessWidget {
  const _SheetHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = context.primaryColor;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('theme-picker-close'),
          tooltip: l10n.close,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
