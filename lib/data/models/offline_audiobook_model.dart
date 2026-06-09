import 'package:equatable/equatable.dart';
import 'package:huda/data/models/offline_book_model.dart'
    show OfflinePreparedBy;

export 'package:huda/data/models/offline_book_model.dart'
    show DownloadProgress, DownloadStatus, OfflinePreparedBy;

class OfflineAudiobookModel extends Equatable {
  final int id;
  final String title;
  final String language;
  final String sourceLanguage;
  final String description;
  final String? imageUrl;
  final String? localImagePath;
  final List<OfflineTrack> tracks;
  final List<OfflinePreparedBy> preparedBy;
  final DateTime downloadedAt;
  final DateTime updatedAt;
  final int fileSize; 
  final int? totalDurationMs; 

  const OfflineAudiobookModel({
    required this.id,
    required this.title,
    required this.language,
    required this.sourceLanguage,
    required this.description,
    this.imageUrl,
    this.localImagePath,
    required this.tracks,
    required this.preparedBy,
    required this.downloadedAt,
    required this.updatedAt,
    required this.fileSize,
    this.totalDurationMs,
  });

  factory OfflineAudiobookModel.fromJson(Map<String, dynamic> json) {
    return OfflineAudiobookModel(
      id: json['id'],
      title: json['title'],
      language: json['language'],
      sourceLanguage: json['sourceLanguage'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      localImagePath: json['localImagePath'],
      tracks: (json['tracks'] as List)
          .map((e) => OfflineTrack.fromJson(e))
          .toList(),
      preparedBy: (json['preparedBy'] as List)
          .map((e) => OfflinePreparedBy.fromJson(e))
          .toList(),
      downloadedAt: DateTime.parse(json['downloadedAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fileSize: json['fileSize'],
      totalDurationMs: json['totalDurationMs'],
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
      'tracks': tracks.map((e) => e.toJson()).toList(),
      'preparedBy': preparedBy.map((e) => e.toJson()).toList(),
      'downloadedAt': downloadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fileSize': fileSize,
      'totalDurationMs': totalDurationMs,
    };
  }

  OfflineAudiobookModel copyWith({
    int? id,
    String? title,
    String? language,
    String? sourceLanguage,
    String? description,
    String? imageUrl,
    String? localImagePath,
    List<OfflineTrack>? tracks,
    List<OfflinePreparedBy>? preparedBy,
    DateTime? downloadedAt,
    DateTime? updatedAt,
    int? fileSize,
    int? totalDurationMs,
  }) {
    return OfflineAudiobookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      tracks: tracks ?? this.tracks,
      preparedBy: preparedBy ?? this.preparedBy,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSize: fileSize ?? this.fileSize,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
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
        tracks,
        preparedBy,
        downloadedAt,
        updatedAt,
        fileSize,
        totalDurationMs,
      ];
}

class OfflineTrack extends Equatable {
  final int order;
  final String size;
  final String extensionType;
  final String description;
  final String originalUrl;
  final String localPath;
  final bool isDownloaded;

  const OfflineTrack({
    required this.order,
    required this.size,
    required this.extensionType,
    required this.description,
    required this.originalUrl,
    required this.localPath,
    required this.isDownloaded,
  });

  factory OfflineTrack.fromJson(Map<String, dynamic> json) {
    return OfflineTrack(
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

  OfflineTrack copyWith({
    int? order,
    String? size,
    String? extensionType,
    String? description,
    String? originalUrl,
    String? localPath,
    bool? isDownloaded,
  }) {
    return OfflineTrack(
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
