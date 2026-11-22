import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/class/dio_errors.dart';
import 'package:huda/data/api/athkar_services.dart';
import 'package:huda/data/models/ahtkar_item_model.dart';
import 'package:huda/data/models/athkar_detail_model.dart';

class AthkarRepository {
  final AthkarService service;

  AthkarRepository(this.service);

  Future<List<AthkarItem>> getAthkarList() async {
    try {
      final arData = await service.getArabicAthkar();
      final enData = await service.getEnglishAthkar();
      final titles = await _translatedTitles();

      final arList = List<Map<String, dynamic>>.from(arData["العربية"]);
      final enList = List<Map<String, dynamic>>.from(enData["English"]);

      return arList.map((arItem) {
        final matchingEn = enList.firstWhere(
          (enItem) => enItem["ID"] == arItem["ID"],
          orElse: () => {},
        );

        return AthkarItem(
          id: arItem["ID"],
          titleAr: arItem["TITLE"],
          titleEn: matchingEn["TITLE"] ?? '',
          audioUrl: arItem["AUDIO_URL"],
          textUrlAr: arItem["TEXT"],
          textUrlEn: matchingEn["TEXT"] ?? '',
          translations: titles['${arItem["ID"]}'] ?? const {},
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }

  static Map<String, Map<String, String>>? _titles;

  /// Bundled chapter titles for app languages other than Arabic and English.
  static Future<Map<String, Map<String, String>>> _translatedTitles() async {
    final cached = _titles;
    if (cached != null) return cached;
    final raw =
        jsonDecode(await rootBundle.loadString('assets/json/athkar_titles.json'))
            as Map<String, dynamic>;
    return _titles = raw.map(
      (id, names) =>
          MapEntry(id, Map<String, String>.from(names as Map<String, dynamic>)),
    );
  }

  Future<AthkarCategory> getAthkarDetail(String id) async {
    try {
      final response = await service.getAthkarDetail(id);

      final entry = response.entries.first;

      final String title = entry.key;
      final List<dynamic> values = entry.value;

      final details =
          values.map((item) => AthkarDetailModel.fromJson(item)).toList();

      return AthkarCategory(title: title, details: details);
    } on DioException catch (e) {
      throw Exception(getDioErrorMessage(e));
    }
  }
}
