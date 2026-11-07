import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/book_pdf_source_resolver.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/book_detail.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/books/books_library_parts.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';

/// The library: the catalogue's books as bindings, a page at a time, in
/// one language or all. Landing tier; the header carries the tooled
/// binding. See `design/features/books/brief.md`.
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  static const double maxContentWidth = 1280;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String? _language;
  final _top = GlobalKey();

  /// After a tap on Retry, until the cubit answers: the failure stays on
  /// screen with "Retrying…" instead of turning into a skeleton.
  bool _retrying = false;
  BooksState? _failure;

  String get _appLanguage =>
      context.read<LocalizationCubit>().state.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _language = _appLanguage;
    context.read<BooksCubit>().fetchBooks(_language!, 1, _appLanguage);
    context.read<LanguagesCubit>().fetchLanguages(_appLanguage);
  }

  void _fetch(int page) {
    context.read<BooksCubit>().fetchBooks(
      _language ?? 'showall',
      page,
      _appLanguage,
    );
  }

  void _changeLanguage(String? language) {
    setState(() => _language = language);
    _fetch(1);
  }

  void _changePage(int page) {
    _fetch(page);
    final top = _top.currentContext;
    if (top != null) {
      Scrollable.ensureVisible(
        top,
        duration: context.tokens.motion.of(
          context,
          context.tokens.motion.medium,
        ),
        curve: context.tokens.motion.standard,
      );
    }
  }

  void _retry() {
    setState(() => _retrying = true);
    _fetch(1);
    context.read<LanguagesCubit>().fetchLanguages(_appLanguage);
  }

  static bool _isLoading(BooksState state) =>
      state is BooksLoading ||
      state is BooksOfflineLoading ||
      state is BooksInitial;

  static bool _isOffline(BooksState state) =>
      state is BooksOfflineLoaded ||
      state is BooksOfflineEmpty ||
      state is BooksOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return HudaRevealScope(
      child: BlocConsumer<BooksCubit, BooksState>(
        listener: (context, state) {
          // A language with no books: show every language instead.
          if (state is BooksLoaded &&
              state.booksResponse.data.isEmpty &&
              _language != null) {
            setState(() => _language = null);
            _fetch(1);
          }
          if (!_isLoading(state) && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          if (state is BooksError || _isOffline(state)) {
            _failure = state;
          }
          final failure = _failure;
          final shown = _retrying && _isLoading(state) && failure != null
              ? failure
              : state;
          // The books are shelved as the library opens.
          return HudaDrawIn(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.linear,
            builder: (context, draw) => HudaLandingScaffold(
              leading: canPop ? const BackButton() : null,
              eyebrow: l10n.books,
              title: l10n.library,
              art: (style) => BookShelfPainter(style: style, draw: draw),
              contentMaxWidth: BooksScreen.maxContentWidth,
              slivers: [
                BooksPage(
                  maxWidth: BooksScreen.maxContentWidth,
                  children: [
                    SliverToBoxAdapter(
                      key: _top,
                      child: _Top(
                        state: shown,
                        language: _language,
                        onLanguage: _changeLanguage,
                      ),
                    ),
                    SliverHudaStateSwitcher(
                      stateKey: _stateKey(shown),
                      sliver: _body(context, shown),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Object _stateKey(BooksState state) => switch (state) {
    BooksLoaded(:final booksResponse) =>
      'page-${booksResponse.links.currentPage}-$_language',
    BooksOfflineLoaded() => 'offline',
    BooksOfflineEmpty() => 'offline-empty',
    BooksOffline() => 'offline-failed',
    BooksError() => 'error',
    _ => 'loading',
  };

  Widget _body(BuildContext context, BooksState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: true, child: child);
    return switch (state) {
      BooksLoaded(:final booksResponse) => SliverMainAxisGroup(
        slivers: [
          _Covers(
            count: booksResponse.data.length,
            cover: (context, i, width) {
              final book = booksResponse.data[i];
              return BookCover(
                title: book.title,
                seed: book.id,
                width: width,
                author: _author([
                  for (final p in book.preparedBy) (p.type, p.title),
                ]),
                onTap: (card) => _openBook(
                  card,
                  id: book.id,
                  language: book.translatedLanguage,
                  title: book.title,
                ),
              );
            },
          ),
          if (booksResponse.links.pagesNumber > 1)
            SliverPadding(
              padding: EdgeInsets.only(top: space.xl),
              sliver: SliverToBoxAdapter(
                child: BooksPager(
                  page: booksResponse.links.currentPage,
                  pages: booksResponse.links.pagesNumber,
                  onPage: _changePage,
                ),
              ),
            ),
        ],
      ),
      BooksOfflineLoaded(:final offlineBooks) => SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(bottom: space.lg),
            sliver: SliverToBoxAdapter(
              child: BooksOfflineNotice(
                count: offlineBooks.length,
                onRetry: _retry,
                retrying: _retrying,
              ),
            ),
          ),
          _Covers(
            count: offlineBooks.length,
            cover: (context, i, width) {
              final book = offlineBooks[i];
              return BookCover(
                title: book.title,
                seed: book.id,
                width: width,
                author: _author([
                  for (final p in book.preparedBy) (p.type, p.title),
                ]),
                downloaded: true,
                onTap: (card) => _openBook(
                  card,
                  id: book.id,
                  language: book.language,
                  title: book.title,
                ),
              );
            },
          ),
        ],
      ),
      BooksOfflineEmpty() => fill(
        HudaStateView(
          identity: booksIdentity,
          title: l10n.noDownloadedBooks,
          message: l10n.downloadBooksWhenOnlineToAccessThemOffline,
          actions: [HudaRetryButton(onRetry: _retry, retrying: _retrying)],
        ),
      ),
      BooksOffline() => fill(
        HudaOfflineState(onRetry: _retry, retrying: _retrying),
      ),
      BooksError() => fill(
        HudaErrorState(
          identity: booksIdentity,
          message: l10n.booksLoadError,
          onRetry: _retry,
          retrying: _retrying,
        ),
      ),
      _ => _Covers(
        count: 12,
        cover: (context, i, _) => BookCoverSkeleton(announce: i == 0),
        reveal: false,
      ),
    };
  }

  /// The book's author, or whoever prepared it first.
  static String? _author(List<(String, String?)> people) {
    for (final (type, name) in people) {
      if (type == 'author' && (name ?? '').isNotEmpty) return name;
    }
    for (final (_, name) in people) {
      if ((name ?? '').isNotEmpty) return name;
    }
    return null;
  }

  void _openBook(
    BuildContext card, {
    required int id,
    required String language,
    required String title,
  }) {
    pushFromCard(
      card,
      (_) =>
          BookDetailScreen.page(bookId: id, language: language, title: title),
    );
  }
}

/// The language chip and, when there is one, the book to continue.
class _Top extends StatelessWidget {
  const _Top({
    required this.state,
    required this.language,
    required this.onLanguage,
  });

  final BooksState state;
  final String? language;
  final ValueChanged<String?> onLanguage;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final offline =
        state is BooksOfflineLoaded ||
        state is BooksOfflineEmpty ||
        state is BooksOffline;
    final progressService = getIt<BookProgressService>();
    return ListenableBuilder(
      listenable: progressService,
      builder: (context, _) {
        final lastRead = progressService.getLastRead();
        // Only beside the books: a failure or the skeleton keeps the top
        // for its own message.
        final showContinue =
            lastRead != null &&
            lastRead.title != null &&
            (state is BooksLoaded);
        return Padding(
          padding: EdgeInsets.only(bottom: space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showContinue) ...[
                HudaReveal(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: BooksContinueCard(
                        progress: lastRead,
                        onTap: () => _openContinueReading(context, lastRead),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: space.lg),
              ],
              if (!offline)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BooksLanguageChip(
                    selected: language,
                    onSelected: onLanguage,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openContinueReading(
    BuildContext context,
    BookProgress progress,
  ) async {
    final language =
        progress.language ??
        context.read<LocalizationCubit>().state.locale.languageCode;
    final source = await BookPdfSourceResolver().resolve(
      bookId: progress.bookId,
      remoteUrl: progress.attachmentUrl ?? _listedPdfUrl(progress.bookId),
    );
    if (!context.mounted) return;

    if (source != null) {
      Navigator.pushNamed(
        context,
        AppRoute.pdfView,
        arguments: {
          'url': source.location,
          'fallbackPdfUrl': source.remoteUrl,
          'bookId': progress.bookId,
          'bookTitle': progress.title ?? '',
          'language': language,
        },
      );
      return;
    }

    // Older saved progress did not include an attachment URL. Keep those
    // records usable once by falling back to the book's page; opening the
    // reader again stores the URL for direct continuation thereafter.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen.page(
          bookId: progress.bookId,
          language: language,
          title: progress.title ?? '',
        ),
      ),
    );
  }

  /// Older progress records did not save their attachment URL. The current
  /// catalogue response already contains it for visible books, so use it to
  /// keep the Continue card a direct reader action during migration.
  String? _listedPdfUrl(int bookId) {
    final state = this.state;
    if (state is! BooksLoaded) return null;
    for (final book in state.booksResponse.data) {
      if (book.id != bookId) continue;
      for (final attachment in book.attachments) {
        if (attachment.extensionType.toUpperCase() != 'PDF') continue;
        final url = attachment.url.trim();
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }
}

/// The covers in a grid that reflows: two a row on phones, up to eight on
/// wide windows, even with a fold.
class _Covers extends StatelessWidget {
  const _Covers({required this.count, required this.cover, this.reveal = true});

  final int count;

  /// Builds cover [i] given its width in the grid.
  final Widget Function(BuildContext context, int i, double width) cover;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final minTileWidth = AdaptiveGrid.tileWidth(
      context,
      context.windowClass.isCompactHeight
          ? 140
          : context.windowClass.width >= WindowWidthClass.expanded
          ? 176
          : 148,
    );
    const maxColumns = 8;
    final fold = FoldInfo.of(context);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // The same columns the grid will choose, for the covers' width.
        final foldGap = fold.splitsHorizontally ? fold.end - fold.start : 0.0;
        final available = constraints.crossAxisExtent - foldGap;
        final columns = AdaptiveGrid.columns(
          width: available,
          minTileWidth: minTileWidth,
          spacing: space.md,
          maxColumns: maxColumns,
          preferEven: fold.hasFold,
        );
        final width = (available - space.md * (columns - 1)) / columns;
        return SliverAdaptiveGrid(
          minTileWidth: minTileWidth,
          spacing: space.md,
          maxColumns: maxColumns,
          itemCount: count,
          itemBuilder: (context, i) => reveal
              ? HudaReveal(index: i, child: cover(context, i, width))
              : cover(context, i, width),
        );
      },
    );
  }
}
