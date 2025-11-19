import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/book_detail/book_detail_cubit.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
import 'package:huda/cubit/download_manager/download_manager_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/services/offline_books_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class BookDetailController {
  final BuildContext context;
  final int bookId;
  final String language;
  final String title;
  final VoidCallback refreshUI;
  final OfflineBooksService _offlineBooksService = OfflineBooksService();

  String? selectedLanguage;
  bool isDownloading = false;
  bool isBookDownloaded = false;
  double downloadProgress = 0.0;

  BookDetailController(
    this.context,
    this.bookId,
    this.language,
    this.title,
    this.refreshUI,
  );

  String get currentLanguageCode =>
      context.read<LocalizationCubit>().state.locale.languageCode;

  void initialize() {
    fetchInitialData();
    checkIfBookDownloaded();
  }

  void dispose() {
    // Clean up any resources if needed
  }

  void fetchInitialData() {
    context.read<BookDetailCubit>().fetchBookDetail(bookId, language);
    context
        .read<BookLanguagesCubit>()
        .fetchBookLanguages(bookId, currentLanguageCode);
    selectedLanguage = null;
  }

  void retryBookDetail() {
    context.read<BookDetailCubit>().fetchBookDetail(
          bookId,
          selectedLanguage ?? language,
        );
  }

  void handleLanguageSelected(String? language) {
    selectedLanguage = language;
    refreshUI();

    if (language == null) {
      context.read<BookDetailCubit>().fetchBookDetail(bookId, this.language);
    } else {
      final translations =
          context.read<BookLanguagesCubit>().state as BookTranslationsLoaded;
      final translation =
          translations.translations.firstWhere((t) => t.slang == language);
      context.read<BookDetailCubit>().fetchBookDetail(
            translation.id,
            translation.slang,
          );
    }
  }

  void handleDownloadStateChanged(bool isDownloading, double progress) {
    isDownloading = isDownloading;
    downloadProgress = progress;
    if (!isDownloading && progress == 1.0) {
      isBookDownloaded = true;
    }
    refreshUI();
  }

  Future<void> checkIfBookDownloaded() async {
    try {
      isBookDownloaded = await _offlineBooksService.isBookDownloaded(bookId);
      refreshUI();
    } catch (e) {
      // Handle error silently
    }
  }

  void handlePrimaryAction(BookDetailLoaded state) {
    if (state.bookDetail.attachments![0].extensionType == 'PDF') {
      Navigator.pushNamed(
        context,
        AppRoute.pdfView,
        arguments: state.bookDetail.attachments![0].url,
      );
    } else {
      _launchUrl(state.bookDetail.attachments![0].url!);
    }
  }

  void handleAttachmentTap(attachment) {
    if (attachment.extensionType == 'PDF') {
      Navigator.pushNamed(
        context,
        AppRoute.pdfView,
        arguments: attachment.url,
      );
    } else {
      _launchUrl(attachment.url!);
    }
  }

  void _launchUrl(String url) {
    try {
      launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void handleOfflinePrimaryAction(BookDetailOfflineLoaded state) {
    final firstAttachment = state.offlineBook.attachments.first;
    handleOfflineAttachmentTap(firstAttachment);
  }

  void handleOfflineAttachmentTap(OfflineAttachment attachment) {
    if (attachment.extensionType == 'PDF') {
      Navigator.pushNamed(
        context,
        AppRoute.pdfView,
        arguments: attachment.localPath,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening files not yet supported'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShareDialog(
          title: title,
          onShareAsPdf: () {
            Navigator.pop(context);
            shareAsPdf();
          },
          onShareAsMessage: () {
            Navigator.pop(context);
            shareAsMessage();
          },
        );
      },
    );
  }

  void showDeleteDialog(BuildContext context, int bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Downloaded Book'),
          content: const Text(
              'Are you sure you want to delete this downloaded book? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteOfflineBook(bookId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteOfflineBook(int bookId) async {
    try {
      await _offlineBooksService.deleteBook(bookId);
      isBookDownloaded = false;
      refreshUI();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete book: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> downloadBook(BookDetailLoaded state) async {
    try {
      isDownloading = true;
      downloadProgress = 0.0;
      refreshUI();

      final languageToUse = selectedLanguage ?? language;

      await context
          .read<DownloadManagerCubit>()
          .downloadBook(state.bookDetail, languageToUse);

      final isDownloaded = await _offlineBooksService.isBookDownloaded(bookId);
      if (context.mounted) {
        isDownloading = false;
        isBookDownloaded = isDownloaded;
        downloadProgress = isDownloaded ? 1.0 : 0.0;
        refreshUI();
      }
    } catch (e) {
      if (context.mounted) {
        isDownloading = false;
        downloadProgress = 0.0;
        refreshUI();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start download: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void shareAsMessage() {
    final message =
        'I found this amazing book "$title" - read it in Huda app! 📚\n\nDownload Huda app to explore more Islamic books and resources.';

    SharePlus.instance.share(ShareParams(
      text: message,
      subject: 'Check out this book: $title',
    ));
  }

  Future<void> shareAsPdf() async {
    try {
      final state = context.read<BookDetailCubit>().state;

      if (state is BookDetailLoaded) {
        final pdfAttachment = state.bookDetail.attachments?.firstWhere(
          (attachment) => attachment.extensionType == 'PDF',
          orElse: () => throw Exception('No PDF found'),
        );

        if (pdfAttachment?.url != null) {
          if (isBookDownloaded) {
            await sharePdfFromLocal();
          } else {
            await sharePdfFromUrl(pdfAttachment!.url!);
          }
        } else {
          throw Exception('PDF URL not available');
        }
      } else if (state is BookDetailOfflineLoaded) {
        await sharePdfFromLocal();
      } else {
        throw Exception('Book details not loaded');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> sharePdfFromLocal() async {
    try {
      final offlineBook = await _offlineBooksService.getBook(bookId);
      if (offlineBook != null && offlineBook.attachments.isNotEmpty) {
        final pdfAttachment = offlineBook.attachments.firstWhere(
          (attachment) => attachment.extensionType == 'PDF',
          orElse: () => throw Exception('No PDF found in offline book'),
        );

        final file = File(pdfAttachment.localPath);
        if (await file.exists()) {
          await SharePlus.instance.share(ShareParams(
            files: [XFile(pdfAttachment.localPath)],
            text: 'Check out this book: $title',
            subject: title,
          ));
        } else {
          throw Exception('PDF file not found locally');
        }
      } else {
        throw Exception('Offline book not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sharePdfFromUrl(String url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparing PDF for sharing...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s]+'), '_')}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      await dio.download(url, filePath);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      await SharePlus.instance.share(ShareParams(
        files: [XFile(filePath)],
        text: 'Check out this book: $title',
        subject: title,
      ));

      Future.delayed(const Duration(seconds: 30), () {
        try {
          File(filePath).deleteSync();
        } catch (e) {
          // Ignore cleanup errors
        }
      });
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
}

class ShareDialog extends StatelessWidget {
  final String title;
  final VoidCallback onShareAsPdf;
  final VoidCallback onShareAsMessage;

  const ShareDialog({
    super.key,
    required this.title,
    required this.onShareAsPdf,
    required this.onShareAsMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share $title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Share as PDF'),
            onTap: onShareAsPdf,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Share as Message'),
            onTap: onShareAsMessage,
          ),
        ],
      ),
    );
  }
}
