import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/settings/language_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';

class LanguageSelectionSection extends StatelessWidget {
  const LanguageSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: BlocBuilder<LocalizationCubit, LocalizationState>(
        builder: (context, localizationState) {
          return LanguagePicker(
            selectedLocale: localizationState.locale,
            onLocaleSelected: (locale) {
              context.read<LocalizationCubit>().setLocale(locale);
            },
          );
        },
      ),
    );
  }
}

