import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationState {
  final Locale locale;

  LocalizationState({required this.locale});

  LocalizationState copyWith({Locale? locale}) {
    return LocalizationState(
      locale: locale ?? this.locale,
    );
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
        final sharedPrefs = await SharedPreferences.getInstance();
        await sharedPrefs.setString('locale', savedLocale);

        emit(LocalizationState(locale: locale));
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
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString('locale', supportedSystemLocale.languageCode);

      emit(LocalizationState(locale: supportedSystemLocale));
    } else {
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString('locale', 'en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_localeKey, locale.languageCode);

      await prefs.setString('locale', locale.languageCode);

      emit(LocalizationState(locale: locale));
    }
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
}
