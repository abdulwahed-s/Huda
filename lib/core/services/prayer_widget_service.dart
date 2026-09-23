import 'dart:convert';

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
  static const List<String> _iOSWidgetNames = [
    iOSWidgetName,
    'HudaEarlyPrayerTimesWidget',
    'HudaLatePrayerTimesWidget',
    'HudaPrayerPathWidget',
    'HudaPrayerAlmanacWidget',
  ];

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
  static const List<String> _customAngleKeys = [
    PrayerTimesCalculator.customFajrAngleKey,
    PrayerTimesCalculator.customMaghribAngleKey,
    PrayerTimesCalculator.customIshaAngleKey,
  ];

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
  static const String _settingsPayloadKey = 'prayer_widget_settings_v2';
  static const String _timeFormatKey = 'prayer_widget_time_format';

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
      timeFormat: PrayerWidgetTimeFormat.fromStorage(
        cache.getDataString(key: _timeFormatKey),
      ),
    );
  }

  static Future<void> initialize() async {
    if (!PlatformUtils.isMobile) return;
    if (PlatformUtils.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }

    // Commit shared values before asking WidgetKit for a replacement timeline.
    // This also recovers a redacted/placeholder widget after an extension
    // watchdog termination instead of waiting for WidgetKit's next refresh.
    await pushSettings();
  }

  static Future<PrayerWidgetUpdateReport?> pushSettings({
    bool triggerNativeUpdate = true,
  }) async {
    if (!PlatformUtils.isMobile) return null;

    final cache = getIt<CacheHelper>();
    await cache.reload();
    final prefs = await SharedPreferences.getInstance();
    if (PlatformUtils.isIOS) await HomeWidget.setAppGroupId(_appGroupId);

    final lat = cache.getDataString(key: _latKey);
    final lon = cache.getDataString(key: _lonKey);
    final countryCode = cache.getDataString(key: _countryCodeKey) ?? '';
    final timeZoneId = cache.getDataString(
      key: PrayerTimesCalculator.timeZoneIdKey,
    );
    final locationMode =
        cache.getDataString(key: PrayerTimesCalculator.locationModeKey) ??
        'manual';
    final method =
        cache.getDataString(key: _methodKey) ??
        PrayerTimesCalculator.defaultMethodToken;
    final madhab =
        cache.getDataString(key: _madhabKey) ??
        PrayerTimesCalculator.defaultMadhabToken;
    final highLatitude =
        cache.getDataString(key: _highLatKey) ??
        PrayerTimesCalculator.defaultHighLatitudeToken;

    await _writeString(prefs, _latKey, lat);
    await _writeString(prefs, _lonKey, lon);
    await _writeString(prefs, _countryCodeKey, countryCode);
    await _writeString(prefs, PrayerTimesCalculator.timeZoneIdKey, timeZoneId);
    await _writeString(
      prefs,
      PrayerTimesCalculator.locationModeKey,
      locationMode,
    );
    await _writeString(prefs, _methodKey, method);
    await _writeString(prefs, _madhabKey, madhab);
    await _writeString(prefs, _highLatKey, highLatitude);

    final customAngles = PrayerTimesCalculator.customAnglesFromCache(cache);
    final customAngleValues = <String, String>{
      PrayerTimesCalculator.customFajrAngleKey: CustomPrayerAngles.canonical(
        customAngles.fajr,
      ),
      PrayerTimesCalculator.customMaghribAngleKey: CustomPrayerAngles.canonical(
        customAngles.maghrib,
      ),
      PrayerTimesCalculator.customIshaAngleKey: CustomPrayerAngles.canonical(
        customAngles.isha,
      ),
    };
    for (final key in _customAngleKeys) {
      await _writeString(prefs, key, customAngleValues[key]);
    }

    final offsets = <String, int>{};
    for (final key in _offsetKeys) {
      final storageKey = PrayerTimesCalculator.offsetKeyFor(key);
      final offset = PrayerTimesCalculator.sanitizeOffset(
        (cache.getData(key: storageKey) as int?) ?? 0,
      );
      offsets[key] = offset;
      await _setInt(prefs, storageKey, offset);
    }

    final theme = _resolveTheme(prefs);
    final settings = readSettings();
    final effectiveLocale = settings.language == PrayerWidgetLanguage.auto
        ? (prefs.getString(_localeKey) ?? 'en')
        : settings.language.code;
    await _writeString(prefs, _themeNameKey, theme['themeName']);
    await _writeString(prefs, _themeModeKey, theme['themeMode']);
    await _writeString(prefs, _localeKey, effectiveLocale);
    await _writeString(prefs, _designKey, settings.design.storage);
    await _writeString(prefs, _languageKey, settings.language.storage);
    await _writeString(prefs, _numeralsKey, settings.numerals.storage);
    await _setBool(prefs, _bgEnabledKey, settings.backgroundEnabled);
    await _writeString(prefs, _bgColorKey, settings.backgroundColor);
    await _setBool(prefs, _bgGlassifyKey, settings.glassify);
    await _setBool(prefs, _bgRoundedKey, settings.rounded);
    await _writeString(prefs, _contentColorKey, settings.contentColor);
    await _writeString(prefs, _highlightColorKey, settings.highlightColor);
    await _setInt(prefs, _contentSizeKey, settings.contentSize);
    await _writeString(prefs, _visualThemeKey, settings.visualTheme.storage);
    await _writeString(prefs, _timeFormatKey, settings.timeFormat.storage);

    final committedAt = DateTime.now().toUtc();
    final payload = jsonEncode(<String, Object?>{
      'version': 2,
      'revision': committedAt.microsecondsSinceEpoch,
      'committedAt': committedAt.toIso8601String(),
      'coordinates': lat == null || lon == null
          ? null
          : <String, String>{'latitude': lat, 'longitude': lon},
      'locationMode': locationMode,
      'timeZoneId': timeZoneId,
      'countryCode': countryCode,
      'calculationMethod': method,
      'madhab': madhab,
      'highLatitudeRule': highLatitude,
      'customAngles': customAngleValues,
      'offsets': offsets,
      'timeFormat': settings.timeFormat.storage,
      'appearance': <String, Object?>{
        'themeName': theme['themeName'],
        'themeMode': theme['themeMode'],
        'locale': effectiveLocale,
        'design': settings.design.storage,
        'language': settings.language.storage,
        'numerals': settings.numerals.storage,
        'backgroundEnabled': settings.backgroundEnabled,
        'backgroundColor': settings.backgroundColor,
        'glassify': settings.glassify,
        'rounded': settings.rounded,
        'contentColor': settings.contentColor,
        'highlightColor': settings.highlightColor,
        'contentSize': settings.contentSize,
      },
    });
    await _setInt(
      prefs,
      _lastUpdateKey,
      committedAt.millisecondsSinceEpoch,
      shareWithWidget: false,
    );
    await _writeString(prefs, _settingsPayloadKey, payload);

    if (triggerNativeUpdate) {
      return _refreshNativeWidget(
        expectedRevision: committedAt.microsecondsSinceEpoch,
      );
    }
    return null;
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
    await cache.saveData(key: _timeFormatKey, value: next.timeFormat.storage);
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
    await cache.removeData(key: _timeFormatKey);
    await pushSettings();
  }

  static Future<PrayerWidgetUpdateReport?> forceUpdate() async {
    return pushSettings();
  }

  static Future<void> onAppThemeChanged() async {
    await pushSettings();
  }

  static Future<PrayerWidgetUpdateReport?> _refreshNativeWidget({
    required int expectedRevision,
  }) async {
    if (PlatformUtils.isIOS) {
      for (final widgetName in _iOSWidgetNames) {
        await requireSuccessfulPlatformOperation(
          HomeWidget.updateWidget(iOSName: widgetName),
          operation: 'reload $widgetName',
        );
      }
    }
    if (PlatformUtils.isAndroid) {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'updatePrayerWidget',
      );
      if (raw == null) {
        throw StateError('Android prayer widget returned no update result');
      }
      final report = PrayerWidgetUpdateReport.fromMap(raw);
      if (report.revision != expectedRevision) {
        throw StateError(
          'Android rendered settings revision ${report.revision}; '
          'expected $expectedRevision',
        );
      }
      if (report.failedUpdates > 0) {
        throw StateError(
          'Failed to update ${report.failedUpdates}/${report.widgetCount} '
          'prayer widgets: ${report.error}',
        );
      }
      if (report.alarmError != null && report.alarmError!.isNotEmpty) {
        throw StateError(
          'Prayer transition scheduling failed: ${report.alarmError}',
        );
      }
      return report;
    }
    return null;
  }

  static Future<void> _writeString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      final removed = await prefs.remove(key);
      if (!removed && prefs.containsKey(key)) {
        throw StateError('Failed to remove $key');
      }
      if (PlatformUtils.isIOS) {
        await _saveWidgetValue<String>(key, null);
      }
      return;
    }
    if (!await prefs.setString(key, value)) {
      throw StateError('Failed to persist $key');
    }
    if (PlatformUtils.isIOS) {
      await _saveWidgetValue<String>(key, value);
    }
  }

  static Future<void> _setInt(
    SharedPreferences prefs,
    String key,
    int value, {
    bool shareWithWidget = true,
  }) async {
    if (!await prefs.setInt(key, value)) {
      throw StateError('Failed to persist $key');
    }
    if (shareWithWidget && PlatformUtils.isIOS) {
      await _saveWidgetValue<int>(key, value);
    }
  }

  static Future<void> _setBool(
    SharedPreferences prefs,
    String key,
    bool value,
  ) async {
    if (!await prefs.setBool(key, value)) {
      throw StateError('Failed to persist $key');
    }
    if (PlatformUtils.isIOS) await _saveWidgetValue<bool>(key, value);
  }

  static Future<void> _saveWidgetValue<T>(String key, T? value) async {
    await requireSuccessfulPlatformOperation(
      HomeWidget.saveWidgetData<T>(key, value),
      operation: 'write App Group value $key',
    );
  }

  @visibleForTesting
  static Future<void> requireSuccessfulPlatformOperation(
    Future<bool?> result, {
    required String operation,
  }) async {
    if (await result != true) throw StateError('Failed to $operation');
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
class PrayerWidgetUpdateReport {
  const PrayerWidgetUpdateReport({
    required this.revision,
    required this.widgetCount,
    required this.successfulUpdates,
    required this.failedUpdates,
    required this.rendererPaths,
    required this.alarmScheduled,
    required this.alarmPrecision,
    this.error,
    this.alarmError,
    this.broadcastError,
  });

  factory PrayerWidgetUpdateReport.fromMap(
    Map<String, Object?> map, {
    Object? broadcastError,
  }) {
    int integer(String key) => (map[key] as num?)?.toInt() ?? 0;
    final paths = <String, int>{};
    final rawPaths = map['rendererPath'];
    if (rawPaths is Map) {
      for (final entry in rawPaths.entries) {
        paths[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }
    return PrayerWidgetUpdateReport(
      revision: integer('revision'),
      widgetCount: integer('widgetCount'),
      successfulUpdates: integer('successfulUpdates'),
      failedUpdates: integer('failedUpdates'),
      rendererPaths: paths,
      alarmScheduled: map['alarmScheduled'] == true,
      alarmPrecision: map['alarmPrecision']?.toString() ?? 'none',
      error: map['error']?.toString(),
      alarmError: map['alarmError']?.toString(),
      broadcastError: broadcastError,
    );
  }

  final int revision;
  final int widgetCount;
  final int successfulUpdates;
  final int failedUpdates;
  final Map<String, int> rendererPaths;
  final bool alarmScheduled;
  final String alarmPrecision;
  final String? error;
  final String? alarmError;
  final Object? broadcastError;
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
  final PrayerWidgetTimeFormat timeFormat;

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
    this.timeFormat = PrayerWidgetTimeFormat.system,
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
    PrayerWidgetTimeFormat? timeFormat,
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
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  static const _unset = Object();
}

enum PrayerWidgetTimeFormat {
  system,
  twelveHour,
  twentyFourHour;

  String get storage => switch (this) {
    system => 'system',
    twelveHour => '12h',
    twentyFourHour => '24h',
  };

  static PrayerWidgetTimeFormat fromStorage(String? raw) => switch (raw) {
    '12h' => twelveHour,
    '24h' => twentyFourHour,
    _ => system,
  };
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
    highlightColor: '#FF4DD0E1',
  ),
  sunset(
    backgroundColor: '#FF5C2A0E',
    contentColor: '#FFFFF5EB',
    highlightColor: '#FFFFD54F',
  ),
  forest(
    backgroundColor: '#FF1B3A2A',
    contentColor: '#FFE8F5E9',
    highlightColor: '#FF66BB6A',
  ),
  midnight(
    backgroundColor: '#FF121218',
    contentColor: '#FFE0E0E8',
    highlightColor: '#FF7986CB',
  ),
  sandstone(
    backgroundColor: '#FFF5E6D3',
    contentColor: '#FF3E2C1A',
    highlightColor: '#FFD84315',
  ),
  rose(
    backgroundColor: '#FF3D1A2E',
    contentColor: '#FFFCE4EC',
    highlightColor: '#FFF06292',
  ),
  lavender(
    backgroundColor: '#FF2E2450',
    contentColor: '#FFEDE7F6',
    highlightColor: '#FFBA68C8',
  ),
  charcoal(
    backgroundColor: '#FF2C2C2C',
    contentColor: '#FFF5F5F5',
    highlightColor: '#FFFFB74D',
  ),
  amber(
    backgroundColor: '#FF4A3000',
    contentColor: '#FFFFF8E1',
    highlightColor: '#FFFFD740',
  ),
  arctic(
    backgroundColor: '#FFE3F2FD',
    contentColor: '#FF0D2137',
    highlightColor: '#FF1976D2',
  ),
  burgundy(
    backgroundColor: '#FF4A0E1E',
    contentColor: '#FFFDE8EF',
    highlightColor: '#FFEF5350',
  ),
  sage(
    backgroundColor: '#FF3B4A3A',
    contentColor: '#FFF1F5E8',
    highlightColor: '#FF81C784',
  );

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
