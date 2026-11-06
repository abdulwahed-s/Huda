import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/chapters/chapters_cubit.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/data/models/book_chapters_model.dart' as chapters;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/widgets/hadith_chapters/hadith_index.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_reader.dart';

/// A hadith collection: its books as an index, and the open book's hadith.
/// Standard tier.
///
/// Like Mail on a foldable: on narrow windows the index, and a book opens
/// over it (Back returns); on wide windows and open folds the index sits
/// beside the reader, split at the fold, and the reader pane shows the
/// collection's title page until a book is chosen. The open book, its page
/// and its place are kept here, so folding, unfolding or resizing shows the
/// same book. See `design/features/hadith/brief.md`.
class HadithChapters extends StatefulWidget {
  const HadithChapters({super.key, required this.collection});

  final HadithCollectionRef collection;

  /// Create the page's cubits. Seams for the redesign harness, which can't
  /// reach the network.
  @visibleForTesting
  static ChaptersCubit Function() createCubit = ChaptersCubit.new;
  // Also used by `HadithDetails`, the reader's own route.
  static HadithDetailsCubit Function() createDetailsCubit =
      HadithDetailsCubit.new;

  /// The screen with its cubit, as the route and the collection tiles open
  /// it.
  static Widget page({required HadithCollectionRef collection}) =>
      BlocProvider<ChaptersCubit>(
        create: (_) => createCubit()..fetchChaptersByBook(collection.slug),
        child: HadithChapters(collection: collection),
      );

  @override
  State<HadithChapters> createState() => _HadithChaptersState();
}

class _HadithChaptersState extends State<HadithChapters> {
  final _search = TextEditingController();
  String _query = '';
  final _nested = GlobalKey<NavigatorState>();

  /// The open book and its cubit; null until one is chosen.
  HadithBookRef? _open;
  HadithDetailsCubit? _details;
  HadithReaderMemory _memory = HadithReaderMemory();

  /// Scroll positions (the index's, each book's), kept here rather than in
  /// a route, so both layouts and the nested navigator share them.
  final _storage = PageStorageBucket();

  bool _retrying = false;
  ChaptersState? _failure;

  HadithCollectionRef get _collection => widget.collection;

  @override
  void dispose() {
    _search.dispose();
    _details?.close();
    super.dispose();
  }

  void _openBook(HadithBookRef book) {
    if (book == _open) return;
    _details?.close();
    setState(() {
      _open = book;
      _memory = HadithReaderMemory();
      _details = HadithChapters.createDetailsCubit()
        ..fetchHadithDetails(book.number, _collection.slug, 1);
    });
  }

  void _closeBook() {
    final details = _details;
    setState(() {
      _open = null;
      _details = null;
    });
    // After the reader has left (its route animates out with it).
    Future<void>.delayed(const Duration(seconds: 1), () => details?.close());
  }

