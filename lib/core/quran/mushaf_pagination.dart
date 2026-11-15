import 'package:huda/core/quran/indopak_page_data.dart';
import 'package:huda/core/quran/page_data.dart';

/// Page <-> ayah mapping of one printed Mushaf. Every page holds whole ayahs,
/// listed as `{"surah", "start", "end"}` sections like [pageData].
class MushafPagination {
  final List _pages;

  const MushafPagination._(this._pages);

  /// KFGQPC V4 (1441H) Madani print, 604 pages: Hafs and Tajweed.
  static const madani = MushafPagination._(pageData);

  /// IndoPak 15 lines (Qudratullah), 610 pages.
  static const indopak = MushafPagination._(indopakPageData);

  int get pageCount => _pages.length;

  List sectionsOf(int page) {
    if (page < 1 || page > pageCount) {
      throw RangeError.range(page, 1, pageCount, 'page');
    }
    return _pages[page - 1] as List;
  }

  /// The page on which [ayah] of [surah] appears.
  int pageOf(int surah, int ayah) {
    for (var index = 0; index < _pages.length; index++) {
      for (final section in _pages[index] as List) {
        if (section['surah'] == surah &&
            (section['start'] as int) <= ayah &&
            (section['end'] as int) >= ayah) {
          return index + 1;
        }
      }
    }
    throw ArgumentError('No page holds $surah:$ayah');
  }

  ({int surah, int ayah}) firstAyahOf(int page) {
    final first = sectionsOf(page).first;
    return (surah: first['surah'] as int, ayah: first['start'] as int);
  }

  /// The same place in [other]: the page holding this page's first ayah.
  int convertPage(int page, MushafPagination other) {
    if (identical(other, this)) return page;
    final first = firstAyahOf(page.clamp(1, pageCount));
    return other.pageOf(first.surah, first.ayah);
  }
}
