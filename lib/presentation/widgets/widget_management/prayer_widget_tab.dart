import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/settings/language_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_choice_sheet.dart';
import 'package:huda/presentation/widgets/widget_management/widget_settings_parts.dart';

/// The Prayer Times widget: its live preview, how to add it, and its
/// design, theme, size, language and time format.
class PrayerWidgetTab extends StatefulWidget {
  const PrayerWidgetTab({super.key});

  @override
  State<PrayerWidgetTab> createState() => _PrayerWidgetTabState();
}

class _PrayerWidgetTabState extends State<PrayerWidgetTab> {
  late PrayerWidgetSettings _settings;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _settings = PrayerWidgetService.readSettings();
  }

  void _failed(Object error) => showHudaToast(
    context,
    message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
    kind: HudaToastKind.failed,
  );

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await PrayerWidgetService.forceUpdate();
      if (!mounted) return;
      showHudaToast(
        context,
        message: AppLocalizations.of(context)!.prayerWidgetUpdated,
      );
    } catch (error) {
      if (mounted) _failed(error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _commit(PrayerWidgetSettings next) async {
    setState(() => _settings = next);
    try {
      await PrayerWidgetService.updateCustomization(next);
    } catch (error) {
      if (!mounted) return;
      setState(() => _settings = PrayerWidgetService.readSettings());
      _failed(error);
    }
  }

  Future<void> _reset() async {
    if (!await confirmWidgetReset(context)) return;
    try {
      await PrayerWidgetService.resetCustomization();
      if (!mounted) return;
      setState(() => _settings = PrayerWidgetService.readSettings());
      showHudaToast(
        context,
        message: AppLocalizations.of(context)!.widgetResetDone,
      );
    } catch (error) {
      if (mounted) _failed(error);
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showSettingsChoiceSheet<PrayerWidgetLanguage>(
      context: context,
      title: l10n.language,
      selected: _settings.language,
      choices: [
        for (final language in PrayerWidgetLanguage.values)
          SettingsChoice(
            key: ValueKey('widgets-language-${language.name}'),
            value: language,
            title: language == PrayerWidgetLanguage.auto
                ? l10n.automatic
                : nativeLanguageName(language.code),
            titleDirection: language == PrayerWidgetLanguage.auto
                ? null
                : languageDirection(language.code),
            subtitle: language == PrayerWidgetLanguage.auto
                ? nativeLanguageName(
                    Localizations.localeOf(context).languageCode,
                  )
                : localizedLanguageName(l10n, language.code),
          ),
      ],
    );
    if (picked != null && picked != _settings.language) {
      await _commit(_settings.copyWith(language: picked));
    }
  }

  PrayerWidgetTimeFormat _effectiveTimeFormat(BuildContext context) {
    if (_settings.timeFormat != PrayerWidgetTimeFormat.system) {
      return _settings.timeFormat;
    }
    return MediaQuery.alwaysUse24HourFormatOf(context)
        ? PrayerWidgetTimeFormat.twentyFourHour
        : PrayerWidgetTimeFormat.twelveHour;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final appPalette = AppColors.getColorScheme(
      context.select<ThemeCubit, AppColorTheme>((c) => c.state.colorTheme),
    );
    final scheme = Theme.of(context).colorScheme;
    final colors = prayerWidgetColors(context, _settings.visualTheme);
    final timeFormat = _effectiveTimeFormat(context);
    final languageCode = _settings.language == PrayerWidgetLanguage.auto
        ? Localizations.localeOf(context).languageCode
        : _settings.language.code;

    return WidgetSettingsLayout(
      preview: WidgetPreviewStage(
        child: PrayerWidgetPreview(
          design: _settings.design,
          colors: colors,
          contentSize: _settings.contentSize,
          twentyFourHour: timeFormat == PrayerWidgetTimeFormat.twentyFourHour,
          languageCode: languageCode,
        ),
      ),
      add: WidgetAddSection(
        androidName: 'PrayerWidgetReceiver',
        qualifiedAndroidName: PrayerWidgetService.androidReceiverName,
        addLabel: l10n.addPrayerWidget,
      ),
      sections: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudaSectionHeader(l10n.design),
            for (final design in PrayerWidgetDesign.values) ...[
              if (design != PrayerWidgetDesign.values.first)
                SizedBox(height: space.xs),
              HudaChoiceRow(
                key: ValueKey('widgets-design-${design.name}'),
                leading: SizedBox(
                  width: 56,
                  height: 44,
                  child: CustomPaint(
                    painter: _DesignMiniaturePainter(
                      design: design,
                      colors: colors,
                    ),
                  ),
                ),
                title: design == PrayerWidgetDesign.hero
                    ? l10n.designHero
                    : l10n.designCompact,
                subtitle: design == PrayerWidgetDesign.hero
                    ? l10n.designHeroDescription
                    : l10n.designCompactDescription,
                selected: _settings.design == design,
                onTap: () {
                  if (_settings.design == design) return;
                  HudaHaptics.selection(context);
                  _commit(_settings.copyWith(design: design));
                },
              ),
            ],
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
                  'Aa',
                  textDirection: TextDirection.ltr,
                  textScaler: TextScaler.noScaling,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color, height: 1),
                ),
                swatches: [
                  for (final theme in PrayerWidgetVisualTheme.values)
                    () {
                      final c = prayerWidgetColors(context, theme);
                      return WidgetThemeSwatch(
                        id: theme.name,
                        label: prayerWidgetThemeLabel(l10n, theme),
                        background: theme == PrayerWidgetVisualTheme.auto
                            ? appPalette.primary
                            : c.background,
                        foreground: theme == PrayerWidgetVisualTheme.auto
                            ? appPalette.primaryVariant
                            : c.content,
                        automatic: theme == PrayerWidgetVisualTheme.auto,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HudaSectionHeader(l10n.content),
            HudaCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      space.md,
                      space.md,
                      space.md,
                      space.xs,
                    ),
                    child: WidgetSizeControl(
                      label: l10n.contentSize,
                      value: _settings.contentSize,
                      min: 60,
                      max: 140,
                      onChanged: (value) => setState(
                        () =>
                            _settings = _settings.copyWith(contentSize: value),
                      ),
                      onChangeEnd: (value) =>
                          _commit(_settings.copyWith(contentSize: value)),
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  HudaSettingsRow(
                    key: const ValueKey('widgets-prayer-language'),
                    icon: Icons.translate_rounded,
                    title: l10n.language,
                    subtitle: _settings.language == PrayerWidgetLanguage.auto
                        ? l10n.automatic
                        : nativeLanguageName(_settings.language.code),
                    trailing: Icon(
                      Icons.unfold_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: _pickLanguage,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: EdgeInsets.all(space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.prayerWidgetTimeFormat,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: space.sm),
                        SegmentedButton<PrayerWidgetTimeFormat>(
                          key: const ValueKey('widgets-time-format'),
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: PrayerWidgetTimeFormat.twelveHour,
                              label: Text(
                                l10n.prayerWidgetTwelveHour,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ButtonSegment(
                              value: PrayerWidgetTimeFormat.twentyFourHour,
                              label: Text(
                                l10n.prayerWidgetTwentyFourHour,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          selected: {timeFormat},
                          onSelectionChanged: (selection) {
                            if (selection.first == timeFormat) return;
                            HudaHaptics.selection(context);
                            _commit(
                              _settings.copyWith(timeFormat: selection.first),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        WidgetAdvancedSection(
          refreshLabel: l10n.forcePrayerWidgetUpdate,
          refreshingLabel: l10n.prayerWidgetUpdating,
          refreshing: _refreshing,
          onRefresh: _refresh,
          onReset: _reset,
        ),
      ],
    );
  }
}

/// A prayer widget theme's colors.
class PrayerWidgetColors {
  const PrayerWidgetColors({
    required this.background,
    required this.backgroundEnd,
    required this.content,
    required this.muted,
    required this.highlight,
  });

  final Color background;
  final Color backgroundEnd;
  final Color content;
  final Color muted;
  final Color highlight;
}

Color? _hex(String? hex) {
  if (hex == null) return null;
  var s = hex.replaceFirst('#', '').toUpperCase();
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}

/// The colors the native prayer widget uses for [theme]. "Automatic"
/// follows the app's palette: drawn here on the app's chrome, an
/// approximation of the native renderer.
PrayerWidgetColors prayerWidgetColors(
  BuildContext context,
  PrayerWidgetVisualTheme theme,
) {
  final tokens = context.tokens;
  final background = _hex(theme.backgroundColor);
  final content = _hex(theme.contentColor);
  final highlight = _hex(theme.highlightColor);
  if (background == null || content == null) {
    return PrayerWidgetColors(
      background: tokens.chrome,
      backgroundEnd: tokens.chromeEnd,
      content: tokens.onChrome,
      muted: tokens.onChromeMuted,
      highlight: tokens.night().extension<HudaTokens>()!.gilt,
    );
  }
  return PrayerWidgetColors(
    background: background,
    backgroundEnd: Color.lerp(background, Colors.black, 0.25)!,
    content: content,
    muted: content.withValues(alpha: 0.72),
    highlight: highlight ?? content,
  );
}

String prayerWidgetThemeLabel(
  AppLocalizations l10n,
  PrayerWidgetVisualTheme theme,
) => switch (theme) {
  PrayerWidgetVisualTheme.auto => l10n.themeAuto,
  PrayerWidgetVisualTheme.ocean => l10n.themeOcean,
  PrayerWidgetVisualTheme.sunset => l10n.themeSunset,
  PrayerWidgetVisualTheme.forest => l10n.themeForest,
  PrayerWidgetVisualTheme.midnight => l10n.themeMidnight,
  PrayerWidgetVisualTheme.sandstone => l10n.themeSandstone,
  PrayerWidgetVisualTheme.rose => l10n.themeRose,
  PrayerWidgetVisualTheme.lavender => l10n.themeLavender,
  PrayerWidgetVisualTheme.charcoal => l10n.themeCharcoal,
  PrayerWidgetVisualTheme.amber => l10n.themeAmber,
  PrayerWidgetVisualTheme.arctic => l10n.themeArctic,
  PrayerWidgetVisualTheme.burgundy => l10n.themeBurgundy,
  PrayerWidgetVisualTheme.sage => l10n.themeSage,
};

/// The prayer widget as it will look, with sample times (Asr next):
/// Spotlight leads with the next prayer; Almanac lists all five. Names
/// come in the widget's language and direction, times in its format.
class PrayerWidgetPreview extends StatelessWidget {
  const PrayerWidgetPreview({
    super.key,
    required this.design,
    required this.colors,
    required this.contentSize,
    required this.twentyFourHour,
    required this.languageCode,
  });

  final PrayerWidgetDesign design;
  final PrayerWidgetColors colors;
  final int contentSize;
  final bool twentyFourHour;
  final String languageCode;

  static const _times = [(4, 52), (12, 14), (15, 42), (18, 21), (19, 47)];
  static const _next = 2;

  String _time(int index) {
    final (h, m) = _times[index];
    final mm = m.toString().padLeft(2, '0');
    if (twentyFourHour) return '${h.toString().padLeft(2, '0')}:$mm';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final duration = tokens.motion.of(context, tokens.motion.medium);
    final curve = tokens.motion.standard;
    final names = lookupAppLocalizations(Locale(languageCode));
    final prayers = [
      names.fajr,
      names.dhuhr,
      names.asr,
      names.maghrib,
      names.isha,
    ];
    final k = contentSize / 100;
    final base = Theme.of(context).textTheme;
    TextStyle style(
      TextStyle? role,
      double size,
      Color color, {
      bool bold = false,
    }) => (role ?? const TextStyle()).copyWith(
      fontSize: size * k,
      color: color,
      height: 1.2,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontFamilyFallback: const ['Amiri'],
    );

    Widget cell(int i) {
      final next = i == _next;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayers[i],
              maxLines: 1,
              style: style(
                base.labelSmall,
                11,
                next ? colors.highlight : colors.muted,
                bold: next,
              ),
            ),
          ),
          SizedBox(height: space.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _time(i),
              maxLines: 1,
              textDirection: TextDirection.ltr,
              style: style(
                base.labelMedium,
                12,
                next ? colors.highlight : colors.content,
                bold: next,
              ),
            ),
          ),
        ],
      );
    }

    final Widget body;
    if (design == PrayerWidgetDesign.hero) {
      body = Column(
        key: const ValueKey('hero'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  prayers[_next],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(
                    base.headlineSmall,
                    26,
                    colors.content,
                    bold: true,
                  ),
                ),
              ),
              SizedBox(width: space.sm),
              Text(
                _time(_next),
                textDirection: TextDirection.ltr,
                style: style(
                  base.titleMedium,
                  18,
                  colors.highlight,
                  bold: true,
                ),
              ),
            ],
          ),
          SizedBox(height: space.sm),
          Container(height: 1, color: colors.content.withValues(alpha: 0.18)),
          SizedBox(height: space.sm),
          Row(
            children: [
              // A small gap keeps the five times apart when they scale down.
              for (var i = 0; i < prayers.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: cell(i),
                  ),
                ),
            ],
          ),
        ],
      );
    } else {
      Widget box(int i) => Container(
        padding: EdgeInsets.symmetric(
          vertical: space.xs,
          horizontal: space.xxs,
        ),
        decoration: BoxDecoration(
          color: i == _next
              ? colors.highlight.withValues(alpha: 0.18)
              : colors.content.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: cell(i),
      );
      body = Column(
        key: const ValueKey('compact'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: space.xs),
                Expanded(child: box(i)),
              ],
            ],
          ),
          SizedBox(height: space.xs),
          Row(
            children: [
              for (var i = 3; i < 5; i++) ...[
                if (i > 3) SizedBox(width: space.xs),
                Expanded(child: box(i)),
              ],
            ],
          ),
        ],
      );
    }

    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: languageDirection(languageCode),
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          padding: EdgeInsets.all(space.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [colors.background, colors.backgroundEnd],
            ),
          ),
          child: HudaAnimatedSize(
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(duration: duration, child: body),
          ),
        ),
      ),
    );
  }
}

