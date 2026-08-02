import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/utils/platform_utils.dart';

class PrayerWidgetService {
  PrayerWidgetService._();

  static const String iOSWidgetName = 'HudaPrayerWidget';

  static const String androidReceiverName =
      'com.aw.huda.widget.prayer.PrayerWidgetReceiver';

  static const String _appGroupId = 'group.hudaHomeApp';
  static const MethodChannel _channel = MethodChannel('com.aw.huda/widget');

  static const String _latKey = PrayerTimesCalculator.latKey;
  static const String _lonKey = PrayerTimesCalculator.lonKey;
  static const String _countryCodeKey = PrayerTimesCalculator.countryCodeKey;
  static const String _methodKey = PrayerTimesCalculator.methodKey;
  static const String _madhabKey = PrayerTimesCalculator.madhabKey;
  static const String _highLatKey = PrayerTimesCalculator.highLatitudeRuleKey;

  static const List<String> _offsetKeys =
      PrayerTimesCalculator.offsetPrayerKeys;

  static const String _themeNameKey = 'themeName';
  static const String _themeModeKey = 'themeMode';

  static const String _designKey = 'prayerWidgetDesign';
  static const String _languageKey = 'prayerWidgetLanguage';
  static const String _numeralsKey = 'prayerWidgetNumerals';
  static const String _bgEnabledKey = 'prayerWidgetBgEnabled';
  static const String _bgColorKey = 'prayerWidgetBgColor';
  static const String _bgGlassifyKey = 'prayerWidgetBgGlassify';
  static const String _bgRoundedKey = 'prayerWidgetBgRounded';
  static const String _contentColorKey = 'prayerWidgetContentColor';
  static const String _highlightColorKey = 'prayerWidgetHighlightColor';
  static const String _contentSizeKey = 'prayerWidgetContentSize';
  static const String _visualThemeKey = 'prayerWidgetVisualTheme';
  static const String _lastUpdateKey = 'prayerWidgetLastUpdate';

  static const String _localeKey = 'locale';

  static PrayerWidgetSettings readSettings() {
    final cache = getIt<CacheHelper>();
    return PrayerWidgetSettings(
      design: PrayerWidgetDesign.fromStorage(
        cache.getDataString(key: _designKey),
      ),
      language: PrayerWidgetLanguage.fromStorage(
        cache.getDataString(key: _languageKey),
      ),
      numerals: PrayerWidgetNumerals.fromStorage(
        cache.getDataString(key: _numeralsKey),
      ),
      backgroundEnabled: (cache.getData(key: _bgEnabledKey) as bool?) ?? true,
      backgroundColor: cache.getDataString(key: _bgColorKey),
      glassify: (cache.getData(key: _bgGlassifyKey) as bool?) ?? false,
      rounded: (cache.getData(key: _bgRoundedKey) as bool?) ?? false,
      contentColor: cache.getDataString(key: _contentColorKey),
      highlightColor: cache.getDataString(key: _highlightColorKey),
      contentSize: (cache.getData(key: _contentSizeKey) as int?) ?? 100,
      visualTheme: PrayerWidgetVisualTheme.fromStorage(
        cache.getDataString(key: _visualThemeKey),
      ),
    );
  }

  static Future<void> initialize() async {
    if (!PlatformUtils.isMobile) return;
    if (PlatformUtils.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }

    await pushSettings(triggerNativeUpdate: false);
  }

