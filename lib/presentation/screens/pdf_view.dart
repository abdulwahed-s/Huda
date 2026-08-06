import 'dart:async';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/pdf_app_bar.dart';
import 'package:huda/presentation/widgets/pdf/pdf_dialogs.dart';
import 'package:huda/presentation/widgets/pdf/pdf_floating_buttons.dart';
import 'package:huda/presentation/widgets/pdf/pdf_sidebar.dart';
import 'package:huda/presentation/widgets/pdf/pdf_viewer_content.dart';
import 'package:pdf_document/pdf_document.dart';

class PdfView extends StatefulWidget {
  const PdfView({
    super.key,
    required this.pdfUrl,
    this.bookId,
    this.bookTitle,
    this.language,
    this.fallbackPdfUrl,
  });

  final String pdfUrl;
  final int? bookId;
  final String? bookTitle;
  final String? language;

  /// Remote copy retained when [pdfUrl] is a downloaded local file.
  final String? fallbackPdfUrl;

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> with TickerProviderStateMixin {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final ValueNotifier<bool> showLeftPane = ValueNotifier<bool>(false);
  final ValueNotifier<PdfOutline?> outline = ValueNotifier<PdfOutline?>(null);
  final ValueNotifier<PdfDocument?> document =
      ValueNotifier<PdfDocument?>(null);
  final ValueNotifier<HudaPdfSearchController?> textSearcher =
      ValueNotifier<HudaPdfSearchController?>(null);
  final TextEditingController _goToPageController = TextEditingController();

  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  final Map<int, List<Marker>> _markers = {};
  Timer? _progressDebounce;
  _PendingBookProgress? _pendingProgress;
  PdfDocument? _pendingReadyDocument;
  PdfDocument? _initializedDocument;
  bool _readyForSaving = false;
  bool _isFullDocumentReady = false;
  bool _hadSelection = false;
  late final AppLifecycleListener _progressLifecycle;

  int _layoutTypeIndex = 0;
  bool get isHorizontalLayout => _layoutTypeIndex == 1;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _pdfViewerController.addListener(_handleViewerControllerChanged);
    _pdfViewerController.viewportChanges.addListener(_handleViewportChanged);
    _progressLifecycle = AppLifecycleListener(
      onHide: _flushReadingProgress,
      onPause: _flushReadingProgress,
      onDetach: _flushReadingProgress,
    );
  }

