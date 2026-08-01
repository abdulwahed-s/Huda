import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

enum AppColorTheme {
  teal,
  purple,
  green,
  blue,
  yellow,
  red,
  orange,
  indigo,
  cream,
  pink,
  brown,
}

class AppColors {
  static const AppColorTheme defaultTheme = AppColorTheme.teal;

  static const Map<AppColorTheme, AppColorScheme> _colorSchemes = {
    AppColorTheme.purple: AppColorScheme(
      primary: Color(0xFF7C3AED),
      primaryVariant: Color(0xFF9333EA),
      primaryLight: Color(0xFF9D7FD6),
      primaryDark: Color(0xFF4C1D95),
      accent: Color(0xFF8B5CF6),
      accentDark: Color(0xFF6D28D9),
      primaryExtraLight: Color(0xFFE0D3E0),
      primarySurface: Color(0xFF9B7C9B),
      darkGradientStart: Color(0xFF1A0A1A),
      darkGradientMid: Color(0xFF2D1B2D),
      darkGradientEnd: Color(0xFF4A2C4A),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A1A2A),
    ),
    AppColorTheme.green: AppColorScheme(
      primary: Color(0xFF166534),
      primaryVariant: Color(0xFF22C55E),
      primaryLight: Color(0xFF4ADE80),
      primaryDark: Color(0xFF14532D),
      accent: Color(0xFF10B981),
      accentDark: Color(0xFF059669),
      primaryExtraLight: Color(0xFFD1FAE5),
      primarySurface: Color(0xFF34D399),
      darkGradientStart: Color(0xFF0A1A0F),
      darkGradientMid: Color(0xFF1B2D20),
      darkGradientEnd: Color(0xFF2C4A35),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF1A2A1F),
    ),
    AppColorTheme.blue: AppColorScheme(
      primary: Color(0xFF1E3A8A),
      primaryVariant: Color(0xFF3B82F6),
      primaryLight: Color(0xFF60A5FA),
      primaryDark: Color(0xFF1E1B4B),
      accent: Color(0xFF2563EB),
      accentDark: Color(0xFF1D4ED8),
      primaryExtraLight: Color(0xFFDBEAFE),
      primarySurface: Color(0xFF6366F1),
      darkGradientStart: Color(0xFF0A0F1A),
      darkGradientMid: Color(0xFF1B202D),
      darkGradientEnd: Color(0xFF2C354A),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF1A1F2A),
    ),
    AppColorTheme.red: AppColorScheme(
      primary: Color(0xFF991B1B),
      primaryVariant: Color(0xFFEF4444),
      primaryLight: Color(0xFFF87171),
      primaryDark: Color(0xFF7F1D1D),
      accent: Color(0xFFDC2626),
      accentDark: Color(0xFFB91C1C),
      primaryExtraLight: Color(0xFFFEE2E2),
      primarySurface: Color(0xFFF87171),
      darkGradientStart: Color(0xFF1A0A0A),
      darkGradientMid: Color(0xFF2D1B1B),
      darkGradientEnd: Color(0xFF4A2C2C),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A1A1A),
    ),
    AppColorTheme.orange: AppColorScheme(
      primary: Color(0xFF9A3412),
      primaryVariant: Color(0xFFF97316),
      primaryLight: Color(0xFFFB923C),
      primaryDark: Color(0xFF7C2D12),
      accent: Color(0xFFEA580C),
      accentDark: Color(0xFFD97706),
      primaryExtraLight: Color(0xFFFED7AA),
      primarySurface: Color(0xFFFB923C),
      darkGradientStart: Color(0xFF1A0F0A),
      darkGradientMid: Color(0xFF2D201B),
      darkGradientEnd: Color(0xFF4A352C),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A1F1A),
    ),
    AppColorTheme.teal: AppColorScheme(
      primary: Color(0xFF134E4A),
      primaryVariant: Color(0xFF14B8A6),
      primaryLight: Color(0xFF5EEAD4),
      primaryDark: Color(0xFF042F2E),
      accent: Color(0xFF0D9488),
      accentDark: Color(0xFF0F766E),
      primaryExtraLight: Color(0xFFCCFDF7),
      primarySurface: Color(0xFF2DD4BF),
      darkGradientStart: Color(0xFF0A1A18),
      darkGradientMid: Color(0xFF1B2D2A),
      darkGradientEnd: Color(0xFF2C4A46),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF1A2A26),
    ),
    AppColorTheme.indigo: AppColorScheme(
      primary: Color(0xFF312E81),
      primaryVariant: Color(0xFF6366F1),
      primaryLight: Color(0xFF818CF8),
      primaryDark: Color(0xFF1E1B4B),
      accent: Color(0xFF4F46E5),
      accentDark: Color(0xFF4338CA),
      primaryExtraLight: Color(0xFFE0E7FF),
      primarySurface: Color(0xFF8B5CF6),
      darkGradientStart: Color(0xFF0F0A1A),
      darkGradientMid: Color(0xFF201B2D),
      darkGradientEnd: Color(0xFF352C4A),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF1F1A2A),
    ),
    AppColorTheme.pink: AppColorScheme(
      primary: Color(0xFF9D174D),
      primaryVariant: Color(0xFFEC4899),
      primaryLight: Color(0xFFF472B6),
      primaryDark: Color(0xFF831843),
      accent: Color(0xFFDB2777),
      accentDark: Color(0xFFBE185D),
      primaryExtraLight: Color(0xFFFCE7F3),
      primarySurface: Color(0xFFF472B6),
      darkGradientStart: Color(0xFF1A0A14),
      darkGradientMid: Color(0xFF2D1B26),
      darkGradientEnd: Color(0xFF4A2C3E),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A1A26),
    ),
    AppColorTheme.yellow: AppColorScheme(
      primary: Color(0xFFA16207),
      primaryVariant: Color(0xFFFACC15),
      primaryLight: Color(0xFFFDE047),
      primaryDark: Color(0xFF713F12),
      accent: Color(0xFFEAB308),
      accentDark: Color(0xFFCA8A04),
      primaryExtraLight: Color(0xFFFEF9C3),
      primarySurface: Color(0xFFFACC15),
      darkGradientStart: Color(0xFF1A180A),
      darkGradientMid: Color(0xFF2D2A1B),
      darkGradientEnd: Color(0xFF4A462C),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A281A),
    ),
    AppColorTheme.brown: AppColorScheme(
      primary: Color(0xFF5D4037),
      primaryVariant: Color(0xFF8D6E63),
      primaryLight: Color(0xFFA1887F),
      primaryDark: Color(0xFF3E2723),
      accent: Color(0xFF795548),
      accentDark: Color(0xFF4E342E),
      primaryExtraLight: Color(0xFFEFEBE9),
      primarySurface: Color(0xFFA1887F),
      darkGradientStart: Color(0xFF1A100C),
      darkGradientMid: Color(0xFF2D211B),
      darkGradientEnd: Color(0xFF4A372C),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A201A),
    ),
    AppColorTheme.cream: AppColorScheme(
      primary: Color(0xFF8A6D3B),
      primaryVariant: Color(0xFFD8C59A),
      primaryLight: Color(0xFFE8DDBF),
      primaryDark: Color(0xFF5C4827),
      accent: Color(0xFFB08D57),
      accentDark: Color(0xFF80683F),
      primaryExtraLight: Color(0xFFFFF8E7),
      primarySurface: Color(0xFFF5E6C8),
      darkGradientStart: Color(0xFF1A160D),
      darkGradientMid: Color(0xFF2D271A),
      darkGradientEnd: Color(0xFF4A402B),
      darkCardBackground: Color(0xFF1A1A1A),
      lightSurface: Color(0xFFFFFDF7),
      darkText: Color(0xFFF8FAFC),
      lightText: Color(0xFF2C2C2C),
      darkTabBackground: Color(0xFF2A2418),
    ),
  };

  static AppColorScheme getColorScheme(AppColorTheme theme) {
    return _colorSchemes[theme] ?? _colorSchemes[defaultTheme]!;
  }

  static AppColorTheme fromStorage(
    String? storedTheme, {
    AppColorTheme fallback = defaultTheme,
  }) {
    if (storedTheme == 'AppColorTheme.gray' || storedTheme == 'gray') {
      return AppColorTheme.cream;
    }

    return AppColorTheme.values.firstWhere(
      (theme) => theme.toString() == storedTheme || theme.name == storedTheme,
      orElse: () => fallback,
    );
  }

  static List<AppColorTheme> get availableThemes => AppColorTheme.values;

  static String getThemeName(AppColorTheme theme, BuildContext context) {
    switch (theme) {
      case AppColorTheme.purple:
        return AppLocalizations.of(context)!.purple;
      case AppColorTheme.green:
        return AppLocalizations.of(context)!.green;
      case AppColorTheme.blue:
        return AppLocalizations.of(context)!.blue;
      case AppColorTheme.red:
        return AppLocalizations.of(context)!.red;
      case AppColorTheme.orange:
        return AppLocalizations.of(context)!.orange;
      case AppColorTheme.teal:
        return AppLocalizations.of(context)!.teal;
      case AppColorTheme.indigo:
        return AppLocalizations.of(context)!.indigo;
      case AppColorTheme.pink:
        return AppLocalizations.of(context)!.pink;
      case AppColorTheme.cream:
        return AppLocalizations.of(context)!.cream;
      case AppColorTheme.brown:
        return AppLocalizations.of(context)!.brown;
      case AppColorTheme.yellow:
        return AppLocalizations.of(context)!.yellow;
    }
  }
}

class AppColorScheme {
  final Color primary;
  final Color primaryVariant;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentDark;

  final Color primaryExtraLight;
  final Color primarySurface;
  final Color darkGradientStart;
  final Color darkGradientMid;
  final Color darkGradientEnd;

  final Color darkCardBackground;
  final Color lightSurface;
  final Color darkText;
  final Color lightText;
  final Color darkTabBackground;

  const AppColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.primaryExtraLight,
    required this.primarySurface,
    required this.darkGradientStart,
    required this.darkGradientMid,
    required this.darkGradientEnd,
    required this.darkCardBackground,
    required this.lightSurface,
    required this.darkText,
    required this.lightText,
    required this.darkTabBackground,
  });
}
