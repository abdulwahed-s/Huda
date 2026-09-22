import 'dart:math' as math;

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
    await QuranWidgetService.updateCustomization(next);
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
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await QuranWidgetService.resetCustomization();
    if (mounted) setState(() => _settings = QuranWidgetService.readSettings());
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<QuranWidgetTranslationLanguage>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: RadioGroup<QuranWidgetTranslationLanguage>(
            groupValue: _settings.language,
            onChanged: (value) => Navigator.pop(sheetContext, value),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: 12.h),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
                  child: Text(
                    l10n.translationLanguage,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final language in QuranWidgetTranslationLanguage.values)
                  RadioListTile<QuranWidgetTranslationLanguage>(
                    value: language,
                    title: Text(_languageLabel(l10n, language)),
                    subtitle: language == QuranWidgetTranslationLanguage.auto
                        ? Text(l10n.translationLanguageDescription)
                        : Text(_sourceName(language.code)),
                  ),
              ],
            ),
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
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.quranWidgetCustomization,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _Section(
            title: l10n.translationLanguage,
            isDark: widget.isDark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                child: Icon(
                  Icons.translate_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(_languageLabel(l10n, _settings.language)),
              subtitle: Text(
                _effectiveLanguage == null
                    ? l10n.arabicTranslationHidden
                    : l10n.translationSource(
                        _sourceName(_effectiveLanguage),
                      ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickLanguage,
            ),
          ),
          _Section(
            title: l10n.quranWidgetTypography,
            isDark: widget.isDark,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.ayahAutoFit,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _settings.ayahAutoFit,
                  onChanged: (value) => _commit(
                    _settings.copyWith(ayahAutoFit: value),
                  ),
                ),
                _TextSizeControl(
                  label: l10n.ayahTextSize,
                  autoLabel: l10n.automatic,
                  value: _settings.ayahTextSize,
                  enabled: !_settings.ayahAutoFit,
                  onChanged: (value) => setState(
                    () => _settings = _settings.copyWith(ayahTextSize: value),
                  ),
                  onChangeEnd: (value) => _commit(
                    _settings.copyWith(ayahTextSize: value),
                  ),
                ),
                Divider(height: 24.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.translationAutoFit,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _settings.translationAutoFit,
                  onChanged: (value) => _commit(
                    _settings.copyWith(translationAutoFit: value),
                  ),
                ),
                _TextSizeControl(
                  label: l10n.translationTextSize,
                  autoLabel: l10n.automatic,
                  value: _settings.translationTextSize,
                  enabled: !_settings.translationAutoFit,
                  onChanged: (value) => setState(
                    () => _settings =
                        _settings.copyWith(translationTextSize: value),
                  ),
                  onChangeEnd: (value) => _commit(
                    _settings.copyWith(translationTextSize: value),
                  ),
                ),
                Divider(height: 16.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.format_bold_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.boldAyah,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _settings.ayahBold,
                  onChanged: (value) => _commit(
                    _settings.copyWith(ayahBold: value),
                  ),
                ),
                Divider(height: 8.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.format_bold_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.boldTranslation,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: _settings.translationBold,
                  onChanged: (value) => _commit(
                    _settings.copyWith(translationBold: value),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: l10n.widgetTheme,
            isDark: widget.isDark,
            child: SizedBox(
              height: 108.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: QuranWidgetVisualTheme.values.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (_, index) {
                  final theme = QuranWidgetVisualTheme.values[index];
                  return _ThemeCard(
                    label: _themeLabel(l10n, theme),
                    palette: _paletteFor(theme),
                    selected: _settings.visualTheme == theme,
                    onTap: () => _commit(
                      _settings.copyWith(visualTheme: theme),
                    ),
                  );
                },
              ),
            ),
          ),
          _Section(
            title: l10n.advanced,
            isDark: widget.isDark,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: FilledButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    icon: _refreshing
                        ? SizedBox.square(
                            dimension: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: OutlinedButton.icon(
                    onPressed: _reset,
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
  ) =>
      switch (value) {
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
        QuranWidgetVisualTheme.forest => l10n.themeForest,
        QuranWidgetVisualTheme.ocean => l10n.themeOcean,
        QuranWidgetVisualTheme.sandstone => l10n.themeSandstone,
        QuranWidgetVisualTheme.midnight => l10n.themeMidnight,
        QuranWidgetVisualTheme.burgundy => l10n.themeBurgundy,
        QuranWidgetVisualTheme.lavender => l10n.themeLavender,
      };

  _Palette _paletteFor(QuranWidgetVisualTheme theme) => switch (theme) {
        QuranWidgetVisualTheme.forest => const _Palette(
            background: Color(0xFF1B3A2A),
            card: Color(0xFF244D38),
            ayah: Color(0xFFE8F5E9),
            translation: Color(0xFFC9DDCB),
            accent: Color(0xFF81C784),
          ),
        QuranWidgetVisualTheme.ocean => const _Palette(
            background: Color(0xFF1A3A5C),
            card: Color(0xFF244B73),
            ayah: Color(0xFFF0F4F8),
            translation: Color(0xFFD2DEE8),
            accent: Color(0xFF4DD0E1),
          ),
        QuranWidgetVisualTheme.sandstone => const _Palette(
            background: Color(0xFFF5E6D3),
            card: Color(0xFFFFF8EF),
            ayah: Color(0xFF3E2C1A),
            translation: Color(0xFF5E4932),
            accent: Color(0xFFA83D15),
            ornament: Color(0xFFC18445),
            isLight: true,
          ),
        QuranWidgetVisualTheme.midnight => const _Palette(
            background: Color(0xFF121218),
            card: Color(0xFF20202A),
            ayah: Color(0xFFF3F0FA),
            translation: Color(0xFFC9C6D5),
            accent: Color(0xFF9FA8DA),
          ),
        QuranWidgetVisualTheme.burgundy => const _Palette(
            background: Color(0xFF4A0E1E),
            card: Color(0xFF62152A),
            ayah: Color(0xFFFDE8EF),
            translation: Color(0xFFE6BEC9),
            accent: Color(0xFFFF8A80),
          ),
        QuranWidgetVisualTheme.lavender => const _Palette(
            background: Color(0xFF2E2450),
            card: Color(0xFF3D3168),
            ayah: Color(0xFFEDE7F6),
            translation: Color(0xFFCBC2DE),
            accent: Color(0xFFD59BE6),
          ),
        QuranWidgetVisualTheme.auto => _autoPalette(),
      };

  _Palette _autoPalette() {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryRgb = primary.toARGB32() & 0x00FFFFFF;
    final isHudaTeal = widget.isDark &&
        const {0x14B8A6, 0x0D9488, 0x134E4A}.contains(primaryRgb);
    if (isHudaTeal) {
      return const _Palette(
        background: Color(0xFF061821),
        card: Color(0xFF0A3339),
        ayah: Color(0xFFF6F5EA),
        translation: Color(0xFFD7E7E5),
        accent: Color(0xFF62E6D2),
      );
    }
    final background = widget.isDark
        ? Color.lerp(const Color(0xFF101212), primary, 0.18)!
        : Color.lerp(Colors.white, primary, 0.09)!;
    final card = widget.isDark
        ? Color.lerp(background, Colors.white, 0.08)!
        : Color.lerp(background, Colors.white, 0.72)!;
    return _Palette(
      background: background,
      card: card,
      ayah: widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF242424),
      translation:
          widget.isDark ? const Color(0xFFD2D8DC) : const Color(0xFF4E5559),
      accent: primary,
      ornament:
          widget.isDark ? const Color(0xFFD9BE72) : const Color(0xFFC18445),
      isLight: !widget.isDark,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.34 : 0.20),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23.r,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(Icons.menu_book_rounded, color: accent, size: 25.sp),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quranVerseWidget,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  l10n.quranWidgetTagline,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.black54,
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.isDark,
    required this.child,
  });

  final String title;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            child,
          ],
        ),
      );
}

