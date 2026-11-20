import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/settings/settings_choice_sheet.dart';

String localizedLanguageName(AppLocalizations l10n, String code) =>
    switch (code) {
      'en' => l10n.english,
      'ar' => l10n.arabic,
      'tr' => l10n.turkish,
      'fr' => l10n.french,
      'es' => l10n.spanish,
      'de' => l10n.german,
      'ru' => l10n.russian,
      'ur' => l10n.urdu,
      'ms' => l10n.malay,
      'bn' => l10n.bengali,
      _ => code.toUpperCase(),
    };

String nativeLanguageName(String code) =>
    LocalizationCubit.languageNames[code] ?? code.toUpperCase();

TextDirection languageDirection(String code) =>
    const {'ar', 'ur'}.contains(code) ? TextDirection.rtl : TextDirection.ltr;

class LanguageRow extends StatelessWidget {
  const LanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocalizationCubit>().state.locale;
    return HudaSettingsRow(
      key: const ValueKey('settings-language'),
      icon: Icons.translate_rounded,
      title: l10n.language,
      subtitle: nativeLanguageName(locale.languageCode),
      trailing: Icon(
        Icons.unfold_more_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () => _choose(context, locale),
    );
  }

  Future<void> _choose(BuildContext context, Locale current) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<LocalizationCubit>();
    final picked = await showSettingsChoiceSheet<Locale>(
      context: context,
      title: l10n.language,
      selected: current,
      choices: [
        for (final locale in LocalizationCubit.supportedLocales)
          SettingsChoice(
            key: ValueKey('settings-language-${locale.languageCode}'),
            value: locale,
            title: nativeLanguageName(locale.languageCode),
            titleDirection: languageDirection(locale.languageCode),
            subtitle: locale.languageCode == current.languageCode
                ? null
                : localizedLanguageName(l10n, locale.languageCode),
          ),
      ],
    );
    if (picked != null && picked != current) {
      await cubit.setLocale(picked);
    }
  }
}