  void _retry() {
    setState(() => _retrying = true);
    context.read<ChaptersCubit>().fetchChaptersByBook(_collection.slug);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = AdaptivePanes.showsTwoPanes(width, FoldInfo.of(context));
    return HudaRevealScope(
      child: BlocListener<ChaptersCubit, ChaptersState>(
        listener: (context, state) {
          if (state is! ChaptersLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        child: PageStorage(
          bucket: _storage,
          child: wide ? _wide(context) : _narrow(context),
        ),
      ),
    );
  }

  /// Back out of the collection, from inside the nested navigator.
  Widget? get _leaveButton {
    final canLeave = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    if (!canLeave) return null;
    return BackButton(onPressed: () => Navigator.of(context).maybePop());
  }

  Widget _wide(BuildContext context) {
    final open = _open;
    final details = _details;
    return HudaScaffold(
      title: _collection.title,
      leading: _leaveButton,
      body: AdaptivePanes(
        primary: _index(context, wide: true),
        // The pane changes with the open book: the title page, or one
        // book's reader, fading through (never two at once).
        secondary: HudaStateSwitcher(
          stateKey: open?.number ?? '',
          sequential: true,
          alignment: Alignment.topCenter,
          child: open == null || details == null
              ? BlocBuilder<ChaptersCubit, ChaptersState>(
                  builder: (context, state) => HadithTitlePage(
                    collection: _collection,
                    bookCount: state is ChaptersLoaded
                        ? state.bookChapters.data?.length
                        : null,
                    // Art only beside the books: not beside an error's or
                    // an empty index's own art.
                    showArt:
                        state is ChaptersLoaded &&
                        (state.bookChapters.data ?? const []).isNotEmpty,
                    // "Choose a book" only when there are books to choose.
                    canChoose:
                        state is ChaptersLoaded &&
                        (state.bookChapters.data ?? const []).isNotEmpty,
                  ),
                )
              : BlocProvider.value(
                  value: details,
                  child: HadithReader(
                    key: ValueKey('reader-${open.number}'),
                    collection: _collection,
                    book: open,
                    memory: _memory,
                    overlayContext: context,
                  ),
                ),
        ),
      ),
    );
  }

  /// The index, and the open book pushed over it, in a navigator of their
  /// own so Back (and the back gesture) closes the book.
  Widget _narrow(BuildContext context) {
    final open = _open;
    final details = _details;
    return NavigatorPopHandler<Object?>(
      enabled: open != null,
      onPopWithResult: (_) => _nested.currentState?.maybePop(),
      child: Navigator(
        key: _nested,
        pages: [
          MaterialPage<void>(
            key: const ValueKey('hadith-index'),
            child: PageStorage(
              bucket: _storage,
              child: HudaScaffold(
                title: _collection.title,
                leading: _leaveButton,
                body: _index(context, wide: false),
              ),
            ),
          ),
          if (open != null && details != null)
            MaterialPage<void>(
              key: ValueKey('hadith-book-${open.number}'),
              child: PageStorage(
                bucket: _storage,
                child: HudaScaffold(
                  title: _collection.title,
                  body: BlocProvider.value(
                    value: details,
                    child: HadithReader(
                      key: ValueKey('reader-${open.number}'),
                      collection: _collection,
                      book: open,
                      memory: _memory,
                    ),
                  ),
                ),
              ),
            ),
        ],
        onDidRemovePage: (page) {
          if (page.key != const ValueKey('hadith-index')) _closeBook();
        },
      ),
    );
  }

  /// The collection's header, the search and its books; on tabletop the
  /// header and search above the band and the books below it.
  Widget _index(BuildContext context, {required bool wide}) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ChaptersCubit, ChaptersState>(
      builder: (context, state) {
        if (state is ChaptersError) _failure = state;
        final failure = _failure;
        final shown = _retrying && state is ChaptersLoading && failure != null
            ? failure
            : state;
        final loaded = shown is ChaptersLoaded ? shown : null;
        final language = Localizations.localeOf(context).languageCode;
        final books = loaded == null
            ? null
            : [
                for (final data in sortHadithBooks(
                  loaded.bookChapters.data ?? const <chapters.Data>[],
                ))
                  HadithBookRef.of(data, language),
              ];
        final compactHeight = context.windowClass.isCompactHeight;
        // The names and counts lead the index on phones. Wide windows have
        // them on the title page, which "About this collection" brings
        // back; short windows keep the room for books.
        final Widget? header = wide
            ? (books == null || books.isEmpty
                  ? null
                  : HudaContentRow(
                      key: const ValueKey('hadith-about'),
                      selected: _open == null,
                      // Tappable while selected too, so it shows its tint
                      // (it does nothing then).
                      onTap: () {
                        if (_open != null) _closeBook();
                      },
                      leading: const HadithFolioMark(),
                      title: l10n.hadithAbout,
                      trailing: const SizedBox.shrink(),
                    ))
            : compactHeight
            ? null
            : HadithCollectionHeader(
                collection: _collection,
                bookCount: books?.length,
              );
        final search = HadithBookSearchField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value.trim()),
        );
        // Full states fill the room under the header and keep their
        // actions above the bottom inset. One lead per state at every
        // size: the system's lamp for a failure, the folio for empty.
        Widget? fill;
        var rows = <Widget>[];
        if (shown is ChaptersError) {
          fill = HudaErrorState(
            message: l10n.hadithBooksLoadError,
            onRetry: _retry,
            retrying: _retrying,
          );
        } else if (books == null) {
          rows = [
            SliverList.builder(
              itemCount: 12,
              itemBuilder: (context, i) =>
                  HadithBookRowSkeleton(announce: i == 0),
            ),
          ];
        } else if (books.isEmpty) {
          fill = HudaEmptyState(
            identity: hadithIdentity,
            title: l10n.noChapters,
            message: l10n.newContent,
          );
        } else {
          rows = _rows(context, books, wide: wide);
        }
        final hasBooks = books != null && books.isNotEmpty;
        final top = <Widget>[
          if (shown is! ChaptersError && header != null)
            HudaReveal(child: header),
          if (hasBooks) search,
        ];
        if (!wide && TabletopSplit.applies(context)) {
          return TabletopSplit(
            top: _list(context, [
              SliverList.list(children: _spaced(context, top)),
            ], tight: true),
            bottom: _list(context, rows, fill: fill),
          );
        }
        return HudaStateSwitcher(
          stateKey: shown.runtimeType,
          alignment: Alignment.topCenter,
          child: _list(
            context,
            [
              if (top.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.only(bottom: context.tokens.space.md),
                  sliver: SliverList.list(children: _spaced(context, top)),
                ),
              ...rows,
            ],
            remember: fill == null,
            fill: fill,
          ),
        );
      },
    );
  }

  List<Widget> _spaced(BuildContext context, List<Widget> children) => [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) SizedBox(height: context.tokens.space.md),
      children[i],
    ],
  ];

  List<Widget> _rows(
    BuildContext context,
    List<HadithBookRef> books, {
    required bool wide,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final query = _query.toLowerCase();
    final shown = query.isEmpty
        ? books
        : [
            for (final book in books)
              if (book.title.toLowerCase().contains(query) ||
                  (book.arabicTitle ?? '').contains(_query) ||
                  book.shownNumber == query)
                book,
          ];
    if (shown.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
            child: HudaEmptyState(
              identity: hadithIdentity,
              title: l10n.noResultsFound,
              message: l10n.tryDifferentSearch,
            ),
          ),
        ),
      ];
    }
    final divider = Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return [
      SliverList.separated(
        itemCount: shown.length,
        separatorBuilder: (_, _) => divider,
        itemBuilder: (context, i) => HudaReveal(
          index: i + 1,
          child: HadithBookRow(
            book: shown[i],
            selected: wide && shown[i] == _open,
            onTap: () => _openBook(shown[i]),
          ),
        ),
      ),
    ];
  }

  /// A scrolling column at the reading measure, in the gutters, ending
  /// above the bottom inset.
  Widget _list(
    BuildContext context,
    List<Widget> slivers, {
    bool tight = false,
    bool remember = false,
    Widget? fill,
  }) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        final gutter = space.gutter(constraints.maxWidth);
        final room = constraints.maxWidth - insets.horizontal - gutter * 2;
        final extra = room > HadithReader.measure
            ? (room - HadithReader.measure) / 2
            : 0.0;
        return CustomScrollView(
          key: remember ? const PageStorageKey('hadith-index') : null,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter + insets.left + extra,
                tight ? space.sm : space.md,
                gutter + insets.right + extra,
                fill != null
                    ? 0
                    : tight
                    ? space.sm
                    : space.xxl + insets.bottom,
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
            // A full state: the room that's left, scrolling inside.
            if (fill != null)
              SliverFillRemaining(hasScrollBody: true, child: fill),
          ],
        );
      },
    );
  }
}
