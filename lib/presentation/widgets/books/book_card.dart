import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/books/book_description.dart';
import 'package:huda/presentation/widgets/books/language_badge.dart';
import 'package:huda/presentation/widgets/books/language_display.dart';
import 'package:huda/presentation/widgets/books/read_more_button.dart';

class BookCard extends StatelessWidget {
  final dynamic book;
  final bool isDark;

  const BookCard({
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
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.darkCardBackground.withValues(alpha: 0.9),
                        context.darkCardBackground,
                      ],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          color: isDark ? context.darkText : context.lightText,
                          height: 1.3,
                        ),
                      ),
                    ),
                    LanguageBadge(language: book.sourceLanguage),
                  ],
                ),
                SizedBox(height: 12.h),
                LanguageDisplay(
                    locale:
                        Locale.fromSubtags(languageCode: book.sourceLanguage)),
                if (book.description != null) ...[
                  SizedBox(height: 12.h),
                  BookDescription(
                      description: book.description, isDark: isDark),
                ],
                SizedBox(height: 16.h),
                const ReadMoreButton(),
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
        'language': book.translatedLanguage.toString(),
        'title': book.title.toString(),
      },
    );
  }
}
