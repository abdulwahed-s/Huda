import 'dart:math';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/theme/app_colors.dart';

class WidgetService {
  static const String _widgetName = 'HudaWidgetProvider';
  static const String _iOSWidgetName = 'HudaWidget';
  static const String _lastUpdateKey = 'last_widget_update';
  static const String _customVersesKey = 'custom_widget_verses';

  // Static callback for theme change notifications
  static Function()? _onThemeChangeCallback;

  // Default verses for the widget
  static const List<String> _inspirationalVerses = [
    "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", // Al-Sharh 94:6
    "وَٱللَّهُ غَفُورٌ رَّحِيمٌ", // Al-Baqarah 2:226
    "وَٱلَّذِينَ صَبَرُوا۟ ٱبْتِغَآءَ وَجْهِ رَبِّهِمْ", // Ar-Ra'd 13:22
    "قَدْ أُجِيبَت دَّعْوَتُكُمَا",
    "فَاسْتَجَابَ لَكُمْ",
    "يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا",
    "سَيَجعَلُ اللَّهُ بَعدَ عُسرٍ يُسرًا",
    "لَا تَدْرِي لَعَلَّ اللَّهَ يُحْدِثُ بَعْدَ ذَٰلِكَ أَمْرًا",
    "رَبِّ اشْرَحْ لِي صَدْرِي",
    "وَتَوَكَّلْ عَلَى ٱللَّهِ ۚ وَكَفَىٰ بِٱللَّهِ وَكِيلًا", // Al-Ahzab 33:3
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

  /// Set callback for theme change notifications
  static void setThemeChangeCallback(Function() callback) {
    _onThemeChangeCallback = callback;
  }

  /// Clear theme change callback
  static void clearThemeChangeCallback() {
    _onThemeChangeCallback = null;
  }

  /// Initialize the widget service
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
    await _updateWidget();
  }

  /// Update the widget with a new random quote
  static Future<void> updateWidget() async {
    await _updateWidget();

    // Trigger immediate widget regeneration callback for content updates
    if (_onThemeChangeCallback != null) {
      debugPrint('📢 Notifying widget generator about content update');
      _onThemeChangeCallback!();
    }
  }

  /// Register interactivity for the widget
  static Future<void> registerInteractivity() async {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  /// Background callback for widget interactions
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    try {
      // Initialize the background isolate
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');

      if (uri?.host == 'updateWidget') {
        await updateWidget();
      }
    } catch (e) {
      debugPrint('Error in background callback: $e');
    }
  }

