part of 'bookmarks_cubit.dart';

@immutable
sealed class BookmarksState {}

final class BookmarksInitial extends BookmarksState {}

final class BookmarksLoading extends BookmarksState {}

final class BookmarksLoaded extends BookmarksState {
  final List<BookmarkModel> bookmarks;
  final BookmarkType? filterType;
  final String searchQuery;
  final Map<String, int> stats;

  BookmarksLoaded({
    required this.bookmarks,
    this.filterType,
    this.searchQuery = '',
    required this.stats,
  });

  BookmarksLoaded copyWith({
    List<BookmarkModel>? bookmarks,
    BookmarkType? filterType,
    String? searchQuery,
    Map<String, int>? stats,
    bool clearFilter = false,
  }) {
    return BookmarksLoaded(
      bookmarks: bookmarks ?? this.bookmarks,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
      searchQuery: searchQuery ?? this.searchQuery,
      stats: stats ?? this.stats,
    );
  }
}

final class BookmarksError extends BookmarksState {
  final String message;

  BookmarksError(this.message);
}

final class BookmarkOperationSuccess extends BookmarksState {
  final String message;
  final List<BookmarkModel> bookmarks;
  final Map<String, int> stats;

  BookmarkOperationSuccess({
    required this.message,
    required this.bookmarks,
    required this.stats,
  });
}

final class BookmarkOperationFailure extends BookmarksState {
  final String message;

  BookmarkOperationFailure(this.message);
}
