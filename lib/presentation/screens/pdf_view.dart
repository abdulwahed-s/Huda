import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/pdf_dialogs.dart';
import 'package:huda/presentation/widgets/pdf/pdf_floating_buttons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:huda/presentation/widgets/pdf/pdf_app_bar.dart';
import 'package:huda/presentation/widgets/pdf/pdf_sidebar.dart';
import 'package:huda/presentation/widgets/pdf/pdf_viewer_content.dart';

class PdfView extends StatefulWidget {
  final String pdfUrl;
  final int? bookId;
  final String? bookTitle;
  final String? language;

  const PdfView({
    super.key,
    required this.pdfUrl,
    this.bookId,
    this.bookTitle,
    this.language,
  });

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> with TickerProviderStateMixin {
  final GlobalKey _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final ValueNotifier<bool> showLeftPane = ValueNotifier<bool>(false);
  final ValueNotifier<List<PdfOutlineNode>?> outline = ValueNotifier(null);
  final ValueNotifier<PdfDocumentRef?> documentRef = ValueNotifier(null);
  final ValueNotifier<PdfTextSearcher?> textSearcher = ValueNotifier(null);
  TextEditingController searchController = TextEditingController();

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final Map<int, List<Marker>> _markers = {};
  List<PdfPageTextRange>? textSelections;
  int _lastSavedPage = 0;
  bool _readyForSaving = false;
  Timer? _progressDebounce;

  int _layoutTypeIndex = 0;
  bool get isHorizontalLayout => _layoutTypeIndex == 1;

  final List<PdfPageLayoutFunction?> _layoutPages = [
    null,
    (pages, params) {
      final height = pages.fold(0.0, (prev, page) => max(prev, page.height)) +
          params.margin * 2;
      final pageLayouts = <Rect>[];
      double x = params.margin;
      for (var page in pages) {
        pageLayouts.add(
          Rect.fromLTWH(
            x,
            (height - page.height) / 2,
            page.width,
            page.height,
          ),
        );
        x += page.width + params.margin;
      }
      return PdfPageLayout(
        pageLayouts: pageLayouts,
        documentSize: Size(x, height),
      );
    },
  ];

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
    _loadDocument();
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      final uri = Uri.tryParse(widget.pdfUrl);
      final docRef = uri != null && uri.isAbsolute
          ? PdfDocumentRefUri(uri)
          : PdfDocumentRefFile(widget.pdfUrl);

      documentRef.value = docRef;

      final document =
          await docRef.loadDocument((downloadedBytes, [totalBytes]) {});

      outline.value = await document.loadOutline();

      textSearcher.value = PdfTextSearcher(_pdfViewerController)
        ..addListener(_update);
    } catch (e) {
      debugPrint(widget.pdfUrl);
      debugPrint('Error loading document: $e');
    }
  }

  void _handlePageChanged(int? page) {
    if (!_readyForSaving) return;
    if (page == null || page == _lastSavedPage) return;
    _lastSavedPage = page;
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(seconds: 2), () {
      if (widget.bookId != null && mounted) {
        getIt<BookProgressService>().savePosition(
          widget.bookId!,
          page,
          totalPages: _pdfViewerController.pageCount,
          title: widget.bookTitle,
          language: widget.language,
        );
      }
    });
  }

  void _onViewerReady() {
    _readyForSaving = true;
    final currentPage = _pdfViewerController.pageNumber ?? 1;
    if (widget.bookId == null) {
      _lastSavedPage = currentPage;
      return;
    }
    final progress =
        getIt<BookProgressService>().getProgress(widget.bookId!);
    if (progress != null && progress.pageNumber > 1 &&
        progress.pageNumber != currentPage) {
      _pdfViewerController.goToPage(pageNumber: progress.pageNumber);
      _lastSavedPage = progress.pageNumber;
    } else {
      _lastSavedPage = currentPage;
    }
  }

  void _update() {
    if (mounted) setState(() {});
  }

  void _changeLayoutType() {
    setState(() {
      _layoutTypeIndex = (_layoutTypeIndex + 1) % _layoutPages.length;
    });
  }

  void _addCurrentSelectionToMarkers(Color color) {
    if (_pdfViewerController.isReady && textSelections != null) {
      for (final selectedText in textSelections!) {
        _markers
            .putIfAbsent(selectedText.pageNumber, () => [])
            .add(Marker(color, selectedText));
      }
      setState(() {});
    }
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
        changeLayoutType: _changeLayoutType,
        showGoToPageDialog: showGoToPageDialog,
        pdfViewerController: _pdfViewerController,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: showLeftPane,
                builder: (context, showPane, child) {
                  return PdfSidebar(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    showLeftPane: showLeftPane,
                    textSearcher: textSearcher,
                    outline: outline,
                    documentRef: documentRef,
                    markers: _markers,
                    pdfViewerController: _pdfViewerController,
                  );
                },
              ),
              PdfViewerContent(
                pdfUrl: widget.pdfUrl,
                pdfViewerController: _pdfViewerController,
                pdfViewerKey: _pdfViewerKey,
                layoutPages: _layoutPages[_layoutTypeIndex],
                isHorizontalLayout: isHorizontalLayout,
                textSearcher: textSearcher,
                markers: _markers,
                isDark: isDark,
                colorScheme: colorScheme,
                onTextSelectionChange: _handleTextSelectionChange,
                onViewerReady: _onViewerReady,
                onPageChanged: _handlePageChanged,
              ),
            ],
          ),
          PdfFloatingButtons(
            fabAnimation: _fabAnimation,
            addRedMarker: () => _addCurrentSelectionToMarkers(Colors.red),
            addGreenMarker: () => _addCurrentSelectionToMarkers(Colors.green),
            addOrangeMarker: () => _addCurrentSelectionToMarkers(Colors.orange),
            pdfViewerController: _pdfViewerController,
            colorScheme: colorScheme,
            isHorizontalLayout: isHorizontalLayout,
          ),
        ],
      ),
    );
  }

  void showGoToPageDialog() {
    showDialog(
      context: context,
      builder: (context) => PdfGoToPageDialog(
        pdfViewerController: _pdfViewerController,
        searchController: searchController,
        isHorizontalLayout: isHorizontalLayout,
      ),
    );
  }

  void _handleTextSelectionChange(PdfTextSelection textSelection) async {
    if (textSelection.hasSelectedText) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
    setState(() {});
    textSelections = await textSelection.getSelectedTextRanges();
  }
}
