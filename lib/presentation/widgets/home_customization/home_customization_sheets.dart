import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';

Future<void> showHomeThemePicker(BuildContext context) {
  final cubit = context.read<HomeCustomizationCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _HomeThemePickerSheet()),
  );
}

class _HomeThemePickerSheet extends StatelessWidget {
  const _HomeThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomNavigationInset = MediaQuery.viewPaddingOf(context).bottom;
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
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + bottomNavigationInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeStyle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('theme-picker-close'),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (
                var index = 0;
                index < HomeThemeId.values.length;
                index++
              ) ...[
                _ThemeChoice(
                  theme: HomeThemeId.values[index],
                  selected: HomeThemeId.values[index] == selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<HomeCustomizationCubit>().selectTheme(
                      HomeThemeId.values[index],
                    );
                    Navigator.of(context).pop();
                  },
                ),
                if (index != HomeThemeId.values.length - 1)
                  const SizedBox(height: 10),
              ],
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
    required this.selected,
    required this.onTap,
  });

  final HomeThemeId theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final name = homeThemeName(context, theme);
    final description = homeThemeDescription(context, theme);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name. $description',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: ValueKey('theme-picker-choice-${theme.name}'),
        color: selected
            ? accent.withValues(alpha: 0.09)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(homeThemeIcon(theme), color: accent, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  child: selected
                      ? Container(
                          key: ValueKey('theme-picker-selected-${theme.name}'),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : SizedBox.square(
                          key: ValueKey(
                            'theme-picker-unselected-${theme.name}',
                          ),
                          dimension: 28,
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
