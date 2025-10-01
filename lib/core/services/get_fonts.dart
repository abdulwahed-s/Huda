import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

String getQuranFonts() {
  final cacheHelper = getIt<CacheHelper>();
  final quranFont = cacheHelper.getData(key: 'quran_font') ?? "Amiri";
  return quranFont;
}

void setQuranFonts(String font) {
  final cacheHelper = getIt<CacheHelper>();
  cacheHelper.saveData(key: 'quran_font', value: font);
}

String getAppFont() {
  final cacheHelper = getIt<CacheHelper>();
  final appFont = cacheHelper.getData(key: 'app_font') ?? "Amiri";
  return appFont;
}

void setAppFont(String font) {
  final cacheHelper = getIt<CacheHelper>();
  cacheHelper.saveData(key: 'app_font', value: font);
}