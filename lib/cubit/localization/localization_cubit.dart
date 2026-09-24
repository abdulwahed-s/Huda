import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/quran_widget_service.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationState {
  final Locale locale;

  LocalizationState({required this.locale});

  LocalizationState copyWith({Locale? locale}) {
    return LocalizationState(locale: locale ?? this.locale);
  }
}

class LocalizationCubit extends Cubit<LocalizationState> {
  static const _localeKey = 'app_locale';

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ar', ''),
    Locale('tr', ''),
    Locale('fr', ''),
    Locale('es', ''),
    Locale('de', ''),
    Locale('ru', ''),
    Locale('ur', ''),
    Locale('ms', ''),
    Locale('bn', ''),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
    'tr': 'Türkçe',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'ru': 'Русский',
    'ur': 'اردو',
    'ms': 'Bahasa Melayu',
    'bn': 'বাংলা',
  };

  LocalizationCubit()
    : super(LocalizationState(locale: const Locale('en', ''))) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = getIt<CacheHelper>();
    final savedLocale = prefs.getDataString(key: _localeKey);

    if (savedLocale != null && savedLocale.isNotEmpty) {
      final locale = Locale(savedLocale, '');
      if (supportedLocales.contains(locale)) {
        await _persistSelectedLocale(savedLocale);

        emit(LocalizationState(locale: locale));
        await QuranWidgetService.onLocaleChanged();
        await _reconcilePrayerPresentation('saved-locale-loaded');
        return;
      }
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    final systemLanguageCode = systemLocale.languageCode;

    final supportedSystemLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == systemLanguageCode,
      orElse: () => const Locale('en', ''),
    );

    if (supportedSystemLocale.languageCode != 'en') {
      await _persistSelectedLocale(supportedSystemLocale.languageCode);

      emit(LocalizationState(locale: supportedSystemLocale));
    } else {
      await _persistSelectedLocale('en');
    }

    await _reconcilePrayerPresentation('system-locale-selected');
    await QuranWidgetService.onLocaleChanged();
  }

  Future<void> setLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      await _persistSelectedLocale(locale.languageCode);

      emit(LocalizationState(locale: locale));
      await QuranWidgetService.onLocaleChanged();

      await _reconcilePrayerPresentation('locale-changed');
    }
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  Future<void> _refreshPrayerWidgetLocale() async {
    try {
      if (PrayerWidgetService.readSettings().language !=
          PrayerWidgetLanguage.auto) {
        return;
      }
      await PrayerWidgetService.pushSettings();
    } catch (error) {
      debugPrint('Could not refresh prayer widget locale: $error');
    }
  }

  Future<void> _reconcilePrayerPresentation(String reason) async {
    if (getIt.isRegistered<PrayerNotificationScheduler>()) {
      await getIt<PrayerNotificationScheduler>().reconcile(
        reason: reason,
        force: true,
      );
      return;
    }
    await _refreshPrayerWidgetLocale();
  }

  Future<void> _persistSelectedLocale(String languageCode) async {
    Future<void> write() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      await prefs.setString('locale', languageCode);
    }

    if (getIt.isRegistered<PrayerLocationRepository>()) {
      await getIt<PrayerLocationRepository>().synchronized((_) => write());
    } else {
      await write();
    }
  }
}
