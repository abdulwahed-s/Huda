import 'package:huda/core/quran/quran_text.dart';
import 'package:huda/core/quran/surah_data.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/models/surah_model.dart';

class SurahBuilder {
  SurahBuilder._();

  static Map<int, List<Ayahs>>? _ayahsBySurah;

  static bool get isDataPreloaded => _ayahsBySurah != null;

  static Map<int, List<Ayahs>> buildAllSurahAyahs() {
    final cached = _ayahsBySurah;
    if (cached != null) return cached;

    final Map<int, List<Ayahs>> grouped = {};
    for (int i = 0; i < quranText.length; i++) {
      final verse = quranText[i];
      final int surahNumber = verse['surah_number'] as int;
      (grouped[surahNumber] ??= <Ayahs>[]).add(
        Ayahs(
          number: i + 1,
          numberInSurah: verse['verse_number'] as int,
          text: verse['content'] as String,
        ),
      );
    }
    _ayahsBySurah = grouped;
    return grouped;
  }

  static SurahModel buildSurahModel(int surahNumber) {
    final entry = surah.firstWhere((s) => s['id'] == surahNumber);
    return SurahModel(
      number: entry['id'] as int,
      name: entry['arabicName'] as String,
      englishName: entry['englishName'] as String,
      englishNameTranslation: entry['englishNameTranslation'] as String,
      revelationType: entry['revelationType'] as String,
      ayahs: buildAllSurahAyahs()[surahNumber] ?? const <Ayahs>[],
    );
  }

  static List<QuranModel> buildQuranIndex() => surah
      .map<QuranModel>((s) => QuranModel(
            number: s['id'] as int,
            name: s['arabicName'] as String,
            englishName: s['englishName'] as String,
            englishNameTranslation: s['englishNameTranslation'] as String,
            numberOfAyahs: s['aya'] as int,
            revelationType: s['revelationType'] as String,
            transliteration: s['transliteration'] as String,
            names: (s['names'] as Map).map((k, v) => MapEntry('$k', '$v')),
            translits:
                (s['translits'] as Map).map((k, v) => MapEntry('$k', '$v')),
          ))
      .toList();
}
