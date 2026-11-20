import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/home_customization/home_theme_preview.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';

class FocusStep extends StatefulWidget {
  const FocusStep({super.key});

  static String titleOf(AppLocalizations l10n, HomeThemeId theme) =>
      switch (theme) {
        HomeThemeId.prayerToday => l10n.setupFocusPrayer,
        HomeThemeId.quranJourney => l10n.setupFocusQuran,
        HomeThemeId.classic => l10n.setupFocusEverything,
      };

  @override
  State<FocusStep> createState() => _FocusStepState();
}

class _FocusStepState extends State<FocusStep> {
  late HomeThemeId _theme = OnboardingScope.read(
    context,
  ).environment.homePreferences.load().selectedTheme;

  Future<void> _save() async {
    final preferences = OnboardingScope.read(
      context,
    ).environment.homePreferences;
    await preferences.save(preferences.load().copyWith(selectedTheme: _theme));
    if (!mounted) return;
    context.read<OnboardingCubit>().next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    String description(HomeThemeId theme) => switch (theme) {
      HomeThemeId.prayerToday => l10n.themePrayerTodayDescription,
      HomeThemeId.quranJourney => l10n.themeQuranJourneyDescription,
      HomeThemeId.classic => l10n.themeClassicDescription,
    };
    return OnboardingStepFrame(
      message: l10n.setupFocusMessage,
      primary: OnboardingAction(
        l10n.continueButton,
        advances: true,
        onPressed: _save,
      ),
      children: [
        OnboardingOptionGrid(
          minTileWidth: 100,
          maxColumns: 3,
          columnChoices: const [1, 3],
          children: [
            for (final theme in const [
              HomeThemeId.prayerToday,
              HomeThemeId.quranJourney,
              HomeThemeId.classic,
            ])
              OnboardingOption(
                key: ValueKey('onboarding-focus-${theme.name}'),
                title: FocusStep.titleOf(l10n, theme),
                selected: _theme == theme,
                previewWidth: 72,
                preview: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: FittedBox(
                    child: SizedBox(
                      width: 120,
                      height: 160,
                      child: HomeThemePreview(theme: theme),
                    ),
                  ),
                ),
                onTap: () => setState(() => _theme = theme),
              ),
          ],
        ),
        SizedBox(height: space.md),
        HudaStateSwitcher(
          stateKey: _theme,
          child: Row(
            key: ValueKey(_theme),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: space.xs),
              Expanded(
                child: Text(
                  description(_theme),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
