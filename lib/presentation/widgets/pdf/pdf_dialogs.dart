import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:dart_pdf_editor/dart_pdf_editor.dart';

class PdfGoToPageDialog extends StatelessWidget {
  final PdfViewerController pdfViewerController;
  final TextEditingController searchController;

  const PdfGoToPageDialog({
    super.key,
    required this.pdfViewerController,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context)!.goToPageTitle,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!
                .enterPageNumber(pdfViewerController.pageCount.toString()),
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.pageNumber,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () async {
            NavigatorState navigatorState = Navigator.of(context);
            final pageNumber = int.tryParse(searchController.text);
            if (pageNumber != null &&
                pdfViewerController.pageCount > 0 &&
                pageNumber > 0 &&
                pageNumber <= pdfViewerController.pageCount) {
              await pdfViewerController.jumpToPage(pageNumber - 1);
            }
            navigatorState.pop();
          },
          child: Text(AppLocalizations.of(context)!.go),
        ),
      ],
    );
  }
}
