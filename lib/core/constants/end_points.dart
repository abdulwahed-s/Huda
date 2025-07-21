class EndPoints {
  static const String baseUrl = 'https://api.alquran.cloud/v1';
  static const String edition = '/edition';
  static String surahEdition(String identifier) => '/quran/$identifier';
  static String oneSurahEdition(String identifier, int number) =>'/surah/$number/$identifier';
  static const String baseUrlAthkar = 'http://www.hisnmuslim.com/api';
  static const arAthkar = "/ar/husn_ar.json";
  static const enAthkar = "/en/husn_en.json";
  static String athkarDetail(String id) => '/en/$id.json';
}
