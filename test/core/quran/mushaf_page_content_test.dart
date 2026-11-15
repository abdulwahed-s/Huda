import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/quran/mushaf_page_content.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/quran/quran_text.dart';

void main() {
  test(
    'indexed lookups preserve text and number glyphs for all 6236 verses',
    () {
      expect(quranText, hasLength(quran.totalVerseCount));
      for (final record in quranText) {
        final surah = record['surah_number'] as int;
        final verse = record['verse_number'] as int;
        final text = record['qcfData'] as String;
        final numberOffset = text.length - (text.endsWith('\n') ? 2 : 1);
        expect(quran.getVerse(surah, verse), record['content']);
        expect(quran.getVerseQCF(surah, verse), text);
        expect(
          quran.getVerseQCF(surah, verse, verseEndSymbol: false),
          text.substring(0, numberOffset),
        );
        expect(
          quran.getVerseNumberQCF(surah, verse),
          text.substring(numberOffset, numberOffset + 1),
        );
      }
      for (final reference in [(0, 1), (115, 1), (1, 0), (1, 8)]) {
        expect(
          () => quran.getVerseQCF(reference.$1, reference.$2),
          throwsA(isA<String>()),
        );
        expect(
          () => quran.getVerseNumberQCF(reference.$1, reference.$2),
          throwsA(isA<String>()),
        );
      }
    },
  );

  test('all pages preserve verse order and first-verse spacing', () {
    final cache = MushafPageContentCache();
    var verseCount = 0;
    for (var page = 1; page <= quran.totalPagesCount; page++) {
      final content = cache.getPage(page);
      final expectedReferences = [
        for (final section in quran.getPageData(page))
          for (
            var verse = section['start'] as int;
            verse <= (section['end'] as int);
            verse++
          )
            (section['surah'] as int, verse),
      ];
      expect(
        content.verses.map((verse) => (verse.surahNumber, verse.verseNumber)),
        expectedReferences,
      );
      final first = content.verses.first;
      final raw = quran.getVerseQCF(
        first.surahNumber,
        first.verseNumber,
        verseEndSymbol: false,
      );
      expect(
        first.text,
        raw.length > 1 ? '${raw[0]}\u200A${raw.substring(1)}' : raw,
      );
      for (final verse in content.verses.skip(1)) {
        expect(
          verse.text,
          quran.getVerseQCF(
            verse.surahNumber,
            verse.verseNumber,
            verseEndSymbol: false,
          ),
        );
      }
      verseCount += content.verses.length;
    }
    expect(verseCount, quran.totalVerseCount);
  });

  test(
    'page cache reuses immutable content, evicts oldest entries and clears',
    () {
      final cache = MushafPageContentCache(maxPages: 2);
      final first = cache.getPage(1);
      final second = cache.getPage(2);
      expect(identical(first, cache.getPage(1)), isTrue);
      cache.getPage(3);
      expect(identical(first, cache.getPage(1)), isTrue);
      expect(identical(second, cache.getPage(2)), isFalse);
      expect(() => first.verses.clear(), throwsUnsupportedError);
      cache.clear();
      expect(identical(first, cache.getPage(1)), isFalse);
    },
  );
}
