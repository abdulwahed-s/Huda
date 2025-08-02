class BooksResponse {
  final List<BookItem> data;
  final Links links;

  BooksResponse({required this.data, required this.links});

  factory BooksResponse.fromJson(Map<String, dynamic> json) {
    return BooksResponse(
      data: (json['data'] as List).map((e) => BookItem.fromJson(e)).toList(),
      links: Links.fromJson(json['links']),
    );
  }
}

class BookItem {
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
  final List<PreparedBy> preparedBy;
  final List<Attachment> attachments;
  final List<dynamic> locales;

  BookItem({
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
    required this.attachments,
    required this.locales,
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id'] ?? 0,
      sourceId: json['source_id'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      addDate: json['add_date'] ?? 0,
      updateDate: json['update_date'] ?? 0,
      description: json['description'],
      fullDescription: json['full_description'],
      sourceLanguage: json['source_language'] ?? '',
      translatedLanguage: json['translated_language'] ?? '',
      image: json['image'],
      numAttachments: json['num_attachments'] ?? 0,
      importanceLevel: json['importance_level'] ?? '',
      apiUrl: json['api_url'] ?? '',
      preparedBy: json['prepared_by'] != null
          ? (json['prepared_by'] as List)
              .map((e) => PreparedBy.fromJson(e))
              .toList()
          : <PreparedBy>[],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => Attachment.fromJson(e))
              .toList()
          : <Attachment>[],
      locales: json['locales'] ?? <dynamic>[],
    );
  }
}

class PreparedBy {
  final int id;
  final int sourceId;
  final String? title;
  final String type;
  final String kind;
  final String? description;
  final String apiUrl;

  PreparedBy({
    required this.id,
    required this.sourceId,
    this.title,
    required this.type,
    required this.kind,
    this.description,
    required this.apiUrl,
  });

  factory PreparedBy.fromJson(Map<String, dynamic> json) {
    return PreparedBy(
      id: json['id'] ?? 0,
      sourceId: json['source_id'] ?? 0,
      title: json['title'],
      type: json['type'] ?? '',
      kind: json['kind'] ?? '',
      description: json['description'],
      apiUrl: json['api_url'] ?? '',
    );
  }
}

class Attachment {
  final int order;
  final String size;
  final String extensionType;
  final String description;
  final String url;

  Attachment({
    required this.order,
    required this.size,
    required this.extensionType,
    required this.description,
    required this.url,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      order: json['order'] ?? 0,
      size: json['size'] ?? '',
      extensionType: json['extension_type'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class Links {
  final String? next;
  final String? prev;
  final String? first;
  final String? last;
  final int currentPage;
  final int pagesNumber;
  final int totalItems;

  Links({
    this.next,
    this.prev,
    this.first,
    this.last,
    required this.currentPage,
    required this.pagesNumber,
    required this.totalItems,
  });

  factory Links.fromJson(Map<String, dynamic> json) {
    return Links(
      next: json['next'],
      prev: json['prev'],
      first: json['first'],
      last: json['last'],
      currentPage: json['current_page'] ?? 1,
      pagesNumber: json['pages_number'] ?? 1,
      totalItems: json['total_items'] ?? 0,
    );
  }
}
