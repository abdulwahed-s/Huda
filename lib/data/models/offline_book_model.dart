import 'package:equatable/equatable.dart';

class OfflineBookModel extends Equatable {
  final int id;
  final String title;
  final String language;
  final String sourceLanguage;
  final String description;
  final String? imageUrl;
  final String? localImagePath;
  final List<OfflineAttachment> attachments;
  final List<OfflinePreparedBy> preparedBy;
  final DateTime downloadedAt;
  final DateTime updatedAt;
  final int fileSize; // Total size in bytes

  const OfflineBookModel({
    required this.id,
    required this.title,
    required this.language,
    required this.sourceLanguage,
    required this.description,
    this.imageUrl,
    this.localImagePath,
    required this.attachments,
    required this.preparedBy,
    required this.downloadedAt,
    required this.updatedAt,
    required this.fileSize,
  });

  factory OfflineBookModel.fromJson(Map<String, dynamic> json) {
    return OfflineBookModel(
      id: json['id'],
      title: json['title'],
      language: json['language'],
      sourceLanguage: json['sourceLanguage'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      localImagePath: json['localImagePath'],
      attachments: (json['attachments'] as List)
          .map((e) => OfflineAttachment.fromJson(e))
          .toList(),
      preparedBy: (json['preparedBy'] as List)
          .map((e) => OfflinePreparedBy.fromJson(e))
          .toList(),
      downloadedAt: DateTime.parse(json['downloadedAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fileSize: json['fileSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'language': language,
      'sourceLanguage': sourceLanguage,
      'description': description,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'preparedBy': preparedBy.map((e) => e.toJson()).toList(),
      'downloadedAt': downloadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  OfflineBookModel copyWith({
    int? id,
    String? title,
    String? language,
    String? sourceLanguage,
    String? description,
    String? imageUrl,
    String? localImagePath,
    List<OfflineAttachment>? attachments,
    List<OfflinePreparedBy>? preparedBy,
    DateTime? downloadedAt,
    DateTime? updatedAt,
    int? fileSize,
  }) {
    return OfflineBookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      attachments: attachments ?? this.attachments,
      preparedBy: preparedBy ?? this.preparedBy,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        language,
        sourceLanguage,
        description,
        imageUrl,
        localImagePath,
        attachments,
        preparedBy,
        downloadedAt,
        updatedAt,
        fileSize,
      ];
}

class OfflineAttachment extends Equatable {
  final int order;
  final String size;
  final String extensionType;
  final String description;
  final String originalUrl;
  final String localPath;
  final bool isDownloaded;

  const OfflineAttachment({
    required this.order,
    required this.size,
    required this.extensionType,
    required this.description,
    required this.originalUrl,
    required this.localPath,
    required this.isDownloaded,
  });

  factory OfflineAttachment.fromJson(Map<String, dynamic> json) {
    return OfflineAttachment(
      order: json['order'],
      size: json['size'],
      extensionType: json['extensionType'],
      description: json['description'],
      originalUrl: json['originalUrl'],
      localPath: json['localPath'],
      isDownloaded: json['isDownloaded'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'size': size,
      'extensionType': extensionType,
      'description': description,
      'originalUrl': originalUrl,
      'localPath': localPath,
      'isDownloaded': isDownloaded,
    };
  }

  OfflineAttachment copyWith({
    int? order,
    String? size,
    String? extensionType,
    String? description,
    String? originalUrl,
    String? localPath,
    bool? isDownloaded,
  }) {
    return OfflineAttachment(
      order: order ?? this.order,
      size: size ?? this.size,
      extensionType: extensionType ?? this.extensionType,
      description: description ?? this.description,
      originalUrl: originalUrl ?? this.originalUrl,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
        order,
        size,
        extensionType,
        description,
        originalUrl,
        localPath,
        isDownloaded,
      ];
}

class OfflinePreparedBy extends Equatable {
  final int id;
  final String? title;
  final String type;
  final String kind;
  final String? description;

  const OfflinePreparedBy({
    required this.id,
    this.title,
    required this.type,
    required this.kind,
    this.description,
  });

  factory OfflinePreparedBy.fromJson(Map<String, dynamic> json) {
    return OfflinePreparedBy(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      kind: json['kind'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'kind': kind,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, title, type, kind, description];
}

class DownloadProgress extends Equatable {
  final int bookId;
  final String fileName;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.bookId,
    required this.fileName,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  DownloadProgress copyWith({
    int? bookId,
    String? fileName,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      bookId: bookId ?? this.bookId,
      fileName: fileName ?? this.fileName,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        bookId,
        fileName,
        progress,
        downloadedBytes,
        totalBytes,
        status,
        error,
      ];
}

enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}
