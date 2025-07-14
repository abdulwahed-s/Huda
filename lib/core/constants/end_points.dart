class EndPoints {
  static const String baseUrl = 'https://api.alquran.cloud/v1';
  static const String edition = '/edition';
  static String surahEdition(String identifier) => '/quran/$identifier';
  static String oneSurahEdition(String identifier,int number) => '/surah/$number/$identifier';
}
