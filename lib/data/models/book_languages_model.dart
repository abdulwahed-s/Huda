class BookLanguagesModel {
  final int id;
  final int sourceId;
  final String slang;
  final String type;
  final String apiUrl;
  final String caseStatus;
  final String importanceLevel;

  BookLanguagesModel({
    required this.id,
    required this.sourceId,
    required this.slang,
    required this.type,
    required this.apiUrl,
    required this.caseStatus,
    required this.importanceLevel,
  });

  factory BookLanguagesModel.fromJson(Map<String, dynamic> json) {
    return BookLanguagesModel(
      id: json['id'],
      sourceId: json['source_id'], // you can also use json['sourceid'] — they are equal
      slang: json['slang'],
      type: json['type'],
      apiUrl: json['api_url'],
      caseStatus: json['case'],
      importanceLevel: json['importance_level'],
    );
  }
}