  @override
  void didUpdateWidget(covariant PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfUrl != widget.pdfUrl) _resetDocumentState();
  }

  @override
  void dispose() {
    _flushReadingProgress();
    _progressLifecycle.dispose();
    _pdfViewerController.viewportChanges.removeListener(_handleViewportChanged);
    _pdfViewerController.removeListener(_handleViewerControllerChanged);
    _pdfViewerController.dispose();
    textSearcher.value?.dispose();
    textSearcher.dispose();
    outline.dispose();
    document.dispose();
    showLeftPane.dispose();
    _goToPageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _resetDocumentState() {
    _flushReadingProgress();
    _readyForSaving = false;
    _isFullDocumentReady = false;
    _hadSelection = false;
    _pendingReadyDocument = null;
    _initializedDocument = null;
    _markers.clear();
    _fabAnimationController.reverse();

    final previousSearch = textSearcher.value;
    textSearcher.value = null;
    previousSearch?.dispose();
    outline.value = null;
    document.value = null;
  }

  void _handleViewerControllerChanged() {
    _tryInitializeReader();
    _handleSelectionChanged();
  }

  void _handleSelectionChanged() {
    final hasSelection = _pdfViewerController.hasSelection;
    if (hasSelection == _hadSelection) return;
    _hadSelection = hasSelection;
    if (hasSelection) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
    if (mounted) setState(() {});
  }

  void _handleFullDocumentReady(PdfDocument value) {
    if (identical(document.value, value)) return;

    _readyForSaving = false;
    _pendingReadyDocument = value;
    _initializedDocument = null;
    _isFullDocumentReady = true;
    document.value = value;
    outline.value = PdfOutline.of(value);

    final previousSearch = textSearcher.value;
    textSearcher.value = HudaPdfSearchController(
      document: value,
      viewerController: _pdfViewerController,
    );
    previousSearch?.dispose();

    _tryInitializeReader();
    if (mounted) setState(() {});
  }

  void _tryInitializeReader() {
    final pendingDocument = _pendingReadyDocument;
    if (pendingDocument == null || _pdfViewerController.pageCount == 0) {
      return;
    }
    if (identical(_initializedDocument, pendingDocument)) return;

    _initializedDocument = pendingDocument;
    _pendingReadyDocument = null;
    _readyForSaving = false;
    unawaited(
      _restoreReadingPosition().whenComplete(() {
        if (mounted && identical(_initializedDocument, pendingDocument)) {
          _readyForSaving = true;
          _captureReadingProgress();
        }
      }),
    );
  }

  Future<void> _restoreReadingPosition() async {
    if (widget.bookId == null) {
      return;
    }

    final progress = getIt<BookProgressService>().getProgress(widget.bookId!);
    final viewport = progress?.viewport;
    if (viewport != null &&
        viewport.pageIndex < _pdfViewerController.pageCount) {
      _pdfViewerController.restoreViewport(
        PdfViewport(
          page: viewport.pageIndex,
          top: viewport.top.clamp(0.0, 1.0).toDouble(),
          left: viewport.left.clamp(0.0, 1.0).toDouble(),
          zoom: viewport.zoom > 0 && viewport.zoom.isFinite ? viewport.zoom : 1,
        ),
      );
    } else {
      final savedPage = progress?.pageNumber;
      if (savedPage != null &&
          savedPage > 1 &&
          savedPage <= _pdfViewerController.pageCount) {
        await _pdfViewerController.jumpToPage(savedPage - 1);
      }
    }

    // `restoreViewport` can intentionally wait for the viewer's next layout.
    // Keep persistence disabled until that queued restore has had a frame to
    // land, otherwise the initial page can overwrite saved progress.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
  }

  void _handleViewportChanged() {
    _captureReadingProgress();
  }

  void _captureReadingProgress() {
    if (!_readyForSaving || widget.bookId == null) return;
    final viewport = _pdfViewerController.captureViewport();
    if (viewport == null) return;

    _pendingProgress = _PendingBookProgress(
      pageNumber: viewport.page + 1,
      totalPages: _pdfViewerController.pageCount,
      viewport: BookReadingViewport(
        pageIndex: viewport.page,
        top: viewport.top,
        left: viewport.left,
        zoom: viewport.zoom,
      ),
    );
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(seconds: 2), () {
      _progressDebounce = null;
      _flushReadingProgress(captureCurrentViewport: false);
    });
  }

  void _flushReadingProgress({bool captureCurrentViewport = true}) {
    if (captureCurrentViewport) _captureCurrentViewportForFlush();
    _progressDebounce?.cancel();
    _progressDebounce = null;

    final pending = _pendingProgress;
    _pendingProgress = null;
    final bookId = widget.bookId;
    if (pending == null || bookId == null) return;

    unawaited(
      getIt<BookProgressService>().savePosition(
        bookId,
        pending.pageNumber,
        totalPages: pending.totalPages,
        title: widget.bookTitle,
        attachmentUrl: _progressAttachmentUrl,
        language: widget.language,
        viewport: pending.viewport,
      ),
    );
  }

  void _captureCurrentViewportForFlush() {
    if (!_readyForSaving || widget.bookId == null) return;
    final viewport = _pdfViewerController.captureViewport();
    if (viewport == null) return;
    _pendingProgress = _PendingBookProgress(
      pageNumber: viewport.page + 1,
      totalPages: _pdfViewerController.pageCount,
      viewport: BookReadingViewport(
        pageIndex: viewport.page,
        top: viewport.top,
        left: viewport.left,
        zoom: viewport.zoom,
      ),
    );
  }

  String? get _progressAttachmentUrl =>
      _httpUrl(widget.fallbackPdfUrl) ?? _httpUrl(widget.pdfUrl);

  String? _httpUrl(String? value) {
    final candidate = value?.trim();
    if (candidate == null || candidate.isEmpty) return null;
    final uri = Uri.tryParse(candidate);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? candidate
        : null;
  }

  void _changeLayoutType() {
    setState(() {
      _layoutTypeIndex = (_layoutTypeIndex + 1) % 2;
    });
  }

  void _addCurrentSelectionToMarkers(Color color) {
    if (!_pdfViewerController.hasSelection) return;
    final selectedText = _pdfViewerController.selectedText;
    for (final pageIndex in _pdfViewerController.selectionPages) {
      final rects = _pdfViewerController.selectionRectsOn(pageIndex);
      if (rects.isEmpty) continue;
      _markers.putIfAbsent(pageIndex, () => []).add(
            Marker(
              color: color,
              pageIndex: pageIndex,
              text: selectedText,
              rects: rects,
            ),
          );
    }
    _pdfViewerController.clearSelection();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: PdfAppBar(
        isDark: isDark,
        colorScheme: colorScheme,
        showLeftPane: showLeftPane,
        isHorizontalLayout: isHorizontalLayout,
        isDocumentReady: _isFullDocumentReady,
        changeLayoutType: _changeLayoutType,
        showGoToPageDialog: _showGoToPageDialog,
        pdfViewerController: _pdfViewerController,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: showLeftPane,
                builder: (context, showPane, child) => PdfSidebar(
                  isDark: isDark,
                  colorScheme: colorScheme,
                  showLeftPane: showLeftPane,
                  textSearcher: textSearcher,
                  outline: outline,
                  document: document,
                  markers: _markers,
                  pdfViewerController: _pdfViewerController,
                  onMarkersChanged: () => setState(() {}),
                ),
              ),
              PdfViewerContent(
                pdfUrl: widget.pdfUrl,
                pdfViewerController: _pdfViewerController,
                isHorizontalLayout: isHorizontalLayout,
                textSearcher: textSearcher,
                markers: _markers,
                isDark: isDark,
                colorScheme: colorScheme,
                onFullDocumentReady: _handleFullDocumentReady,
              ),
            ],
          ),
          if (_isFullDocumentReady)
            PdfFloatingButtons(
              fabAnimation: _fabAnimation,
              addRedMarker: () => _addCurrentSelectionToMarkers(Colors.red),
              addGreenMarker: () => _addCurrentSelectionToMarkers(Colors.green),
              addOrangeMarker: () =>
                  _addCurrentSelectionToMarkers(Colors.orange),
              pdfViewerController: _pdfViewerController,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }

  void _showGoToPageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => PdfGoToPageDialog(
        pdfViewerController: _pdfViewerController,
        searchController: _goToPageController,
      ),
    );
  }
}

class _PendingBookProgress {
  const _PendingBookProgress({
    required this.pageNumber,
    required this.totalPages,
    required this.viewport,
  });

  final int pageNumber;
  final int totalPages;
  final BookReadingViewport viewport;
}