  static Future<void> pushSettings({bool triggerNativeUpdate = true}) async {
    if (!PlatformUtils.isMobile) return;

    try {
      final cache = getIt<CacheHelper>();
      final prefs = await SharedPreferences.getInstance();

      if (PlatformUtils.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }

      final lat = cache.getDataString(key: _latKey);
      final lon = cache.getDataString(key: _lonKey);
      await _writeString(prefs, _latKey, lat);
      await _writeString(prefs, _lonKey, lon);

      await _writeString(
          prefs, _countryCodeKey, cache.getDataString(key: _countryCodeKey));
      await _writeString(
          prefs,
          _methodKey,
          cache.getDataString(key: _methodKey) ??
              PrayerTimesCalculator.defaultMethodToken);
      await _writeString(
          prefs,
          _madhabKey,
          cache.getDataString(key: _madhabKey) ??
              PrayerTimesCalculator.defaultMadhabToken);
      await _writeString(
          prefs,
          _highLatKey,
          cache.getDataString(key: _highLatKey) ??
              PrayerTimesCalculator.defaultHighLatitudeToken);

      for (final key in _offsetKeys) {
        final storageKey = PrayerTimesCalculator.offsetKeyFor(key);
        final offset = (cache.getData(key: storageKey) as int?) ?? 0;
        await prefs.setInt(storageKey, offset);
        if (PlatformUtils.isIOS) {
          await HomeWidget.saveWidgetData<int>(storageKey, offset);
        }
      }

      final theme = _resolveTheme(prefs);
      await _writeString(prefs, _themeNameKey, theme['themeName']);
      await _writeString(prefs, _themeModeKey, theme['themeMode']);

      final settings = readSettings();
      final effectiveLocale = settings.language == PrayerWidgetLanguage.auto
          ? (prefs.getString(_localeKey) ?? 'en')
          : settings.language.code;
      await _writeString(prefs, _localeKey, effectiveLocale);

      await _writeString(prefs, _designKey, settings.design.storage);
      await _writeString(prefs, _languageKey, settings.language.storage);
      await _writeString(prefs, _numeralsKey, settings.numerals.storage);
      await prefs.setBool(_bgEnabledKey, settings.backgroundEnabled);
      await _writeString(prefs, _bgColorKey, settings.backgroundColor);
      await prefs.setBool(_bgGlassifyKey, settings.glassify);
      await prefs.setBool(_bgRoundedKey, settings.rounded);
      await _writeString(prefs, _contentColorKey, settings.contentColor);
      await _writeString(prefs, _highlightColorKey, settings.highlightColor);
      await prefs.setInt(_contentSizeKey, settings.contentSize);
      await _writeString(prefs, _visualThemeKey, settings.visualTheme.storage);
      if (PlatformUtils.isIOS) {
        await HomeWidget.saveWidgetData<bool>(
            _bgEnabledKey, settings.backgroundEnabled);
        await HomeWidget.saveWidgetData<bool>(
            _bgGlassifyKey, settings.glassify);
        await HomeWidget.saveWidgetData<bool>(_bgRoundedKey, settings.rounded);
        await HomeWidget.saveWidgetData<int>(
            _contentSizeKey, settings.contentSize);
      }

      await prefs.setInt(
        _lastUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (triggerNativeUpdate) {
        await _refreshNativeWidget();
      }
    } catch (e) {
      debugPrint('❌ PrayerWidgetService.pushSettings error: $e');
    }
  }

  static Future<void> updateCustomization(PrayerWidgetSettings next) async {
    final cache = getIt<CacheHelper>();
    await cache.saveData(key: _designKey, value: next.design.storage);
    await cache.saveData(key: _languageKey, value: next.language.storage);
    await cache.saveData(key: _numeralsKey, value: next.numerals.storage);
    await cache.saveData(key: _bgEnabledKey, value: next.backgroundEnabled);
    if (next.backgroundColor != null) {
      await cache.saveData(key: _bgColorKey, value: next.backgroundColor);
    } else {
      await cache.removeData(key: _bgColorKey);
    }
    await cache.saveData(key: _bgGlassifyKey, value: next.glassify);
    await cache.saveData(key: _bgRoundedKey, value: next.rounded);
    if (next.contentColor != null) {
      await cache.saveData(key: _contentColorKey, value: next.contentColor);
    } else {
      await cache.removeData(key: _contentColorKey);
    }
    if (next.highlightColor != null) {
      await cache.saveData(key: _highlightColorKey, value: next.highlightColor);
    } else {
      await cache.removeData(key: _highlightColorKey);
    }
    await cache.saveData(key: _contentSizeKey, value: next.contentSize);
    await cache.saveData(key: _visualThemeKey, value: next.visualTheme.storage);
    await pushSettings();
  }

  static Future<void> resetCustomization() async {
    final cache = getIt<CacheHelper>();
    await cache.removeData(key: _designKey);
    await cache.removeData(key: _languageKey);
    await cache.removeData(key: _numeralsKey);
    await cache.removeData(key: _bgEnabledKey);
    await cache.removeData(key: _bgColorKey);
    await cache.removeData(key: _bgGlassifyKey);
    await cache.removeData(key: _bgRoundedKey);
    await cache.removeData(key: _contentColorKey);
    await cache.removeData(key: _highlightColorKey);
    await cache.removeData(key: _contentSizeKey);
    await cache.removeData(key: _visualThemeKey);
    await pushSettings();
  }

  static Future<void> forceUpdate() async {
    await pushSettings();
  }

  static Future<void> onAppThemeChanged() async {
    await pushSettings();
  }

  static Future<void> _refreshNativeWidget() async {
    try {
      if (PlatformUtils.isIOS) {
        await HomeWidget.updateWidget(iOSName: iOSWidgetName);
      }
      if (PlatformUtils.isAndroid) {
        try {
          await HomeWidget.updateWidget(
            qualifiedAndroidName: androidReceiverName,
          );
        } catch (e) {
          debugPrint('⚠️ home_widget broadcast failed: $e');
        }
        try {
          await _channel.invokeMethod('updatePrayerWidget');
        } catch (e) {
          debugPrint('⚠️ MethodChannel updatePrayerWidget failed: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ _refreshNativeWidget error: $e');
    }
  }

  static Future<void> _writeString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      if (PlatformUtils.isIOS) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
      return;
    }
    await prefs.setString(key, value);
    if (PlatformUtils.isIOS) {
      await HomeWidget.saveWidgetData<String>(key, value);
    }
  }

  static Map<String, String> _resolveTheme(SharedPreferences prefs) {
    final savedColorTheme = prefs.getString('color_theme');
    final savedThemeMode = prefs.getString('theme_mode');

    final colorTheme = AppColors.fromStorage(savedColorTheme);

    String themeMode;
    if (savedThemeMode == 'dark') {
      themeMode = 'dark';
    } else if (savedThemeMode == 'light') {
      themeMode = 'light';
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      themeMode = brightness == Brightness.dark ? 'dark' : 'light';
    }

    return {
      'themeName': colorTheme.toString().split('.').last,
      'themeMode': themeMode,
    };
  }
}

@immutable
class PrayerWidgetSettings {
  final PrayerWidgetDesign design;
  final PrayerWidgetLanguage language;
  final PrayerWidgetNumerals numerals;
  final bool backgroundEnabled;

