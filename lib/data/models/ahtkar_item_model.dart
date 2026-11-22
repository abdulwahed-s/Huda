class AthkarItem {
  final int id;
  final String titleAr;
  final String titleEn;
  final String audioUrl;
  final String textUrlAr;
  final String textUrlEn;

  /// Chapter titles for languages hisnmuslim.com doesn't serve, by code.
  final Map<String, String> translations;

  AthkarItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.audioUrl,
    required this.textUrlAr,
    required this.textUrlEn,
    this.translations = const {},
  });

  /// The chapter title to show for [languageCode]: Arabic for Arabic,
  /// then a bundled translation, then the English title.
  String displayTitle(String languageCode) {
    if (languageCode == 'ar') return titleAr;
    final translated = translations[languageCode];
    if (translated != null && translated.isNotEmpty) return translated;
    return titleEn.trim().isEmpty ? titleAr : titleEn;
  }
}
