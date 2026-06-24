import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final double textScaleFactor;
  final AppColorTheme colorTheme;
  final String fontFamily;

  ThemeState({
    required this.themeMode,
    required this.textScaleFactor,
    required this.colorTheme,
    required this.fontFamily,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    double? textScaleFactor,
    AppColorTheme? colorTheme,
    String? fontFamily,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      colorTheme: colorTheme ?? this.colorTheme,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _themeKey = 'theme_mode';
  static const _scaleKey = 'text_scale_factor';
  static const _colorThemeKey = 'color_theme';
  static const _fontKey = 'font_family';

  bool isDark = false;

  ThemeCubit()
      : super(ThemeState(
          themeMode: ThemeMode.system,
          textScaleFactor: 1.0,
          colorTheme: AppColorTheme.purple,
          fontFamily: 'Amiri',
        )) {
    _loadSettings();
  }

  static const double _minScale = 0.5;
  static const double _maxScale = 2.0;

  static double _sanitizeScale(Object? raw) {
    final value = (raw is num) ? raw.toDouble() : 1.0;
    if (value.isNaN || value.isInfinite) return 1.0;
    return value.clamp(_minScale, _maxScale);
  }

  Future<void> _loadSettings() async {
    final prefs = getIt<CacheHelper>();
    final savedMode = prefs.getDataString(key: _themeKey);
    final savedScale = _sanitizeScale(prefs.getData(key: _scaleKey));
    final savedColorTheme = prefs.getDataString(key: _colorThemeKey);
    final savedFont =
        AppFonts.sanitize(prefs.getDataString(key: _fontKey) ?? AppFonts.amiri);

    ThemeMode themeMode;
    if (savedMode == 'light') {
      themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    AppColorTheme colorTheme = AppColorTheme.purple;
    if (savedColorTheme != null) {
      try {
        colorTheme = AppColorTheme.values.firstWhere(
          (theme) => theme.toString() == savedColorTheme,
        );
      } catch (e) {
        colorTheme = AppColorTheme.purple;
      }
    }

    isDark = themeMode == ThemeMode.dark;
    emit(ThemeState(
      themeMode: themeMode,
      textScaleFactor: savedScale,
      colorTheme: colorTheme,
      fontFamily: savedFont,
    ));
  }

  Future<void> toggleTheme(bool useDark) async {
    final mode = useDark ? ThemeMode.dark : ThemeMode.light;
    isDark = useDark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, useDark ? 'dark' : 'light');
    emit(state.copyWith(themeMode: mode));

    await WidgetService.onThemeChanged();
  }

  Future<void> useSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    emit(state.copyWith(themeMode: ThemeMode.system));

    await WidgetService.onThemeChanged();
  }

  Future<void> setTextScaleFactor(double scale) async {
    final safeScale = _sanitizeScale(scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scaleKey, safeScale);

    emit(state.copyWith(textScaleFactor: safeScale));
  }

  Future<void> setColorTheme(AppColorTheme colorTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorThemeKey, colorTheme.toString());

    emit(state.copyWith(colorTheme: colorTheme));

    await WidgetService.onThemeChanged();
  }

  Future<void> setFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, fontFamily);
    emit(state.copyWith(fontFamily: fontFamily));

    await WidgetService.onThemeChanged();
  }
}
