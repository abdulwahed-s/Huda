class CounselingResponse {
  final String counselingText;
  final String ayah;
  final String ayahTranslation;
  final String ayahReference;
  final String duaa;
  final String duaaTranslation;

  const CounselingResponse({
    required this.counselingText,
    required this.ayah,
    required this.ayahTranslation,
    required this.ayahReference,
    required this.duaa,
    required this.duaaTranslation,
  });

  factory CounselingResponse.fromJson(Map<String, dynamic> json) {
    return CounselingResponse(
      counselingText: json['counseling_text'] ?? '',
      ayah: json['ayah'] ?? '',
      ayahTranslation: json['ayah_translation'] ?? '',
      ayahReference: json['ayah_reference'] ?? '',
      duaa: json['duaa'] ?? '',
      duaaTranslation: json['duaa_translation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'counseling_text': counselingText,
    'ayah': ayah,
    'ayah_translation': ayahTranslation,
    'ayah_reference': ayahReference,
    'duaa': duaa,
    'duaa_translation': duaaTranslation,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounselingResponse &&
        other.counselingText == counselingText &&
        other.ayah == ayah &&
        other.ayahTranslation == ayahTranslation &&
        other.ayahReference == ayahReference &&
        other.duaa == duaa &&
        other.duaaTranslation == duaaTranslation;
  }

  @override
  int get hashCode => Object.hash(
    counselingText,
    ayah,
    ayahTranslation,
    ayahReference,
    duaa,
    duaaTranslation,
  );
}
