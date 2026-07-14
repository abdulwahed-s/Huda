import 'dart:convert';

import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/models/home/home_preferences.dart';

class HomePreferencesService {
  HomePreferencesService({required CacheHelper cache}) : _cache = cache;

  static const _preferencesKey = 'home_customization_v1';
  final CacheHelper _cache;

  HomePreferences load() {
    final raw = _cache.getDataString(key: _preferencesKey);
    if (raw == null || raw.isEmpty) return HomePreferences.defaults();

    try {
      final json = jsonDecode(raw);
      if (json is! Map) return HomePreferences.defaults();
      return HomePreferences.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return HomePreferences.defaults();
    }
  }

  Future<void> save(HomePreferences preferences) async {
    await _cache.saveData(
      key: _preferencesKey,
      value: jsonEncode(preferences.toJson()),
    );
  }
}
