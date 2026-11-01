import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/core/services/quran_widget_service.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/theme/huda_haptics_setting.dart';
import 'package:huda/core/theme/huda_text_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final double textScaleFactor;
  final AppColorTheme colorTheme;
  final String fontFamily;

  /// The app's "Haptic feedback" switch (Settings).
  final bool hapticsEnabled;

  /// "Pure black" (Settings, Appearance): a black page in dark mode, for
  /// OLED screens. Light mode ignores it.
  final bool pureBlack;

  ThemeState({
    required this.themeMode,
    required this.textScaleFactor,
    required this.colorTheme,
    required this.fontFamily,
    this.hapticsEnabled = true,
    this.pureBlack = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    double? textScaleFactor,
    AppColorTheme? colorTheme,
    String? fontFamily,
    bool? hapticsEnabled,
    bool? pureBlack,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      colorTheme: colorTheme ?? this.colorTheme,
      fontFamily: fontFamily ?? this.fontFamily,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      pureBlack: pureBlack ?? this.pureBlack,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _themeKey = 'theme_mode';
  static const _scaleKey = 'text_scale_factor';
  static const _colorThemeKey = 'color_theme';
  static const _fontKey = 'font_family';
  static const _pureBlackKey = 'pure_black';

  /// Set once the saved text size has been migrated from "replaces the
  /// device's text size" to "relative to it" (see `CombinedTextScaler`).
  static const _scaleRelativeKey = 'text_scale_relative_v1';

  bool isDark = false;

  ThemeCubit()
      : super(ThemeState(
          themeMode: ThemeMode.system,
          textScaleFactor: 1.0,
          colorTheme: AppColors.defaultTheme,
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
    var savedScale = _sanitizeScale(prefs.getData(key: _scaleKey));
    if (prefs.getData(key: _scaleRelativeKey) != true) {
      // One time: keep the effective size the person chose. Fresh installs
      // have nothing saved and start at 1.0 (the device's size).
      if (prefs.getData(key: _scaleKey) != null) {
        savedScale = migrateTextScaleToRelative(
          savedScale,
          deviceScale: WidgetsBinding.instance.platformDispatcher.textScaleFactor,
          min: _minScale,
          max: _maxScale,
        );
        await prefs.saveData(key: _scaleKey, value: savedScale);
      }
      await prefs.saveData(key: _scaleRelativeKey, value: true);
    }
    final savedColorTheme = prefs.getDataString(key: _colorThemeKey);
    final savedFont =
        AppFonts.sanitize(prefs.getDataString(key: _fontKey) ?? AppFonts.amiri);
    final savedHaptics =
        prefs.getData(key: HudaHapticsSetting.storageKey) != false;
    final savedPureBlack = prefs.getData(key: _pureBlackKey) == true;
    HudaHapticsSetting.enabled = savedHaptics;

    ThemeMode themeMode;
    if (savedMode == 'light') {
      themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }

    AppColorTheme colorTheme = AppColors.defaultTheme;
    if (savedColorTheme != null) {
      colorTheme = AppColors.fromStorage(savedColorTheme);
    }

    isDark = themeMode == ThemeMode.dark;
    emit(ThemeState(
      themeMode: themeMode,
      textScaleFactor: savedScale,
      colorTheme: colorTheme,
      fontFamily: savedFont,
      hapticsEnabled: savedHaptics,
      pureBlack: savedPureBlack,
    ));
  }

  Future<void> toggleTheme(bool useDark) async {
    final mode = useDark ? ThemeMode.dark : ThemeMode.light;
    isDark = useDark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, useDark ? 'dark' : 'light');
    emit(state.copyWith(themeMode: mode));

    await _updateWidgetTheme();
  }

  Future<void> useSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    emit(state.copyWith(themeMode: ThemeMode.system));

    await _updateWidgetTheme();
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

    await _updateWidgetTheme();
  }

  Future<void> _updateWidgetTheme() async {
    await QuranWidgetService.onThemeChanged();
    await PrayerWidgetService.onAppThemeChanged();
  }

  Future<void> setFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, fontFamily);
    emit(state.copyWith(fontFamily: fontFamily));

    await QuranWidgetService.onThemeChanged();
  }

  /// The "Pure black" switch. Home-screen widgets don't follow it.
  Future<void> setPureBlack(bool enabled) async {
    emit(state.copyWith(pureBlack: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pureBlackKey, enabled);
  }

  /// The app's "Haptic feedback" switch: `HudaHaptics` follows it at once.
  Future<void> setHapticsEnabled(bool enabled) async {
    HudaHapticsSetting.enabled = enabled;
    emit(state.copyWith(hapticsEnabled: enabled));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HudaHapticsSetting.storageKey, enabled);
  }
}
