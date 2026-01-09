import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/utils/platform_utils.dart';

class WidgetService {
  static const String _iOSWidgetName = 'HudaWidget';
  static const String _lastUpdateKey = 'last_widget_update';
  static const String _customVersesKey = 'custom_widget_verses';

  static const MethodChannel _channel = MethodChannel('com.aw.huda/widget');

  static const List<String> _inspirationalVerses = [
    "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
    "وَٱللَّهُ غَفُورٌ رَّحِيمٌ",
    "وَٱلَّذِينَ صَبَرُوا۟ ٱبْتِغَآءَ وَجْهِ رَبِّهِمْ",
    "قَدْ أُجِيبَت دَّعْوَتُكُمَا",
    "فَاسْتَجَابَ لَكُمْ",
    "يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا",
    "سَيَجعَلُ اللَّهُ بَعدَ عُسرٍ يُسرًا",
    "لَا تَدْرِي لَعَلَّ اللَّهَ يُحْدِثُ بَعْدَ ذَٰلِكَ أَمْرًا",
    "رَبِّ اشْرَحْ لِي صَدْرِي",
    "وَتَوَكَّلْ عَلَى ٱللَّهِ ۚ وَكَفَىٰ بِٱللَّهِ وَكِيلًا",
    "نَصْرٌ مِنَ اللَّهِ وَفَتْحٌ قَرِيبٌ",
    "ادْعُونِي أَسْتَجِبْ لَكُمْ",
    "فَاسْتَجَابَ لَهُ رَبُّهُ",
    "عَسَىٰ أَنْ يَكُونَ قَرِيبًا",
    "اذْكُرُوا نِعْمَةَ اللَّهِ عَلَيْكُمْ",
    "وَأَثَابَهُمْ فَتْحًا قَرِيبًا",
    "فَنِعْمَ الْمَوْلَىٰ وَنِعْمَ النَّصِيرُ",
    "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا مَا آتَاهَا",
    "فَإِن تُبْتُمْ فَهُوَ خَيْرٌ لَّكُمْ",
    "إِنَّ وَعْدَ اللَّهِ حَقٌّ"
  ];

  static Future<void> initialize() async {
    if (!PlatformUtils.isMobile) return;

    if (PlatformUtils.isIOS) {
      await HomeWidget.setAppGroupId('group.hudaHomeApp');
    }

    await _saveThemeDataToPrefs();
  }

