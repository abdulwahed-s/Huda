import 'dart:ui';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

class SurahScreenSettingsService {
  static const _bgColorKey = 'surah_bg_color';
  static const _textColorKey = 'surah_text_color';

  final CacheHelper _cache = getIt<CacheHelper>();

  Color? getBackgroundColor() {
    final value = _cache.getData(key: _bgColorKey);
    if (value == null) return null;
    return Color(value as int);
  }

  Future<void> setBackgroundColor(Color? color) async {
    if (color == null) {
      await _cache.removeData(key: _bgColorKey);
    } else {
      await _cache.saveData(key: _bgColorKey, value: color.toARGB32());
    }
  }

  Color? getTextColor() {
    final value = _cache.getData(key: _textColorKey);
    if (value == null) return null;
    return Color(value as int);
  }

  Future<void> setTextColor(Color? color) async {
    if (color == null) {
      await _cache.removeData(key: _textColorKey);
    } else {
      await _cache.saveData(key: _textColorKey, value: color.toARGB32());
    }
  }

  Future<void> resetAll() async {
    await _cache.removeData(key: _bgColorKey);
    await _cache.removeData(key: _textColorKey);
  }
}
