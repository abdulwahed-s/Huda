class AthkarDetailModel {
  int? id;
  String? arabicText;
  String? languageArabicTranslatedText;
  String? translatedText;
  int? repeat;
  String? audio;

  AthkarDetailModel({
    this.id,
    this.arabicText,
    this.languageArabicTranslatedText,
    this.translatedText,
    this.repeat,
    this.audio,
  });

  AthkarDetailModel.fromJson(Map<String, dynamic> json) {
    id = json['ID'];
    arabicText = json['ARABIC_TEXT'];
    languageArabicTranslatedText = json['LANGUAGE_ARABIC_TRANSLATED_TEXT'];
    translatedText = json['TRANSLATED_TEXT'];
    repeat = json['REPEAT'];
    audio = json['AUDIO'];
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'ARABIC_TEXT': arabicText,
      'LANGUAGE_ARABIC_TRANSLATED_TEXT': languageArabicTranslatedText,
      'TRANSLATED_TEXT': translatedText,
      'REPEAT': repeat,
      'AUDIO': audio,
    };
  }
}


class AthkarCategory {
  final String title;
  final List<AthkarDetailModel> details;

  AthkarCategory({required this.title, required this.details});
}
