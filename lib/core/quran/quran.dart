import 'package:huda/core/quran/juz_data.dart';
import 'package:huda/core/quran/page_data.dart';
import 'package:huda/core/quran/surah_data.dart';
import 'package:huda/core/quran/quran_text.dart';
import 'package:huda/core/quran/sajdah_verses.dart';

List getPageData(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  return pageData[pageNumber - 1];
}

const int totalPagesCount = 604;

const int totalMakkiSurahs = 89;

const int totalMadaniSurahs = 25;

const int totalJuzCount = 30;

const int totalSurahCount = 114;

const int totalVerseCount = 6236;

const String basmala = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";

const String sajdah = "سَجْدَةٌ";

int getSurahCountByPage(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  return pageData[pageNumber - 1].length;
}

int getVerseCountByPage(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  int totalVerseCount = 0;
  for (int i = 0; i < pageData[pageNumber - 1].length; i++) {
    totalVerseCount +=
        int.parse(pageData[pageNumber - 1][i]!["end"].toString());
  }
  return totalVerseCount;
}

int getJuzNumber(int surahNumber, int verseNumber) {
  for (var juz in juz) {
    if (juz["verses"].keys.contains(surahNumber)) {
      if (verseNumber >= juz["verses"][surahNumber][0] &&
          verseNumber <= juz["verses"][surahNumber][1]) {
        return int.parse(juz["id"].toString());
      }
    }
  }
  return -1;
}

Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber) {
  return juz[juzNumber - 1]["verses"];
}

String getSurahName(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['name'].toString();
}

String getSurahNameEnglish(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['english'].toString();
}

String getSurahNameTurkish(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['turkish'].toString();
}

String getSurahNameArabic(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['arabic'].toString();
}

String getSurahNameLocalized(int surahNumber, String languageCode) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  final data = surah[surahNumber - 1];
  if (languageCode == 'ar' || languageCode == 'ur') {
    return data['arabic'].toString();
  }
  final translits = data['translits'] as Map?;
  return (translits?[languageCode] ?? data['transliteration']).toString();
}

int getPageNumber(int surahNumber, int verseNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }

  for (int pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
    for (int surahIndexInPage = 0;
        surahIndexInPage < pageData[pageIndex].length;
        surahIndexInPage++) {
      final e = pageData[pageIndex][surahIndexInPage];
      if (e['surah'] == surahNumber &&
          e['start'] <= verseNumber &&
          e['end'] >= verseNumber) {
        return pageIndex + 1;
      }
    }
  }

  throw "Invalid verse number.";
}

String getPlaceOfRevelation(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['place'].toString();
}

int getVerseCount(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No verse found with given surahNumber";
  }
  return int.parse(surah[surahNumber - 1]['aya'].toString());
}

String getVerse(int surahNumber, int verseNumber,
    {bool verseEndSymbol = false}) {
  String verse = "";
  for (var i in quranText) {
    if (i['surah_number'] == surahNumber && i['verse_number'] == verseNumber) {
      verse = i['content'].toString();
      break;
    }
  }

  if (verse == "") {
    throw "No verse found with given surahNumber and verseNumber.\n\n";
  }

  return verse + (verseEndSymbol ? getVerseEndSymbol(verseNumber) : "");
}

String getVerseQCF(int surahNumber, int verseNumber,
    {bool verseEndSymbol = true}) {
  String verse = "";
  for (var i in quranText) {
    if (i['surah_number'] == surahNumber && i['verse_number'] == verseNumber) {
      final String qcfData = i['qcfData'].toString();
      if (verseEndSymbol) {
        verse = qcfData;
      } else {
        final bool endsWithNewline = qcfData.endsWith('\n');
        verse = qcfData.substring(
          0,
          qcfData.length - (endsWithNewline ? 2 : 1),
        );
      }
      break;
    }
  }

  if (verse == "") {
    throw "No verse found with given surahNumber and verseNumber.\n\n";
  }

  return verse;
}

