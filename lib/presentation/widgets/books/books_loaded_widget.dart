import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/book_pdf_source_resolver.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/books/book_card.dart';
import 'package:huda/presentation/widgets/books/continue_reading_card.dart';
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

  String? _resolveLanguageName(BuildContext context, String code) {
    final state = context.watch<LanguagesCubit>().state;
    if (state is LanguagesLoaded) {
      for (final lang in state.languages) {
        if (lang.langsymbol == code) return lang.langtranslation;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final progressService = getIt<BookProgressService>();
    return ListenableBuilder(
      listenable: progressService,
      builder: (context, child) {
        final lastRead = progressService.getLastRead();
        return SliverMainAxisGroup(
          slivers: [
            if (lastRead != null && lastRead.title != null)
              SliverToBoxAdapter(
                child: ContinueReadingCard(
                  progress: lastRead,
                  onTap: () => _openContinueReading(context, lastRead),
                ),
              ),
            if (selectedLanguage != null)
              SelectedLanguageChip(
                language: selectedLanguage!,
                languageName: _resolveLanguageName(context, selectedLanguage!),
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
      },
    );
  }

  Future<void> _openContinueReading(
    BuildContext context,
    BookProgress progress,
  ) async {
    final source = await BookPdfSourceResolver().resolve(
      bookId: progress.bookId,
      remoteUrl: progress.attachmentUrl ?? _listedPdfUrl(progress.bookId),
    );
    if (!context.mounted) return;

    if (source != null) {
      Navigator.pushNamed(
        context,
        AppRoute.pdfView,
        arguments: {
          'url': source.location,
          'fallbackPdfUrl': source.remoteUrl,
          'bookId': progress.bookId,
          'bookTitle': progress.title ?? '',
          'language': progress.language ??
              context.read<LocalizationCubit>().state.locale.languageCode,
        },
      );
      return;
    }

    // Older saved progress did not include an attachment URL. Keep those
    // records usable once by falling back to the detail route; opening the
    // reader again stores the URL for direct continuation thereafter.
    Navigator.pushNamed(
      context,
      AppRoute.bookDetail,
      arguments: {
        'bookId': progress.bookId.toString(),
        'language': progress.language ??
            context.read<LocalizationCubit>().state.locale.languageCode,
        'title': progress.title ?? '',
      },
    );
  }

  /// Older progress records did not save their attachment URL. The current
  /// catalogue response already contains it for visible books, so use it to
  /// keep the Continue Reading card a direct reader action during migration.
  String? _listedPdfUrl(int bookId) {
    for (final book in state.booksResponse.data) {
      if (book.id != bookId) continue;
      for (final attachment in book.attachments) {
        if (attachment.extensionType.toUpperCase() != 'PDF') continue;
        final url = attachment.url.trim();
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }
}
