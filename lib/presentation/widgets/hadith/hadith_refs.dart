import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/data/models/book_chapters_model.dart' as chapters;
import 'package:huda/data/models/hadith_books_model.dart' as books;

class HadithCollectionRef {
  const HadithCollectionRef({
    required this.slug,
    required this.title,
    this.arabicTitle,
    this.intro,
    this.hadithCount,
  });

  factory HadithCollectionRef.of(books.Data data, String languageCode) {
    String clean(String? text) =>
        HadithTextFormatter.format(text ?? '').plainText.trim();
    String? arabic;
    String? intro;
    for (final entry in data.collection ?? const <books.Collection>[]) {
      if (entry.lang == 'ar' && clean(entry.title).isNotEmpty) {
        arabic = clean(entry.title);
      }
      if (entry.lang == 'en' && clean(entry.shortIntro).isNotEmpty) {
        intro = clean(entry.shortIntro);
      }
    }
    final title = clean(
      data.collectionForLanguage(languageCode)?.title ?? data.name,
    );
    return HadithCollectionRef(
      slug: data.name ?? '',
      title: title.isEmpty ? data.name ?? '' : title,
      arabicTitle: arabic,
      // sunnah.com only writes intros in English; other languages skip them.
      intro: languageCode == 'en' ? intro : null,
      hadithCount: data.totalAvailableHadith,
    );
  }

  final String slug;

  final String title;
  final String? arabicTitle;
  final String? intro;

  final int? hadithCount;

  bool get available => (hadithCount ?? 1) > 0;
}

class HadithBookRef {
  const HadithBookRef({
    required this.number,
    required this.title,
    this.arabicTitle,
    this.firstHadith,
    this.lastHadith,
  });

  factory HadithBookRef.of(chapters.Data data, String languageCode) {
    String clean(String? text) =>
        HadithTextFormatter.format(text ?? '').plainText.trim();
    String? arabic;
    for (final entry in data.book ?? const <chapters.Book>[]) {
      if (entry.lang == 'ar' && clean(entry.name).isNotEmpty) {
        arabic = clean(entry.name);
      }
    }
    final number = data.bookNumber ?? '';
    final title = clean(data.bookForLanguage(languageCode)?.name);
    return HadithBookRef(
      number: number,
      title: title.isEmpty ? number : title,
      arabicTitle: arabic,
      firstHadith: data.hadithStartNumber,
      lastHadith: data.hadithEndNumber,
    );
  }

  final String number;
  final String title;
  final String? arabicTitle;
  final int? firstHadith;
  final int? lastHadith;

  String get shownNumber => number == 'introduction' ? '0' : number;

  @override
  bool operator ==(Object other) =>
      other is HadithBookRef && other.number == number;

  @override
  int get hashCode => number.hashCode;
}

List<chapters.Data> sortHadithBooks(List<chapters.Data> books) {
  final number = RegExp(r'^(\d+)([a-zA-Z]*)$');
  int compare(chapters.Data a, chapters.Data b) {
    final x = a.bookNumber ?? '';
    final y = b.bookNumber ?? '';
    if (x == y) return 0;
    if (x == 'introduction') return -1;
    if (y == 'introduction') return 1;
    final mx = number.firstMatch(x);
    final my = number.firstMatch(y);
    final nx = int.tryParse(mx?.group(1) ?? x) ?? 0;
    final ny = int.tryParse(my?.group(1) ?? y) ?? 0;
    if (nx != ny) return nx.compareTo(ny);
    return (mx?.group(2) ?? '').compareTo(my?.group(2) ?? '');
  }

  return List.of(books)..sort(compare);
}
