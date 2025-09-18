import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/download_manager/download_manager_cubit.dart';
import 'package:huda/presentation/widgets/book_detail/download_button.dart';
import 'package:huda/presentation/widgets/book_detail/primary_button.dart';

class ActionButtonsSection extends StatefulWidget {
  final dynamic bookDetail;
  final bool isBookDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final int bookId;
  final VoidCallback onPrimaryAction;
  final VoidCallback onDownload;
  final Function(bool, double) onDownloadStateChanged; 

  const ActionButtonsSection({
    super.key,
    required this.bookDetail,
    required this.isBookDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.bookId,
    required this.onPrimaryAction,
    required this.onDownload,
    required this.onDownloadStateChanged, 
  });

  @override
  State<ActionButtonsSection> createState() => _ActionButtonsSectionState();
}

class _ActionButtonsSectionState extends State<ActionButtonsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocListener<DownloadManagerCubit, DownloadManagerState>(
          listener: (context, downloadState) {
            if (downloadState is DownloadInProgress &&
                downloadState.progress.bookId == widget.bookId) {
              widget.onDownloadStateChanged(
                  true, downloadState.progress.progress);
            } else if (downloadState is DownloadCompleted &&
                downloadState.bookId == widget.bookId) {
              widget.onDownloadStateChanged(false, 1.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Book downloaded successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (downloadState is DownloadError &&
                downloadState.bookId == widget.bookId) {
              widget.onDownloadStateChanged(false, 0.0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download failed: ${downloadState.message}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  icon: widget.bookDetail.attachments![0].extensionType == 'PDF'
                      ? Icons.picture_as_pdf_rounded
                      : Icons.file_download_rounded,
                  label:
                      widget.bookDetail.attachments![0].extensionType == 'PDF'
                          ? 'Read PDF'
                          : 'Open File',
                  onPressed: widget.onPrimaryAction,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: DownloadButton(
                  isBookDownloaded: widget.isBookDownloaded,
                  isDownloading: widget.isDownloading,
                  downloadProgress: widget.downloadProgress,
                  onPressed: widget.isDownloading || widget.isBookDownloaded
                      ? null
                      : widget.onDownload,
                  label: widget.isBookDownloaded
                      ? 'Downloaded'
                      : widget.isDownloading
                          ? '${(widget.downloadProgress * 100).toInt()}%'
                          : 'Download',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