/// A design's thumbnail in the chosen theme's colors.
class _DesignMiniaturePainter extends CustomPainter {
  const _DesignMiniaturePainter({required this.design, required this.colors});

  final PrayerWidgetDesign design;
  final PrayerWidgetColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = LinearGradient(
          colors: [colors.background, colors.backgroundEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final content = Paint()..color = colors.content;
    final faint = Paint()..color = colors.content.withValues(alpha: 0.22);
    final highlight = Paint()..color = colors.highlight;
    RRect bar(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * x, size.height * y, size.width * w, h),
          const Radius.circular(2),
        );
    if (design == PrayerWidgetDesign.hero) {
      canvas.drawRRect(bar(0.12, 0.2, 0.42, 6), content);
      canvas.drawRRect(bar(0.64, 0.24, 0.24, 4), highlight);
      canvas.drawRRect(bar(0.12, 0.5, 0.76, 1), faint);
      for (var i = 0; i < 5; i++) {
        canvas.drawRRect(
          bar(0.12 + i * 0.16, 0.66, 0.11, 3),
          i == 2 ? highlight : faint,
        );
      }
    } else {
      for (var row = 0; row < 2; row++) {
        final count = row == 0 ? 3 : 2;
        for (var i = 0; i < count; i++) {
          final w = (0.76 - (count - 1) * 0.04) / count;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                size.width * (0.12 + i * (w + 0.04)),
                size.height * (0.18 + row * 0.36),
                size.width * w,
                size.height * 0.28,
              ),
              const Radius.circular(3),
            ),
            row == 0 && i == 2 ? highlight : faint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DesignMiniaturePainter oldDelegate) =>
      oldDelegate.design != design || oldDelegate.colors != colors;
}
