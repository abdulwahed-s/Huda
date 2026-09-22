import 'dart:convert';

import 'package:flutter/services.dart';

class QuranWidgetCatalog {
  const QuranWidgetCatalog({
    required this.version,
    required this.surahs,
    required this.sources,
    required this.verses,
  });

  final int version;
  final Map<int, QuranWidgetSurah> surahs;
  final Map<String, QuranWidgetTranslationSource> sources;
  final List<QuranWidgetVerse> verses;

  static const assetPath = 'assets/json/quran_widget_verses.json';

  static Future<QuranWidgetCatalog> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return QuranWidgetCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory QuranWidgetCatalog.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as Map<String, dynamic>? ?? const {};
    final rawSurahs = json['surahs'] as Map<String, dynamic>? ?? const {};
    final rawVerses = json['verses'] as List<dynamic>? ?? const [];
    return QuranWidgetCatalog(
      version: json['version'] as int? ?? 0,
      surahs: rawSurahs.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          QuranWidgetSurah.fromJson(value as Map<String, dynamic>),
        ),
      )..remove(0),
      sources: rawSources.map(
        (key, value) => MapEntry(
          key,
          QuranWidgetTranslationSource.fromJson(value as Map<String, dynamic>),
        ),
      ),
      verses: rawVerses
          .map(
            (value) => QuranWidgetVerse.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  QuranWidgetVerse verseFor(
    DateTime date, {
    required QuranWidgetSize size,
    int offset = 0,
  }) {
    if (verses.isEmpty) {
      throw StateError('The Quran widget catalog is empty.');
    }
    final eligible = verses
        .where((verse) => verse.widgetSizes.contains(size))
        .toList(growable: false);
    if (eligible.isEmpty) {
      return verses.firstWhere(
        (verse) => verse.id == '94:6',
        orElse: () => verses.first,
      );
    }
    final epochHour = date.toUtc().millisecondsSinceEpoch ~/ 3600000;
    final index = (epochHour + offset) % eligible.length;
    return eligible[index];
  }

  String displayReference(QuranWidgetVerse verse, String appLocale) {
    final language = appLocale.split(RegExp('[-_]')).first.toLowerCase();
    final name = surahs[verse.surah]?.displayNameFor(language);
    return name == null || name.isEmpty
        ? '${verse.surah}:${verse.ayah}'
        : '$name • ${verse.ayah}';
  }
}

class QuranWidgetSurah {
  const QuranWidgetSurah({required this.displayNames});

  final Map<String, String> displayNames;

  String? displayNameFor(String language) {
    final localized = displayNames[language]?.trim();
    if (localized != null && localized.isNotEmpty) return localized;
    final canonical = displayNames['en']?.trim();
    return canonical == null || canonical.isEmpty ? null : canonical;
  }

  factory QuranWidgetSurah.fromJson(Map<String, dynamic> json) {
    final names = json['displayNames'] as Map<String, dynamic>? ?? const {};
    return QuranWidgetSurah(
      displayNames: names.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}

class QuranWidgetTranslationSource {
  const QuranWidgetTranslationSource({
    required this.edition,
    required this.name,
  });

  final String edition;
  final String name;

  factory QuranWidgetTranslationSource.fromJson(Map<String, dynamic> json) {
    return QuranWidgetTranslationSource(
      edition: json['edition'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class QuranWidgetVerse {
  const QuranWidgetVerse({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.widgetSizes,
    required this.arabic,
    required this.translations,
  });

  final String id;
  final int surah;
  final int ayah;
  final Set<QuranWidgetSize> widgetSizes;
  final String arabic;
  final Map<String, String> translations;

  String? translationFor(String? language) {
    if (language == null || language == 'ar') return null;
    final value = translations[language];
    return value == null || value.trim().isEmpty ? null : value;
  }

  factory QuranWidgetVerse.fromJson(Map<String, dynamic> json) {
    final rawTranslations =
        json['translations'] as Map<String, dynamic>? ?? const {};
    final rawWidgetSizes = json['widgetSizes'] as List<dynamic>? ?? const [];
    return QuranWidgetVerse(
      id: json['id'] as String? ?? '',
      surah: json['surah'] as int? ?? 0,
      ayah: json['ayah'] as int? ?? 0,
      widgetSizes: Set.unmodifiable(
        rawWidgetSizes
            .map((value) => QuranWidgetSize.fromJson(value.toString()))
            .whereType<QuranWidgetSize>(),
      ),
      arabic: json['arabic'] as String? ?? '',
      translations: rawTranslations.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}

enum QuranWidgetSize {
  small,
  medium,
  large;

  static QuranWidgetSize? fromJson(String value) {
    for (final size in values) {
      if (size.name == value) return size;
    }
    return null;
  }
}
