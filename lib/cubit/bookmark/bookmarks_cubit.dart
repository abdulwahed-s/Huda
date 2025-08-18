import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/bookmark_service.dart';

part 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  final BookmarkService _bookmarkService;

  BookmarksCubit({required BookmarkService bookmarkService})
      : _bookmarkService = bookmarkService,
        super(BookmarksInitial());

  Future<void> loadBookmarks() async {
    try {
      emit(BookmarksLoading());
      final bookmarks = await _bookmarkService.getAllBookmarks();
      final stats = await _bookmarkService.getBookmarkStats();

      emit(BookmarksLoaded(
        bookmarks: bookmarks,
        stats: stats,
      ));
    } catch (e) {
      emit(BookmarksError('Failed to load bookmarks: $e'));
    }
  }

  Future<void> filterBookmarks(BookmarkType? type) async {
    try {
      emit(BookmarksLoading());

      List<BookmarkModel> bookmarks;
      if (type != null) {
        bookmarks = await _bookmarkService.getBookmarksByType(type);
      } else {
        bookmarks = await _bookmarkService.getAllBookmarks();
      }

      final stats = await _bookmarkService.getBookmarkStats();

      emit(BookmarksLoaded(
        bookmarks: bookmarks,
        filterType: type,
        stats: stats,
      ));
    } catch (e) {
      emit(BookmarksError('Failed to filter bookmarks: $e'));
    }
  }

  Future<void> searchBookmarks(String query) async {
    try {
      emit(BookmarksLoading());

      List<BookmarkModel> bookmarks;
      if (query.isEmpty) {
        bookmarks = await _bookmarkService.getAllBookmarks();
      } else {
        bookmarks = await _bookmarkService.searchBookmarks(query);
      }

      final stats = await _bookmarkService.getBookmarkStats();

      emit(BookmarksLoaded(
        bookmarks: bookmarks,
        searchQuery: query,
        stats: stats,
      ));
    } catch (e) {
      emit(BookmarksError('Failed to search bookmarks: $e'));
    }
  }

  Future<void> addBookmark({
    required int surahNumber,
    required int ayahNumber,
    required String ayahText,
    required String surahName,
    required BookmarkType type,
    Color? color,
    String? note,
    double? ayahPosition,
  }) async {
    try {
      final bookmark = BookmarkModel(
        id: BookmarkService.generateBookmarkId(surahNumber, ayahNumber, type),
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        ayahText: ayahText,
        surahName: surahName,
        type: type,
        color: color ??
            (type == BookmarkType.bookmark
                ? BookmarkColors.getDefaultColor()
                : null),
        note: note,
        ayahPosition: ayahPosition,
        createdAt: DateTime.now(),
      );

      final success = await _bookmarkService.addBookmark(bookmark);

      if (success) {
        final bookmarks = await _bookmarkService.getAllBookmarks();
        final stats = await _bookmarkService.getBookmarkStats();

        emit(BookmarkOperationSuccess(
          message: 'Bookmark added successfully',
          bookmarks: bookmarks,
          stats: stats,
        ));

        emit(BookmarksLoaded(
          bookmarks: bookmarks,
          stats: stats,
        ));
      } else {
        emit(BookmarkOperationFailure('Failed to add bookmark'));
      }
    } catch (e) {
      emit(BookmarkOperationFailure('Error adding bookmark: $e'));
    }
  }

  Future<void> removeBookmark(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    try {
      final success =
          await _bookmarkService.removeBookmark(surahNumber, ayahNumber, type);

      if (success) {
        final bookmarks = await _bookmarkService.getAllBookmarks();
        final stats = await _bookmarkService.getBookmarkStats();

        emit(BookmarkOperationSuccess(
          message: 'Bookmark removed successfully',
          bookmarks: bookmarks,
          stats: stats,
        ));

        emit(BookmarksLoaded(
          bookmarks: bookmarks,
          stats: stats,
        ));
      } else {
        emit(BookmarkOperationFailure('Failed to remove bookmark'));
      }
    } catch (e) {
      emit(BookmarkOperationFailure('Error removing bookmark: $e'));
    }
  }

  Future<void> updateBookmarkNote(
    int surahNumber,
    int ayahNumber,
    String note,
  ) async {
    try {
      final existingBookmark = await _bookmarkService.getBookmark(
        surahNumber,
        ayahNumber,
        BookmarkType.note,
      );

      if (existingBookmark != null) {
        final updatedBookmark = existingBookmark.copyWith(
          note: note,
          updatedAt: DateTime.now(),
        );

        final success = await _bookmarkService.addBookmark(updatedBookmark);

        if (success) {
          final bookmarks = await _bookmarkService.getAllBookmarks();
          final stats = await _bookmarkService.getBookmarkStats();

          emit(BookmarkOperationSuccess(
            message: 'Note updated successfully',
            bookmarks: bookmarks,
            stats: stats,
          ));

          emit(BookmarksLoaded(
            bookmarks: bookmarks,
            stats: stats,
          ));
        } else {
          emit(BookmarkOperationFailure('Failed to update note'));
        }
      } else {
        emit(BookmarkOperationFailure('Note not found'));
      }
    } catch (e) {
      emit(BookmarkOperationFailure('Error updating note: $e'));
    }
  }

  Future<void> clearAllBookmarks() async {
    try {
      final success = await _bookmarkService.clearAllBookmarks();

      if (success) {
        emit(BookmarkOperationSuccess(
          message: 'All bookmarks cleared',
          bookmarks: [],
          stats: {'total': 0, 'bookmarks': 0, 'notes': 0, 'stars': 0},
        ));

        emit(BookmarksLoaded(
          bookmarks: [],
          stats: {'total': 0, 'bookmarks': 0, 'notes': 0, 'stars': 0},
        ));
      } else {
        emit(BookmarkOperationFailure('Failed to clear bookmarks'));
      }
    } catch (e) {
      emit(BookmarkOperationFailure('Error clearing bookmarks: $e'));
    }
  }

  Future<bool> isAyahBookmarked(int surahNumber, int ayahNumber) async {
    return await _bookmarkService.isAyahBookmarked(surahNumber, ayahNumber);
  }

  Future<bool> hasBookmarkType(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    return await _bookmarkService.hasBookmarkType(
        surahNumber, ayahNumber, type);
  }

  Future<BookmarkModel?> getBookmark(
      int surahNumber, int ayahNumber, BookmarkType type) async {
    return await _bookmarkService.getBookmark(surahNumber, ayahNumber, type);
  }
}