class _TextSizeControl extends StatelessWidget {
  const _TextSizeControl({
    required this.label,
    required this.autoLabel,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final String autoLabel;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.38);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.62,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 20.sp,
                color: foreground,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? null : foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: 52.w),
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  enabled ? '$value%' : autoLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          Slider(
            min: 70,
            max: 140,
            divisions: 14,
            value: value.toDouble(),
            label: '$value%',
            onChanged: enabled ? (next) => onChanged(next.round()) : null,
            onChangeEnd: enabled ? (next) => onChangeEnd(next.round()) : null,
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _Palette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 94.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.card,
                  palette.background,
                  palette.background,
                ],
                stops: const [0, 0.58, 1],
              ),
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : palette.accent.withValues(alpha: 0.45),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NoorThemeGeometryPainter(palette),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(7.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              padding: EdgeInsets.all(3.5.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.accent.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.42),
                                  width: 0.7,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/huda.png',
                                color: palette.ayah,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 13.h,
                              width: 31.w,
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              decoration: BoxDecoration(
                                color: palette.ayah.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: palette.ayah.withValues(alpha: 0.16),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 2.5.w,
                                    height: 2.5.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: palette.ornament,
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color:
                                          palette.ayah.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'آية',
                          style: TextStyle(
                            color: palette.ayah,
                            fontFamily: 'Amiri',
                            fontSize: 16.sp,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12.w,
                              height: 0.7,
                              color: palette.accent.withValues(alpha: 0.48),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 3.w),
                              width: 2.5.w,
                              height: 2.5.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.ornament,
                              ),
                            ),
                            Container(
                              width: 12.w,
                              height: 0.7,
                              color: palette.accent.withValues(alpha: 0.48),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.translation,
                            fontSize: 9.sp,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NoorThemeGeometryPainter extends CustomPainter {
  const _NoorThemeGeometryPainter(this.palette);

  final _Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.accent.withValues(alpha: palette.isLight ? 0.13 : 0.22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.18),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = palette.accent.withValues(alpha: palette.isLight ? 0.10 : 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final arch = Path()
      ..moveTo(size.width * 0.18, size.height * 0.94)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.52,
        size.width * 0.35,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.09,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.22,
        size.width * 0.82,
        size.height * 0.52,
        size.width * 0.82,
        size.height * 0.94,
      );
    canvas.drawPath(arch, linePaint);

    final star = Path();
    final center = Offset(size.width * 0.96, size.height * 0.05);
    final outer = math.min(size.width, size.height) * 0.26;
    for (var index = 0; index < 16; index++) {
      final angle = -math.pi / 2 + index * math.pi / 8;
      final radius = index.isEven ? outer : outer * 0.46;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..color = palette.ornament.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _NoorThemeGeometryPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _Palette {
  const _Palette({
    required this.background,
    required this.card,
    required this.ayah,
    required this.translation,
    required this.accent,
    this.ornament = const Color(0xFFD9BE72),
    this.isLight = false,
  });

  final Color background;
  final Color card;
  final Color ayah;
  final Color translation;
  final Color accent;
  final Color ornament;
  final bool isLight;
}
