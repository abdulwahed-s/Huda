import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';

const Map<String, String> onboardingGreetings = {
  'en': 'Welcome',
  'ar': 'أهلًا وسهلًا',
  'tr': 'Hoş geldiniz',
  'fr': 'Bienvenue',
  'es': 'Bienvenido',
  'de': 'Willkommen',
  'ru': 'Добро пожаловать',
  'ur': 'خوش آمدید',
  'ms': 'Selamat datang',
  'bn': 'স্বাগতম',
};

const Set<String> _rtlLanguages = {'ar', 'ur'};

class WelcomeLanguageStep extends StatefulWidget {
  const WelcomeLanguageStep({super.key});

  @override
  State<WelcomeLanguageStep> createState() => _WelcomeLanguageStepState();
}

class _WelcomeLanguageStepState extends State<WelcomeLanguageStep> {
  String? _pending;

  Future<void> _choose(Locale locale) async {
    HudaHaptics.selection(context);
    setState(() => _pending = locale.languageCode);
    await OnboardingScope.read(context).switchLanguage(locale);
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final current = context.watch<LocalizationCubit>().state.locale;
    final chosen = _pending ?? current.languageCode;
    final veil = OnboardingScope.of(context).veil;
    return OnboardingStepFrame(
      veilContent: false,
      primary: OnboardingAction(
        l10n.getStarted,
        advances: true,
        key: const ValueKey('onboarding-get-started'),
        onPressed: () => context.read<OnboardingCubit>().next(),
      ),
      children: [
        FadeTransition(
          opacity: veil,
          child: HudaEyebrow(l10n.language, header: true),
        ),
        SizedBox(height: space.sm),
        _LanguageGrid(
          children: [
            for (final locale in LocalizationCubit.supportedLocales)
              _LanguageTile(
                key: ValueKey('onboarding-language-${locale.languageCode}'),
                code: locale.languageCode,
                selected: locale.languageCode == chosen,
                onTap: () => _choose(locale),
              ),
          ],
        ),
      ],
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minTile = 150 * scale;
        var columns = ((constraints.maxWidth + space.xs) / (minTile + space.xs))
            .floor()
            .clamp(1, 5);
        if (columns > 2 && columns < 5) columns = 2;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: space.xs));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: space.xs),
                    Expanded(
                      child: i + j < children.length
                          ? children[i + j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final name = LocalizationCubit.languageNames[code] ?? code;
    final greeting = onboardingGreetings[code] ?? name;
    final direction = _rtlLanguages.contains(code)
        ? TextDirection.rtl
        : TextDirection.ltr;
    final foreground = selected ? tokens.onChrome : scheme.onSurface;
    final muted = selected ? tokens.onChromeMuted : scheme.onSurfaceVariant;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final shape = HudaLanternBorder(
      radius: tokens.radius.md,
      engraving: selected ? tokens.onChrome.withValues(alpha: 0.24) : null,
      side: selected ? BorderSide.none : BorderSide(color: scheme.outline),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: name,
      excludeSemantics: true,
      child: HudaPressable(
        child: AnimatedContainer(
          duration: duration,
          decoration: ShapeDecoration(
            color: selected ? tokens.lit : scheme.surface,
            shape: shape,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: selected ? null : onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: space.md,
                    vertical: space.xs,
                  ),
                  child: Directionality(
                    textDirection: direction,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: duration,
                          style: (textTheme.titleMedium ?? const TextStyle())
                              .copyWith(color: foreground),
                          child: Text(name),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: duration,
                          style: (textTheme.bodySmall ?? const TextStyle())
                              .copyWith(color: muted),
                          child: Text(greeting),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
