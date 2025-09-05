import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/pdf/pdf_page_text_cache.dart';
import 'package:huda/presentation/widgets/pdf/search_result_tile.dart';
import 'package:pdfrx/pdfrx.dart';

class TextSearchView extends StatefulWidget {
  const TextSearchView({
    required this.textSearcher,
    super.key,
  });

  final PdfTextSearcher textSearcher;

  @override
  State<TextSearchView> createState() => _TextSearchViewState();
}

class _TextSearchViewState extends State<TextSearchView> {
  final focusNode = FocusNode();
  final searchTextController = TextEditingController();
  late final pageTextStore =
      PdfPageTextCache(textSearcher: widget.textSearcher);
  final scrollController = ScrollController();

  @override
  void initState() {
    widget.textSearcher.addListener(_searchResultUpdated);
    searchTextController.addListener(_searchTextUpdated);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    widget.textSearcher.removeListener(_searchResultUpdated);
    searchTextController.removeListener(_searchTextUpdated);
    searchTextController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _searchTextUpdated() {
    widget.textSearcher.startTextSearch(searchTextController.text);
  }

  int? _currentSearchSession;
  final _matchIndexToListIndex = <int>[];
  final _listIndexToMatchIndex = <int>[];

  void _searchResultUpdated() {
    if (_currentSearchSession != widget.textSearcher.searchSession) {
      _currentSearchSession = widget.textSearcher.searchSession;
      _matchIndexToListIndex.clear();
      _listIndexToMatchIndex.clear();
    }
    for (int i = _matchIndexToListIndex.length;
        i < widget.textSearcher.matches.length;
        i++) {
      if (i == 0 ||
          widget.textSearcher.matches[i - 1].pageNumber !=
              widget.textSearcher.matches[i].pageNumber) {
        _listIndexToMatchIndex.add(-widget.textSearcher.matches[i].pageNumber);
      }
      _matchIndexToListIndex.add(_listIndexToMatchIndex.length);
      _listIndexToMatchIndex.add(i);
    }

    if (mounted) setState(() {});
  }

  static const double itemHeight = 60;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Modern search field
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: TextField(
              focusNode: focusNode,
              controller: searchTextController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchInDocument,
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: searchTextController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchTextController.clear();
                          widget.textSearcher.resetTextSearch();
                          focusNode.requestFocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          const SizedBox(height: 12),

          // Search progress
          if (widget.textSearcher.isSearching)
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: widget.textSearcher.searchProgress,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          const SizedBox(height: 8),

          // Search controls
          if (widget.textSearcher.hasMatches) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.matchesCount(
                          (widget.textSearcher.currentIndex! + 1).toString(),
                          widget.textSearcher.matches.length.toString()),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: (widget.textSearcher.currentIndex ?? 0) > 0
                        ? () async {
                            await widget.textSearcher.goToPrevMatch();
                            _conditionScrollPosition();
                          }
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: (widget.textSearcher.currentIndex ?? 0) <
                            widget.textSearcher.matches.length - 1
                        ? () async {
                            await widget.textSearcher.goToNextMatch();
                            _conditionScrollPosition();
                          }
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search results
          Expanded(
            child: ListView.builder(
              key: Key(searchTextController.text),
              controller: scrollController,
              itemCount: _listIndexToMatchIndex.length,
              itemBuilder: (context, index) {
                final matchIndex = _listIndexToMatchIndex[index];
                if (matchIndex >= 0 &&
                    matchIndex < widget.textSearcher.matches.length) {
                  final match = widget.textSearcher.matches[matchIndex];
                  return SearchResultTile(
                    key: ValueKey(index),
                    match: match,
                    onTap: () async {
                      await widget.textSearcher.goToMatchOfIndex(matchIndex);
                      if (mounted) setState(() {});
                    },
                    pageTextStore: pageTextStore,
                    height: itemHeight,
                    isCurrent: matchIndex == widget.textSearcher.currentIndex,
                  );
                } else {
                  return Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      AppLocalizations.of(context)!
                          .pageLabel((-matchIndex).toString()),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _conditionScrollPosition() {
    final pos = scrollController.position;
    final newPos =
        itemHeight * _matchIndexToListIndex[widget.textSearcher.currentIndex!];
    if (newPos + itemHeight > pos.pixels + pos.viewportDimension) {
      scrollController.animateTo(
        newPos + itemHeight - pos.viewportDimension,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    } else if (newPos < pos.pixels) {
      scrollController.animateTo(
        newPos,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }

    if (mounted) setState(() {});
  }
}

