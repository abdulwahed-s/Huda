import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:path_provider/path_provider.dart';

class OfflineBooksService {
  static const String _booksKey = 'offline_books';
  static const String _downloadProgressKey = 'download_progress';

  static bool get isSupported => !kIsWeb;

  Future<Directory> _getBooksDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Offline books not supported on web');
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDocDir.path}/huda_books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  Future<Directory> _getBookDirectory(int bookId) async {
    final booksDir = await _getBooksDirectory();
    final bookDir = Directory('${booksDir.path}/$bookId');
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  Future<void> saveBook(OfflineBookModel book) async {
    try {
      final bookDir = await _getBookDirectory(book.id);
      final bookInfoFile = File('${bookDir.path}/book_info.json');
      await bookInfoFile.writeAsString(jsonEncode(book.toJson()));

      final books = await getAllBooks();
      final existingIndex = books.indexWhere((b) => b.id == book.id);

      if (existingIndex != -1) {
        books[existingIndex] = book;
      } else {
        books.add(book);
      }

      await _saveBooksToPrefs(books);
    } catch (e) {
      throw Exception('Failed to save book: $e');
    }
  }

  Future<List<OfflineBookModel>> getAllBooks() async {
    try {
      final booksData = CacheHelper.sharedPreferences.getString(_booksKey);
      if (booksData == null) return [];

      final List<dynamic> booksList = jsonDecode(booksData);
      return booksList
          .map((bookJson) => OfflineBookModel.fromJson(bookJson))
          .toList();
    } catch (e) {
      return await _getBooksFromDirectory();
    }
  }

  Future<List<OfflineBookModel>> _getBooksFromDirectory() async {
    try {
      final booksDir = await _getBooksDirectory();
      final List<OfflineBookModel> books = [];

      await for (final entity in booksDir.list()) {
        if (entity is Directory) {
          try {
            final bookInfoFile = File('${entity.path}/book_info.json');
            if (await bookInfoFile.exists()) {
              final bookData = await bookInfoFile.readAsString();
              final book = OfflineBookModel.fromJson(jsonDecode(bookData));
              books.add(book);
            }
          } catch (e) {
            continue;
          }
        }
      }

      await _saveBooksToPrefs(books);
      return books;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveBooksToPrefs(List<OfflineBookModel> books) async {
    final booksJson = books.map((book) => book.toJson()).toList();
    await CacheHelper.sharedPreferences
        .setString(_booksKey, jsonEncode(booksJson));
  }

  Future<OfflineBookModel?> getBook(int bookId) async {
    try {
      final books = await getAllBooks();
      return books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteBook(int bookId) async {
    try {
      final bookDir = await _getBookDirectory(bookId);
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }

      final books = await getAllBooks();
      books.removeWhere((book) => book.id == bookId);
      await _saveBooksToPrefs(books);

      await removeDownloadProgress(bookId);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Future<bool> isBookDownloaded(int bookId) async {
    final book = await getBook(bookId);
    if (book == null) return false;

    for (final attachment in book.attachments) {
      if (!attachment.isDownloaded ||
          !await File(attachment.localPath).exists()) {
        return false;
      }
    }
    return true;
  }

  Future<List<OfflineBookModel>> getBooksByLanguage(String language) async {
    final books = await getAllBooks();
    return books.where((book) => book.language == language).toList();
  }

  Future<List<OfflineBookModel>> searchBooks(String query) async {
    final books = await getAllBooks();
    final lowercaseQuery = query.toLowerCase();

    return books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
          book.description.toLowerCase().contains(lowercaseQuery) ||
          book.preparedBy.any((author) =>
              author.title?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Future<int> getTotalDownloadedSize() async {
    final books = await getAllBooks();
    return books.fold<int>(0, (total, book) => total + book.fileSize);
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    final books = await getAllBooks();
    final totalSize = await getTotalDownloadedSize();

    return {
      'totalBooks': books.length,
      'totalSize': totalSize,
      'sizeFormatted': _formatBytes(totalSize),
      'booksByLanguage': _groupBooksByLanguage(books),
    };
  }

  Map<String, int> _groupBooksByLanguage(List<OfflineBookModel> books) {
    final Map<String, int> languageCount = {};
    for (final book in books) {
      languageCount[book.language] = (languageCount[book.language] ?? 0) + 1;
    }
    return languageCount;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> saveDownloadProgress(DownloadProgress progress) async {
    try {
      final progressMap = await _getAllDownloadProgress();
      progressMap[progress.bookId.toString()] = progress.toJson();
      await CacheHelper.sharedPreferences
          .setString(_downloadProgressKey, jsonEncode(progressMap));
    } catch (e) {
      throw Exception('Failed to save download progress: $e');
    }
  }

  Future<DownloadProgress?> getDownloadProgress(int bookId) async {
    try {
      final progressMap = await _getAllDownloadProgress();
      final progressData = progressMap[bookId.toString()];
      if (progressData != null) {
        return DownloadProgress(
          bookId: progressData['bookId'],
          fileName: progressData['fileName'],
          progress: progressData['progress'],
          downloadedBytes: progressData['downloadedBytes'],
          totalBytes: progressData['totalBytes'],
          status: DownloadStatus.values
              .firstWhere((status) => status.name == progressData['status']),
          error: progressData['error'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getAllDownloadProgress() async {
    try {
      final progressData =
          CacheHelper.sharedPreferences.getString(_downloadProgressKey);
      if (progressData == null) return {};
      return Map<String, dynamic>.from(jsonDecode(progressData));
    } catch (e) {
      return {};
    }
  }

  Future<void> removeDownloadProgress(int bookId) async {
    try {
      final progressMap = await _getAllDownloadProgress();
      progressMap.remove(bookId.toString());
      await CacheHelper.sharedPreferences
          .setString(_downloadProgressKey, jsonEncode(progressMap));
    } catch (e) {
      // print('Failed to remove download progress: $e');
    }
  }

  Future<String> getAttachmentPath(int bookId, String fileName) async {
    final bookDir = await _getBookDirectory(bookId);
    final attachmentsDir = Directory('${bookDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return '${attachmentsDir.path}/$fileName';
  }

  Future<String> getImagePath(int bookId, String fileName) async {
    final bookDir = await _getBookDirectory(bookId);
    final imagesDir = Directory('${bookDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return '${imagesDir.path}/$fileName';
  }

  Future<void> cleanupOrphanedFiles() async {
    try {
      final booksDir = await _getBooksDirectory();
      final books = await getAllBooks();
      final validBookIds = books.map((book) => book.id.toString()).toSet();

      await for (final entity in booksDir.list()) {
        if (entity is Directory) {
          final dirName = entity.path.split('/').last;
          if (!validBookIds.contains(dirName)) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      // print('Failed to cleanup orphaned files: $e');
    }
  }

  Future<Map<String, dynamic>> exportBookData() async {
    final books = await getAllBooks();
    final storageInfo = await getStorageInfo();

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'books': books.map((book) => book.toJson()).toList(),
      'storageInfo': storageInfo,
    };
  }
}

extension on DownloadProgress {
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'fileName': fileName,
      'progress': progress,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'status': status.name,
      'error': error,
    };
  }
}
