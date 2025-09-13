import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmark_menu.dart';
import 'package:huda/presentation/widgets/bookmarks/note_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/ayah_text_widget.dart';

class BookmarkCard extends StatelessWidget {
  final BookmarkModel bookmark;
  final bool isDark;
  final Function(BookmarkModel) onNavigateToAyah;
  final Function(String, BookmarkModel) onHandleBookmarkAction;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.isDark,
    required this.onNavigateToAyah,
    required this.onHandleBookmarkAction,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final displayColor = bookmark.color ?? _getBookmarkTypeColor(bookmark.type);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  appColors.darkCardBackground,
                  appColors.darkCardBackground.withValues(alpha: 0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey)
                .withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () => onNavigateToAyah(bookmark),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              displayColor.withValues(alpha: 0.2),
                              displayColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: displayColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: displayColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                _getBookmarkTypeIcon(bookmark.type),
                                size: 14.r,
                                color: displayColor,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                _getBookmarkTypeLabel(bookmark.type, context),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: displayColor,
                                  fontFamily: 'Amiri',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (bookmark.color != null) ...[
                              SizedBox(width: 6.w),
                              Container(
                                width: 12.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: bookmark.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? appColors.darkTabBackground
                                  .withValues(alpha: 0.6)
                              : appColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: appColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 12.r,
                              color: appColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                '${bookmark.surahName} ${bookmark.surahNumber}:${bookmark.ayahNumber}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: appColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Amiri',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    BookmarkMenu(
                      bookmark: bookmark,
                      isDark: isDark,
                      onHandleBookmarkAction: onHandleBookmarkAction,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                AyahTextWidget(
                  ayahText: bookmark.ayahText,
                  isDark: isDark,
                ),
                if (bookmark.type == BookmarkType.note && bookmark.note != null)
                  NoteWidget(
                    note: bookmark.note!,
                    displayColor: displayColor,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBookmarkTypeColor(BookmarkType type) {
    switch (type) {
      case BookmarkType.bookmark:
        return const Color(0xFF674B5D);
      case BookmarkType.note:
        return Colors.orange;
      case BookmarkType.star:
        return Colors.amber;
    }
  }

  IconData _getBookmarkTypeIcon(BookmarkType type) {
    switch (type) {
      case BookmarkType.bookmark:
        return Icons.bookmark;
      case BookmarkType.note:
        return Icons.note;
      case BookmarkType.star:
        return Icons.star;
    }
  }

  String _getBookmarkTypeLabel(BookmarkType type, BuildContext context) {
    switch (type) {
      case BookmarkType.bookmark:
        return AppLocalizations.of(context)!.bookmark;
      case BookmarkType.note:
        return AppLocalizations.of(context)!.note;
      case BookmarkType.star:
        return AppLocalizations.of(context)!.star;
    }
  }
}