String getVerseNumberQCF(int surahNumber, int verseNumber) {
  String glyph = "";
  for (var i in quranText) {
    if (i['surah_number'] == surahNumber && i['verse_number'] == verseNumber) {
      final String qcfData = i['qcfData'].toString();
      final bool endsWithNewline = qcfData.endsWith('\n');
      glyph = endsWithNewline
          ? qcfData.substring(qcfData.length - 2, qcfData.length - 1)
          : qcfData.substring(qcfData.length - 1);
      break;
    }
  }

  if (glyph == "") {
    throw "No verse found with given surahNumber and verseNumber.\n\n";
  }

  return glyph;
}

String getJuzURL(int juzNumber) {
  return "https://quran.com/juz/$juzNumber";
}

String getSurahURL(int surahNumber) {
  return "https://quran.com/$surahNumber";
}

String getVerseURL(int surahNumber, int verseNumber) {
  return "https://quran.com/$surahNumber/$verseNumber";
}

String getVerseEndSymbol(int verseNumber, {bool arabicNumeral = true}) {
  var arabicNumeric = '';
  var digits = verseNumber.toString().split("").toList();

  if (!arabicNumeral) return '\u06dd${verseNumber.toString()}';

  const Map arabicNumbers = {
    "0": "٠",
    "1": "۱",
    "2": "۲",
    "3": "۳",
    "4": "٤",
    "5": "٥",
    "6": "٦",
    "7": "۷",
    "8": "۸",
    "9": "۹"
  };

  for (var e in digits) {
    arabicNumeric += arabicNumbers[e];
  }

  return '\u06dd$arabicNumeric';
}

List<int> getSurahPages(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "Invalid surahNumber";
  }

  const pagesCount = totalPagesCount;
  List<int> pages = [];
  for (int currentPage = 1; currentPage <= pagesCount; currentPage++) {
    final pageData = getPageData(currentPage);
    for (int j = 0; j < pageData.length; j++) {
      final currentSurahNum = pageData[j]['surah'];
      if (currentSurahNum == surahNumber) {
        pages.add(currentPage);
        break;
      }
    }
  }
  return pages;
}

enum SurahSeperator {
  none,
  surahName,
  surahNameArabic,
  surahNameEnglish,
  surahNameTurkish,
}

List<String> getVersesTextByPage(int pageNumber,
    {bool verseEndSymbol = false,
    SurahSeperator surahSeperator = SurahSeperator.none,
    String customSurahSeperator = ""}) {
  if (pageNumber > 604 || pageNumber <= 0) {
    throw "Invalid pageNumber";
  }

  List<String> verses = [];
  final pageData = getPageData(pageNumber);
  for (var data in pageData) {
    if (customSurahSeperator != "") {
      verses.add(customSurahSeperator);
    } else if (surahSeperator == SurahSeperator.surahName) {
      verses.add(getSurahName(data["surah"]));
    } else if (surahSeperator == SurahSeperator.surahNameArabic) {
      verses.add(getSurahNameArabic(data["surah"]));
    } else if (surahSeperator == SurahSeperator.surahNameEnglish) {
      verses.add(getSurahNameEnglish(data["surah"]));
    } else if (surahSeperator == SurahSeperator.surahNameTurkish) {
      verses.add(getSurahNameTurkish(data["surah"]));
    }
    for (int j = data["start"]; j <= data["end"]; j++) {
      verses.add(getVerse(data["surah"], j, verseEndSymbol: verseEndSymbol));
    }
  }
  return verses;
}

String getAudioURLBySurah(int surahNumber, reciterIdentifier) {
  return "https://cdn.islamic.network/quran/audio-surah/64/$reciterIdentifier/$surahNumber.mp3";
}

String getAudioURLByVerse(int surahNumber, int verseNumber, reciterIdentifier) {
  int verseNum = 0;
  for (var i in quranText) {
    if (i['surah_number'] == surahNumber && i['verse_number'] == verseNumber) {
      verseNum = quranText.indexOf(i) + 1;
      break;
    }
  }
  if (reciterIdentifier == "ar.parhizgar" ||
      reciterIdentifier == "ar.muhammadjibreel" ||
      reciterIdentifier == "ar.muhammadayyoub" ||
      reciterIdentifier == "ar.ibrahimakhbar" ||
      reciterIdentifier == "ar.minshawi") {
    return "https://cdn.islamic.network/quran/audio/128/$reciterIdentifier/$verseNum.mp3";
  } else {
    return "https://cdn.islamic.network/quran/audio/64/$reciterIdentifier/$verseNum.mp3";
  }
}