  /// Internal method to update the widget
  static Future<void> _updateWidget() async {
    try {
      // Ensure proper initialization
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');

      final quote = await getRandomQuoteAsync();
      final now = DateTime.now().toIso8601String();

      // Get current theme color
      final themeColorData = await _getCurrentThemeColor();

      // Save data with correct keys that Android widget expects
      await HomeWidget.saveWidgetData<String>('quote', quote);
      await HomeWidget.saveWidgetData<String>('lastUpdate', now);
      await HomeWidget.saveWidgetData<String>(
          'themeColorPrimary', themeColorData['primary']);
      await HomeWidget.saveWidgetData<String>(
          'themeColorAccent', themeColorData['accent']);
      await HomeWidget.saveWidgetData<String>(
          'themeName', themeColorData['themeName']);
      await HomeWidget.saveWidgetData<String>(
          'themeMode', themeColorData['themeMode']);

      // Mark that image generation is needed
      await HomeWidget.saveWidgetData<String>('needsImageGeneration', 'true');
      await HomeWidget.saveWidgetData<String>(
          'flutter.needsCompleteWidgetImage', 'true');

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _widgetName,
      );

      // Save last update time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Save generated image path
  static Future<void> saveGeneratedImagePath(String imagePath) async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      await HomeWidget.saveWidgetData<String>('textImagePath', imagePath);
      await HomeWidget.saveWidgetData<String>('needsImageGeneration', 'false');

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      debugPrint('Error saving image path: $e');
    }
  }

  /// Check if image generation is needed
  static Future<bool> needsImageGeneration() async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      final needsGeneration = await HomeWidget.getWidgetData<String>(
          'needsImageGeneration',
          defaultValue: 'false');
      return needsGeneration == 'true';
    } catch (e) {
      debugPrint('Error checking image generation status: $e');
      return false;
    }
  }

  /// Trigger image generation when theme changes
  static Future<void> onThemeChanged() async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      // Mark that new image needs to be generated with new theme
      await HomeWidget.saveWidgetData<String>('needsImageGeneration', 'true');
      await HomeWidget.saveWidgetData<String>(
          'flutter.needsCompleteWidgetImage', 'true');

      // Get current theme data
      final themeColorData = await _getCurrentThemeColor();

      // Update theme data in widget storage
      await HomeWidget.saveWidgetData<String>(
          'themeColorPrimary', themeColorData['primary']);
      await HomeWidget.saveWidgetData<String>(
          'themeColorAccent', themeColorData['accent']);
      await HomeWidget.saveWidgetData<String>(
          'themeName', themeColorData['themeName']);
      await HomeWidget.saveWidgetData<String>(
          'themeMode', themeColorData['themeMode']);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _widgetName,
      );

      debugPrint('🎨 Theme changed - marked widget for regeneration');

      // Notify CompleteWidgetGenerator about theme change for immediate regeneration
      if (_onThemeChangeCallback != null) {
        debugPrint('📢 Notifying widget generator about theme change');
        _onThemeChangeCallback!();
      }
    } catch (e) {
      debugPrint('Error handling theme change: $e');
    }
  }

  /// Force widget update when system theme changes
  static Future<void> onSystemThemeChanged() async {
    try {
      debugPrint('🌓 System theme changed - updating widget');

      // Clear any cached theme mode to force re-detection
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');

      // Get fresh theme data with system detection
      final themeColorData = await _getCurrentThemeColor();

      // Update theme data in widget storage
      await HomeWidget.saveWidgetData<String>(
          'themeColorPrimary', themeColorData['primary']);
      await HomeWidget.saveWidgetData<String>(
          'themeColorAccent', themeColorData['accent']);
      await HomeWidget.saveWidgetData<String>(
          'themeName', themeColorData['themeName']);
      await HomeWidget.saveWidgetData<String>(
          'themeMode', themeColorData['themeMode']);

      // Mark that new image needs to be generated with new theme
      await HomeWidget.saveWidgetData<String>('needsImageGeneration', 'true');
      await HomeWidget.saveWidgetData<String>(
          'flutter.needsCompleteWidgetImage', 'true');

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _widgetName,
      );

      debugPrint('✅ Widget updated for system theme change');
    } catch (e) {
      debugPrint('Error updating widget for system theme change: $e');
    }
  }

  /// Get current theme data for image generation
  static Future<Map<String, String>> getCurrentThemeDataForGeneration() async {
    return await _getCurrentThemeColor();
  }

  /// Force update the widget immediately
  static Future<void> forceUpdateWidget() async {
    await _updateWidget();

    // Trigger immediate widget regeneration callback
    if (_onThemeChangeCallback != null) {
      debugPrint('📢 Notifying widget generator about forced update');
      _onThemeChangeCallback!();
    }
  }

  /// Get last update time
  static Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Check if widget should be updated (every 2 hours - Android friendly)
  static Future<bool> shouldUpdateWidget() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inHours >=
        2; // Update every 2 hours for better battery life
  }

  /// Get a random quote
  static Future<String> getRandomQuoteAsync() async {
    // Get custom verses first, then fall back to default ones
    final customVerses = await getCustomVerses();
    final allVerses = [...customVerses, ..._inspirationalVerses];

    if (allVerses.isEmpty) {
      return _inspirationalVerses[0]; // Fallback to first default verse
    }

    final random = Random();
    final selectedVerse = allVerses[random.nextInt(allVerses.length)];
    return selectedVerse;
  }

  /// Add a custom verse to the widget collection
  static Future<bool> addCustomVerse(String verse,
      {String? surahName, int? ayahNumber}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customVerses = await getCustomVerses();

      // Check if verse already exists
      if (!customVerses.contains(verse)) {
        customVerses.add(verse);
        final versesJson = customVerses;
        await prefs.setStringList(_customVersesKey, versesJson);

        // Update widget to potentially show the new verse
        await updateWidget();
        return true;
      } else {
        return false; // Verse already exists
      }
    } catch (e) {
      debugPrint('Error adding custom verse: $e');
      return false;
    }
  }

  /// Get all custom verses
  static Future<List<String>> getCustomVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versesJson = prefs.getStringList(_customVersesKey);
      if (versesJson != null) {
        return versesJson;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting custom verses: $e');
      return [];
    }
  }

  /// Remove a custom verse
  static Future<bool> removeCustomVerse(String verse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customVerses = await getCustomVerses();

      if (customVerses.remove(verse)) {
        await prefs.setStringList(_customVersesKey, customVerses);
        await updateWidget();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing custom verse: $e');
      return false;
    }
  }

  /// Clear all custom verses
  static Future<void> clearCustomVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customVersesKey);
      await updateWidget();
    } catch (e) {
      debugPrint('Error clearing custom verses: $e');
    }
  }

  /// Get the number of custom verses
  static Future<int> getCustomVersesCount() async {
    final verses = await getCustomVerses();
    return verses.length;
  }

  /// Check if a verse is already in custom collection
  static Future<bool> isVerseInCustomCollection(String verse) async {
    final customVerses = await getCustomVerses();
    return customVerses.contains(verse);
  }

  /// Get all verses (custom + default) for display purposes
  static Future<List<String>> getAllVerses() async {
    final customVerses = await getCustomVerses();
    return [...customVerses, ..._inspirationalVerses];
  }

  /// Get current theme color from SharedPreferences
  static Future<Map<String, String>> _getCurrentThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColorTheme = prefs.getString('color_theme');
      final savedThemeMode = prefs.getString('theme_mode');

      // Parse the theme enum
      AppColorTheme colorTheme = AppColorTheme.purple; // default
      if (savedColorTheme != null) {
        try {
          colorTheme = AppColorTheme.values.firstWhere(
            (theme) => theme.toString() == savedColorTheme,
          );
        } catch (e) {
          colorTheme = AppColorTheme.purple;
        }
      }

      // Determine theme mode with proper system theme detection
      String themeMode = 'light'; // default
      if (savedThemeMode == 'dark') {
        themeMode = 'dark';
      } else if (savedThemeMode == 'light') {
        themeMode = 'light';
      } else {
        // savedThemeMode is null (system theme) or 'system'
        // Detect actual system theme
        themeMode = await _getSystemThemeMode();
      }

      // Get color scheme and convert to hex strings
      final colorScheme = AppColors.getColorScheme(colorTheme);
      final themeName =
          colorTheme.toString().split('.').last; // Get just the theme name

      return {
        'primary':
            '#${colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
        'accent':
            '#${colorScheme.accent.toARGB32().toRadixString(16).substring(2)}',
        'themeName': themeName,
        'themeMode': themeMode,
      };
    } catch (e) {
      debugPrint('Error getting theme color: $e');
      // Return default purple theme colors
      return {
        'primary': '#FF674B5D',
        'accent': '#FF8B5CF6',
        'themeName': 'purple',
      };
    }
  }

  /// Detect system theme mode using platform brightness
  static Future<String> _getSystemThemeMode() async {
    try {
      // Use WidgetsBinding to get system brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? 'dark' : 'light';
    } catch (e) {
      debugPrint('Error detecting system theme: $e');
      // Fallback: try to get it from saved theme mode or default to light
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('theme_mode');
      if (savedMode == 'dark') return 'dark';
      return 'light'; // Default fallback
    }
  }

  /// Check and update widget if needed
  static Future<void> checkAndUpdate() async {
    if (await shouldUpdateWidget()) {
      await updateWidget();
    }
  }

  /// Get current widget data for image generation
  static Future<Map<String, dynamic>> getCurrentWidgetData() async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');

      final ayah = await HomeWidget.getWidgetData<String>('quote',
          defaultValue: 'إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا');
      final timestamp = await HomeWidget.getWidgetData<String>('lastUpdate',
          defaultValue: 'آخر تحديث: الآن');
      final themeName = await HomeWidget.getWidgetData<String>('themeName',
          defaultValue: 'purple');
      final themeMode = await HomeWidget.getWidgetData<String>('themeMode',
          defaultValue: 'system');

      // Remove surah and verse info since they're not part of our ayah lists
      // final prefs = await SharedPreferences.getInstance();
      // final surahName = prefs.getString('widget_surah_name') ?? 'سورة الشرح';
      // final verseNumber = prefs.getString('widget_verse_number') ?? 'آية 6';

      // Determine if dark mode based on theme mode and system settings
      bool isDarkMode = false;
      if (themeMode == 'dark') {
        isDarkMode = true;
      } else if (themeMode == 'light') {
        isDarkMode = false;
      } else {
        // System mode - detect actual system theme
        final systemTheme = await _getSystemThemeMode();
        isDarkMode = systemTheme == 'dark';
      }

      return {
        'ayah': ayah,
        'surahName': '', // Remove surah info
        'verseNumber': '', // Remove verse info
        'themeName': themeName,
        'isDarkMode': isDarkMode,
        'timestamp': _formatTimestamp(timestamp ?? 'آخر تحديث: الآن'),
      };
    } catch (e) {
      debugPrint('Error getting current widget data: $e');
      return {
        'ayah': 'إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا',
        'surahName': '', // Remove surah info
        'verseNumber': '', // Remove verse info
        'themeName': 'purple',
        'isDarkMode': false,
        'timestamp': 'آخر تحديث: الآن',
      };
    }
  }

  /// Check if complete widget image generation is needed
  static Future<bool> needsCompleteWidgetImage() async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      final needsGeneration = await HomeWidget.getWidgetData<String>(
          'flutter.needsCompleteWidgetImage',
          defaultValue: 'true');
      return needsGeneration == 'true';
    } catch (e) {
      debugPrint('Error checking complete widget image generation status: $e');
      return true; // Default to generating
    }
  }

  /// Save the complete widget image path
  static Future<void> saveCompleteWidgetImagePath(String imagePath) async {
    try {
      debugPrint('🔄 Saving complete widget image path: $imagePath');
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      await HomeWidget.saveWidgetData<String>(
          'flutter.completeWidgetImagePath', imagePath);
      await HomeWidget.saveWidgetData<String>(
          'flutter.needsCompleteWidgetImage', 'false');

      debugPrint('📱 Updating home widget...');
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _widgetName,
      );
      debugPrint('✅ Widget updated with new image path');
    } catch (e) {
      debugPrint('❌ Error saving complete widget image path: $e');
    }
  }

  /// Mark that complete widget image needs regeneration
  static Future<void> markCompleteWidgetImageNeeded() async {
    try {
      await HomeWidget.setAppGroupId('group.com.aw.huda.widget');
      await HomeWidget.saveWidgetData<String>(
          'flutter.needsCompleteWidgetImage', 'true');
    } catch (e) {
      debugPrint('Error marking complete widget image needed: $e');
    }
  }

  /// Format timestamp for display
  static String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'آخر تحديث: الآن';
      } else if (difference.inMinutes < 60) {
        return 'آخر تحديث: ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'آخر تحديث: ${difference.inHours} ساعة';
      } else {
        return 'آخر تحديث: ${difference.inDays} يوم';
      }
    } catch (e) {
      return 'آخر تحديث: الآن';
    }
  }

  // Android Optimization Methods

  /// Android-optimized widget update with reduced frequency
  static Future<void> updateWidgetOptimized() async {
    // Only update if enough time has passed or theme changed
    if (await shouldUpdateWidget() || await _hasThemeChanged()) {
      await _updateWidget();
    } else {
      debugPrint(
          '⏭️ Skipping widget update - too frequent (Android optimization)');
    }
  }

  /// Check if theme has changed since last update
  static Future<bool> _hasThemeChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTheme = prefs.getString('last_widget_theme') ?? '';

      final currentThemeData = await _getCurrentThemeColor();
      final currentTheme =
          '${currentThemeData['themeName']}_${currentThemeData['themeMode']}';

      if (lastTheme != currentTheme) {
        await prefs.setString('last_widget_theme', currentTheme);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking theme change: $e');
      return false;
    }
  }

  /// Set widget update strategy for Android optimization
  static Future<void> setOptimizationMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_optimization_enabled', enabled);
    debugPrint(enabled
        ? '🔋 Android widget optimization enabled'
        : '⚡ High-frequency widget updates enabled');
  }

  /// Check if optimization mode is enabled
  static Future<bool> isOptimizationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('widget_optimization_enabled') ??
        true; // Default to enabled
  }
}
