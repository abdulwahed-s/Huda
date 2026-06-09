import 'dart:convert';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

class BookProgress {
  final int bookId;
  final int pageNumber;
  final int totalPages;
  final DateTime updatedAt;
  final String? title;
  final String? author;
  final String? attachmentUrl;
  final String? language;

  BookProgress({
    required this.bookId,
    required this.pageNumber,
    required this.totalPages,
    required this.updatedAt,
    this.title,
    this.author,
    this.attachmentUrl,
    this.language,
  });

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      bookId: json['bookId'],
      pageNumber: json['pageNumber'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      title: json['title'],
      author: json['author'],
      attachmentUrl: json['attachmentUrl'],
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'title': title,
      'author': author,
      'attachmentUrl': attachmentUrl,
      'language': language,
    };
  }
}

class BookProgressService {
  static const String _progressKey = 'book_progress';
  static const String _lastReadIdKey = 'book_last_read_id';

  final CacheHelper _cacheHelper = getIt<CacheHelper>();

  Map<String, dynamic> _readAll() {
    try {
      final data = _cacheHelper.getDataString(key: _progressKey);
      if (data == null) return {};
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  Future<void> savePosition(
    int bookId,
    int pageNumber, {
    int? totalPages,
    String? title,
    String? author,
    String? attachmentUrl,
    String? language,
  }) async {
    final all = _readAll();
    final existing = all[bookId.toString()];
    final progress = BookProgress(
      bookId: bookId,
      pageNumber: pageNumber,
      totalPages: totalPages ?? (existing != null ? existing['totalPages'] : 0),
      updatedAt: DateTime.now(),
      title: title ?? (existing != null ? existing['title'] : null),
      author: author ?? (existing != null ? existing['author'] : null),
      attachmentUrl:
          attachmentUrl ?? (existing != null ? existing['attachmentUrl'] : null),
      language: language ?? (existing != null ? existing['language'] : null),
    );
    all[bookId.toString()] = progress.toJson();
    await _cacheHelper.saveData(key: _progressKey, value: jsonEncode(all));
    await _cacheHelper.saveData(key: _lastReadIdKey, value: bookId);
  }

  BookProgress? getProgress(int bookId) {
    final all = _readAll();
    final data = all[bookId.toString()];
    if (data == null) return null;
    try {
      return BookProgress.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  BookProgress? getLastRead() {
    final id = _cacheHelper.getData(key: _lastReadIdKey) as int?;
    if (id == null) return null;
    return getProgress(id);
  }

  bool hasProgress(int bookId) => getProgress(bookId) != null;

  Future<void> clear(int bookId) async {
    final all = _readAll();
    all.remove(bookId.toString());
    await _cacheHelper.saveData(key: _progressKey, value: jsonEncode(all));
    final lastId = _cacheHelper.getData(key: _lastReadIdKey) as int?;
    if (lastId == bookId) {
      await _cacheHelper.removeData(key: _lastReadIdKey);
    }
  }
}
