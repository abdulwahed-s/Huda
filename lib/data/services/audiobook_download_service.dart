import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';
import 'package:path/path.dart' as path;

class AudiobookDownloadService {
  final Dio _dio = Dio();
  final OfflineAudiobooksService _offlineService = OfflineAudiobooksService();

  Function(DownloadProgress)? onProgressUpdate;

  static bool get isSupported => !kIsWeb;

  AudiobookDownloadService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  Future<void> downloadAudiobook(
      AudioDetailModel detail, String language) async {
    if (kIsWeb) {
      throw UnsupportedError('Audiobook downloads not supported on web');
    }
    try {
      final offline = await _createOfflineModel(detail, language);

      await _updateProgress(offline.id, 'Initializing download...', 0.0, 0, 1,
          DownloadStatus.downloading);

      String? localImagePath;
      if (detail.image != null && detail.image!.isNotEmpty) {
        try {
          localImagePath = await _downloadImage(offline.id, detail.image!);
        } catch (e) {
          //
        }
      }

      final List<OfflineTrack> downloadedTracks = [];
      for (int i = 0; i < offline.tracks.length; i++) {
        final track = offline.tracks[i];
        await _updateProgress(offline.id, 'Downloading ${track.description}...',
            i / offline.tracks.length, 0, 1, DownloadStatus.downloading);
        downloadedTracks.add(await _downloadTrack(offline.id, track));
      }

      final finalModel = offline.copyWith(
        localImagePath: localImagePath,
        tracks: downloadedTracks,
        downloadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _offlineService.saveAudiobook(finalModel);

      await _updateProgress(offline.id, 'Download completed', 1.0, 1, 1,
          DownloadStatus.completed);

      Future.delayed(const Duration(seconds: 3), () {
        _offlineService.removeDownloadProgress(offline.id);
      });
    } catch (e) {
      await _updateProgress(
          detail.id!, 'Download failed', 0.0, 0, 1, DownloadStatus.failed,
          error: e.toString());
      throw Exception('Failed to download audiobook: $e');
    }
  }

  Future<OfflineAudiobookModel> _createOfflineModel(
      AudioDetailModel detail, String language) async {
    final List<OfflineTrack> tracks = [];
    int totalSize = 0;

    for (final attachment in detail.attachments ?? <AudioTrack>[]) {
      final localPath =
          await _offlineService.getTrackPath(detail.id!, attachment.order);

      tracks.add(OfflineTrack(
        order: attachment.order,
        size: attachment.size,
        extensionType: attachment.extensionType,
        description: attachment.description,
        originalUrl: attachment.url,
        localPath: localPath,
        isDownloaded: false,
      ));

      try {
        totalSize += _parseSizeString(attachment.size);
      } catch (e) {
        totalSize += 1024 * 1024;
      }
    }

    final List<OfflinePreparedBy> preparedBy = [];
    for (final p in detail.preparedBy ?? <AudioDetailPreparedBy>[]) {
      preparedBy.add(OfflinePreparedBy(
        id: p.id ?? 0,
        title: p.title,
        type: p.type ?? '',
        kind: p.kind ?? '',
        description: p.description,
      ));
    }

    return OfflineAudiobookModel(
      id: detail.id!,
      title: detail.title ?? '',
      language: language,
      sourceLanguage: detail.sourceLanguage ?? '',
      description: detail.description ?? '',
      imageUrl: detail.image,
      tracks: tracks,
      preparedBy: preparedBy,
      downloadedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fileSize: totalSize,
    );
  }

  Future<String> _downloadImage(int id, String imageUrl) async {
    final fileName = _getFileNameFromUrl(imageUrl, fallbackExt: 'jpg');
    final localPath = await _offlineService.getImagePath(id, fileName);
    await _dio.download(
      imageUrl,
      localPath,
      options: Options(responseType: ResponseType.bytes),
    );
    return localPath;
  }

  Future<OfflineTrack> _downloadTrack(int id, OfflineTrack track) async {
    await _dio.download(
      track.originalUrl,
      track.localPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _updateProgress(
            id,
            'Downloading ${track.description}...',
            received / total,
            received,
            total,
            DownloadStatus.downloading,
          );
        }
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return track.copyWith(isDownloaded: true);
  }

  Future<void> _updateProgress(
    int id,
    String fileName,
    double progress,
    int downloadedBytes,
    int totalBytes,
    DownloadStatus status, {
    String? error,
  }) async {
    final downloadProgress = DownloadProgress(
      bookId: id,
      fileName: fileName,
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      status: status,
      error: error,
    );
    await _offlineService.saveDownloadProgress(downloadProgress);
    onProgressUpdate?.call(downloadProgress);
  }

  Future<void> cancelDownload(int id) async {
    try {
      await _updateProgress(
          id, 'Download cancelled', 0.0, 0, 1, DownloadStatus.cancelled);
      await _offlineService.deleteAudiobook(id);
    } catch (e) {
      //
    }
  }

  Future<bool> isDownloading(int id) async {
    final progress = await _offlineService.getDownloadProgress(id);
    return progress?.status == DownloadStatus.downloading;
  }

  Future<DownloadProgress?> getDownloadProgress(int id) async {
    return await _offlineService.getDownloadProgress(id);
  }

  Future<bool> validateDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final stat = await file.stat();
      return stat.size > 0;
    } catch (e) {
      return false;
    }
  }

  String _getFileNameFromUrl(String url, {String fallbackExt = 'mp3'}) {
    final uri = Uri.parse(url);
    String fileName = path.basename(uri.path);
    if (!fileName.contains('.')) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) fileName = segments.last;
      if (!fileName.contains('.')) fileName = '$fileName.$fallbackExt';
    }
    return fileName;
  }

  int _parseSizeString(String sizeStr) {
    final cleanSize = sizeStr.toLowerCase().replaceAll(RegExp(r'[^\d\.]'), '');
    final size = double.tryParse(cleanSize) ?? 1.0;
    if (sizeStr.toLowerCase().contains('kb')) {
      return (size * 1024).round();
    } else if (sizeStr.toLowerCase().contains('mb')) {
      return (size * 1024 * 1024).round();
    } else if (sizeStr.toLowerCase().contains('gb')) {
      return (size * 1024 * 1024 * 1024).round();
    } else {
      return size.round();
    }
  }
}
