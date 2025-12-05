import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/models/books_detail_model.dart';
import 'package:huda/data/services/offline_books_service.dart';
import 'package:path/path.dart' as path;

class BookDownloadService {
  final Dio _dio = Dio();
  final OfflineBooksService _offlineBooksService = OfflineBooksService();

  Function(DownloadProgress)? onProgressUpdate;

  static bool get isSupported => !kIsWeb;

  BookDownloadService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  Future<void> downloadBook(BookDetailModel bookDetail, String language) async {
    if (kIsWeb) {
      throw UnsupportedError('Book downloads not supported on web');
    }
    try {
      final offlineBook = await _createOfflineBookModel(bookDetail, language);

      await _updateProgress(offlineBook.id, 'Initializing download...', 0.0, 0,
          1, DownloadStatus.downloading);

      String? localImagePath;
      if (bookDetail.image != null && bookDetail.image!.isNotEmpty) {
        try {
          localImagePath =
              await _downloadImage(offlineBook.id, bookDetail.image!);
        } catch (e) {
          //
        }
      }

      final List<OfflineAttachment> downloadedAttachments = [];
      for (int i = 0; i < offlineBook.attachments.length; i++) {
        final attachment = offlineBook.attachments[i];

        await _updateProgress(
            offlineBook.id,
            'Downloading ${attachment.description}...',
            i / offlineBook.attachments.length,
            0,
            1,
            DownloadStatus.downloading);

        final downloadedAttachment =
            await _downloadAttachment(offlineBook.id, attachment);
        downloadedAttachments.add(downloadedAttachment);
      }

      final finalOfflineBook = offlineBook.copyWith(
        localImagePath: localImagePath,
        attachments: downloadedAttachments,
        downloadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _offlineBooksService.saveBook(finalOfflineBook);

      await _updateProgress(offlineBook.id, 'Download completed', 1.0, 1, 1,
          DownloadStatus.completed);

      Future.delayed(const Duration(seconds: 3), () {
        _offlineBooksService.removeDownloadProgress(offlineBook.id);
      });
    } catch (e) {
      print(e);
      await _updateProgress(
          bookDetail.id!, 'Download failed', 0.0, 0, 1, DownloadStatus.failed,
          error: e.toString());
      throw Exception('Failed to download book: $e');
    }
  }

  Future<OfflineBookModel> _createOfflineBookModel(
      BookDetailModel bookDetail, String language) async {
    final List<OfflineAttachment> offlineAttachments = [];
    int totalSize = 0;

    for (final attachment in bookDetail.attachments ?? []) {
      final fileName = _getFileNameFromUrl(attachment.url ?? '');
      final localPath = await _offlineBooksService.getAttachmentPath(
          bookDetail.id!, fileName);

      final offlineAttachment = OfflineAttachment(
        order: attachment.order,
        size: attachment.size,
        extensionType: attachment.extensionType,
        description: attachment.description,
        originalUrl: attachment.url ?? '',
        localPath: localPath,
        isDownloaded: false,
      );

      offlineAttachments.add(offlineAttachment);

      try {
        final sizeValue = _parseSizeString(attachment.size);
        totalSize += sizeValue;
      } catch (e) {
        totalSize += 1024 * 1024;
      }
    }

    final List<OfflinePreparedBy> offlinePreparedBy = [];
    for (final preparedBy in bookDetail.preparedBy ?? []) {
      offlinePreparedBy.add(OfflinePreparedBy(
        id: preparedBy.id,
        title: preparedBy.title,
        type: preparedBy.type,
        kind: preparedBy.kind,
        description: preparedBy.description,
      ));
    }

    return OfflineBookModel(
      id: bookDetail.id!,
      title: bookDetail.title ?? '',
      language: language,
      sourceLanguage: bookDetail.sourceLanguage ?? '',
      description: bookDetail.description ?? '',
      imageUrl: bookDetail.image,
      attachments: offlineAttachments,
      preparedBy: offlinePreparedBy,
      downloadedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fileSize: totalSize,
    );
  }

  Future<String> _downloadImage(int bookId, String imageUrl) async {
    final fileName = _getFileNameFromUrl(imageUrl);
    final localPath = await _offlineBooksService.getImagePath(bookId, fileName);

    await _dio.download(
      imageUrl,
      localPath,
      options: Options(responseType: ResponseType.bytes),
    );

    return localPath;
  }

  Future<OfflineAttachment> _downloadAttachment(
      int bookId, OfflineAttachment attachment) async {
    await _dio.download(
      attachment.originalUrl,
      attachment.localPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          _updateProgress(
            bookId,
            'Downloading ${attachment.description}...',
            progress,
            received,
            total,
            DownloadStatus.downloading,
          );
        }
      },
      options: Options(responseType: ResponseType.bytes),
    );

    return attachment.copyWith(isDownloaded: true);
  }

  Future<void> _updateProgress(
    int bookId,
    String fileName,
    double progress,
    int downloadedBytes,
    int totalBytes,
    DownloadStatus status, {
    String? error,
  }) async {
    final downloadProgress = DownloadProgress(
      bookId: bookId,
      fileName: fileName,
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      status: status,
      error: error,
    );

    await _offlineBooksService.saveDownloadProgress(downloadProgress);
    onProgressUpdate?.call(downloadProgress);
  }

  Future<void> cancelDownload(int bookId) async {
    try {
      await _updateProgress(
        bookId,
        'Download cancelled',
        0.0,
        0,
        1,
        DownloadStatus.cancelled,
      );

      await _cleanupPartialDownload(bookId);
    } catch (e) {
      //
    }
  }

  Future<void> _cleanupPartialDownload(int bookId) async {
    try {
      await _offlineBooksService.deleteBook(bookId);
    } catch (e) {
      //
    }
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    String fileName = path.basename(uri.path);

    if (!fileName.contains('.')) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        fileName = segments.last;
      }

      if (!fileName.contains('.')) {
        fileName = '$fileName.pdf';
      }
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

  Future<bool> isDownloading(int bookId) async {
    final progress = await _offlineBooksService.getDownloadProgress(bookId);
    return progress?.status == DownloadStatus.downloading;
  }

  Future<DownloadProgress?> getDownloadProgress(int bookId) async {
    return await _offlineBooksService.getDownloadProgress(bookId);
  }

  Future<void> pauseDownload(int bookId) async {
    await _updateProgress(
      bookId,
      'Download paused',
      0.0,
      0,
      1,
      DownloadStatus.paused,
    );
  }

  Future<void> resumeDownload(int bookId) async {
    await _updateProgress(
      bookId,
      'Resuming download...',
      0.0,
      0,
      1,
      DownloadStatus.downloading,
    );
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

  Future<int> getAvailableDiskSpace() async {
    try {
      return 1024 * 1024 * 1024;
    } catch (e) {
      return 0;
    }
  }
}
