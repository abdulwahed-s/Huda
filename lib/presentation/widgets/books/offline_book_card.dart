import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/books/author_row.dart';
import 'package:huda/presentation/widgets/books/download_badge.dart';

class OfflineBookCard extends StatelessWidget {
  final dynamic book;
  final bool isDark;

  const OfflineBookCard({
    super.key,
    required this.book,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: isDark ? 4 : 2,
        shadowColor:
            isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: () => _navigateToBookDetail(context, book),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DownloadBadge(),
                    const Spacer(),
                    Text(
                      book.sourceLanguage.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? context.darkText.withValues(alpha: 0.6)
                            : context.lightText.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.darkText : context.lightText,
                    fontFamily: 'Amiri',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    book.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark
                          ? context.darkText.withValues(alpha: 0.7)
                          : context.lightText.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (book.preparedBy.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  AuthorRow(
                      author: book.preparedBy.first.title ?? 'Unknown Author'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBookDetail(BuildContext context, dynamic book) {
    Navigator.pushNamed(
      context,
      AppRoute.bookDetail,
      arguments: {
        'bookId': book.id.toString(),
        'language': book.language.toString(),
        'title': book.title.toString(),
      },
    );
  }
}
