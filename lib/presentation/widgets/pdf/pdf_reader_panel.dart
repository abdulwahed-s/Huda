import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:pdf_document/pdf_document.dart';

class PdfReaderPanel extends StatelessWidget {
  const PdfReaderPanel({
    super.key,
    required this.controller,
    required this.textSearcher,
    required this.outline,
    required this.document,
    required this.markers,
    required this.markersVersion,
    required this.onMarkersChanged,
    this.onNavigate,
    this.initialTab,
  });

  final PdfViewerController controller;
  final ValueNotifier<HudaPdfSearchController?> textSearcher;
  final ValueNotifier<PdfOutline?> outline;
  final ValueNotifier<PdfDocument?> document;
  final Map<int, List<Marker>> markers;

  final Listenable markersVersion;
  final VoidCallback onMarkersChanged;

  final VoidCallback? onNavigate;
  final int? initialTab;

  static const int contentsTab = 0;
  static const int searchTab = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasOutline = (outline.value?.items.isNotEmpty ?? false);
    void navigated() => onNavigate?.call();
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab ?? (hasOutline ? contentsTab : searchTab),
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.contents),
              Tab(text: l10n.search),
              Tab(text: l10n.pages),
              Tab(text: l10n.booksHighlights),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ValueListenableBuilder<PdfOutline?>(
                  valueListenable: outline,
                  builder: (context, value, _) => _Contents(
                    outline: value,
                    onTap: (destination) {
                      controller.showDestination(destination);
                      navigated();
                    },
                  ),
                ),
                ValueListenableBuilder<HudaPdfSearchController?>(
                  valueListenable: textSearcher,
                  builder: (context, search, _) => search == null
                      ? const Center(child: _Spinner())
                      : _Search(
                          key: ValueKey(search),
                          search: search,
                          onShow: navigated,
                        ),
                ),
                ValueListenableBuilder<PdfDocument?>(
                  valueListenable: document,
                  builder: (context, value, _) => value == null
                      ? const Center(child: _Spinner())
                      : _Pages(
                          document: value,
                          controller: controller,
                          onTap: (index) {
                            controller.jumpToPage(index);
                            navigated();
                          },
                        ),
                ),
                ListenableBuilder(
                  listenable: markersVersion,
                  builder: (context, _) => _Highlights(
                    markers: markers,
                    onChanged: onMarkersChanged,
                    onTap: (marker) async {
                      final bounds = marker.bounds;
                      if (bounds == null) return;
                      navigated();
                      await controller.showRect(marker.pageIndex, bounds);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      HudaLampSpinner(size: 28, color: context.tokens.gilt);
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, this.hint});

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final hint = this.hint;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: space.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            if (hint != null) ...[
              SizedBox(height: space.xs),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({required this.outline, required this.onTap});

  final PdfOutline? outline;
  final ValueChanged<PdfDestination> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final entries = [..._flatten(outline?.items ?? const [], 0)];
    if (entries.isEmpty) {
      return _Empty(
        icon: Icons.toc_rounded,
        title: l10n.noTableOfContents,
        hint: l10n.booksContentsHint,
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: space.xs),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final (node, level) = entries[i];
        final destination = node.destination;
        return InkWell(
          onTap: destination == null ? null : () => onTap(destination),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.md + level * space.md,
                space.sm,
                space.md,
                space.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  node.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: level == 0
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Iterable<(PdfOutlineItem, int)> _flatten(
    List<PdfOutlineItem> items,
    int level,
  ) sync* {
    for (final item in items) {
      yield (item, level);
      yield* _flatten(item.children, level + 1);
    }
  }
}

class _Search extends StatefulWidget {
  const _Search({super.key, required this.search, required this.onShow});

  final HudaPdfSearchController search;
  final VoidCallback onShow;

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  final _field = TextEditingController();
  final _scroll = ScrollController();
  static const double _itemHeight = 64;

  @override
  void initState() {
    super.initState();
    widget.search.addListener(_changed);
  }

  @override
  void dispose() {
    widget.search.removeListener(_changed);
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _keepCurrentInView() {
    final index = widget.search.currentIndex;
    if (!_scroll.hasClients || index < 0) return;
    final position = _scroll.position;
    final top = _itemHeight * index;
    if (top + _itemHeight > position.pixels + position.viewportDimension) {
      _scroll.jumpTo(top + _itemHeight - position.viewportDimension);
    } else if (top < position.pixels) {
      _scroll.jumpTo(top);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final search = widget.search;
    final matches = search.matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(space.md, space.md, space.md, space.sm),
          child: HudaSearchField(
            controller: _field,
            hintText: l10n.searchInDocument,
            onChanged: (value) {
              if (value.trim().isEmpty) {
                search.reset();
              } else {
                search.search(value);
              }
            },
          ),
        ),
        SizedBox(
          height: 3,
          child: search.isSearching
              ? LinearProgressIndicator(value: search.progress)
              : null,
        ),
        if (search.hasMatches)
          Padding(
            padding: EdgeInsetsDirectional.only(start: space.md, end: space.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.matchesCount(
                      (search.currentIndex + 1).toString(),
                      matches.length.toString(),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.previous,
                  onPressed: search.currentIndex > 0
                      ? () async {
                          await search.goToPreviousMatch();
                          _keepCurrentInView();
                        }
                      : null,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  tooltip: l10n.next,
                  onPressed:
                      search.currentIndex >= 0 &&
                          search.currentIndex < matches.length - 1
                      ? () async {
                          await search.goToNextMatch();
                          _keepCurrentInView();
                        }
                      : null,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ),
        Expanded(
          child:
              _field.text.trim().isNotEmpty &&
                  !search.isSearching &&
                  !search.hasMatches
              ? _Empty(
                  icon: Icons.search_off_rounded,
                  title: l10n.booksNoMatches,
                )
              : ListView.builder(
                  controller: _scroll,
                  itemExtent: _itemHeight,
                  itemCount: matches.length,
                  itemBuilder: (context, i) {
                    final match = matches[i];
                    final current = i == search.currentIndex;
                    final style = theme.textTheme.bodySmall!;
                    return Material(
                      color: current
                          ? scheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await search.goToMatchOfIndex(i);
                          widget.onShow();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: space.md,
                            vertical: space.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.pageLabel(match.pageNumber.toString()),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  style: style,
                                  children: [
                                    TextSpan(text: match.before),
                                    TextSpan(
                                      text: match.match,
                                      style: style.copyWith(
                                        fontWeight: FontWeight.w700,
                                        backgroundColor: scheme.primary
                                            .withValues(alpha: 0.18),
                                      ),
                                    ),
                                    TextSpan(text: match.after),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Pages extends StatelessWidget {
  const _Pages({
    required this.document,
    required this.controller,
    required this.onTap,
  });

  final PdfDocument document;
  final PdfViewerController controller;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => GridView.builder(
        padding: EdgeInsets.all(space.md),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 132,
          mainAxisSpacing: space.md,
          crossAxisSpacing: space.md,
          childAspectRatio: 0.62,
        ),
        itemCount: document.pageCount,
        itemBuilder: (context, index) {
          final current = index == controller.currentPage;
          return Semantics(
            button: true,
            selected: current,
            label: l10n.pageLabel('${index + 1}'),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(tokens.radius.sm),
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(tokens.radius.sm),
                        border: Border.all(
                          color: current
                              ? tokens.lit
                              : theme.colorScheme.outlineVariant,
                          width: current ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radius.sm),
                        child: ColoredBox(
                          color: Colors.white,
                          child: PdfPageView(page: document.page(index)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: space.xs),
                  Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: current
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({
    required this.markers,
    required this.onChanged,
    required this.onTap,
  });

  final Map<int, List<Marker>> markers;
  final VoidCallback onChanged;
  final ValueChanged<Marker> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final all = [
      for (final page in (markers.keys.toList()..sort())) ...markers[page]!,
    ];
    if (all.isEmpty) {
      return _Empty(
        icon: Icons.border_color_rounded,
        title: l10n.booksNoHighlights,
        hint: l10n.booksHighlightsHint,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: space.xs),
      itemCount: all.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final marker = all[i];
        return InkWell(
          onTap: () => onTap(marker),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.md,
              space.sm,
              space.xs,
              space.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: marker.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pageLabel(marker.pageNumber.toString()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        marker.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => onDelete(context, marker),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onDelete(BuildContext context, Marker marker) {
    markers[marker.pageIndex]?.remove(marker);
    if (markers[marker.pageIndex]?.isEmpty ?? false) {
      markers.remove(marker.pageIndex);
    }
    onChanged();
    PdfReaderPanelUndo.of(context)?.call(marker);
  }
}

class PdfReaderPanelUndo extends InheritedWidget {
  const PdfReaderPanelUndo({
    super.key,
    required this.onRemoved,
    required super.child,
  });

  final ValueChanged<Marker> onRemoved;

  static ValueChanged<Marker>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PdfReaderPanelUndo>()
      ?.onRemoved;

  @override
  bool updateShouldNotify(PdfReaderPanelUndo old) => old.onRemoved != onRemoved;
}
