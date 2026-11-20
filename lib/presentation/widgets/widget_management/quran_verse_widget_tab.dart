import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/quran_widget_service.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/settings/language_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_choice_sheet.dart';
import 'package:huda/presentation/widgets/widget_management/widget_settings_parts.dart';

class QuranVerseWidgetTab extends StatefulWidget {
  const QuranVerseWidgetTab({super.key});

  @override
  State<QuranVerseWidgetTab> createState() => _QuranVerseWidgetTabState();
}

class _QuranVerseWidgetTabState extends State<QuranVerseWidgetTab> {
  late QuranWidgetSettings _settings;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _settings = QuranWidgetService.readSettings();
  }

  Future<void> _commit(QuranWidgetSettings next) async {
    setState(() => _settings = next);
    try {
      await QuranWidgetService.updateCustomization(next);
    } catch (error) {
      if (!mounted) return;
      _failed(error);
    }
  }

  void _failed(Object error) => showHudaToast(
    context,
    message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
    kind: HudaToastKind.failed,
  );

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await QuranWidgetService.refreshNow();
      if (!mounted) return;
      setState(() => _settings = QuranWidgetService.readSettings());
      showHudaToast(
        context,
        message: AppLocalizations.of(context)!.quranWidgetUpdated,
      );
    } catch (error) {
      if (mounted) _failed(error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _reset() async {
    if (!await confirmWidgetReset(context)) return;
    try {
      await QuranWidgetService.resetCustomization();
      if (mounted) {
        showHudaToast(
          context,
          message: AppLocalizations.of(context)!.widgetResetDone,
        );
      }
    } catch (error) {
      if (mounted) _failed(error);
    } finally {
      if (mounted) {
        setState(() => _settings = QuranWidgetService.readSettings());
      }
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final appLanguage = Localizations.localeOf(context).languageCode;
    final automatic = _settings.effectiveLanguage(appLanguage);
    final picked = await showSettingsChoiceSheet<QuranWidgetTranslationLanguage>(
      context: context,
      title: l10n.translationLanguage,
      description: l10n.translationLanguageDescription,
      selected: _settings.language,
      choices: [
        for (final language in QuranWidgetTranslationLanguage.values)
          SettingsChoice(
            key: ValueKey('widgets-language-${language.name}'),
            value: language,
            title: language == QuranWidgetTranslationLanguage.auto
                ? l10n.automatic
                : nativeLanguageName(language.code!),
            titleDirection: language == QuranWidgetTranslationLanguage.auto
                ? null
                : languageDirection(language.code!),
            subtitle: language == QuranWidgetTranslationLanguage.auto
                ? (automatic == null
                      ? l10n.arabicTranslationHidden
                      : l10n.translationSource(quranTranslationSource(automatic)))
                : quranTranslationSource(language.code),
          ),
      ],
    );
    if (picked != null && picked != _settings.language) {
      await _commit(_settings.copyWith(language: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final appPalette = AppColors.getColorScheme(
      context.select<ThemeCubit, AppColorTheme>((c) => c.state.colorTheme),
    );
    final effective = _settings.effectiveLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final palette = quranWidgetPalette(context, _settings.visualTheme);

    return WidgetSettingsLayout(
      preview: WidgetPreviewStage(
        child: QuranWidgetPreview(
          settings: _settings,
          palette: palette,
          source: effective == null ? null : quranTranslationSource(effective),
        ),
      ),
      add: WidgetAddSection(
        androidName: 'HudaGlanceWidgetReceiver',
        qualifiedAndroidName: 'com.aw.huda.widget.HudaGlanceWidgetReceiver',
        addLabel: l10n.addWidget,
      ),
      sections: [
        HudaSection(
          title: l10n.translationLanguage,
          children: [
            HudaSettingsRow(
              key: const ValueKey('widgets-quran-language'),
              icon: Icons.translate_rounded,
              title: _settings.language == QuranWidgetTranslationLanguage.auto
                  ? l10n.automatic
                  : nativeLanguageName(_settings.language.code!),
              subtitle: effective == null
                  ? l10n.arabicTranslationHidden
                  : l10n.translationSource(quranTranslationSource(effective)),
              trailing: Icon(
                Icons.unfold_more_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: _pickLanguage,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudaSectionHeader(l10n.quranWidgetTypography),
            HudaCard(
              padding: EdgeInsets.all(space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypeGroup(
                    sizeLabel: l10n.ayahTextSize,
                    autoFitLabel: l10n.ayahAutoFit,
                    boldLabel: l10n.boldAyah,
                    value: _settings.ayahTextSize,
                    autoFit: _settings.ayahAutoFit,
                    bold: _settings.ayahBold,
                    onAutoFit: (v) =>
                        _commit(_settings.copyWith(ayahAutoFit: v)),
                    onBold: (v) => _commit(_settings.copyWith(ayahBold: v)),
                    onSize: (v) => setState(
                      () => _settings = _settings.copyWith(ayahTextSize: v),
                    ),
                    onSizeEnd: (v) =>
                        _commit(_settings.copyWith(ayahTextSize: v)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: space.sm),
                    child: const Divider(height: 1),
                  ),
                  _TypeGroup(
                    sizeLabel: l10n.translationTextSize,
                    autoFitLabel: l10n.translationAutoFit,
                    boldLabel: l10n.boldTranslation,
                    value: _settings.translationTextSize,
                    autoFit: _settings.translationAutoFit,
                    bold: _settings.translationBold,
                    onAutoFit: (v) =>
                        _commit(_settings.copyWith(translationAutoFit: v)),
                    onBold: (v) =>
                        _commit(_settings.copyWith(translationBold: v)),
                    onSize: (v) => setState(
                      () => _settings = _settings.copyWith(
                        translationTextSize: v,
                      ),
                    ),
                    onSizeEnd: (v) =>
                        _commit(_settings.copyWith(translationTextSize: v)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudaSectionHeader(l10n.widgetTheme),
            HudaCard(
              padding: EdgeInsets.all(space.sm),
              child: WidgetThemeGrid(
                glyph: (color) => Text(
                  'آ',
                  textDirection: TextDirection.rtl,
                  textScaler: TextScaler.noScaling,
                  style: context.type.arabicTitle.copyWith(
                    color: color,
                    fontSize: 24,
                    height: 1,
                  ),
                ),
                swatches: [
                  for (final theme in QuranWidgetVisualTheme.values)
                    () {
                      final p = quranWidgetPalette(context, theme);
                      return WidgetThemeSwatch(
                        id: theme.name,
                        label: quranWidgetThemeLabel(l10n, theme),
                        background: theme == QuranWidgetVisualTheme.auto
                            ? appPalette.primary
                            : p.background,
                        foreground: theme == QuranWidgetVisualTheme.auto
                            ? appPalette.primaryVariant
                            : p.ayah,
                        automatic: theme == QuranWidgetVisualTheme.auto,
                        selected: _settings.visualTheme == theme,
                        onTap: () =>
                            _commit(_settings.copyWith(visualTheme: theme)),
                      );
                    }(),
                ],
              ),
            ),
          ],
        ),
        WidgetAdvancedSection(
          refreshLabel: l10n.forceQuranWidgetUpdate,
          refreshingLabel: l10n.quranWidgetUpdating,
          refreshing: _refreshing,
          onRefresh: _refresh,
          onReset: _reset,
        ),
      ],
    );
  }
}

class _TypeGroup extends StatelessWidget {
  const _TypeGroup({
    required this.sizeLabel,
    required this.autoFitLabel,
    required this.boldLabel,
    required this.value,
    required this.autoFit,
    required this.bold,
    required this.onAutoFit,
    required this.onBold,
    required this.onSize,
    required this.onSizeEnd,
  });

  final String sizeLabel;
  final String autoFitLabel;
  final String boldLabel;
  final int value;
  final bool autoFit;
  final bool bold;
  final ValueChanged<bool> onAutoFit;
  final ValueChanged<bool> onBold;
  final ValueChanged<int> onSize;
  final ValueChanged<int> onSizeEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetSizeControl(
          label: sizeLabel,
          value: value,
          min: 70,
          max: 140,
          automaticLabel: autoFit ? l10n.automatic : null,
          onChanged: onSize,
          onChangeEnd: onSizeEnd,
        ),
        WidgetSwitchRow(
          icon: Icons.fit_screen_rounded,
          label: autoFitLabel,
          value: autoFit,
          onChanged: onAutoFit,
        ),
        WidgetSwitchRow(
          icon: Icons.format_bold_rounded,
          label: boldLabel,
          value: bold,
          onChanged: onBold,
        ),
      ],
    );
  }
}

class QuranWidgetPreview extends StatelessWidget {
  const QuranWidgetPreview({
    super.key,
    required this.settings,
    required this.palette,
    required this.source,
  });

  final QuranWidgetSettings settings;
  final QuranWidgetPalette palette;

  final String? source;

  static const _ayah = 'فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final duration = tokens.motion.of(context, tokens.motion.medium);
    final curve = tokens.motion.standard;
    final ayahSize = settings.ayahAutoFit ? 1.0 : settings.ayahTextSize / 100;
    final translationSize = settings.translationAutoFit
        ? 1.0
        : settings.translationTextSize / 100;
    final source = this.source;
    final base = Theme.of(context).textTheme;
    return MediaQuery.withNoTextScaling(
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        padding: EdgeInsets.symmetric(horizontal: space.lg, vertical: space.md),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.ayah.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: curve,
              textAlign: TextAlign.center,
              style: context.type.ayah.copyWith(
                fontSize: 22 * ayahSize,
                height: 1.8,
                color: palette.ayah,
                fontWeight: settings.ayahBold
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
              child: const Text(_ayah, textDirection: TextDirection.rtl),
            ),
            if (source != null) ...[
              SizedBox(height: space.xxs),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: curve,
                textAlign: TextAlign.center,
                style: (base.bodySmall ?? const TextStyle()).copyWith(
                  fontSize: 13 * translationSize,
                  color: palette.translation,
                  fontWeight: settings.translationBold
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
                child: Text(source),
              ),
            ],
            SizedBox(height: space.xs),
            Text(
              '94:5',
              textDirection: TextDirection.ltr,
              style: base.labelSmall?.copyWith(
                color: palette.translation.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuranWidgetPalette {
  const QuranWidgetPalette({
    required this.background,
    required this.ayah,
    required this.translation,
  });

  final Color background;
  final Color ayah;
  final Color translation;
}

String quranTranslationSource(String? code) =>
    const {
      'en': 'Saheeh International',
      'tr': 'Diyanet İşleri',
      'fr': 'Muhammad Hamidullah',
      'de': 'Bubenheim & Elyas',
      'es': 'Julio Cortes',
      'ur': 'Fateh Muhammad Jalandhry',
      'ru': 'Elmir Kuliev',
      'ms': 'Abdullah Muhammad Basmeih',
      'bn': 'Muhiuddin Khan',
    }[code] ??
    'Saheeh International';

String quranWidgetThemeLabel(
  AppLocalizations l10n,
  QuranWidgetVisualTheme value,
) => switch (value) {
  QuranWidgetVisualTheme.auto => l10n.themeAuto,
  QuranWidgetVisualTheme.ocean => l10n.themeOcean,
  QuranWidgetVisualTheme.sunset => l10n.themeSunset,
  QuranWidgetVisualTheme.forest => l10n.themeForest,
  QuranWidgetVisualTheme.midnight => l10n.themeMidnight,
  QuranWidgetVisualTheme.sandstone => l10n.themeSandstone,
  QuranWidgetVisualTheme.rose => l10n.themeRose,
  QuranWidgetVisualTheme.lavender => l10n.themeLavender,
  QuranWidgetVisualTheme.charcoal => l10n.themeCharcoal,
  QuranWidgetVisualTheme.amber => l10n.themeAmber,
  QuranWidgetVisualTheme.arctic => l10n.themeArctic,
  QuranWidgetVisualTheme.burgundy => l10n.themeBurgundy,
  QuranWidgetVisualTheme.sage => l10n.themeSage,
};

QuranWidgetPalette quranWidgetPalette(
  BuildContext context,
  QuranWidgetVisualTheme theme,
) => switch (theme) {
  QuranWidgetVisualTheme.ocean => const QuranWidgetPalette(
    background: Color(0xFF1A3A5C),
    ayah: Color(0xFFF0F4F8),
    translation: Color(0xFFD2DEE8),
  ),
  QuranWidgetVisualTheme.sunset => const QuranWidgetPalette(
    background: Color(0xFF5C2A0E),
    ayah: Color(0xFFFFF5EB),
    translation: Color(0xFFE6D6C7),
  ),
  QuranWidgetVisualTheme.forest => const QuranWidgetPalette(
    background: Color(0xFF1B3A2A),
    ayah: Color(0xFFE8F5E9),
    translation: Color(0xFFC9DDCB),
  ),
  QuranWidgetVisualTheme.midnight => const QuranWidgetPalette(
    background: Color(0xFF121218),
    ayah: Color(0xFFE0E0E8),
    translation: Color(0xFFC9C6D5),
  ),
  QuranWidgetVisualTheme.sandstone => const QuranWidgetPalette(
    background: Color(0xFFF5E6D3),
    ayah: Color(0xFF3E2C1A),
    translation: Color(0xFF5E4932),
  ),
  QuranWidgetVisualTheme.rose => const QuranWidgetPalette(
    background: Color(0xFF3D1A2E),
    ayah: Color(0xFFFCE4EC),
    translation: Color(0xFFDFC5CF),
  ),
  QuranWidgetVisualTheme.lavender => const QuranWidgetPalette(
    background: Color(0xFF2E2450),
    ayah: Color(0xFFEDE7F6),
    translation: Color(0xFFCBC2DE),
  ),
  QuranWidgetVisualTheme.charcoal => const QuranWidgetPalette(
    background: Color(0xFF2C2C2C),
    ayah: Color(0xFFF5F5F5),
    translation: Color(0xFFD6D6D6),
  ),
  QuranWidgetVisualTheme.amber => const QuranWidgetPalette(
    background: Color(0xFF4A3000),
    ayah: Color(0xFFFFF8E1),
    translation: Color(0xFFE6D8AD),
  ),
  QuranWidgetVisualTheme.arctic => const QuranWidgetPalette(
    background: Color(0xFFE3F2FD),
    ayah: Color(0xFF0D2137),
    translation: Color(0xFF40566D),
  ),
  QuranWidgetVisualTheme.burgundy => const QuranWidgetPalette(
    background: Color(0xFF4A0E1E),
    ayah: Color(0xFFFDE8EF),
    translation: Color(0xFFE6BEC9),
  ),
  QuranWidgetVisualTheme.sage => const QuranWidgetPalette(
    background: Color(0xFF3B4A3A),
    ayah: Color(0xFFF1F5E8),
    translation: Color(0xFFD0DACA),
  ),
  QuranWidgetVisualTheme.auto => _autoPalette(context),
};

QuranWidgetPalette _autoPalette(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primary = AppColors.getColorScheme(
    context.read<ThemeCubit>().state.colorTheme,
  ).primary;
  final primaryRgb = primary.toARGB32() & 0x00FFFFFF;
  final isHudaTeal =
      isDark && const {0x14B8A6, 0x0D9488, 0x134E4A}.contains(primaryRgb);
  if (isHudaTeal) {
    return const QuranWidgetPalette(
      background: Color(0xFF061821),
      ayah: Color(0xFFF6F5EA),
      translation: Color(0xFFD7E7E5),
    );
  }
  final background = isDark
      ? Color.lerp(const Color(0xFF101212), primary, 0.18)!
      : Color.lerp(Colors.white, primary, 0.09)!;
  return QuranWidgetPalette(
    background: background,
    ayah: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF242424),
    translation: isDark ? const Color(0xFFD2D8DC) : const Color(0xFF4E5559),
  );
}
