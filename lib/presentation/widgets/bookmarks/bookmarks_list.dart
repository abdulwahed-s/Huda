import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmark_card.dart';

class BookmarksList extends StatelessWidget {
  final List<BookmarkModel> bookmarks;
  final bool isDark;
  final Function(BookmarkModel) onNavigateToAyah;
  final Function(String, BookmarkModel) onHandleBookmarkAction;

  const BookmarksList({
    super.key,
    required this.bookmarks,
    required this.isDark,
    required this.onNavigateToAyah,
    required this.onHandleBookmarkAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkCard(
          bookmark: bookmark,
          isDark: isDark,
          onNavigateToAyah: onNavigateToAyah,
          onHandleBookmarkAction: onHandleBookmarkAction,
        );
      },
    );
  }
}
