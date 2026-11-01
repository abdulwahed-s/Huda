import 'package:flutter/material.dart';

/// Spacing on a 4 px scale. Widgets pick by intent: `md` between related
/// items, `xl` between sections, `xs` inside a control.
@immutable
class HudaSpace {
  const HudaSpace();

  double get xxs => 4;
  double get xs => 8;
  double get sm => 12;
  double get md => 16;
  double get lg => 20;
  double get xl => 24;
  double get xxl => 32;
  double get xxxl => 40;
  double get huge => 48;
  double get giant => 64;

  /// The page margin for a window or pane of [width]: 16 on compact, 24 on
  /// medium, 32 from expanded up.
  double gutter(double width) => width >= 840 ? 32 : (width >= 600 ? 24 : 16);
}

/// Corner radii by role.
@immutable
class HudaRadii {
  const HudaRadii();

  /// Chips, small marks, swatches.
  double get sm => 6;

  /// Buttons, list rows, inputs.
  double get md => 12;

  /// Cards and sections.
  double get lg => 16;

  /// Sheets, dialogs, hero containers.
  double get xl => 24;

  BorderRadius get card => BorderRadius.circular(lg);
  BorderRadius get control => BorderRadius.circular(md);
}

@immutable
class HudaMotion {
  const HudaMotion();

  /// State changes of one control (a press, a toggle).
  Duration get short => const Duration(milliseconds: 150);

  /// A component changing (a card expanding, a sheet's content swapping).
  Duration get medium => const Duration(milliseconds: 250);

  /// A screen-level change (entering, a header collapsing into place).
  Duration get long => const Duration(milliseconds: 400);

  Curve get standard => Curves.easeOutCubic;
  Curve get emphasized => Curves.easeInOutCubicEmphasized;

  /// [duration], or zero when the platform asks to reduce motion.
  Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Stroke widths for ornament line work and rules.
@immutable
class HudaStrokes {
  const HudaStrokes();

  double get hairline => 1;
  double get fine => 1.5;
  double get bold => 2.5;
}

/// Elevation by role. Lantern keeps surfaces flat; depth comes from the
/// chrome and the page tone, not shadows. Cards have none (owner,
/// 2026-10-30: borders that don't look "bordery").
@immutable
class HudaElevation {
  const HudaElevation();

  double get card => 0;
  double get raised => 3;
  double get overlay => 6;
}

/// How an ornament is drawn.
enum OrnamentRender {
  /// Engraved line work, on ordinary surfaces.
  line,

  /// Filled shapes (seals, medallions).
  filled,

  /// Bright line with a soft halo, on deep chrome.
  luminous,
}

/// Design tokens and Lantern's chrome colors, read with `context.tokens`.
@immutable
class HudaTokens extends ThemeExtension<HudaTokens> {
  const HudaTokens({
    required this.chrome,
    required this.chromeEnd,
    required this.onChrome,
    required this.onChromeMuted,
    required this.lit,
    required this.gilt,
    required this.ornament,
    required this.ornamentQuiet,
    required this.night,
    this.pureBlack = false,
  });

  HudaSpace get space => const HudaSpace();
  HudaRadii get radius => const HudaRadii();
  HudaMotion get motion => const HudaMotion();
  HudaStrokes get stroke => const HudaStrokes();
  HudaElevation get elevation => const HudaElevation();

  /// The deep band of landing headers and night screens: a vertical
  /// gradient from [chrome] to [chromeEnd], its text and its ornament.
  final Color chrome;
  final Color chromeEnd;
  final Color onChrome;
  final Color onChromeMuted;

  /// Lit controls (the primary button, the selected chip, an on switch):
  /// the chrome, a step brighter at night so it stands off the page.
  final Color lit;

  /// Lantern's gold, for ornament on [chrome].
  final Color gilt;

  /// Ornament on ordinary surfaces: strong (frames, empty states) and
  /// quiet (beside text).
  final Color ornament;
  final Color ornamentQuiet;

  /// The night theme for immersive focus screens (counters, Qiblah,
  /// players), built from the same color theme and font. Use it through
  /// `HudaNight`, not directly.
  final ThemeData Function() night;

