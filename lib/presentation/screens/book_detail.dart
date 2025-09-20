import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/book_detail/book_detail_cubit.dart';
import 'package:huda/presentation/widgets/book_detail/book_detail_animations.dart';
import 'package:huda/presentation/widgets/book_detail/book_detail_controller.dart';
import 'package:huda/presentation/widgets/book_detail/book_loaded_state.dart';
import 'package:huda/presentation/widgets/book_detail/book_loading_state.dart';
import 'package:huda/presentation/widgets/book_detail/book_offline_loaded_state.dart';
import 'package:huda/presentation/widgets/book_detail/languages_section.dart';
import 'package:huda/presentation/widgets/book_detail/book_detail_app_bar.dart';
import 'package:huda/presentation/widgets/book_detail/error_state_card.dart';
import 'package:huda/presentation/widgets/book_detail/offline_state_card.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;
  final String language;
  final String title;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.language,
    required this.title,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with TickerProviderStateMixin {
  late BookDetailAnimations animations;
  late BookDetailController controller;

  @override
  void initState() {
    super.initState();
    animations = BookDetailAnimations(this);
    controller = BookDetailController(
      context,
      widget.bookId,
      widget.language,
      widget.title,
      () => setState(() {}),
    );
    animations.initialize();
    controller.initialize();
  }

  @override
  void dispose() {
    animations.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          BookDetailAppBar(
            title: widget.title,
            isDark: isDark,
            onSharePressed: () => controller.showShareDialog(context),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: animations.fadeAnimation,
              child: SlideTransition(
                position: animations.slideAnimation,
                child: Column(
                  children: [
                    _buildBookDetailSection(),
                    SizedBox(height: 24.h),
                    LanguagesSection(
                      selectedLanguage: controller.selectedLanguage,
                      bookId: widget.bookId,
                      currentLanguageCode: controller.currentLanguageCode,
                      onLanguageSelected: controller.handleLanguageSelected,
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetailSection() {
    return BlocBuilder<BookDetailCubit, BookDetailState>(
      builder: (context, state) {
        if (state is BookDetailLoading) {
          return const BookLoadingState();
        } else if (state is BookDetailLoaded) {
          return BookLoadedState(
            bookDetail: state.bookDetail,
            isBookDownloaded: controller.isBookDownloaded,
            isDownloading: controller.isDownloading,
            downloadProgress: controller.downloadProgress,
            bookId: widget.bookId,
            title: widget.title,
            onPrimaryAction: () => controller.handlePrimaryAction(state),
            onDownload: () => controller.downloadBook(state),
            onAttachmentTap: controller.handleAttachmentTap,
            onDownloadStateChanged: controller.handleDownloadStateChanged,
          );
        } else if (state is BookDetailOfflineLoaded) {
          return BookOfflineLoadedState(
            offlineBook: state.offlineBook,
            onPrimaryAction: () => controller.handleOfflinePrimaryAction(state),
            onDelete: () =>
                controller.showDeleteDialog(context, state.offlineBook.id),
            onAttachmentTap: controller.handleOfflineAttachmentTap,
          );
        } else if (state is BookDetailOffline) {
          return OfflineStateCard(
            section: 'Book Details',
            onRetry: controller.retryBookDetail,
          );
        } else if (state is BookDetailError) {
          return ErrorStateCard(
            error: state.error == 'Exception: Error: There is no Data'
                ? 'The selected language is not available'
                : 'Error: ${state.error}',
            section: 'Book Details',
            onRetry: controller.retryBookDetail,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
