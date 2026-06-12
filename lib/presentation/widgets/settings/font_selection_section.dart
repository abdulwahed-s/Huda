import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/presentation/widgets/settings/font_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';

class FontSelectionSection extends StatelessWidget {
  const FontSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return FontPicker(
            selectedFont: themeState.fontFamily,
            onFontSelected: (font) {
              context.read<ThemeCubit>().setFontFamily(font);
            },
          );
        },
      ),
    );
  }
}
