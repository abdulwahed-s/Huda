import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/pdf_loading_error_widgets.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerContent extends StatelessWidget {
  final String pdfUrl;
  final PdfViewerController pdfViewerController;
  final GlobalKey pdfViewerKey;
  final PdfPageLayoutFunction? layoutPages;
  final bool isHorizontalLayout;
  final ValueNotifier<PdfTextSearcher?> textSearcher;
  final Map<int, List<Marker>> markers;
  final bool isDark;
  final ColorScheme colorScheme;
  final ValueChanged<PdfTextSelection> onTextSelectionChange;

  const PdfViewerContent({
    super.key,
    required this.pdfUrl,
    required this.pdfViewerController,
    required this.pdfViewerKey,
    required this.layoutPages,
    required this.isHorizontalLayout,
    required this.textSearcher,
    required this.markers,
    required this.isDark,
    required this.colorScheme,
    required this.onTextSelectionChange,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDark ? Colors.black.withValues(alpha: 0.3) : Colors.transparent,
              BlendMode.darken,
            ),
            child: pdfUrl.startsWith('/')
                ? PdfViewer.file(
                    pdfUrl,
                    controller: pdfViewerController,
                    useProgressiveLoading: true,
                    key: pdfViewerKey,
                    params: _buildPdfViewerParams(),
                  )
                : PdfViewer.uri(
                    Uri.parse(pdfUrl),
                    controller: pdfViewerController,
                    useProgressiveLoading: true,
                    key: pdfViewerKey,
                    params: _buildPdfViewerParams(),
                  ),
          ),
        ),
      ),
    );
  }

  PdfViewerParams _buildPdfViewerParams() {
    return PdfViewerParams(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      layoutPages: layoutPages,
      scrollHorizontallyByMouseWheel: isHorizontalLayout,
      pageAnchor: isHorizontalLayout ? PdfPageAnchor.left : PdfPageAnchor.top,
      pageAnchorEnd:
          isHorizontalLayout ? PdfPageAnchor.right : PdfPageAnchor.bottom,
      maxScale: 8,
      minScale: 0.5,
      textSelectionParams: PdfTextSelectionParams(
        enabled: true,
        onTextSelectionChange: onTextSelectionChange, // Use the callback here
      ),
      viewerOverlayBuilder: (context, size, handleLinkTap) {
        return [
          PdfViewerScrollThumb(
            controller: pdfViewerController,
            orientation: isHorizontalLayout
                ? ScrollbarOrientation.bottom
                : ScrollbarOrientation.right,
            thumbSize: const Size(50, 30),
            thumbBuilder: (context, thumbSize, pageNumber, controller) =>
                Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  pageNumber.toString(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      pagePaintCallbacks: [
        if (textSearcher.value != null)
          textSearcher.value!.pageTextMatchPaintCallback,
        (canvas, pageRect, page) {
          final pageMarkers = markers[page.pageNumber];
          if (pageMarkers == null) return;

          for (final marker in pageMarkers) {
            final paint = Paint()
              ..color = marker.color.withAlpha(100)
              ..style = PaintingStyle.fill;

            canvas.drawRect(
              marker.range.bounds
                  .toRectInDocument(page: page, pageRect: pageRect),
              paint,
            );
          }
        },
      ],
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
        return PdfLoadingWidget(
          bytesDownloaded: bytesDownloaded,
          totalBytes: totalBytes,
          colorScheme: colorScheme,
        );
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        return PdfErrorWidget(
          error: error,
          colorScheme: colorScheme,
        );
      },
      onDocumentChanged: (document) async {
        if (document == null) {
          textSearcher.value?.dispose();
          textSearcher.value = null;
          // outline should be handled by parent
        }
      },
      onViewerReady: (document, controller) async {
        // outline and text searcher should be handled by parent
        controller.requestFocus();
      },
    );
  }
}
