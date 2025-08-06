class EndPoints {
  static const String baseUrl = 'https://api.alquran.cloud/v1';
  static const String edition = '/edition';
  static String surahEdition(String identifier) => '/quran/$identifier';
  static String oneSurahEdition(String identifier, int number) =>'/surah/$number/$identifier';
  static const String baseUrlAthkar = 'http://www.hisnmuslim.com/api';
  static const arAthkar = "/ar/husn_ar.json";
  static const enAthkar = "/en/husn_en.json";
  static String athkarDetail(String id) => '/en/$id.json';
  static const String hadithBaseUrl = 'https://hadithapi.com/api';
  static const String hadithBooks = '/books';
  static String bookChapter(String bookSlug) => 'https://hadithapi.com/api/$bookSlug/chapters';
  static const String hadithDetail = '/hadiths';
  static const String islamhouseBaseUrl = 'https://api3.islamhouse.com/v3/paV29H2gm56kvLPy';
  static String books(String lang,int page,String respLang) => '$islamhouseBaseUrl/main/books/$respLang/$lang/$page/25/json';
  static String bookDetail(String lang, int bookId) => '$islamhouseBaseUrl/main/get-item/$bookId/$lang/json';
  static String bookLanguages(int sourceId,String respLang) => '$islamhouseBaseUrl/main/get-item-translations/$sourceId/$respLang/json';
  static String allBooksLanguages(String lang) => '$islamhouseBaseUrl/main/get-available-languages/books/$lang/json';
}
