int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class AudiosResponse {
  final List<AudioItem> data;
  final AudioLinks links;

  AudiosResponse({required this.data, required this.links});

  factory AudiosResponse.fromJson(Map<String, dynamic> json) {
    return AudiosResponse(
      data: (json['data'] as List).map((e) => AudioItem.fromJson(e)).toList(),
      links: AudioLinks.fromJson(json['links']),
    );
  }
}

class AudioItem {
  final int id;
  final int sourceId;
  final String title;
  final String type;
  final int addDate;
  final int updateDate;
  final String? description;
  final String? fullDescription;
  final String sourceLanguage;
  final String translatedLanguage;
  final String? image;
  final int numAttachments;
  final String importanceLevel;
  final String apiUrl;
  final List<AudioPreparedBy> preparedBy;

  AudioItem({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.type,
    required this.addDate,
    required this.updateDate,
    this.description,
    this.fullDescription,
    required this.sourceLanguage,
    required this.translatedLanguage,
    this.image,
    required this.numAttachments,
    required this.importanceLevel,
    required this.apiUrl,
    required this.preparedBy,
  });

  factory AudioItem.fromJson(Map<String, dynamic> json) {
    return AudioItem(
      id: _toInt(json['id']),
      sourceId: _toInt(json['source_id']),
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      addDate: _toInt(json['add_date']),
      updateDate: _toInt(json['update_date']),
      description: json['description'],
      fullDescription: json['full_description'],
      sourceLanguage: json['source_language'] ?? '',
      translatedLanguage: json['translated_language'] ?? '',
      image: json['image'],
      numAttachments: _toInt(json['num_attachments']),
      importanceLevel: json['importance_level'] ?? '',
      apiUrl: json['api_url'] ?? '',
      preparedBy: json['prepared_by'] != null
          ? (json['prepared_by'] as List)
              .map((e) => AudioPreparedBy.fromJson(e))
              .toList()
          : <AudioPreparedBy>[],
    );
  }
}

class AudioPreparedBy {
  final int id;
  final int sourceId;
  final String? title;
  final String type;
  final String kind;
  final String? description;
  final String apiUrl;

  AudioPreparedBy({
    required this.id,
    required this.sourceId,
    this.title,
    required this.type,
    required this.kind,
    this.description,
    required this.apiUrl,
  });

  factory AudioPreparedBy.fromJson(Map<String, dynamic> json) {
    return AudioPreparedBy(
      id: _toInt(json['id']),
      sourceId: _toInt(json['source_id']),
      title: json['title'],
      type: json['type'] ?? '',
      kind: json['kind'] ?? '',
      description: json['description'],
      apiUrl: json['api_url'] ?? '',
    );
  }
}

class AudioLinks {
  final String? next;
  final String? prev;
  final String? first;
  final String? last;
  final int currentPage;
  final int pagesNumber;
  final int totalItems;

  AudioLinks({
    this.next,
    this.prev,
    this.first,
    this.last,
    required this.currentPage,
    required this.pagesNumber,
    required this.totalItems,
  });

  factory AudioLinks.fromJson(Map<String, dynamic> json) {
    return AudioLinks(
      next: json['next'],
      prev: json['prev'],
      first: json['first'],
      last: json['last'],
      currentPage: _toInt(json['current_page'], 1),
      pagesNumber: _toInt(json['pages_number'], 1),
      totalItems: _toInt(json['total_items']),
    );
  }
}