  final String? backgroundColor;
  final bool glassify;
  final bool rounded;

  final String? contentColor;

  final String? highlightColor;

  final int contentSize;

  final PrayerWidgetVisualTheme visualTheme;

  const PrayerWidgetSettings({
    this.design = PrayerWidgetDesign.hero,
    this.language = PrayerWidgetLanguage.auto,
    this.numerals = PrayerWidgetNumerals.latin,
    this.backgroundEnabled = true,
    this.backgroundColor,
    this.glassify = false,
    this.rounded = false,
    this.contentColor,
    this.highlightColor,
    this.contentSize = 100,
    this.visualTheme = PrayerWidgetVisualTheme.auto,
  });

  PrayerWidgetSettings copyWith({
    PrayerWidgetDesign? design,
    PrayerWidgetLanguage? language,
    PrayerWidgetNumerals? numerals,
    bool? backgroundEnabled,
    Object? backgroundColor = _unset,
    bool? glassify,
    bool? rounded,
    Object? contentColor = _unset,
    Object? highlightColor = _unset,
    int? contentSize,
    PrayerWidgetVisualTheme? visualTheme,
  }) {
    final newTheme = visualTheme ?? this.visualTheme;
    return PrayerWidgetSettings(
      design: design ?? this.design,
      language: language ?? this.language,
      numerals: numerals ?? this.numerals,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundColor: visualTheme != null
          ? newTheme.backgroundColor
          : (backgroundColor == _unset
              ? this.backgroundColor
              : backgroundColor as String?),
      glassify: glassify ?? this.glassify,
      rounded: rounded ?? this.rounded,
      contentColor: visualTheme != null
          ? newTheme.contentColor
          : (contentColor == _unset
              ? this.contentColor
              : contentColor as String?),
      highlightColor: visualTheme != null
          ? newTheme.highlightColor
          : (highlightColor == _unset
              ? this.highlightColor
              : highlightColor as String?),
      contentSize: contentSize ?? this.contentSize,
      visualTheme: newTheme,
    );
  }

