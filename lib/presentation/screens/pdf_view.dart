import 'dart:async';
import 'dart:math' as math;

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/books_library_parts.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/pdf_reader_capsule.dart';
import 'package:huda/presentation/widgets/pdf/pdf_reader_panel.dart';
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

  final String? fallbackPdfUrl;

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final ValueNotifier<bool> showLeftPane = ValueNotifier<bool>(false);
  final ValueNotifier<PdfOutline?> outline = ValueNotifier<PdfOutline?>(null);
  final ValueNotifier<PdfDocument?> document = ValueNotifier<PdfDocument?>(
    null,
  );
  final ValueNotifier<HudaPdfSearchController?> textSearcher =
      ValueNotifier<HudaPdfSearchController?>(null);
  final ValueNotifier<int> _markersVersion = ValueNotifier<int>(0);

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
    _markersVersion.dispose();
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
      _markers
          .putIfAbsent(pageIndex, () => [])
          .add(
            Marker(
              color: color,
              pageIndex: pageIndex,
              text: selectedText,
              rects: rects,
            ),
          );
    }
    _pdfViewerController.clearSelection();
    _markersChanged();
  }

  void _markersChanged() {
    _markersVersion.value++;
    if (mounted) setState(() {});
  }

  void _restoreMarker(Marker marker) {
    _markers.putIfAbsent(marker.pageIndex, () => []).add(marker);
    _markersChanged();
  }

  void _onMarkerRemoved(Marker marker) {
    final l10n = AppLocalizations.of(context)!;
    showHudaToast(
      context,
      message: l10n.booksHighlightRemoved,
      actionLabel: l10n.undo,
      onAction: () => _restoreMarker(marker),
    );
  }

  bool _panelOpen = false;

  static const double _panelWidth = 360;
  static const double _inlinePanelMinWidth = 840;

  PdfReaderPanel _panel({VoidCallback? onNavigate}) => PdfReaderPanel(
    controller: _pdfViewerController,
    textSearcher: textSearcher,
    outline: outline,
    document: document,
    markers: _markers,
    markersVersion: _markersVersion,
    onMarkersChanged: _markersChanged,
    onNavigate: onNavigate,
  );

  void _togglePanel(bool inline) {
    if (inline) {
      setState(() => _panelOpen = !_panelOpen);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showHudaSheet<void>(
      context: context,
      title: l10n.booksReaderPanel,
      expand: true,
      builder: (sheetContext) => PdfReaderPanelUndo(
        onRemoved: _onMarkerRemoved,
        child: _panel(onNavigate: () => Navigator.of(sheetContext).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final inline = width >= _inlinePanelMinWidth;
    final panelShown = inline && _panelOpen && _isFullDocumentReady;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      color: colorScheme.surfaceContainerHigh,
      child: HudaImmersiveScaffold(
        title: widget.bookTitle?.isNotEmpty == true
            ? widget.bookTitle
            : l10n.pdfViewer,
        actions: [
          IconButton(
            tooltip: l10n.booksReaderPanel,
            isSelected: panelShown,
            onPressed: _isFullDocumentReady ? () => _togglePanel(inline) : null,
            icon: const Icon(Icons.toc_rounded),
          ),
          IconButton(
            tooltip: isHorizontalLayout
                ? l10n.booksScrollDown
                : l10n.booksScrollAcross,
            onPressed: _isFullDocumentReady ? _changeLayoutType : null,
            icon: Icon(
              isHorizontalLayout
                  ? Icons.swap_vert_rounded
                  : Icons.swap_horiz_rounded,
            ),
          ),
        ],
        body: Builder(
          builder: (context) {
            final insets = MediaQuery.paddingOf(context);
            final capsuleRoom = insets.bottom + space.md + 56;
            final fold = FoldInfo.of(context);
            final windowWidth = MediaQuery.sizeOf(context).width;
            final panelRoom = panelShown ? _panelWidth : 0.0;
            var capsuleLeft = (rtl ? 0.0 : panelRoom) + space.md;
            var capsuleRight = (rtl ? panelRoom : 0.0) + space.md;
            if (fold.avoided && fold.splitsHorizontally) {
              if (rtl) {
                final right = windowWidth - fold.start - insets.right;
                capsuleRight = math.max(capsuleRight, right + space.md);
              } else {
                final left = fold.end - insets.left;
                capsuleLeft = math.max(capsuleLeft, left + space.md);
              }
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(
                insets.left,
                insets.top,
                insets.right,
                0,
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeLeft: true,
                removeRight: true,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: tokens.motion.of(
                            context,
                            tokens.motion.medium,
                          ),
                          curve: tokens.motion.emphasized,
                          width: panelShown ? _panelWidth : 0,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            border: BorderDirectional(
                              end: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: panelShown
                              ? OverflowBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  minWidth: _panelWidth,
                                  maxWidth: _panelWidth,
                                  child: PdfReaderPanelUndo(
                                    onRemoved: _onMarkerRemoved,
                                    child: _panel(),
                                  ),
                                )
                              : null,
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
                          bottomClearance: capsuleRoom,
                        ),
                      ],
                    ),
                    if (_isFullDocumentReady)
                      Positioned(
                        left: capsuleLeft,
                        right: capsuleRight,
                        bottom: insets.bottom + space.md,
                        child: Center(
                          child: PdfReaderCapsule(
                            controller: _pdfViewerController,
                            selecting: _hadSelection,
                            inks: [
                              (color: _inkRed, label: l10n.booksInkRed),
                              (color: _inkGreen, label: l10n.booksInkGreen),
                              (color: _inkOrange, label: l10n.booksInkOrange),
                            ],
                            onInk: _addCurrentSelectionToMarkers,
                            onClearSelection:
                                _pdfViewerController.clearSelection,
                            onGoToPage: _goToPage,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const Color _inkRed = Colors.red;
  static const Color _inkGreen = Colors.green;
  static const Color _inkOrange = Colors.orange;

  Future<void> _goToPage() async {
    final count = _pdfViewerController.pageCount;
    if (count < 1) return;
    final page = await showBooksPageJump(
      context,
      current: _pdfViewerController.currentPage + 1,
      count: count,
    );
    if (page != null) await _pdfViewerController.jumpToPage(page - 1);
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
