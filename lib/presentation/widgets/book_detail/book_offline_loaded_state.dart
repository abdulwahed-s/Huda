import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/presentation/widgets/book_detail/offline_attachment_item.dart';
import 'package:huda/presentation/widgets/book_detail/offline_book_info_card.dart';
import 'package:huda/presentation/widgets/book_detail/primary_button.dart';

class BookOfflineLoadedState extends StatelessWidget {
  final OfflineBookModel offlineBook;
  final VoidCallback onPrimaryAction;
  final VoidCallback onDelete;
  final Function(OfflineAttachment) onAttachmentTap;

  const BookOfflineLoadedState({
    super.key,
    required this.offlineBook,
    required this.onPrimaryAction,
    required this.onDelete,
    required this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  icon: offlineBook.attachments.first.extensionType == 'PDF'
                      ? Icons.picture_as_pdf_rounded
                      : Icons.file_download_rounded,
                  label: offlineBook.attachments.first.extensionType == 'PDF'
                      ? 'Read PDF'
                      : 'Open File',
                  onPressed: onPrimaryAction,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: PrimaryButton(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  onPressed: onDelete,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          OfflineBookInfoCard(offlineBook: offlineBook),
          SizedBox(height: 24.h),
          if (offlineBook.attachments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attachment_rounded,
                      color: context.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Files (${offlineBook.attachments.length})',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ...offlineBook.attachments.map((attachment) {
                  return OfflineAttachmentItem(
                    attachment: attachment,
                    onTap: () => onAttachmentTap(attachment),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
