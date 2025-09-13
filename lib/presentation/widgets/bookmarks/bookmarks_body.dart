import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmarks_list.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmarks_list_with_stats.dart';
import 'package:huda/presentation/widgets/bookmarks/empty_state_for_tab_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/empty_state_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/error_state_widget.dart';

class BookmarksBody extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final BookmarkType? currentFilter;
  final TabController tabController;
  final Function(BookmarkModel) onNavigateToAyah;
  final Function(String, BookmarkModel) onHandleBookmarkAction;

  const BookmarksBody({
    super.key,
    required this.isDark,
    required this.searchQuery,
    required this.currentFilter,
    required this.tabController,
    required this.onNavigateToAyah,
    required this.onHandleBookmarkAction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookmarksCubit, BookmarksState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is BookmarksLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF674B5D)),
          );
        }

        if (state is BookmarksError) {
          return ErrorStateWidget(state: state);
        }

        final allBookmarks =
            state is BookmarksLoaded ? state.bookmarks : <BookmarkModel>[];
        final stats = state is BookmarksLoaded
            ? state.stats
            : {'total': 0, 'bookmarks': 0, 'notes': 0, 'stars': 0};

        final searchFilteredBookmarks = _filterBookmarksBySearch(allBookmarks);
        final filteredBookmarks = _filterBookmarksByType(
            searchFilteredBookmarks, BookmarkType.bookmark);
        final noteBookmarks =
            _filterBookmarksByType(searchFilteredBookmarks, BookmarkType.note);
        final starBookmarks =
            _filterBookmarksByType(searchFilteredBookmarks, BookmarkType.star);

        return Column(
          children: [
            Expanded(
              child: searchFilteredBookmarks.isEmpty
                  ? EmptyStateWidget(isDark: isDark)
                  : TabBarView(
                      controller: tabController,
                      children: [
                        BookmarksListWithStats(
                          bookmarks: searchFilteredBookmarks,
                          stats: stats,
                          isDark: isDark,
                          onNavigateToAyah: onNavigateToAyah,
                          onHandleBookmarkAction: onHandleBookmarkAction,
                        ),
                        filteredBookmarks.isEmpty
                            ? EmptyStateForTabWidget(
                                isDark: isDark,
                                title: AppLocalizations.of(context)!
                                    .noBookmarksYet,
                                subtitle: AppLocalizations.of(context)!
                                    .startBookmarkingFavoriteVerses,
                              )
                            : BookmarksList(
                                bookmarks: filteredBookmarks,
                                isDark: isDark,
                                onNavigateToAyah: onNavigateToAyah,
                                onHandleBookmarkAction: onHandleBookmarkAction,
                              ),
                        noteBookmarks.isEmpty
                            ? EmptyStateForTabWidget(
                                isDark: isDark,
                                title: AppLocalizations.of(context)!.noNotesYet,
                                subtitle: AppLocalizations.of(context)!
                                    .addNotesToFavoriteVerses,
                              )
                            : BookmarksList(
                                bookmarks: noteBookmarks,
                                isDark: isDark,
                                onNavigateToAyah: onNavigateToAyah,
                                onHandleBookmarkAction: onHandleBookmarkAction,
                              ),
                        starBookmarks.isEmpty
                            ? EmptyStateForTabWidget(
                                isDark: isDark,
                                title: AppLocalizations.of(context)!
                                    .noStarredVersesYet,
                                subtitle: AppLocalizations.of(context)!
                                    .starImportantVerses,
                              )
                            : BookmarksList(
                                bookmarks: starBookmarks,
                                isDark: isDark,
                                onNavigateToAyah: onNavigateToAyah,
                                onHandleBookmarkAction: onHandleBookmarkAction,
                              ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  List<BookmarkModel> _filterBookmarksBySearch(List<BookmarkModel> bookmarks) {
    return searchQuery.isEmpty
        ? bookmarks
        : bookmarks.where((bookmark) {
            final normalizedQuery = TextUtils.removeDiacriticsAndNormalize(
                searchQuery.toLowerCase());
            final normalizedAyahText = TextUtils.removeDiacriticsAndNormalize(
                bookmark.ayahText.toLowerCase());
            final normalizedSurahName = TextUtils.removeDiacriticsAndNormalize(
                bookmark.surahName.toLowerCase());
            final normalizedNote = bookmark.note != null
                ? TextUtils.removeDiacriticsAndNormalize(
                    bookmark.note!.toLowerCase())
                : '';

            return normalizedAyahText.contains(normalizedQuery) ||
                normalizedSurahName.contains(normalizedQuery) ||
                (bookmark.note != null &&
                    normalizedNote.contains(normalizedQuery));
          }).toList();
  }

  List<BookmarkModel> _filterBookmarksByType(
      List<BookmarkModel> bookmarks, BookmarkType type) {
    return bookmarks.where((b) => b.type == type).toList();
  }
}
