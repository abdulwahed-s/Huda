import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/quran_widget_service.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/widget_management/add_widget_section.dart';

class QuranVerseWidgetTab extends StatefulWidget {
  const QuranVerseWidgetTab({super.key, required this.isDark});

  final bool isDark;

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
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await QuranWidgetService.refreshNow();
      if (!mounted) return;
      setState(() => _settings = QuranWidgetService.readSettings());
      HudaSnackBar.success(
        context,
        message: AppLocalizations.of(context)!.quranWidgetUpdated,
      );
    } catch (error) {
      if (!mounted) return;
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetWidgetCustomization),
        content: Text(l10n.resetWidgetCustomizationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await QuranWidgetService.resetCustomization();
    } catch (error) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: l10n.errorUpdatingWidget('$error'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _settings = QuranWidgetService.readSettings());
      }
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<QuranWidgetTranslationLanguage>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return FractionallySizedBox(
          heightFactor: 0.84,
          child: Column(
            children: [
              _LanguageSheetHeader(
                title: l10n.translationLanguage,
                description: l10n.translationLanguageDescription,
                onClose: () => Navigator.pop(sheetContext),
              ),
              Divider(height: 1, color: Theme.of(sheetContext).dividerColor),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    12.h,
                    16.w,
                    20.h + MediaQuery.viewPaddingOf(sheetContext).bottom,
                  ),
                  itemCount: QuranWidgetTranslationLanguage.values.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final language =
                        QuranWidgetTranslationLanguage.values[index];
                    final automaticLanguage = _settings.effectiveLanguage(
                      Localizations.localeOf(sheetContext).languageCode,
                    );
                    return _LanguageOption(
                      title: _languageLabel(l10n, language),
                      subtitle: language == QuranWidgetTranslationLanguage.auto
                          ? (automaticLanguage == null
                                ? l10n.arabicTranslationHidden
                                : l10n.translationSource(
                                    _sourceName(automaticLanguage),
                                  ))
                          : _sourceName(language.code),
                      code: language.code,
                      selected: language == _settings.language,
                      onTap: () => Navigator.pop(sheetContext, language),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await _commit(_settings.copyWith(language: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        16.h + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(isDark: widget.isDark),
          SizedBox(height: 12.h),
          AddWidgetSection(isDark: widget.isDark),
          SizedBox(height: 20.h),
          _CustomizationHeading(title: l10n.quranWidgetCustomization),
          SizedBox(height: 12.h),
          _Section(
            title: l10n.translationLanguage,
            icon: Icons.translate_rounded,
            isDark: widget.isDark,
            child: _SelectionTile(
              title: _languageLabel(l10n, _settings.language),
              subtitle: _effectiveLanguage == null
                  ? l10n.arabicTranslationHidden
                  : l10n.translationSource(_sourceName(_effectiveLanguage)),
              icon: _settings.language == QuranWidgetTranslationLanguage.auto
                  ? Icons.language_rounded
                  : Icons.translate_rounded,
              onTap: _pickLanguage,
            ),
          ),
          _Section(
            title: l10n.quranWidgetTypography,
            icon: Icons.text_fields_rounded,
            isDark: widget.isDark,
            child: Column(
              children: [
                _TypographyGroup(
                  title: l10n.ayahTextSize,
                  previewText: 'آية',
                  previewFontFamily: 'Amiri',
                  autoFitLabel: l10n.ayahAutoFit,
                  boldLabel: l10n.boldAyah,
                  autoLabel: l10n.automatic,
                  value: _settings.ayahTextSize,
                  autoFit: _settings.ayahAutoFit,
                  bold: _settings.ayahBold,
                  onAutoFitChanged: (value) =>
                      _commit(_settings.copyWith(ayahAutoFit: value)),
                  onBoldChanged: (value) =>
                      _commit(_settings.copyWith(ayahBold: value)),
                  onSizeChanged: (value) => setState(
                    () => _settings = _settings.copyWith(ayahTextSize: value),
                  ),
                  onSizeChangeEnd: (value) =>
                      _commit(_settings.copyWith(ayahTextSize: value)),
                ),
                SizedBox(height: 12.h),
                _TypographyGroup(
                  title: l10n.translationTextSize,
                  previewText: 'Aa',
                  autoFitLabel: l10n.translationAutoFit,
                  boldLabel: l10n.boldTranslation,
                  autoLabel: l10n.automatic,
                  value: _settings.translationTextSize,
                  autoFit: _settings.translationAutoFit,
                  bold: _settings.translationBold,
                  onAutoFitChanged: (value) =>
                      _commit(_settings.copyWith(translationAutoFit: value)),
                  onBoldChanged: (value) =>
                      _commit(_settings.copyWith(translationBold: value)),
                  onSizeChanged: (value) => setState(
                    () => _settings = _settings.copyWith(
                      translationTextSize: value,
                    ),
                  ),
                  onSizeChangeEnd: (value) =>
                      _commit(_settings.copyWith(translationTextSize: value)),
                ),
              ],
            ),
          ),
          _Section(
            title: l10n.widgetTheme,
            icon: Icons.palette_outlined,
            isDark: widget.isDark,
            child: SizedBox(
              height: 108.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: QuranWidgetVisualTheme.values.length,
                separatorBuilder: (_, _) => SizedBox(width: 10.w),
                itemBuilder: (_, index) {
                  final theme = QuranWidgetVisualTheme.values[index];
                  return _ThemeCard(
                    label: _themeLabel(l10n, theme),
                    palette: _paletteFor(theme),
                    automatic: theme == QuranWidgetVisualTheme.auto,
                    selected: _settings.visualTheme == theme,
                    onTap: () =>
                        _commit(_settings.copyWith(visualTheme: theme)),
                  );
                },
              ),
            ),
          ),
          _Section(
            title: l10n.advanced,
            icon: Icons.settings_outlined,
            isDark: widget.isDark,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: FilledButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    icon: _refreshing
                        ? SizedBox.square(
                            dimension: 18.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _refreshing
                          ? l10n.quranWidgetUpdating
                          : l10n.forceQuranWidgetUpdate,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.42),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.resetWidgetCustomization),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? get _effectiveLanguage =>
      _settings.effectiveLanguage(Localizations.localeOf(context).languageCode);

  String _sourceName(String? code) =>
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

  String _languageLabel(
    AppLocalizations l10n,
    QuranWidgetTranslationLanguage value,
  ) => switch (value) {
    QuranWidgetTranslationLanguage.auto => l10n.automatic,
    QuranWidgetTranslationLanguage.en => l10n.english,
    QuranWidgetTranslationLanguage.tr => l10n.turkish,
    QuranWidgetTranslationLanguage.fr => l10n.french,
    QuranWidgetTranslationLanguage.de => l10n.german,
    QuranWidgetTranslationLanguage.es => l10n.spanish,
    QuranWidgetTranslationLanguage.ur => l10n.urdu,
    QuranWidgetTranslationLanguage.ru => l10n.russian,
    QuranWidgetTranslationLanguage.ms => l10n.malay,
    QuranWidgetTranslationLanguage.bn => l10n.bengali,
  };

  String _themeLabel(AppLocalizations l10n, QuranWidgetVisualTheme value) =>
      switch (value) {
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

  _Palette _paletteFor(QuranWidgetVisualTheme theme) => switch (theme) {
    QuranWidgetVisualTheme.ocean => const _Palette(
      background: Color(0xFF1A3A5C),
      ayah: Color(0xFFF0F4F8),
      translation: Color(0xFFD2DEE8),
    ),
    QuranWidgetVisualTheme.sunset => const _Palette(
      background: Color(0xFF5C2A0E),
      ayah: Color(0xFFFFF5EB),
      translation: Color(0xFFE6D6C7),
    ),
    QuranWidgetVisualTheme.forest => const _Palette(
      background: Color(0xFF1B3A2A),
      ayah: Color(0xFFE8F5E9),
      translation: Color(0xFFC9DDCB),
    ),
    QuranWidgetVisualTheme.midnight => const _Palette(
      background: Color(0xFF121218),
      ayah: Color(0xFFE0E0E8),
      translation: Color(0xFFC9C6D5),
    ),
    QuranWidgetVisualTheme.sandstone => const _Palette(
      background: Color(0xFFF5E6D3),
      ayah: Color(0xFF3E2C1A),
      translation: Color(0xFF5E4932),
    ),
    QuranWidgetVisualTheme.rose => const _Palette(
      background: Color(0xFF3D1A2E),
      ayah: Color(0xFFFCE4EC),
      translation: Color(0xFFDFC5CF),
    ),
    QuranWidgetVisualTheme.lavender => const _Palette(
      background: Color(0xFF2E2450),
      ayah: Color(0xFFEDE7F6),
      translation: Color(0xFFCBC2DE),
    ),
    QuranWidgetVisualTheme.charcoal => const _Palette(
      background: Color(0xFF2C2C2C),
      ayah: Color(0xFFF5F5F5),
      translation: Color(0xFFD6D6D6),
    ),
    QuranWidgetVisualTheme.amber => const _Palette(
      background: Color(0xFF4A3000),
      ayah: Color(0xFFFFF8E1),
      translation: Color(0xFFE6D8AD),
    ),
    QuranWidgetVisualTheme.arctic => const _Palette(
      background: Color(0xFFE3F2FD),
      ayah: Color(0xFF0D2137),
      translation: Color(0xFF40566D),
    ),
    QuranWidgetVisualTheme.burgundy => const _Palette(
      background: Color(0xFF4A0E1E),
      ayah: Color(0xFFFDE8EF),
      translation: Color(0xFFE6BEC9),
    ),
    QuranWidgetVisualTheme.sage => const _Palette(
      background: Color(0xFF3B4A3A),
      ayah: Color(0xFFF1F5E8),
      translation: Color(0xFFD0DACA),
    ),
    QuranWidgetVisualTheme.auto => _autoPalette(),
  };

  _Palette _autoPalette() {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryRgb = primary.toARGB32() & 0x00FFFFFF;
    final isHudaTeal =
        widget.isDark &&
        const {0x14B8A6, 0x0D9488, 0x134E4A}.contains(primaryRgb);
    if (isHudaTeal) {
      return const _Palette(
        background: Color(0xFF061821),
        ayah: Color(0xFFF6F5EA),
        translation: Color(0xFFD7E7E5),
      );
    }
    final background = widget.isDark
        ? Color.lerp(const Color(0xFF101212), primary, 0.18)!
        : Color.lerp(Colors.white, primary, 0.09)!;
    return _Palette(
      background: background,
      ayah: widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF242424),
      translation: widget.isDark
          ? const Color(0xFFD2D8DC)
          : const Color(0xFF4E5559),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            accent.withValues(alpha: isDark ? 0.26 : 0.16),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.menu_book_rounded, color: accent, size: 27.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quranVerseWidget,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  l10n.quranWidgetTagline,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizationHeading extends StatelessWidget {
  const _CustomizationHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: colorScheme.primary,
            size: 19.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17.sp,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, size: 17.sp, color: colorScheme.primary),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 21.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypographyGroup extends StatelessWidget {
  const _TypographyGroup({
    required this.title,
    required this.previewText,
    this.previewFontFamily,
    required this.autoFitLabel,
    required this.boldLabel,
    required this.autoLabel,
    required this.value,
    required this.autoFit,
    required this.bold,
    required this.onAutoFitChanged,
    required this.onBoldChanged,
    required this.onSizeChanged,
    required this.onSizeChangeEnd,
  });

  final String title;
  final String previewText;
  final String? previewFontFamily;
  final String autoFitLabel;
  final String boldLabel;
  final String autoLabel;
  final int value;
  final bool autoFit;
  final bool bold;
  final ValueChanged<bool> onAutoFitChanged;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<int> onSizeChanged;
  final ValueChanged<int> onSizeChangeEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sliderEnabled = !autoFit;
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Text(
                  previewText,
                  textDirection: previewFontFamily == null
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: previewFontFamily,
                    fontSize: (20 * (value / 100)).clamp(15, 27).sp,
                    height: 1,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: BoxConstraints(minWidth: 54.w),
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  sliderEnabled ? '$value%' : autoLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: sliderEnabled ? 1 : 0.44,
            child: Row(
              children: [
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 70,
                    max: 140,
                    divisions: 14,
                    value: value.toDouble(),
                    label: '$value%',
                    onChanged: sliderEnabled
                        ? (next) => onSizeChanged(next.round())
                        : null,
                    onChangeEnd: sliderEnabled
                        ? (next) => onSizeChangeEnd(next.round())
                        : null,
                  ),
                ),
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 12.h),
          _TypographyToggle(
            icon: Icons.fit_screen_rounded,
            label: autoFitLabel,
            value: autoFit,
            onChanged: onAutoFitChanged,
          ),
          Divider(height: 8.h),
          _TypographyToggle(
            icon: Icons.format_bold_rounded,
            label: boldLabel,
            value: bold,
            onChanged: onBoldChanged,
          ),
        ],
      ),
    );
  }
}

class _TypographyToggle extends StatelessWidget {
  const _TypographyToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            Icon(icon, size: 19.sp, color: colorScheme.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheetHeader extends StatelessWidget {
  const _LanguageSheetHeader({
    required this.title,
    required this.description,
    required this.onClose,
  });

  final String title;
  final String description;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 2.h, 12.w, 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: colorScheme.primary,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: code == null
                      ? Icon(
                          Icons.language_rounded,
                          size: 20.sp,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        )
                      : Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            code!.toUpperCase(),
                            style: TextStyle(
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          height: 1.35,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.palette,
    required this.automatic,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _Palette palette;
  final bool automatic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 80.w,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? accent : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (automatic)
                Icon(Icons.palette_outlined, color: accent, size: 24.sp)
              else
                Text(
                  'آ',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: palette.ayah,
                    fontFamily: 'Amiri',
                    fontSize: 25.sp,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: automatic
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : palette.translation,
                    fontSize: 11.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Icon(Icons.check_circle, color: accent, size: 16.sp),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.background,
    required this.ayah,
    required this.translation,
  });

  final Color background;
  final Color ayah;
  final Color translation;
}
