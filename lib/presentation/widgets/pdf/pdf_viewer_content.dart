import 'dart:async';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/pdf_loading_error_widgets.dart';
import 'package:huda/presentation/widgets/pdf/pdf_page_scrubber.dart';
import 'package:huda/presentation/widgets/pdf/pdf_preview_caching_byte_source.dart';
import 'package:huda/presentation/widgets/pdf/pdf_source_resolver.dart';
import 'package:pdf_document/pdf_document.dart';

class PdfViewerContent extends StatefulWidget {
  const PdfViewerContent({
    super.key,
    required this.pdfUrl,
    required this.pdfViewerController,
    required this.isHorizontalLayout,
    required this.textSearcher,
    required this.markers,
    required this.isDark,
    required this.colorScheme,
    required this.onFullDocumentReady,
  });

  final String pdfUrl;
  final PdfViewerController pdfViewerController;
  final bool isHorizontalLayout;
  final ValueNotifier<HudaPdfSearchController?> textSearcher;
  final Map<int, List<Marker>> markers;
  final bool isDark;
  final ColorScheme colorScheme;
  final ValueChanged<PdfDocument> onFullDocumentReady;

  @override
  State<PdfViewerContent> createState() => _PdfViewerContentState();
}

class _PdfViewerContentState extends State<PdfViewerContent> {
  PdfByteSource? _source;
  PdfDocument? _previewDocument;
  PdfDocument? _fullDocument;
  PdfDocument? _reportedFullDocument;
  Object? _loadError;
  int _bytesDownloaded = 0;
  int? _totalBytes;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _openSource();
  }

  @override
  void didUpdateWidget(covariant PdfViewerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfUrl != widget.pdfUrl) {
      _closeSource();
      _previewDocument = null;
      _fullDocument = null;
      _reportedFullDocument = null;
      _loadError = null;
      _bytesDownloaded = 0;
      _totalBytes = null;
      _openSource();
    }
  }

  @override
  void dispose() {
    _closeSource();
    super.dispose();
  }

  void _openSource() {
    final generation = ++_loadGeneration;
    try {
      final rawSource = createPdfByteSource(widget.pdfUrl);
      final source = _isRemoteLocation(widget.pdfUrl)
          ? PdfPreviewCachingByteSource(rawSource)
          : rawSource;
      _source = source;
      unawaited(_loadDocument(source, generation));
    } on Object catch (error) {
      _loadError = error;
    }
  }

  void _closeSource() {
    ++_loadGeneration;
    final source = _source;
    _source = null;
    if (source != null) unawaited(source.close());
  }

  bool _isCurrentLoad(int generation, PdfByteSource source) =>
      mounted && generation == _loadGeneration && identical(source, _source);

  Future<void> _loadDocument(PdfByteSource source, int generation) async {
    if (_isRemoteLocation(widget.pdfUrl)) {
      try {
        final preview = await PdfDocument.openSource(
          source,
          options: PdfSourceLoadOptions(
            firstPaintPages: 1,
            onProgress: (fetched, total) =>
                _reportLoadProgress(source, generation, fetched, total),
          ),
        );
        if (!_isCurrentLoad(generation, source)) return;
        setState(() => _previewDocument = preview);
      } on Object {
        // 
      }
    }

    if (source case PdfPreviewCachingByteSource()) {
      source.finishPreview();
    }

    try {
      final document = await PdfDocument.openSource(
        source,
        options: PdfSourceLoadOptions(
          onProgress: (fetched, total) =>
              _reportLoadProgress(source, generation, fetched, total),
        ),
      );
      if (!_isCurrentLoad(generation, source)) return;
      setState(() {
        _fullDocument = document;
        _previewDocument = null;
        _loadError = null;
        if (_totalBytes != null) _bytesDownloaded = _totalBytes!;
      });
      if (source case PdfPreviewCachingByteSource()) {
        source.clearPreviewCache();
      }
      _reportFullDocument(document);
    } on Object catch (error) {
      if (!_isCurrentLoad(generation, source)) return;
      setState(() => _loadError = error);
    }
  }

  void _reportLoadProgress(
    PdfByteSource source,
    int generation,
    int downloaded,
    int? total,
  ) {
    if (!_isCurrentLoad(generation, source)) return;
    final displayedDownloaded =
        total == _totalBytes && downloaded < _bytesDownloaded
            ? _bytesDownloaded
            : downloaded;
    if (displayedDownloaded == _bytesDownloaded && total == _totalBytes) {
      return;
    }
    setState(() {
      _bytesDownloaded = displayedDownloaded;
      _totalBytes = total;
    });
  }

  bool _isRemoteLocation(String location) {
    final uri = Uri.tryParse(location);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

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
              widget.isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.transparent,
              BlendMode.darken,
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final document = _fullDocument ?? _previewDocument;
    if (document == null) {
      if (_loadError case final error?) {
        return PdfErrorWidget(error: error, colorScheme: widget.colorScheme);
      }
      return PdfLoadingWidget(
        bytesDownloaded: _bytesDownloaded,
        totalBytes: _totalBytes,
        colorScheme: widget.colorScheme,
      );
    }

    return ValueListenableBuilder<HudaPdfSearchController?>(
      valueListenable: widget.textSearcher,
      builder: (context, search, child) {
        if (search == null) return _buildDocumentViewer(document, null);
        return AnimatedBuilder(
          animation: search,
          builder: (context, child) => _buildDocumentViewer(document, search),
        );
      },
    );
  }

  Widget _buildDocumentViewer(
    PdfDocument document,
    HudaPdfSearchController? search,
  ) {
    final isComplete = identical(document, _fullDocument);
    final loadError = _loadError;
    return Stack(
      children: [
        PdfViewer(
          key: ValueKey('pdf-viewer-${widget.pdfUrl}'),
          document: document,
          controller: widget.pdfViewerController,
          documentId: widget.pdfUrl,
          pageLayout: widget.isHorizontalLayout
              ? const PdfPageLayout.horizontalContinuous()
              : const PdfPageLayout.verticalContinuous(),
          initialFit: PdfViewerFit.page,
          minZoom: 0.5,
          maxZoom: 8,
          pageSpacing: 12,
          backgroundColor:
              widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          pageOverlayBuilder: (context, pageIndex, geometry) =>
              _buildPageOverlays(pageIndex, geometry, search),
          scrollIndicatorBuilder: (context, controller, metrics) =>
              PdfPageScrubber(
            key: const ValueKey('pdf-page-scrubber'),
            controller: controller,
            metrics: metrics,
            colorScheme: widget.colorScheme,
          ),
        ),
        if (!isComplete && loadError == null)
          Positioned.fill(
            child: PdfPreparingDocumentOverlay(
              bytesDownloaded: _bytesDownloaded,
              totalBytes: _totalBytes,
              colorScheme: widget.colorScheme,
            ),
          ),
        if (!isComplete && loadError != null)
          Positioned.fill(
            child: AbsorbPointer(
              child: PdfErrorWidget(
                error: loadError,
                colorScheme: widget.colorScheme,
              ),
            ),
          ),
      ],
    );
  }

  void _reportFullDocument(PdfDocument document) {
    if (identical(_reportedFullDocument, document)) return;
    _reportedFullDocument = document;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_reportedFullDocument, document)) {
        widget.onFullDocumentReady(document);
      }
    });
  }

  List<Widget> _buildPageOverlays(
    int pageIndex,
    PdfPageGeometry geometry,
    HudaPdfSearchController? search,
  ) {
    final overlays = <Widget>[];

    if (search != null) {
      for (var index = 0; index < search.matches.length; index++) {
        final match = search.matches[index];
        if (match.pageIndex != pageIndex) continue;
        final color = widget.colorScheme.primary.withValues(
          alpha: index == search.currentIndex ? 0.38 : 0.22,
        );
        for (final rect in match.rects) {
          overlays.add(_overlayForRect(geometry, rect, color));
        }
      }
    }

    for (final marker in widget.markers[pageIndex] ?? const <Marker>[]) {
      for (final rect in marker.rects) {
        overlays.add(
          _overlayForRect(
            geometry,
            rect,
            marker.color.withValues(alpha: 0.4),
          ),
        );
      }
    }

    return overlays;
  }

  Widget _overlayForRect(PdfPageGeometry geometry, PdfRect rect, Color color) {
    return Positioned.fromRect(
      rect: geometry.toViewRect(rect),
      child: IgnorePointer(child: ColoredBox(color: color)),
    );
  }
}
