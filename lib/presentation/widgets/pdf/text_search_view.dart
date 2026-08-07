import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';
import 'package:huda/presentation/widgets/pdf/search_result_tile.dart';

class TextSearchView extends StatefulWidget {
  const TextSearchView({
    required this.textSearcher,
    super.key,
  });

  final HudaPdfSearchController textSearcher;

  @override
  State<TextSearchView> createState() => _TextSearchViewState();
}

class _TextSearchViewState extends State<TextSearchView> {
  final focusNode = FocusNode();
  final searchTextController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.textSearcher.addListener(_searchResultUpdated);
    searchTextController.addListener(_searchTextUpdated);
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
    widget.textSearcher.search(searchTextController.text);
  }

  void _searchResultUpdated() {
    if (mounted) setState(() {});
  }

  static const double itemHeight = 60;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = _buildListItems();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                          widget.textSearcher.reset();
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
                  value: widget.textSearcher.progress,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
          const SizedBox(height: 8),
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
                        (widget.textSearcher.currentIndex + 1).toString(),
                        widget.textSearcher.matches.length.toString(),
                      ),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.textSearcher.currentIndex > 0
                        ? () async {
                            await widget.textSearcher.goToPreviousMatch();
                            _conditionScrollPosition();
                          }
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: widget.textSearcher.currentIndex >= 0 &&
                            widget.textSearcher.currentIndex <
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
          Expanded(
            child: ListView.builder(
              key: Key(searchTextController.text),
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.matchIndex case final matchIndex?) {
                  final match = widget.textSearcher.matches[matchIndex];
                  return SearchResultTile(
                    key: ValueKey('match-$matchIndex'),
                    match: match,
                    onTap: () async {
                      await widget.textSearcher.goToMatchOfIndex(matchIndex);
                      _conditionScrollPosition();
                    },
                    height: itemHeight,
                    isCurrent: matchIndex == widget.textSearcher.currentIndex,
                  );
                }

                return Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    AppLocalizations.of(context)!
                        .pageLabel(item.pageNumber.toString()),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_SearchListItem> _buildListItems() {
    final items = <_SearchListItem>[];
    var previousPage = -1;
    for (var index = 0; index < widget.textSearcher.matches.length; index++) {
      final match = widget.textSearcher.matches[index];
      if (match.pageIndex != previousPage) {
        previousPage = match.pageIndex;
        items.add(_SearchListItem.pageHeader(match.pageNumber));
      }
      items.add(_SearchListItem.match(index));
    }
    return items;
  }

  void _conditionScrollPosition() {
    if (!scrollController.hasClients || widget.textSearcher.currentIndex < 0) {
      return;
    }
    final items = _buildListItems();
    final itemIndex = items.indexWhere(
      (item) => item.matchIndex == widget.textSearcher.currentIndex,
    );
    if (itemIndex < 0) return;

    final pos = scrollController.position;
    final newPos = itemHeight * itemIndex;
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
  }
}

class _SearchListItem {
  const _SearchListItem._({this.matchIndex, required this.pageNumber});

  factory _SearchListItem.match(int matchIndex) =>
      _SearchListItem._(matchIndex: matchIndex, pageNumber: 0);

  factory _SearchListItem.pageHeader(int pageNumber) =>
      _SearchListItem._(pageNumber: pageNumber);

  final int? matchIndex;
  final int pageNumber;
}
