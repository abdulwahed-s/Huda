import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/quran/mushaf_page_content.dart';
import 'package:huda/core/quran/mushaf_pagination.dart';
import 'package:huda/core/quran/quran.dart' as quran;

Iterable<(int, int)> allAyahs() sync* {
  for (var surah = 1; surah <= 114; surah++) {
    for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
      yield (surah, ayah);
    }
  }
}

void main() {
  test('Madani pagination is the existing page data', () {
    const madani = MushafPagination.madani;
    expect(madani.pageCount, quran.totalPagesCount);
    for (final (surah, ayah) in allAyahs()) {
      expect(
        madani.pageOf(surah, ayah),
        quran.getPageNumber(surah, ayah),
        reason: '$surah:$ayah',
      );
    }
  });

  test('IndoPak pagination holds every ayah once, in reading order', () {
    const indopak = MushafPagination.indopak;
    expect(indopak.pageCount, 610);
    var previous = 1;
    var count = 0;
    for (final (surah, ayah) in allAyahs()) {
      final page = indopak.pageOf(surah, ayah);
      expect(page, greaterThanOrEqualTo(previous), reason: '$surah:$ayah');
      previous = page;
      count++;
    }
    expect(count, 6236);
    expect(indopak.pageOf(1, 1), 1);
    expect(indopak.pageOf(2, 1), 2);
    expect(indopak.pageOf(3, 1), 50);
    expect(indopak.pageOf(114, 6), 610);
    for (var page = 1; page <= indopak.pageCount; page++) {
      expect(indopak.sectionsOf(page), isNotEmpty, reason: 'page $page');
    }
    expect(() => indopak.sectionsOf(611), throwsRangeError);
  });

  test('switching layouts keeps the reader on the same ayah', () {
    const madani = MushafPagination.madani;
    const indopak = MushafPagination.indopak;
    for (final page in [1, 2, 50, 300, 577, 604]) {
      final first = madani.firstAyahOf(page);
      final converted = madani.convertPage(page, indopak);
      expect(
        indopak.pageOf(first.surah, first.ayah),
        converted,
        reason: 'Madani page $page',
      );
    }
    expect(indopak.convertPage(610, madani), madani.pageOf(113, 1));
    expect(madani.convertPage(42, madani), 42);
  });

  test('page content follows the given pagination', () {
    final indopak = MushafPageContentCache(
      pagination: MushafPagination.indopak,
    );
    final page50 = indopak.getPage(50);
    expect(page50.firstSurah, 3);
    expect(page50.verses.first.verseNumber, 1);
    expect(indopak.getPage(610).verses.last.surahNumber, 114);
    expect(MushafPageContentCache().getPage(50).firstSurah, 3);
  });
}
