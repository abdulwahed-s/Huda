import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';

@immutable
class PrayerPalette {
  const PrayerPalette._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.page,
    required this.card,
    required this.cardRaised,
    required this.border,
    required this.divider,
    required this.tint,
    required this.tintStrong,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.warning,
    required this.error,
    required this.success,
    required this.heroStart,
    required this.heroEnd,
  });

  factory PrayerPalette.of(BuildContext context) =>
      PrayerPalette.fromTheme(Theme.of(context));

  factory PrayerPalette.fromTheme(ThemeData theme) {
    final tokens = theme.extension<HudaTokens>();
    if (tokens != null) return PrayerPalette._lantern(theme, tokens);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final primary = scheme.primary;
    final page = scheme.surface;
    Color over(double alpha) =>
        Color.alphaBlend(primary.withValues(alpha: alpha), page);
    return PrayerPalette._(
      isDark: dark,
      primary: primary,
      onPrimary: scheme.onPrimary,
      page: page,
      card: over(dark ? 0.10 : 0.045),
      cardRaised: dark ? over(0.16) : Colors.white,
      border: primary.withValues(alpha: dark ? 0.26 : 0.13),
      divider: scheme.onSurface.withValues(alpha: dark ? 0.09 : 0.07),
      tint: primary.withValues(alpha: dark ? 0.18 : 0.08),
      tintStrong: primary.withValues(alpha: dark ? 0.30 : 0.14),
      ink: scheme.onSurface,
      muted: scheme.onSurface.withValues(alpha: dark ? 0.70 : 0.64),
      faint: scheme.onSurface.withValues(alpha: dark ? 0.44 : 0.40),
      warning: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      error: dark ? const Color(0xFFF87171) : const Color(0xFFC62828),
      success: dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      heroStart: Color.lerp(primary, Colors.white, dark ? 0.04 : 0.10)!,
      heroEnd: Color.lerp(primary, Colors.black, dark ? 0.50 : 0.38)!,
    );
  }

  /// The Lantern system (`HudaTheme`): cards and outlines from the
  /// scheme, the hero on the chrome. Themes without Lantern tokens (the
  /// Linux tray renderer) keep the mapping above.
  factory PrayerPalette._lantern(ThemeData theme, HudaTokens tokens) {
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final primary = scheme.primary;
    return PrayerPalette._(
      isDark: dark,
      primary: primary,
      onPrimary: scheme.onPrimary,
      page: scheme.surface,
      card: scheme.surfaceContainerLowest,
      cardRaised: scheme.surfaceContainerLowest,
      border: scheme.outlineVariant,
      divider: scheme.outlineVariant,
      tint: primary.withValues(alpha: dark ? 0.16 : 0.07),
      tintStrong: primary.withValues(alpha: dark ? 0.26 : 0.12),
      ink: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      faint: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      warning: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      error: scheme.error,
      success: dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      heroStart: tokens.chrome,
      heroEnd: tokens.chromeEnd,
    );
  }

  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color page;

  final Color card;

  final Color cardRaised;
  final Color border;
  final Color divider;

  final Color tint;
  final Color tintStrong;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color warning;
  final Color error;
  final Color success;
  final Color heroStart;
  final Color heroEnd;

  /// Card radius: Lantern's `radius.lg` (16).
  static const double cardRadius = 16;

  BoxDecoration cardDecoration({double radius = cardRadius, Color? color}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );
}
