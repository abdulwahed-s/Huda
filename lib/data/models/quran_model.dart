class QuranModel {
  int? number;
  String? name;
  String? englishName;
  String? englishNameTranslation;
  int? numberOfAyahs;
  String? revelationType;

  String? transliteration;

  Map<String, String>? names;

  Map<String, String>? translits;

  QuranModel(
      {this.number,
      this.name,
      this.englishName,
      this.englishNameTranslation,
      this.numberOfAyahs,
      this.revelationType,
      this.transliteration,
      this.names,
      this.translits});

  String localizedName(String languageCode) =>
      names?[languageCode] ?? names?['en'] ?? englishName ?? '';

  String? localizedTransliteration(String languageCode) {
    if (languageCode == 'ar' || languageCode == 'ur') return null;
    return translits?[languageCode] ?? transliteration;
  }

  QuranModel.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    name = json['name'];
    englishName = json['englishName'];
    englishNameTranslation = json['englishNameTranslation'];
    numberOfAyahs = json['numberOfAyahs'];
    revelationType = json['revelationType'];
    transliteration = json['transliteration'];
    names = (json['names'] as Map?)?.map((k, v) => MapEntry('$k', '$v'));
    translits = (json['translits'] as Map?)?.map((k, v) => MapEntry('$k', '$v'));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['number'] = number;
    data['name'] = name;
    data['englishName'] = englishName;
    data['englishNameTranslation'] = englishNameTranslation;
    data['numberOfAyahs'] = numberOfAyahs;
    data['revelationType'] = revelationType;
    data['transliteration'] = transliteration;
    data['names'] = names;
    data['translits'] = translits;
    return data;
  }
}
