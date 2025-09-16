import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final ScrollController scrollController;

  const BooksLoadedWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (selectedLanguage != null)
          SelectedLanguageChip(
            language: selectedLanguage!,
            onClear: () => onLanguageChanged(null),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
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
          child: PaginationSection(
            currentPage: state.booksResponse.links.currentPage,
            totalPages: state.booksResponse.links.pagesNumber,
            isDark: isDark,
            onPageChanged: (page) {
              context.read<BooksCubit>().fetchBooks(
                  selectedLanguage ?? 'showall',
                  page,
                  context.read<LocalizationCubit>().state.locale.languageCode);
            },
          ),
        ),
      ],
    );
  }
}