  static Future<void> updateWidget() async {
    if (!PlatformUtils.isMobile) return;

    try {
      final quote = await getRandomQuoteAsync();
      final now = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quote', quote);
      await prefs.setString('lastUpdate', now);

      final themeColorData = await _getCurrentThemeColor();

      await prefs.setString(
          'themeName', themeColorData['themeName'] ?? 'purple');
      await prefs.setString(
          'themeMode', themeColorData['themeMode'] ?? 'light');

      if (PlatformUtils.isIOS) {
        await HomeWidget.setAppGroupId('group.hudaHomeApp');
        await HomeWidget.saveWidgetData<String>('quote', quote);
        await HomeWidget.saveWidgetData<String>('lastUpdate', now);
        await HomeWidget.saveWidgetData<String>(
            'themeName', themeColorData['themeName']);
        await HomeWidget.saveWidgetData<String>(
            'themeMode', themeColorData['themeMode']);
        await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
      }

      if (PlatformUtils.isAndroid) {
        try {
          await _channel.invokeMethod('updateWidget');
          debugPrint('📱 Triggered native widget update');
        } catch (e) {
          debugPrint(
              'MethodChannel not available (expected on older versions): $e');
        }
      }

      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static Future<void> onThemeChanged() async {
    if (!PlatformUtils.isMobile) return;

    try {
      await _saveThemeDataToPrefs();

      await Future.delayed(const Duration(milliseconds: 100));

      if (PlatformUtils.isIOS) {
        await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
      }

      if (PlatformUtils.isAndroid) {
        try {
          await _channel.invokeMethod('updateWidget');
          debugPrint('🎨 Theme changed - triggered native widget update');
        } catch (e) {
          debugPrint('MethodChannel not available: $e');
        }
      }
    } catch (e) {
      debugPrint('Error handling theme change: $e');
    }
  }

  static Future<void> forceUpdateWidget() async {
    if (!PlatformUtils.isMobile) return;
    await updateWidget();
  }

  static Future<String> getRandomQuoteAsync() async {
    final customVerses = await getCustomVerses();
    final allVerses = [...customVerses, ..._inspirationalVerses];

    if (allVerses.isEmpty) {
      return _inspirationalVerses[0];
    }

    final random = Random();
    return allVerses[random.nextInt(allVerses.length)];
  }

  static Future<bool> addCustomVerse(String verse,
      {String? surahName, int? ayahNumber}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customVerses = await getCustomVerses();

      if (!customVerses.contains(verse)) {
        customVerses.add(verse);
        await prefs.setStringList(_customVersesKey, customVerses);

        await prefs.setString(
            'flutter.custom_widget_verses', customVerses.join('|||'));

        await updateWidget();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding custom verse: $e');
      return false;
    }
  }

  static Future<List<String>> getCustomVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_customVersesKey) ?? [];
    } catch (e) {
      debugPrint('Error getting custom verses: $e');
      return [];
    }
  }

  static Future<bool> removeCustomVerse(String verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customVerses = await getCustomVerses();

      if (customVerses.remove(verse)) {
        await prefs.setStringList(_customVersesKey, customVerses);
        await prefs.setString(
            'flutter.custom_widget_verses', customVerses.join('|||'));
        await updateWidget();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing custom verse: $e');
      return false;
    }
  }

  static Future<void> clearCustomVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customVersesKey);
      await prefs.remove('flutter.custom_widget_verses');
      await updateWidget();
    } catch (e) {
      debugPrint('Error clearing custom verses: $e');
    }
  }

  static Future<int> getCustomVersesCount() async {
    final verses = await getCustomVerses();
    return verses.length;
  }

  static Future<bool> isVerseInCustomCollection(String verse) async {
    final customVerses = await getCustomVerses();
    return customVerses.contains(verse);
  }

  static Future<List<String>> getAllVerses() async {
    final customVerses = await getCustomVerses();
    return [...customVerses, ..._inspirationalVerses];
  }

  static Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> _saveThemeDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeColorData = await _getCurrentThemeColor();

      await prefs.setString(
          'themeName', themeColorData['themeName'] ?? 'purple');
      await prefs.setString(
          'themeMode', themeColorData['themeMode'] ?? 'light');

      debugPrint(
          '💾 Saved theme to prefs: themeName=${themeColorData['themeName']}, themeMode=${themeColorData['themeMode']}');
    } catch (e) {
      debugPrint('Error saving theme data to prefs: $e');
    }
  }

  static Future<Map<String, String>> _getCurrentThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColorTheme = prefs.getString('color_theme');
      final savedThemeMode = prefs.getString('theme_mode');

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

      String themeMode = 'light';
      if (savedThemeMode == 'dark') {
        themeMode = 'dark';
      } else if (savedThemeMode == 'light') {
        themeMode = 'light';
      } else {
        themeMode = await _getSystemThemeMode();
      }

      final themeName = colorTheme.toString().split('.').last;

      return {
        'themeName': themeName,
        'themeMode': themeMode,
      };
    } catch (e) {
      debugPrint('Error getting theme color: $e');
      return {
        'themeName': 'purple',
        'themeMode': 'light',
      };
    }
  }

  static Future<String> _getSystemThemeMode() async {
    try {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? 'dark' : 'light';
    } catch (e) {
      debugPrint('Error detecting system theme: $e');
      return 'light';
    }
  }
}
