import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';

/// A viewport is stored as page-relative fractions instead of pixels so a
/// reader can resume correctly after a window-size or orientation change.
class BookReadingViewport {
  const BookReadingViewport({
    required this.pageIndex,
    this.top = 0,
    this.left = 0,
    this.zoom = 1,
  });

  final int pageIndex;
  final double top;
  final double left;
  final double zoom;

  factory BookReadingViewport.fromJson(Object? value) {
    if (value is! Map) return const BookReadingViewport(pageIndex: 0);
    final page = value['page'];
    if (page is! int || page < 0) {
      return const BookReadingViewport(pageIndex: 0);
    }
    return BookReadingViewport(
      pageIndex: page,
      top: _finiteNumber(value['top'], fallback: 0),
      left: _finiteNumber(value['left'], fallback: 0),
      zoom: _finiteNumber(value['zoom'], fallback: 1),
    );
  }

  static BookReadingViewport? tryFromJson(Object? value) {
    if (value is! Map || value['page'] is! int || (value['page'] as int) < 0) {
      return null;
    }
    return BookReadingViewport.fromJson(value);
  }

  static double _finiteNumber(Object? value, {required double fallback}) {
    final number = (value as num?)?.toDouble();
    return number != null && number.isFinite ? number : fallback;
  }

  Map<String, dynamic> toJson() => {
        'page': pageIndex,
        if (top != 0) 'top': top,
        if (left != 0) 'left': left,
        'zoom': zoom,
      };
}

class BookProgress {
  final int bookId;
  final int pageNumber;
  final int totalPages;
  final DateTime updatedAt;
  final String? title;
  final String? author;
  final String? attachmentUrl;
  final String? language;
  final BookReadingViewport? viewport;

  BookProgress({
    required this.bookId,
    required this.pageNumber,
    required this.totalPages,
    required this.updatedAt,
    this.title,
    this.author,
    this.attachmentUrl,
    this.language,
    this.viewport,
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
      viewport: BookReadingViewport.tryFromJson(json['viewport']),
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
      if (viewport != null) 'viewport': viewport!.toJson(),
    };
  }
}

class BookProgressService extends ChangeNotifier {
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
    BookReadingViewport? viewport,
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
      attachmentUrl: attachmentUrl ??
          (existing != null ? existing['attachmentUrl'] : null),
      language: language ?? (existing != null ? existing['language'] : null),
      viewport: viewport ??
          (existing != null
              ? BookReadingViewport.tryFromJson(existing['viewport'])
              : null),
    );
    all[bookId.toString()] = progress.toJson();
    await _cacheHelper.saveData(key: _progressKey, value: jsonEncode(all));
    await _cacheHelper.saveData(key: _lastReadIdKey, value: bookId);
    notifyListeners();
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
    notifyListeners();
  }
}
