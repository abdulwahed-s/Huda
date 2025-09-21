import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/presentation/widgets/settings/color_theme_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';

class ColorThemeSelectionSection extends StatelessWidget {
  const ColorThemeSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return ColorThemePicker(
            selectedTheme: themeState.colorTheme,
            onThemeSelected: (colorTheme) {
              context.read<ThemeCubit>().setColorTheme(colorTheme);
            },
          );
        },
      ),
    );
  }
}
