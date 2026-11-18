import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';

/// Light, dark or the device's setting, as one segmented control (the lit
/// segment is the choice). The three labels stack when a third of the
/// width can't hold them (narrow windows at large text).
class ThemeModeControl extends StatelessWidget {
  const ThemeModeControl({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mode = context.select<ThemeCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );
    final scale = math.min(MediaQuery.textScalerOf(context).scale(16) / 16, 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Icons go first when space is short; the labels stack only when
        // a third of the width can't hold them.
        final third = constraints.maxWidth / 3;
        final icons = third >= 124 * scale;
        final stacked = third < 80 * scale;
        return SegmentedButton<ThemeMode>(
          key: const ValueKey('settings-theme-mode'),
          direction: stacked ? Axis.vertical : Axis.horizontal,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              icon: icons ? const Icon(Icons.light_mode_outlined) : null,
              label: Text(
                l10n.setupThemeLight,
                textAlign: TextAlign.center,
                key: const ValueKey('settings-theme-light'),
              ),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: icons ? const Icon(Icons.dark_mode_outlined) : null,
              label: Text(
                l10n.setupThemeDark,
                textAlign: TextAlign.center,
                key: const ValueKey('settings-theme-dark'),
              ),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: icons ? const Icon(Icons.brightness_auto_outlined) : null,
              label: Text(
                l10n.setupThemeSystem,
                textAlign: TextAlign.center,
                key: const ValueKey('settings-theme-system'),
              ),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            final next = selection.first;
            if (next == mode) return;
            HudaHaptics.selection(context);
            final themes = context.read<ThemeCubit>();
            if (next == ThemeMode.system) {
              themes.useSystemTheme();
            } else {
              themes.toggleTheme(next == ThemeMode.dark);
            }
          },
        );
      },
    );
  }
}
