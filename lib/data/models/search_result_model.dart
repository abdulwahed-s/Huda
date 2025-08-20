import 'package:huda/data/models/quran_model.dart';

class SearchResult {
  final SearchResultType type;
  final QuranModel? surah;
  final AyahSearchResult? ayahResult;

  SearchResult.surah(this.surah)
      : type = SearchResultType.surah,
        ayahResult = null;

  SearchResult.ayah(this.ayahResult)
      : type = SearchResultType.ayah,
        surah = null;

  SearchResult.divider()
      : type = SearchResultType.divider,
        surah = null,
        ayahResult = null;
}

enum SearchResultType {
  surah,
  ayah,
  divider,
}

class AyahSearchResult {
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;
  final int ayahNumber;
  final String ayahText;
  final String highlightedText; // Text with highlighting (todo add this soon)

  AyahSearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahNumber,
    required this.ayahText,
    required this.highlightedText,
  });
}
