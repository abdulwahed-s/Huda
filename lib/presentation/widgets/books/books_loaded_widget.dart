import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/books/book_card.dart';
import 'package:huda/presentation/widgets/books/pagination_section.dart';
import 'package:huda/presentation/widgets/books/selected_language_chip.dart';

class BooksLoadedWidget extends StatelessWidget {
  final BooksLoaded state;
  final bool isDark;
  final String? selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;

  const BooksLoadedWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (selectedLanguage != null)
          SelectedLanguageChip(
            language: selectedLanguage!,
            onClear: () => onLanguageChanged(null),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  context.responsive(mobile: 2, tablet: 3, desktop: 6),
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => BookCard(
                book: state.booksResponse.data[index],
                isDark: isDark,
              ),
              childCount: state.booksResponse.data.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 32.h),
            child: PaginationSection(
              currentPage: state.booksResponse.links.currentPage,
              totalPages: state.booksResponse.links.pagesNumber,
              isDark: isDark,
              onPageChanged: (page) {
                context.read<BooksCubit>().fetchBooks(
                    selectedLanguage ?? 'showall',
                    page,
                    context
                        .read<LocalizationCubit>()
                        .state
                        .locale
                        .languageCode);
              },
            ),
          ),
        ),
      ],
    );
  }
}