bool isSajdahVerse(int surahNumber, int verseNumber) =>
    sajdahVerses[surahNumber] == verseNumber;

String getAudioURLByVerseNumber(int verseNumber, reciterIdentifier) {
  return "https://cdn.islamic.network/quran/audio/64/$reciterIdentifier/$verseNumber.mp3";
}

String normalise(String input) => input
    .replaceAll('\u0610', '')
    .replaceAll('\u0611', '')
    .replaceAll('\u0612', '')
    .replaceAll('\u0613', '')
    .replaceAll('\u0614', '')
    .replaceAll('\u0615', '')
    .replaceAll('\u0616', '')
    .replaceAll('\u0617', '')
    .replaceAll('\u0618', '')
    .replaceAll('\u0619', '')
    .replaceAll('\u061A', '')
    .replaceAll('\u06D6', '')
    .replaceAll('\u06D7', '')
    .replaceAll('\u06D8', '')
    .replaceAll('\u06D9', '')
    .replaceAll('\u06DA', '')
    .replaceAll('\u06DB', '')
    .replaceAll('\u06DC', '')
    .replaceAll('\u06DD', '')
    .replaceAll('\u06DE', '')
    .replaceAll('\u06DF', '')
    .replaceAll('\u06E0', '')
    .replaceAll('\u06E1', '')
    .replaceAll('\u06E2', '')
    .replaceAll('\u06E3', '')
    .replaceAll('\u06E4', '')
    .replaceAll('\u06E5', '')
    .replaceAll('\u06E6', '')
    .replaceAll('\u06E7', '')
    .replaceAll('\u06E8', '')
    .replaceAll('\u06E9', '')
    .replaceAll('\u06EA', '')
    .replaceAll('\u06EB', '')
    .replaceAll('\u06EC', '')
    .replaceAll('\u06ED', '')
    .replaceAll('\u0640', '')
    .replaceAll('\u064B', '')
    .replaceAll('\u064C', '')
    .replaceAll('\u064D', '')
    .replaceAll('\u064E', '')
    .replaceAll('\u064F', '')
    .replaceAll('\u0650', '')
    .replaceAll('\u0651', '')
    .replaceAll('\u0652', '')
    .replaceAll('\u0653', '')
    .replaceAll('\u0654', '')
    .replaceAll('\u0655', '')
    .replaceAll('\u0656', '')
    .replaceAll('\u0657', '')
    .replaceAll('\u0658', '')
    .replaceAll('\u0659', '')
    .replaceAll('\u065A', '')
    .replaceAll('\u065B', '')
    .replaceAll('\u065C', '')
    .replaceAll('\u065D', '')
    .replaceAll('\u065E', '')
    .replaceAll('\u065F', '')
    .replaceAll('\u0670', '')
    .replaceAll('\u0624', '\u0648')
    .replaceAll('\u0629', '\u0647')
    .replaceAll('\u064A', '\u0649')
    .replaceAll('\u0626', '\u0649')
    .replaceAll('\u0622', '\u0627')
    .replaceAll('\u0623', '\u0627')
    .replaceAll('\u0625', '\u0627');

String removeDiacritics(String input) {
  Map<String, String> diacriticsMap = {
    'َ': '',
    'ُ': '',
    'ِ': '',
    'ّ': '',
    'ً': '',
    'ٌ': '',
    'ٍ': '',
  };

  String diacriticsPattern =
      diacriticsMap.keys.map((e) => RegExp.escape(e)).join('|');
  RegExp exp = RegExp('[$diacriticsPattern]');

  String textWithoutDiacritics = input.replaceAll(exp, '');

  return textWithoutDiacritics;
}
