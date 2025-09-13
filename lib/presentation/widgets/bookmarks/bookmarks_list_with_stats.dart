import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmark_card.dart';
import 'package:huda/presentation/widgets/bookmarks/stat_item_widget.dart';

class BookmarksListWithStats extends StatelessWidget {
  final List<BookmarkModel> bookmarks;
  final Map<String, int> stats;
  final bool isDark;
  final Function(BookmarkModel) onNavigateToAyah;
  final Function(String, BookmarkModel) onHandleBookmarkAction;

  const BookmarksListWithStats({
    super.key,
    required this.bookmarks,
    required this.stats,
    required this.isDark,
    required this.onNavigateToAyah,
    required this.onHandleBookmarkAction,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        if (stats['total']! > 0)
          Container(
            margin: EdgeInsets.only(bottom: 24.h),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        appColors.darkGradientStart,
                        appColors.darkGradientMid,
                        appColors.darkGradientEnd,
                      ]
                    : [
                        appColors.primary,
                        appColors.primaryVariant,
                        appColors.accent,
                      ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: appColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .bookmarksYourCollection,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Amiri',
                            ),
                          ),
                          Text(
                            '${stats['total']} ${AppLocalizations.of(context)!.bookmarksSavedVerses}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: StatItemWidget(
                        label: AppLocalizations.of(context)!.bookmarks,
                        count: stats['bookmarks']!,
                        icon: Icons.bookmark_rounded,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: StatItemWidget(
                        label: AppLocalizations.of(context)!.notes,
                        count: stats['notes']!,
                        icon: Icons.sticky_note_2_rounded,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: StatItemWidget(
                        label: AppLocalizations.of(context)!.stars,
                        count: stats['stars']!,
                        icon: Icons.star_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ...bookmarks.map((bookmark) => BookmarkCard(
              bookmark: bookmark,
              isDark: isDark,
              onNavigateToAyah: onNavigateToAyah,
              onHandleBookmarkAction: onHandleBookmarkAction,
            )),
      ],
    );
  }
}

