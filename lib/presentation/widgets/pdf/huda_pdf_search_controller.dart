import 'dart:async';
import 'dart:math' as math;

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_document/pdf_document.dart';
import 'package:pdf_graphics/pdf_graphics.dart';

class HudaPdfSearchHit {
  HudaPdfSearchHit({
    required this.pageIndex,
    required this.start,
    required this.end,
    required List<PdfRect> rects,
    required this.before,
    required this.match,
    required this.after,
  }) : rects = List.unmodifiable(rects);

  final int pageIndex;
  final int start;
  final int end;
  final List<PdfRect> rects;
  final String before;
  final String match;
  final String after;

  int get pageNumber => pageIndex + 1;
}

class HudaPdfSearchController extends ChangeNotifier {
  HudaPdfSearchController({
    required PdfDocument document,
    required PdfViewerController viewerController,
    PdfPageText Function(PdfDocument document, int pageIndex)? extractPageText,
    this.debounceDuration = const Duration(milliseconds: 180),
  })  : _document = document,
        _viewerController = viewerController,
        _extractPageText = extractPageText ?? PdfTextExtractor.extract;

  final PdfDocument _document;
  final PdfViewerController _viewerController;
  final PdfPageText Function(PdfDocument document, int pageIndex)
      _extractPageText;
  final Duration debounceDuration;

  Timer? _debounce;
  int _searchSession = 0;
  String _query = '';
  bool _isSearching = false;
  double _progress = 0;
  List<HudaPdfSearchHit> _matches = const [];
  int _currentIndex = -1;

  int get searchSession => _searchSession;
  String get query => _query;
  bool get isSearching => _isSearching;
  double get progress => _progress;
  List<HudaPdfSearchHit> get matches => _matches;
  int get currentIndex => _currentIndex;
  bool get hasMatches => _matches.isNotEmpty;

  void search(String query) {
    _debounce?.cancel();
    final session = ++_searchSession;
    _query = query;
    _matches = const [];
    _currentIndex = -1;
    _progress = 0;
    _isSearching = query.isNotEmpty;
    notifyListeners();

    if (query.isEmpty) return;
    _debounce = Timer(debounceDuration, () => _runSearch(session, query));
  }

  void reset() => search('');

  Future<void> goToNextMatch() async {
    if (_currentIndex < 0 || _currentIndex >= _matches.length - 1) return;
    await goToMatchOfIndex(_currentIndex + 1);
  }

  Future<void> goToPreviousMatch() async {
    if (_currentIndex <= 0) return;
    await goToMatchOfIndex(_currentIndex - 1);
  }

  Future<void> goToMatchOfIndex(int index) async {
    if (index < 0 || index >= _matches.length) return;
    _currentIndex = index;
    notifyListeners();

    final hit = _matches[index];
    final bounds = _boundsOf(hit.rects);
    if (bounds == null) {
      await _viewerController.jumpToPage(hit.pageIndex);
      return;
    }
    await _viewerController.showRect(hit.pageIndex, bounds);
  }

  Future<void> _runSearch(int session, String query) async {
    final hits = <HudaPdfSearchHit>[];
    final pageCount = _document.pageCount;

    if (pageCount == 0) {
      if (_isCurrentSession(session)) {
        _isSearching = false;
        _progress = 1;
        notifyListeners();
      }
      return;
    }

    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      if (!_isCurrentSession(session)) return;

      try {
        final pageText = _extractPageText(_document, pageIndex);
        hits.addAll(_hitsFromPage(pageText, query));
      } on Object catch (error) {
        debugPrint(
            'Could not extract PDF text from page ${pageIndex + 1}: $error');
      }

      if (!_isCurrentSession(session)) return;
      _matches = List.unmodifiable(hits);
      _progress = (pageIndex + 1) / pageCount;
      if (_currentIndex < 0 && hits.isNotEmpty) _currentIndex = 0;
      notifyListeners();

      await Future<void>.delayed(Duration.zero);
    }

    if (!_isCurrentSession(session)) return;
    _isSearching = false;
    _progress = 1;
    notifyListeners();
    if (_currentIndex >= 0) await goToMatchOfIndex(_currentIndex);
  }

  bool _isCurrentSession(int session) => session == _searchSession;

  Iterable<HudaPdfSearchHit> _hitsFromPage(PdfPageText pageText, String query) {
    return pageText.findAll(query).map(
          (match) => _hitFromMatch(pageText, match),
        );
  }

  HudaPdfSearchHit _hitFromMatch(PdfPageText pageText, PdfTextMatch match) {
    final text = pageText.text;
    final first = text.lastIndexOf('\n', math.max(0, match.start - 1)) + 1;
    final newlineAfter = text.indexOf('\n', match.end);
    final last = newlineAfter < 0 ? text.length : newlineAfter;

    return HudaPdfSearchHit(
      pageIndex: match.pageIndex,
      start: match.start,
      end: match.end,
      rects: match.rects,
      before: text.substring(first, match.start),
      match: text.substring(match.start, match.end),
      after: text.substring(match.end, last),
    );
  }

  PdfRect? _boundsOf(List<PdfRect> rects) {
    if (rects.isEmpty) return null;
    var left = rects.first.left;
    var bottom = rects.first.bottom;
    var right = rects.first.right;
    var top = rects.first.top;
    for (final rect in rects.skip(1)) {
      left = math.min(left, rect.left);
      bottom = math.min(bottom, rect.bottom);
      right = math.max(right, rect.right);
      top = math.max(top, rect.top);
    }
    return PdfRect(left, bottom, right, top);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    ++_searchSession;
    super.dispose();
  }
}
