import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/books_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/book_detail/action_buttons_section.dart';
import 'package:huda/presentation/widgets/book_detail/attachments_section.dart';
import 'package:huda/presentation/widgets/book_detail/book_info_card.dart';

class BookLoadedState extends StatelessWidget {
  final BookDetailModel bookDetail;
  final bool isBookDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final int bookId;
  final String title;
  final VoidCallback onPrimaryAction;
  final VoidCallback onDownload;
  final Function(bool, double) onDownloadStateChanged; // Add this callback
  final Function(Attachment) onAttachmentTap;

  const BookLoadedState({
    super.key,
    required this.bookDetail,
    required this.isBookDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.bookId,
    required this.title,
    required this.onPrimaryAction,
    required this.onDownload,
    required this.onDownloadStateChanged, // Add this parameter
    required this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionButtonsSection(
            bookDetail: bookDetail,
            isBookDownloaded: isBookDownloaded,
            isDownloading: isDownloading,
            downloadProgress: downloadProgress,
            bookId: bookId,
            onPrimaryAction: onPrimaryAction,
            onDownload: onDownload,
            onDownloadStateChanged: onDownloadStateChanged, // Pass the callback
          ),
          SizedBox(height: 32.h),
          BookInfoCard(
            title: bookDetail.title ?? 'Untitled',
            description: bookDetail.description ?? 'No description available',
            preparedBy: bookDetail.preparedBy ?? [],
            sectionTitle: AppLocalizations.of(context)!.bookDetails,
          ),
          SizedBox(height: 24.h),
          AttachmentsSection(
            attachments: bookDetail.attachments ?? [],
            onAttachmentTap: (attachment) => onAttachmentTap(attachment),
          ),
        ],
      ),
    );
  }
}
