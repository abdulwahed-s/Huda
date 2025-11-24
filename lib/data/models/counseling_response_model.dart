class CounselingResponse {
  final String counselingText;
  final String ayah;
  final String ayahTranslation;
  final String ayahReference;
  final String duaa;
  final String duaaTranslation;

  CounselingResponse({
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
}