  /// The "Pure black" setting is on and this is the dark theme.
  final bool pureBlack;

  LinearGradient get chromeGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [chrome, chromeEnd],
  );

  /// Large chrome areas (night screens, landing bands, Home's hero): the
  /// chrome gradient, or with [pureBlack] a glow of the palette at the
  /// top fading into black, so OLED pages stay dark below it. Small chrome
  /// (tiles, toasts, lit controls) keeps [chromeGradient].
  LinearGradient get bandGradient => pureBlack
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [chromeEnd, chrome, Colors.black],
          stops: const [0, 0.45, 1],
        )
      : chromeGradient;

  @override
  HudaTokens copyWith({
    Color? chrome,
    Color? chromeEnd,
    Color? onChrome,
    Color? onChromeMuted,
    Color? lit,
    Color? gilt,
    Color? ornament,
    Color? ornamentQuiet,
    bool? pureBlack,
  }) => HudaTokens(
    chrome: chrome ?? this.chrome,
    chromeEnd: chromeEnd ?? this.chromeEnd,
    onChrome: onChrome ?? this.onChrome,
    onChromeMuted: onChromeMuted ?? this.onChromeMuted,
    lit: lit ?? this.lit,
    gilt: gilt ?? this.gilt,
    ornament: ornament ?? this.ornament,
    ornamentQuiet: ornamentQuiet ?? this.ornamentQuiet,
    night: night,
    pureBlack: pureBlack ?? this.pureBlack,
  );

  @override
  HudaTokens lerp(HudaTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return HudaTokens(
      chrome: c(chrome, other.chrome),
      chromeEnd: c(chromeEnd, other.chromeEnd),
      onChrome: c(onChrome, other.onChrome),
      onChromeMuted: c(onChromeMuted, other.onChromeMuted),
      lit: c(lit, other.lit),
      gilt: c(gilt, other.gilt),
      ornament: c(ornament, other.ornament),
      ornamentQuiet: c(ornamentQuiet, other.ornamentQuiet),
      night: t < 0.5 ? night : other.night,
      pureBlack: t < 0.5 ? pureBlack : other.pureBlack,
    );
  }
}

/// Arabic content roles and the few extra Latin roles the Material scale
/// lacks. Read with `context.type`.
@immutable
class HudaTypeRoles extends ThemeExtension<HudaTypeRoles> {
  const HudaTypeRoles({
    required this.ayah,
    required this.dhikr,
    required this.hadith,
    required this.surahTitle,
    required this.arabicTitle,
    required this.arabicLabel,
    required this.counter,
    required this.eyebrow,
  });

  /// Quran text (Uthmanic font).
  final TextStyle ayah;

  /// A dhikr or dua, the hero text of Athkar and Tasbih.
  final TextStyle dhikr;

  /// Hadith matn.
  final TextStyle hadith;

  /// Surah names in the surah-name font.
  final TextStyle surahTitle;

  /// Arabic names of books, collections, categories.
  final TextStyle arabicTitle;

  /// Short Arabic text in UI (chips, captions).
  final TextStyle arabicLabel;

  /// The big number of a counter.
  final TextStyle counter;

  /// A small tracked label above a title or section ("LIBRARY"), shown in
  /// capitals; in the gilt on chrome.
  final TextStyle eyebrow;

  @override
  HudaTypeRoles copyWith() => this;

  @override
  HudaTypeRoles lerp(HudaTypeRoles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return HudaTypeRoles(
      ayah: l(ayah, other.ayah),
      dhikr: l(dhikr, other.dhikr),
      hadith: l(hadith, other.hadith),
      surahTitle: l(surahTitle, other.surahTitle),
      arabicTitle: l(arabicTitle, other.arabicTitle),
      arabicLabel: l(arabicLabel, other.arabicLabel),
      counter: l(counter, other.counter),
      eyebrow: l(eyebrow, other.eyebrow),
    );
  }
}

extension HudaThemeContext on BuildContext {
  HudaTokens get tokens => Theme.of(this).extension<HudaTokens>()!;
  HudaTypeRoles get type => Theme.of(this).extension<HudaTypeRoles>()!;
}
