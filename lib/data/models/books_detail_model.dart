class BookDetailModel {
  final int? id;
  final int? sourceId;
  final String? title;
  final String? description;
  final String? fullDescription;
  final String? type;
  final int? addDate;
  final int? updateDate;
  final String? orginalItem;
  final String? translationLanguage;
  final String? sourceLanguage;
  final int? displayBoxMp4Default;
  final String? image;
  final List<String>? locales;
  final Map<String, LocaleType>? localesTypes;
  final String? caseStatus;
  final String? importanceLevel;
  final int? hits;
  final List<PreparedBy>? preparedBy;
  final List<Attachment>? attachments;

  BookDetailModel({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.type,
    required this.addDate,
    required this.updateDate,
    required this.orginalItem,
    required this.translationLanguage,
    required this.sourceLanguage,
    required this.displayBoxMp4Default,
    required this.image,
    required this.locales,
    required this.localesTypes,
    required this.caseStatus,
    required this.importanceLevel,
    required this.hits,
    required this.preparedBy,
    required this.attachments,
  });

  factory BookDetailModel.fromJson(Map<String, dynamic> json) {
    return BookDetailModel(
      id: json['id'],
      sourceId: json['source_id'],
      title: json['title'],
      description: json['description'],
      fullDescription: json['full_description'],
      type: json['type'],
      addDate: json['add_date'],
      updateDate: json['update_date'],
      orginalItem: json['orginal_item'],
      translationLanguage: json['translation_language'],
      sourceLanguage: json['source_language'],
      displayBoxMp4Default: json['display_box_mp4_default'],
      image: json['image'],
      locales: List<String>.from(json['locales']),
      localesTypes: (json['locales-types'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, LocaleType.fromJson(value)),
      ),
      caseStatus: json['case'],
      importanceLevel: json['importance_level'],
      hits: json['hits'],
      preparedBy: (json['prepared_by'] as List)
          .map((e) => PreparedBy.fromJson(e))
          .toList(),
      attachments: (json['attachments'] as List)
          .map((e) => Attachment.fromJson(e))
          .toList(),
    );
  }
}

class LocaleType {
  final String? locale;
  final String? type;

  LocaleType({
    required this.locale,
    required this.type,
  });

  factory LocaleType.fromJson(Map<String, dynamic> json) {
    return LocaleType(
      locale: json['locale'],
      type: json['type'],
    );
  }
}

class PreparedBy {
  final int? id;
  final int? sourceId;
  final String? title;
  final String? type;
  final String? kind;
  final String? description;
  final String? apiUrl;

  PreparedBy({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.type,
    required this.kind,
    required this.description,
    required this.apiUrl,
  });

  factory PreparedBy.fromJson(Map<String, dynamic> json) {
    return PreparedBy(
      id: json['id'],
      sourceId: json['source_id'],
      title: json['title'],
      type: json['type'],
      kind: json['kind'],
      description: json['description'],
      apiUrl: json['api_url'],
    );
  }
}

class Attachment {
  final int? order;
  final String? size;
  final String? extensionType;
  final String? description;
  final String? url;

  Attachment({
    required this.order,
    required this.size,
    required this.extensionType,
    required this.description,
    required this.url,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      order: json['order'],
      size: json['size'],
      extensionType: json['extension_type'],
      description: json['description'],
      url: json['url'],
    );
  }
}
