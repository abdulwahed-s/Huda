import 'dart:developer';

import 'package:huda/core/quran/mushaf_pagination.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/utils/hizb_calculator.dart';

class MushafVerseContent {
  final int surahNumber;
  final int verseNumber;
  final String text;
  final String numberGlyph;

  const MushafVerseContent({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
    required this.numberGlyph,
  });
}

class MushafPageContent {
  final int firstSurah;
  final int juzNumber;
  final String? hizbText;
  final List<MushafVerseContent> verses;

  const MushafPageContent({
    required this.firstSurah,
    required this.juzNumber,
    required this.hizbText,
    required this.verses,
  });

  factory MushafPageContent.fromPage(
    int pageNumber, {
    MushafPagination pagination = MushafPagination.madani,
  }) {
    final sections = pagination.sectionsOf(pageNumber);
    final firstSurah = sections.first['surah'] as int;
    final firstVerse = sections.first['start'] as int;
    final verses = <MushafVerseContent>[];
    for (final section in sections) {
      final surah = section['surah'] as int;
      for (
        var verse = section['start'] as int;
        verse <= (section['end'] as int);
        verse++
      ) {
        final rawText = quran.getVerseQCF(surah, verse, verseEndSymbol: false);
        final text = verses.isEmpty && rawText.length > 1
            ? '${rawText.substring(0, 1)}\u200A${rawText.substring(1)}'
            : rawText;
        verses.add(
          MushafVerseContent(
            surahNumber: surah,
            verseNumber: verse,
            text: text,
            numberGlyph: quran.getVerseNumberQCF(surah, verse),
          ),
        );
      }
    }
    return MushafPageContent(
      firstSurah: firstSurah,
      juzNumber: quran.getJuzNumber(firstSurah, firstVerse),
      hizbText: getHizbTextForPage(sections),
      verses: List.unmodifiable(verses),
    );
  }
}

/// Reader-local LRU of immutable content. Styles, fonts, recognizers and
/// highlights are rebuilt from current settings, so they cannot become stale.
class MushafPageContentCache {
  final int maxPages;
  final MushafPagination pagination;
  final _pages = <int, MushafPageContent>{};

  MushafPageContentCache({
    this.maxPages = 12,
    this.pagination = MushafPagination.madani,
  }) : assert(maxPages > 0);

  MushafPageContent getPage(int pageNumber) {
    final cached = _pages.remove(pageNumber);
    final content =
        cached ??
        Timeline.timeSync<MushafPageContent>(
          'Quran page content',
          () => MushafPageContent.fromPage(pageNumber, pagination: pagination),
          arguments: {'page': pageNumber},
        );
    _pages[pageNumber] = content;
    if (_pages.length > maxPages) _pages.remove(_pages.keys.first);
    return content;
  }

  void clear() => _pages.clear();
}
