import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class QuranWidgetService {
  QuranWidgetService._();

  static Future<void> _operationQueue = Future<void>.value();

  static const iOSWidgetName = 'HudaWidget';
  static const _appGroupId = 'group.hudaHomeApp';
  static const _channel = MethodChannel('com.aw.huda/widget');

  static const _languageKey = 'quranWidgetTranslationLanguage';
  static const _themeKey = 'quranWidgetVisualTheme';
  static const _ayahTextSizeKey = 'quranWidgetAyahTextSize';
  static const _translationTextSizeKey = 'quranWidgetTranslationTextSize';
  static const _ayahAutoFitKey = 'quranWidgetAyahAutoFit';
  static const _translationAutoFitKey = 'quranWidgetTranslationAutoFit';
  static const _ayahBoldKey = 'quranWidgetAyahBold';
  static const _translationBoldKey = 'quranWidgetTranslationBold';
  static const _legacyColorKeys = [
    'quranWidgetBackgroundColor',
    'quranWidgetAyahColor',
    'quranWidgetTranslationColor',
    'quranWidgetAccentColor',
  ];
  static const _rotationOffsetKey = 'quranWidgetRotationOffset';
  static const _migrationKey = 'quran_widget_standalone_migrated_v1';
  static const _localeKey = 'locale';

  static QuranWidgetSettings readSettings() {
    final cache = getIt<CacheHelper>();
    return QuranWidgetSettings(
      language: QuranWidgetTranslationLanguage.fromStorage(
        cache.getDataString(key: _languageKey),
      ),
      visualTheme: QuranWidgetVisualTheme.fromStorage(
        cache.getDataString(key: _themeKey),
      ),
      ayahTextSize: ((cache.getData(key: _ayahTextSizeKey) as int?) ?? 100)
          .clamp(70, 140)
          .toInt(),
      translationTextSize:
          ((cache.getData(key: _translationTextSizeKey) as int?) ?? 100)
              .clamp(70, 140)
              .toInt(),
      ayahAutoFit: (cache.getData(key: _ayahAutoFitKey) as bool?) ?? true,
      translationAutoFit:
          (cache.getData(key: _translationAutoFitKey) as bool?) ?? true,
      ayahBold: (cache.getData(key: _ayahBoldKey) as bool?) ?? false,
      translationBold:
          (cache.getData(key: _translationBoldKey) as bool?) ?? false,
      rotationOffset: (cache.getData(key: _rotationOffsetKey) as int?) ?? 0,
    );
  }

  static Future<void> initialize() {
    if (!PlatformUtils.isMobile) return Future<void>.value();
    return _enqueueOperation(() async {
      if (PlatformUtils.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }
      await _migrateLegacyWidgetData();
      await _pushSettingsNow();
    });
  }

  static Future<void> updateCustomization(QuranWidgetSettings next) {
    return _enqueueOperation(() async {
      final cache = getIt<CacheHelper>();
      await cache.saveData(key: _languageKey, value: next.language.storage);
      await cache.saveData(key: _themeKey, value: next.visualTheme.storage);
      await cache.saveData(key: _ayahTextSizeKey, value: next.ayahTextSize);
      await cache.saveData(
        key: _translationTextSizeKey,
        value: next.translationTextSize,
      );
      await cache.saveData(key: _ayahAutoFitKey, value: next.ayahAutoFit);
      await cache.saveData(
        key: _translationAutoFitKey,
        value: next.translationAutoFit,
      );
      await cache.saveData(key: _ayahBoldKey, value: next.ayahBold);
      await cache.saveData(
        key: _translationBoldKey,
        value: next.translationBold,
      );
      await cache.saveData(key: _rotationOffsetKey, value: next.rotationOffset);
      await _pushSettingsNow(throwOnFailure: true);
    });
  }

  static Future<void> resetCustomization() {
    return _enqueueOperation(() async {
      final cache = getIt<CacheHelper>();
      for (final key in [
        _languageKey,
        _themeKey,
        _ayahTextSizeKey,
        _translationTextSizeKey,
        _ayahAutoFitKey,
        _translationAutoFitKey,
        _ayahBoldKey,
        _translationBoldKey,
        ..._legacyColorKeys,
        _rotationOffsetKey,
      ]) {
        await cache.removeData(key: key);
      }
      await _pushSettingsNow(throwOnFailure: true);
    });
  }

  static Future<void> refreshNow() {
    return _enqueueOperation(() async {
      final cache = getIt<CacheHelper>();
      final current = readSettings();
      await cache.saveData(
        key: _rotationOffsetKey,
        value: current.rotationOffset + 1,
      );
      await _pushSettingsNow(throwOnFailure: true);
    });
  }

  static Future<void> onThemeChanged() => pushSettings();

  static Future<void> onLocaleChanged() => pushSettings();

  static Future<void> pushSettings({bool triggerNativeUpdate = true}) {
    if (!PlatformUtils.isMobile) return Future<void>.value();
    return _enqueueOperation(
      () => _pushSettingsNow(triggerNativeUpdate: triggerNativeUpdate),
    );
  }

  static Future<void> _pushSettingsNow({
    bool triggerNativeUpdate = true,
    bool throwOnFailure = false,
  }) async {
    if (!PlatformUtils.isMobile) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (PlatformUtils.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }

      final settings = readSettings();
      final theme = _resolveAppTheme(prefs);
      await _writeString(prefs, 'themeName', theme.themeName);
      await _writeString(prefs, 'themeMode', theme.themeMode);
      await _writeString(
        prefs,
        _localeKey,
        prefs.getString(_localeKey) ?? 'en',
      );
      await _writeString(prefs, _languageKey, settings.language.storage);
      await _writeString(prefs, _themeKey, settings.visualTheme.storage);
      await prefs.setInt(_ayahTextSizeKey, settings.ayahTextSize);
      await prefs.setInt(_translationTextSizeKey, settings.translationTextSize);
      await prefs.setBool(_ayahAutoFitKey, settings.ayahAutoFit);
      await prefs.setBool(_translationAutoFitKey, settings.translationAutoFit);
      await prefs.setBool(_ayahBoldKey, settings.ayahBold);
      await prefs.setBool(_translationBoldKey, settings.translationBold);
      if (PlatformUtils.isIOS) {
        await HomeWidget.saveWidgetData<int>(
          _ayahTextSizeKey,
          settings.ayahTextSize,
        );
        await HomeWidget.saveWidgetData<int>(
          _translationTextSizeKey,
          settings.translationTextSize,
        );
        await HomeWidget.saveWidgetData<bool>(
          _ayahAutoFitKey,
          settings.ayahAutoFit,
        );
        await HomeWidget.saveWidgetData<bool>(
          _translationAutoFitKey,
          settings.translationAutoFit,
        );
        await HomeWidget.saveWidgetData<bool>(_ayahBoldKey, settings.ayahBold);
        await HomeWidget.saveWidgetData<bool>(
          _translationBoldKey,
          settings.translationBold,
        );
      }
      for (final key in _legacyColorKeys) {
        await prefs.remove(key);
        if (PlatformUtils.isIOS) {
          await HomeWidget.saveWidgetData<String>(key, null);
        }
      }
      await prefs.setInt(_rotationOffsetKey, settings.rotationOffset);
      if (PlatformUtils.isIOS) {
        await HomeWidget.saveWidgetData<int>(
          _rotationOffsetKey,
          settings.rotationOffset,
        );
      }

      if (triggerNativeUpdate) await _refreshNativeWidget();
    } catch (error, stackTrace) {
      debugPrint('QuranWidgetService.pushSettings failed: $error');
      if (throwOnFailure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  static Future<void> _enqueueOperation(Future<void> Function() operation) {
    final queued = _operationQueue.then((_) => operation());
    _operationQueue = queued.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return queued;
  }

  static Future<void> _refreshNativeWidget() async {
    if (PlatformUtils.isIOS) {
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } else if (PlatformUtils.isAndroid) {
      await _channel.invokeMethod<void>('refreshQuranWidget');
    }
  }

  static Future<void> _migrateLegacyWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    for (final taskName in [
      'frequentWidgetUpdate',
      'backupWidgetUpdate',
      'immediateWidgetUpdate',
      'frequent-widget-update',
      'backup-widget-update',
      'conservative-widget-update',
      'immediate-widget-update',
    ]) {
      try {
        await Workmanager().cancelByUniqueName(taskName);
      } catch (_) {}
    }

    for (final key in [
      'custom_widget_verses',
      'widgetCustomVersesNative',
      'quote',
      'lastUpdate',
      'last_widget_update',
      'widget_background_updates_enabled',
    ]) {
      await prefs.remove(key);
    }
    if (PlatformUtils.isIOS) {
      await HomeWidget.saveWidgetData<String>('quote', null);
    }
    await prefs.setBool(_migrationKey, true);
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

  static _AppThemeSnapshot _resolveAppTheme(SharedPreferences prefs) {
    final colorTheme = AppColors.fromStorage(prefs.getString('color_theme'));
    final rawMode = prefs.getString('theme_mode');
    final mode = rawMode == 'dark' || rawMode == 'light'
        ? rawMode!
        : WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
        ? 'dark'
        : 'light';
    return _AppThemeSnapshot(
      themeName: colorTheme.toString().split('.').last,
      themeMode: mode,
    );
  }
}

class _AppThemeSnapshot {
  const _AppThemeSnapshot({required this.themeName, required this.themeMode});

  final String themeName;
  final String themeMode;
}

@immutable
class QuranWidgetSettings {
  const QuranWidgetSettings({
    this.language = QuranWidgetTranslationLanguage.auto,
    this.visualTheme = QuranWidgetVisualTheme.auto,
    this.ayahTextSize = 100,
    this.translationTextSize = 100,
    this.ayahAutoFit = true,
    this.translationAutoFit = true,
    this.ayahBold = false,
    this.translationBold = false,
    this.rotationOffset = 0,
  });

  final QuranWidgetTranslationLanguage language;
  final QuranWidgetVisualTheme visualTheme;
  final int ayahTextSize;
  final int translationTextSize;
  final bool ayahAutoFit;
  final bool translationAutoFit;
  final bool ayahBold;
  final bool translationBold;
  final int rotationOffset;

  String? effectiveLanguage(String appLocale) {
    if (language != QuranWidgetTranslationLanguage.auto) {
      return language.code;
    }
    if (appLocale == 'ar') return null;
    return QuranWidgetTranslationLanguage.supportedCodes.contains(appLocale)
        ? appLocale
        : 'en';
  }

  QuranWidgetSettings copyWith({
    QuranWidgetTranslationLanguage? language,
    QuranWidgetVisualTheme? visualTheme,
    int? ayahTextSize,
    int? translationTextSize,
    bool? ayahAutoFit,
    bool? translationAutoFit,
    bool? ayahBold,
    bool? translationBold,
    int? rotationOffset,
  }) {
    return QuranWidgetSettings(
      language: language ?? this.language,
      visualTheme: visualTheme ?? this.visualTheme,
      ayahTextSize: ayahTextSize ?? this.ayahTextSize,
      translationTextSize: translationTextSize ?? this.translationTextSize,
      ayahAutoFit: ayahAutoFit ?? this.ayahAutoFit,
      translationAutoFit: translationAutoFit ?? this.translationAutoFit,
      ayahBold: ayahBold ?? this.ayahBold,
      translationBold: translationBold ?? this.translationBold,
      rotationOffset: rotationOffset ?? this.rotationOffset,
    );
  }
}

enum QuranWidgetTranslationLanguage {
  auto,
  en,
  tr,
  fr,
  de,
  es,
  ur,
  ru,
  ms,
  bn;

  String get storage => name;
  String? get code => this == auto ? null : name;

  static const supportedCodes = {
    'en',
    'tr',
    'fr',
    'de',
    'es',
    'ur',
    'ru',
    'ms',
    'bn',
  };

  static QuranWidgetTranslationLanguage fromStorage(String? raw) {
    return values.firstWhere((value) => value.name == raw, orElse: () => auto);
  }
}

enum QuranWidgetVisualTheme {
  auto,
  ocean,
  sunset,
  forest,
  midnight,
  sandstone,
  rose,
  lavender,
  charcoal,
  amber,
  arctic,
  burgundy,
  sage;

  String get storage => name;

  static QuranWidgetVisualTheme fromStorage(String? raw) {
    return values.firstWhere((value) => value.name == raw, orElse: () => auto);
  }
}
