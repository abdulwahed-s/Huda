import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// Builds Huda's redesigned theme (direction C, "Lantern", chosen by the
/// owner on 2026-10-30): a full Material 3 color scheme derived from the
/// owner's [AppColorTheme], the type scale with Arabic roles, the tokens,
/// and component themes. See `design/LANGUAGE.md`, "Decided in foundation".
///
/// It is the app's root theme (`app.dart`); focus screens switch to its
/// night with `HudaNight`.
abstract final class HudaTheme {
  /// [onChrome] builds the night theme (`HudaNight`), whose pages are the
  /// chrome: outlines are derived from the warm text.
  ///
  /// [pureBlack] (the "Pure black" setting, for OLED screens) applies to
  /// the dark theme only: the page is black, and night screens and
  /// landing bands fade from the palette into black.
  static ThemeData build({
    required AppColorTheme colorTheme,
    required Brightness brightness,
    String fontFamily = AppFonts.amiri,
    bool onChrome = false,
    bool pureBlack = false,
  }) {
    final black = pureBlack && brightness == Brightness.dark;
    final palette = AppColors.getColorScheme(colorTheme);
    var scheme = colorScheme(palette, brightness, pureBlack: black);
    final family = AppFonts.resolve(fontFamily);
    final tokens = _tokens(
      palette,
      scheme,
      pureBlack: black,
      night: () => _night(colorTheme, fontFamily, pureBlack: black),
    );
    if (onChrome) {
      // Night pages are the chrome, not the neutral surface the scheme's
      // outlines are blended over (those read near-black there). Outlines
      // are the warm text at strength instead: `outline` keeps quiet and
      // unselected controls at 3:1, `outlineVariant` stays soft for
      // surfaces.
      scheme = scheme.copyWith(
        outline: tokens.onChrome.withValues(alpha: 0.42),
        outlineVariant: tokens.onChrome.withValues(alpha: 0.14),
      );
    }
    final text = _textTheme(scheme, family);
    final roles = _roles(scheme, family);
    final radius = tokens.radius;
    final stroke = tokens.stroke;
    final controlShape = RoundedRectangleBorder(borderRadius: radius.control);
    // Lantern controls: "lit" (the chrome) marks the primary action and
    // what's selected; quiet controls sit on the page. No gold on controls
    // (owner round 4).
    // Lit buttons carry an engraving (a rosette with contour rings), carved
    // in the warm off-white, not gilded: gold stays in ornament and lamps.
    final litShape = HudaLanternBorder(
      radius: radius.md,
      engraving: tokens.onChrome.withValues(alpha: 0.24),
    );
    final quietShape = HudaLanternBorder(radius: radius.md);
    // The brighter end of the chrome, so lit controls stand off the page at
    // night too.
    final lit = tokens.lit;
    // Pressing a lit button deepens it (a lighter wash reads as disabled).
    final onChromeOverlay = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.pressed)
          ? Colors.black.withValues(alpha: 0.16)
          : states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
          ? tokens.onChrome.withValues(alpha: 0.08)
          : null,
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final buttonText = text.labelLarge;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      // Ink tinted from the palette, never a neutral gray splash.
      splashFactory: InkRipple.splashFactory,
      splashColor: scheme.primary.withValues(alpha: 0.10),
      highlightColor: scheme.primary.withValues(alpha: 0.06),
      hoverColor: scheme.primary.withValues(alpha: 0.05),
      focusColor: scheme.primary.withValues(alpha: 0.10),
      extensions: [tokens, roles],
      // The standard tier sits on the page (owner, 2026-10-30); the deep
      // band belongs to landing headers and night screens.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: 0.3),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        // Transparent bars over the page; an app bar's style also reaches
        // the navigation bar when nothing else covers the bottom edge.
        systemOverlayStyle: HudaSystemUi.over(
          top: brightness,
          bottom: brightness,
        ),
      ),
      // Orient: each platform's own route motion (LANGUAGE.md, "Motion").
      // Android's is fade-forwards plus the predictive back gesture's
      // preview, which plain fade-forwards would drop.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        // No shadow: a shadow doubles the hairline into a rim. Depth
        // comes from the chrome and the page tone.
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: radius.card,
          side: BorderSide(
            color: scheme.outlineVariant,
            width: stroke.hairline,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: stroke.hairline,
        space: stroke.hairline,
      ),
      listTileTheme: ListTileThemeData(
        shape: controlShape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: litShape,
          backgroundColor: lit,
          foregroundColor: tokens.onChrome,
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
        ).copyWith(overlayColor: onChromeOverlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: quietShape,
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: quietShape,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: quietShape,
          selectedBackgroundColor: lit,
          selectedForegroundColor: tokens.onChrome,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
        ),
        // Selected chips are lit: chrome, warm text, a gilt check.
        // Chips resolve only the label's color by state, not the style.
        labelStyle: text.labelLarge!.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? tokens.onChrome
                : scheme.onSurface,
          ),
        ),
        // Selected is lit: the chrome (a step brighter than night pages),
        // no check, no gold edge.
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: lit)
              // Unselected chips on the night chrome have no fill, so
              // their outline carries their contrast.
              : BorderSide(
                  color: onChrome ? scheme.outline : scheme.outlineVariant,
                ),
        ),
        showCheckmark: false,
        backgroundColor: Colors.transparent,
        color: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? lit : Colors.transparent,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.xl),
        ),
        titleTextStyle: text.titleLarge,
      ),
      // Menus (⋮): the page's raised surface with a hairline in the
      // palette's tone, never Material's near-black outline (added in
      // `quran`).
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius.xl)),
        ),
      ),
      // A lit switch: chrome track, warm thumb.
      switchTheme: SwitchThemeData(
        // Off keeps a 3:1 thumb and outline: soft borders don't apply to
        // a control whose state is its contrast.
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.onChrome
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? lit
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? lit
              : scheme.onSurfaceVariant,
        ),
      ),
      // Each surface's own primary: `MaterialApp` would hand every field
      // the root theme's, which disappears on a night surface
      // (`HudaNight`, Prayer's city search).
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.4),
        selectionHandleColor: scheme.primary,
      ),
      // Lit like the switch: the chrome track and handle.
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: lit,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: lit,
        // No shadow: it draws a dark rim around the handle.
        thumbShape: const RoundSliderThumbShape(
          elevation: 0,
          pressedElevation: 0,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: lit,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radius.sm),
        ),
      ),
    );
  }

  /// How the app moves from one theme to the next (light and dark, a color
  /// theme, the font, pure black): the whole app eases over (`medium`,
  /// `standard`), at once when the platform reduces motion. For
  /// `MaterialApp.themeAnimationStyle`.
  static AnimationStyle changeAnimation(BuildContext context) {
    const motion = HudaMotion();
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? AnimationStyle.noAnimation
        : AnimationStyle(duration: motion.medium, curve: motion.standard);
  }

  static ThemeData _night(
    AppColorTheme colorTheme,
    String fontFamily, {
    bool pureBlack = false,
  }) {
    final night = build(
      colorTheme: colorTheme,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      onChrome: true,
      pureBlack: pureBlack,
    );
    // Night screens paint the chrome gradient themselves: canvas
    // Materials (chips, menus) must not paint over it.
    return night.copyWith(
      canvasColor: Colors.transparent,
      scaffoldBackgroundColor: pureBlack
          ? Colors.black
          : night.extension<HudaTokens>()!.chrome,
    );
  }

  // Color ---------------------------------------------------------------

  /// The full Material 3 scheme for a palette: accents faithful to the
  /// palette's own hue and chroma (so brown stays brown and purple isn't
  /// electric), neutral surfaces, and the gilt as `tertiary`.
  ///
  /// [pureBlack] (dark only) puts the page on black, with containers a few
  /// steps above it and outlines blended over black, so cards and sheets
  /// still separate from the page.
  static ColorScheme colorScheme(
    AppColorScheme palette,
    Brightness brightness, {
    bool pureBlack = false,
  }) {
    final dark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final neutral = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );
    if (dark && pureBlack) {
      const page = Colors.black;
      return base.copyWith(
        surface: page,
        surfaceDim: page,
        surfaceBright: const Color(0xFF2A2A2A),
        surfaceContainerLowest: const Color(0xFF0A0A0A),
        surfaceContainerLow: const Color(0xFF121212),
        surfaceContainer: const Color(0xFF181818),
        surfaceContainerHigh: const Color(0xFF202020),
        surfaceContainerHighest: const Color(0xFF282828),
        onSurface: neutral.onSurface,
        onSurfaceVariant: neutral.onSurfaceVariant,
        outline: Color.alphaBlend(base.primary.withValues(alpha: 0.32), page),
        outlineVariant: Color.alphaBlend(
          base.primary.withValues(alpha: 0.16),
          page,
        ),
        tertiary: giltFor(palette, dark: dark),
        onTertiary: const Color(0xFF241A00),
      );
    }
    return base.copyWith(
      surface: neutral.surface,
      surfaceDim: neutral.surfaceDim,
      surfaceBright: neutral.surfaceBright,
      surfaceContainerLowest: neutral.surfaceContainerLowest,
      surfaceContainerLow: neutral.surfaceContainerLow,
      surfaceContainer: neutral.surfaceContainer,
      surfaceContainerHigh: neutral.surfaceContainerHigh,
      surfaceContainerHighest: neutral.surfaceContainerHighest,
      onSurface: neutral.onSurface,
      onSurfaceVariant: neutral.onSurfaceVariant,
      // Soft borders, as in the current app: the palette's primary at low
      // opacity over the page, never a gray or near-black line.
      outline: Color.alphaBlend(
        base.primary.withValues(alpha: dark ? 0.32 : 0.24),
        neutral.surface,
      ),
      outlineVariant: Color.alphaBlend(
        base.primary.withValues(alpha: dark ? 0.16 : 0.10),
        neutral.surface,
      ),
      tertiary: giltFor(palette, dark: dark),
      onTertiary: dark ? const Color(0xFF241A00) : Colors.white,
    );
  }

  /// Lantern's gilt, kept inside a gold band (36–48°): the palette only
  /// nudges it a few degrees, so cool palettes don't turn lime or pink.
  /// The light tone is dark enough for small text on white (AA); the dark
  /// tone glows on the chrome.
  static Color giltFor(AppColorScheme palette, {required bool dark}) {
    const lamp = 44.0;
    final hue = HSLColor.fromColor(palette.primary).hue;
    var delta = (hue - lamp) % 360;
    if (delta > 180) delta -= 360;
    return HSLColor.fromAHSL(
      1,
      // A tight band (36–48°): green and teal palettes don't drift to
      // chartreuse, red ones don't go orange.
      lamp + (delta * 0.12).clamp(-8.0, 4.0),
      dark ? 0.6 : 0.62,
      dark ? 0.68 : 0.31,
    ).toColor();
  }

  /// The chrome is the palette's hue at saturation ≤ 0.72. At night it sits
  /// at L 0.11 → 0.17 (lit 0.26): any deeper and neighboring hues (red,
  /// pink, orange) collapse into the same near-black (owner, 2026-11-13).
  static HudaTokens _tokens(
    AppColorScheme palette,
    ColorScheme scheme, {
    required ThemeData Function() night,
    bool pureBlack = false,
  }) {
    final dark = scheme.brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(palette.primary);
    final saturation = hsl.saturation.clamp(0.0, 0.72);
    Color deep(double lightness) =>
        hsl.withSaturation(saturation).withLightness(lightness).toColor();
    const onChrome = Color(0xFFF7F3EA);
    return HudaTokens(
      chrome: deep(dark ? 0.11 : 0.14),
      chromeEnd: deep(dark ? 0.17 : 0.22),
      onChrome: onChrome,
      onChromeMuted: onChrome.withValues(alpha: 0.72),
      lit: deep(dark ? 0.26 : 0.22),
      gilt: giltFor(palette, dark: true),
      ornament: scheme.tertiary,
      ornamentQuiet: scheme.tertiary.withValues(alpha: 0.2),
      night: night,
      pureBlack: pureBlack,
    );
  }

  // Type ----------------------------------------------------------------

  /// Arabic text inside a Latin UI face falls back to Amiri, never to
  /// whatever the platform picks.
  static const _arabicFallback = ['Amiri'];

  /// Every UI role follows the font setting (owner, 2026-10-30). Amiri has
  /// only regular and bold, so emphasis is w700, never w500/w600: no faux
  /// bold. Styles are fresh, with the family set explicitly, because
  /// component themes don't merge with the platform typography.
  static TextTheme _textTheme(ColorScheme scheme, String? family) {
    const bold = FontWeight.w700;
    const regular = FontWeight.w400;
    TextStyle s(
      double size,
      double height,
      FontWeight weight, {
      double spacing = 0,
    }) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: _arabicFallback,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: spacing,
      color: scheme.onSurface,
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
    );
    return TextTheme(
      displayLarge: s(56, 1.12, regular),
      displayMedium: s(44, 1.15, regular),
      displaySmall: s(36, 1.2, regular),
      headlineLarge: s(32, 1.25, regular, spacing: 0.4),
      headlineMedium: s(28, 1.25, regular),
      headlineSmall: s(24, 1.3, regular),
      titleLarge: s(21, 1.3, bold),
      titleMedium: s(17, 1.35, bold),
      titleSmall: s(15, 1.4, bold),
      bodyLarge: s(17, 1.55, regular),
      bodyMedium: s(15, 1.5, regular),
      bodySmall: s(13, 1.45, regular),
      labelLarge: s(15, 1.3, bold),
      labelMedium: s(13, 1.3, bold),
      labelSmall: s(12, 1.3, regular, spacing: 1.6),
    );
  }

  static HudaTypeRoles _roles(ColorScheme scheme, String? family) {
    final ink = scheme.onSurface;
    return HudaTypeRoles(
      ayah: TextStyle(
        fontFamily: 'uthmanic',
        fontSize: 28,
        height: 2.0,
        color: ink,
      ),
      dhikr: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 28,
        height: 1.9,
        color: ink,
      ),
      hadith: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 22,
        height: 1.95,
        color: ink,
      ),
      surahTitle: TextStyle(fontFamily: 'arsura', fontSize: 34, color: ink),
      arabicTitle: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 22,
        height: 1.75,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      arabicLabel: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 16,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      counter: TextStyle(
        fontFamily: family,
        fontFamilyFallback: _arabicFallback,
        fontSize: 72,
        height: 1.05,
        color: ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      eyebrow: TextStyle(
        fontFamily: family,
        fontFamilyFallback: _arabicFallback,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: scheme.tertiary,
      ),
    );
  }
}
