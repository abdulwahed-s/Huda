int? _toIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class AudioDetailModel {
  final int? id;
  final int? sourceId;
  final String? title;
  final String? description;
  final String? fullDescription;
  final String? type;
  final int? addDate;
  final int? updateDate;
  final String? translationLanguage;
  final String? sourceLanguage;
  final String? image;
  final List<String>? locales;
  final String? caseStatus;
  final String? importanceLevel;
  final int? hits;
  final List<AudioDetailPreparedBy>? preparedBy;
  final List<AudioTrack>? attachments;

  AudioDetailModel({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.type,
    required this.addDate,
    required this.updateDate,
    required this.translationLanguage,
    required this.sourceLanguage,
    required this.image,
    required this.locales,
    required this.caseStatus,
    required this.importanceLevel,
    required this.hits,
    required this.preparedBy,
    required this.attachments,
  });

  factory AudioDetailModel.fromJson(Map<String, dynamic> json) {
    return AudioDetailModel(
      id: _toIntOrNull(json['id']),
      sourceId: _toIntOrNull(json['source_id']),
      title: json['title'],
      description: json['description'],
      fullDescription: json['full_description'],
      type: json['type'],
      addDate: _toIntOrNull(json['add_date']),
      updateDate: _toIntOrNull(json['update_date']),
      translationLanguage: json['translation_language'],
      sourceLanguage: json['source_language'],
      image: json['image'],
      locales: json['locales'] != null
          ? List<String>.from(json['locales'])
          : <String>[],
      caseStatus: json['case'],
      importanceLevel: json['importance_level'],
      hits: _toIntOrNull(json['hits']),
      preparedBy: json['prepared_by'] != null
          ? (json['prepared_by'] as List)
              .map((e) => AudioDetailPreparedBy.fromJson(e))
              .toList()
          : <AudioDetailPreparedBy>[],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => AudioTrack.fromJson(e))
              .toList()
          : <AudioTrack>[],
    );
  }
}

class AudioDetailPreparedBy {
  final int? id;
  final int? sourceId;
  final String? title;
  final String? type;
  final String? kind;
  final String? description;
  final String? apiUrl;

  AudioDetailPreparedBy({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.type,
    required this.kind,
    required this.description,
    required this.apiUrl,
  });

  factory AudioDetailPreparedBy.fromJson(Map<String, dynamic> json) {
    return AudioDetailPreparedBy(
      id: _toIntOrNull(json['id']),
      sourceId: _toIntOrNull(json['source_id']),
      title: json['title'],
      type: json['type'],
      kind: json['kind'],
      description: json['description'],
      apiUrl: json['api_url'],
    );
  }
}

/// One audio attachment = one chapter/track of an audiobook.
class AudioTrack {
  final int order;
  final String size;
  final String extensionType;
  final String description;
  final String url;

  AudioTrack({
    required this.order,
    required this.size,
    required this.extensionType,
    required this.description,
    required this.url,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      order: _toIntOrNull(json['order']) ?? 0,
      size: json['size'] ?? '',
      extensionType: json['extension_type'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
