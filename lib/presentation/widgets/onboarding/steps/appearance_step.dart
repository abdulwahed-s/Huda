import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_theme.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/settings/color_theme_picker.dart';

class AppearanceStep extends StatefulWidget {
  const AppearanceStep({super.key});

  @override
  State<AppearanceStep> createState() => _AppearanceStepState();
}

class _AppearanceStepState extends State<AppearanceStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final themes = context.watch<ThemeCubit>();
    final state = themes.state;
    final onboarding = context.read<OnboardingCubit>();
    return OnboardingStepFrame(
      message: l10n.setupLookMessage,
      primary: OnboardingAction(
        l10n.continueButton,
        advances: true,
        onPressed: () => onboarding.next(),
      ),
      children: [
        HudaEyebrow(l10n.theme, header: true),
        SizedBox(height: space.sm),
        _ThemeModeChoice(
          selected: state.themeMode,
          state: state,
          onSelected: (mode) {
            if (mode == ThemeMode.system) {
              themes.useSystemTheme();
            } else {
              themes.toggleTheme(mode == ThemeMode.dark);
            }
          },
        ),
        SizedBox(height: space.xl),
        HudaEyebrow(l10n.colorTheme, header: true),
        SizedBox(height: space.sm),
        ColorThemePicker(
          selectedTheme: state.colorTheme,
          showHeader: false,
          onThemeSelected: (theme) {
            HudaHaptics.selection(context);
            themes.setColorTheme(theme);
          },
        ),
      ],
    );
  }
}

class _ThemeModeChoice extends StatelessWidget {
  const _ThemeModeChoice({
    required this.selected,
    required this.state,
    required this.onSelected,
  });

  final ThemeMode selected;
  final ThemeState state;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ThemeData build(Brightness brightness) => HudaTheme.build(
      colorTheme: state.colorTheme,
      brightness: brightness,
      fontFamily: state.fontFamily,
    );
    final light = build(Brightness.light);
    final dark = build(Brightness.dark);
    final modes = [
      (ThemeMode.light, l10n.setupThemeLight, _MiniPage(theme: light)),
      (ThemeMode.dark, l10n.setupThemeDark, _MiniPage(theme: dark)),
      (
        ThemeMode.system,
        l10n.setupThemeSystem,
        Row(
          children: [
            Expanded(
              child: _MiniPage(theme: light, half: _Half.start),
            ),
            Expanded(
              child: _MiniPage(theme: dark, half: _Half.end),
            ),
          ],
        ),
      ),
    ];
    return OnboardingOptionGrid(
      key: const ValueKey('onboarding-theme-mode'),
      minTileWidth: 96,
      maxColumns: 3,
      columnChoices: const [1, 3],
      children: [
        for (final (mode, label, page) in modes)
          OnboardingOption(
            key: ValueKey('onboarding-theme-${mode.name}'),
            title: label,
            selected: selected == mode,
            previewWidth: 64,
            preview: AspectRatio(aspectRatio: 1.25, child: page),
            onTap: () => onSelected(mode),
          ),
      ],
    );
  }
}

enum _Half { start, end }

class _MiniPage extends StatelessWidget {
  const _MiniPage({required this.theme, this.half});

  final ThemeData theme;
  final _Half? half;

  @override
  Widget build(BuildContext context) {
    final tokens = theme.extension<HudaTokens>()!;
    final scheme = theme.colorScheme;
    final r = Radius.circular(tokens.radius.sm);
    final radius = switch (half) {
      null => BorderRadius.all(r),
      _Half.start => BorderRadiusDirectional.horizontal(
        start: r,
      ).resolve(Directionality.of(context)),
      _Half.end => BorderRadiusDirectional.horizontal(
        end: r,
      ).resolve(Directionality.of(context)),
    };
    Widget bar(double width, Color color, {double height = 4}) =>
        FractionallySizedBox(
          widthFactor: width,
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: tokens.chromeGradient),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: bar(0.5, tokens.gilt, height: 3),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      bar(0.9, scheme.onSurface.withValues(alpha: 0.5)),
                      bar(0.6, scheme.onSurface.withValues(alpha: 0.3)),
                      bar(0.75, tokens.lit, height: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
