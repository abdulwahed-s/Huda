import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/models/bookmark_model.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';

  final CacheHelper _cacheHelper;

  final StreamController<BookmarkChange> _bookmarkChangesController =
      StreamController<BookmarkChange>.broadcast();

  Stream<BookmarkChange> get bookmarkChanges =>
      _bookmarkChangesController.stream;

  BookmarkService({required CacheHelper cacheHelper})
      : _cacheHelper = cacheHelper;

  Future<List<BookmarkModel>> getAllBookmarks() async {
    try {
      final bookmarksJson = await _cacheHelper.getData(key: _bookmarksKey);
      if (bookmarksJson == null) return [];

      final List<dynamic> bookmarksList = json.decode(bookmarksJson);
      return bookmarksList
          .map((bookmark) => BookmarkModel.fromJson(bookmark))
          .toList();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      return [];
    }
  }

  Future<List<BookmarkModel>> getBookmarksByType(BookmarkType type) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks.where((bookmark) => bookmark.type == type).toList();
  }

  Future<List<BookmarkModel>> getBookmarksForSurah(int surahNumber) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks
        .where((bookmark) => bookmark.surahNumber == surahNumber)
        .toList();
  }

  Future<bool> isAyahBookmarked(int surahNumber, int ayahNumber) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks.any((bookmark) =>
        bookmark.surahNumber == surahNumber &&
        bookmark.ayahNumber == ayahNumber);
  }

  Future<bool> hasBookmarkType(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks.any((bookmark) =>
        bookmark.surahNumber == surahNumber &&
        bookmark.ayahNumber == ayahNumber &&
        bookmark.type == type);
  }

  Future<BookmarkModel?> getBookmark(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    final allBookmarks = await getAllBookmarks();
    try {
      return allBookmarks.firstWhere((bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.ayahNumber == ayahNumber &&
          bookmark.type == type);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addBookmark(BookmarkModel bookmark) async {
    try {
      final allBookmarks = await getAllBookmarks();

      final existingIndex = allBookmarks.indexWhere((b) =>
          b.surahNumber == bookmark.surahNumber &&
          b.ayahNumber == bookmark.ayahNumber &&
          b.type == bookmark.type);

      final isUpdate = existingIndex != -1;

      if (isUpdate) {
        allBookmarks[existingIndex] = bookmark.copyWith(
          updatedAt: DateTime.now(),
        );
      } else {
        allBookmarks.add(bookmark);
      }

      await _saveBookmarks(allBookmarks);

      _bookmarkChangesController.add(BookmarkChange(
        surahNumber: bookmark.surahNumber,
        ayahNumber: bookmark.ayahNumber,
        type: bookmark.type,
        action: isUpdate
            ? BookmarkChangeAction.updated
            : BookmarkChangeAction.added,
      ));

      return true;
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
      return false;
    }
  }

  Future<bool> removeBookmark(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    try {
      final allBookmarks = await getAllBookmarks();
      final originalLength = allBookmarks.length;

      allBookmarks.removeWhere((bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.ayahNumber == ayahNumber &&
          bookmark.type == type);

      final wasRemoved = allBookmarks.length < originalLength;

      await _saveBookmarks(allBookmarks);

      if (wasRemoved) {
        _bookmarkChangesController.add(BookmarkChange(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          type: type,
          action: BookmarkChangeAction.removed,
        ));
      }

      return true;
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      return false;
    }
  }

  Future<bool> removeAllBookmarksForAyah(
      int surahNumber, int ayahNumber) async {
    try {
      final allBookmarks = await getAllBookmarks();
      allBookmarks.removeWhere((bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.ayahNumber == ayahNumber);

      await _saveBookmarks(allBookmarks);
      return true;
    } catch (e) {
      debugPrint('Error removing all bookmarks for ayah: $e');
      return false;
    }
  }

  Future<bool> clearAllBookmarks() async {
    try {
      await _cacheHelper.removeData(key: _bookmarksKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing bookmarks: $e');
      return false;
    }
  }

  Future<Map<String, int>> getBookmarkStats() async {
    final allBookmarks = await getAllBookmarks();
    return {
      'total': allBookmarks.length,
      'bookmarks':
          allBookmarks.where((b) => b.type == BookmarkType.bookmark).length,
      'notes': allBookmarks.where((b) => b.type == BookmarkType.note).length,
      'stars': allBookmarks.where((b) => b.type == BookmarkType.star).length,
    };
  }

  String normalizeArabic(String input) {
    const diacritics = [
      '\u064B',
      '\u064C',
      '\u064D',
      '\u064E',
      '\u064F',
      '\u0650',
      '\u0651',
      '\u0652',
      '\u0653',
      '\u0654',
      '\u0655',
      '\u0670',
      '\u0656',
      '\u0657',
      '\u0658',
      '\u0659',
      '\u065A',
      '\u065B',
      '\u065C',
      '\u065D',
      '\u065E',
      '\u065F',
    ];

    var result = input;
    for (var mark in diacritics) {
      result = result.replaceAll(mark, '');
    }

    return result
        .replaceAll(RegExp(r'[إأآآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  Future<List<BookmarkModel>> searchBookmarks(String query) async {
    final allBookmarks = await getAllBookmarks();

    final normalizedQuery = normalizeArabic(query);

    return allBookmarks.where((bookmark) {
      final normalizedAyah = normalizeArabic(bookmark.ayahText);
      final normalizedSurah = normalizeArabic(bookmark.surahName);
      final normalizedNote = normalizeArabic(bookmark.note ?? '');

      return normalizedAyah.contains(normalizedQuery) ||
          normalizedSurah.contains(normalizedQuery) ||
          normalizedNote.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _saveBookmarks(List<BookmarkModel> bookmarks) async {
    final bookmarksJson = json.encode(
      bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    );
    await _cacheHelper.saveData(key: _bookmarksKey, value: bookmarksJson);
  }

  static String generateBookmarkId(
      int surahNumber, int ayahNumber, BookmarkType type) {
    return '${surahNumber}_${ayahNumber}_${type.name}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _bookmarkChangesController.close();
  }
}