  static const _unset = Object();
}

enum PrayerWidgetDesign {
  hero,

  compact;

  String get storage => name;

  static PrayerWidgetDesign fromStorage(String? raw) {
    if (raw == null) return PrayerWidgetDesign.hero;
    return PrayerWidgetDesign.values.firstWhere(
      (d) => d.name == raw,
      orElse: () => PrayerWidgetDesign.hero,
    );
  }
}

enum PrayerWidgetLanguage {
  auto,
  ar,
  en,
  tr,
  fr,
  es,
  de,
  ru,
  ur,
  ms,
  bn;

  String get storage => name;

  String get code => this == PrayerWidgetLanguage.auto ? 'auto' : name;

  static PrayerWidgetLanguage fromStorage(String? raw) {
    if (raw == null) return PrayerWidgetLanguage.auto;
    return PrayerWidgetLanguage.values.firstWhere(
      (l) => l.name == raw,
      orElse: () => PrayerWidgetLanguage.auto,
    );
  }
}

enum PrayerWidgetNumerals {
  auto,
  latin,
  arabic;

  String get storage => name;

  static PrayerWidgetNumerals fromStorage(String? raw) {
    if (raw == null) return PrayerWidgetNumerals.latin;
    return PrayerWidgetNumerals.values.firstWhere(
      (n) => n.name == raw,
      orElse: () => PrayerWidgetNumerals.latin,
    );
  }
}

enum PrayerWidgetVisualTheme {
  auto(backgroundColor: null, contentColor: null, highlightColor: null),
  ocean(
      backgroundColor: '#FF1A3A5C',
      contentColor: '#FFF0F4F8',
      highlightColor: '#FF4DD0E1'),
  sunset(
      backgroundColor: '#FF5C2A0E',
      contentColor: '#FFFFF5EB',
      highlightColor: '#FFFFD54F'),
  forest(
      backgroundColor: '#FF1B3A2A',
      contentColor: '#FFE8F5E9',
      highlightColor: '#FF66BB6A'),
  midnight(
      backgroundColor: '#FF121218',
      contentColor: '#FFE0E0E8',
      highlightColor: '#FF7986CB'),
  sandstone(
      backgroundColor: '#FFF5E6D3',
      contentColor: '#FF3E2C1A',
      highlightColor: '#FFD84315'),
  rose(
      backgroundColor: '#FF3D1A2E',
      contentColor: '#FFFCE4EC',
      highlightColor: '#FFF06292'),
  lavender(
      backgroundColor: '#FF2E2450',
      contentColor: '#FFEDE7F6',
      highlightColor: '#FFBA68C8'),
  charcoal(
      backgroundColor: '#FF2C2C2C',
      contentColor: '#FFF5F5F5',
      highlightColor: '#FFFFB74D'),
  amber(
      backgroundColor: '#FF4A3000',
      contentColor: '#FFFFF8E1',
      highlightColor: '#FFFFD740'),
  arctic(
      backgroundColor: '#FFE3F2FD',
      contentColor: '#FF0D2137',
      highlightColor: '#FF1976D2'),
  burgundy(
      backgroundColor: '#FF4A0E1E',
      contentColor: '#FFFDE8EF',
      highlightColor: '#FFEF5350'),
  sage(
      backgroundColor: '#FF3B4A3A',
      contentColor: '#FFF1F5E8',
      highlightColor: '#FF81C784');

  const PrayerWidgetVisualTheme({
    required this.backgroundColor,
    required this.contentColor,
    required this.highlightColor,
  });

  final String? backgroundColor;
  final String? contentColor;
  final String? highlightColor;

  String get storage => name;

  static PrayerWidgetVisualTheme fromStorage(String? raw) {
    if (raw == null) return PrayerWidgetVisualTheme.auto;
    return PrayerWidgetVisualTheme.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => PrayerWidgetVisualTheme.auto,
    );
  }
}
