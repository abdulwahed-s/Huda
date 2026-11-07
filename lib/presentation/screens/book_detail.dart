import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/book_detail/book_detail_cubit.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
import 'package:huda/cubit/download_manager/download_manager_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/book_detail/book_detail_controller.dart';
import 'package:huda/presentation/widgets/book_detail/book_page_parts.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/share/huda_share_sheet.dart';

/// A book's page: the open binding (its title page beside the board's
/// inside), Read and Download, what it is about, the other languages it
/// comes in and its other formats. Standard tier; the binding opens on its
/// spine as the page appears. Two panes from 840 wide and on open folds.
/// See `design/features/books/brief.md`.
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.language,
    required this.title,
  });

  final int bookId;
  final String language;
  final String title;

  /// The cubits the page creates, replaced by the redesign harness.
  @visibleForTesting
  static BookDetailCubit Function() createCubit = BookDetailCubit.new;
  @visibleForTesting
  static BookLanguagesCubit Function() createLanguagesCubit =
      BookLanguagesCubit.new;
  @visibleForTesting
  static DownloadManagerCubit Function() createDownloadCubit =
      DownloadManagerCubit.new;

  /// The page with its cubits and the Lantern theme, as the route and the
  /// library's covers open it.
  static Widget page({
    required int bookId,
    required String language,
    required String title,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider<BookDetailCubit>(create: (_) => createCubit()),
      BlocProvider<BookLanguagesCubit>(create: (_) => createLanguagesCubit()),
      BlocProvider<DownloadManagerCubit>(create: (_) => createDownloadCubit()),
    ],
    child: BookDetailScreen(bookId: bookId, language: language, title: title),
  );

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final BookDetailController controller;
  bool _retrying = false;
  BookDetailState? _failure;

  @override
  void initState() {
    super.initState();
    controller = BookDetailController(
      context,
      widget.bookId,
      widget.language,
      widget.title,
      () {
        if (mounted) setState(() {});
      },
    );
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _retrying = true);
    controller.retryBookDetail();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<DownloadManagerCubit, DownloadManagerState>(
      listener: _onDownload,
      child: BlocConsumer<BookDetailCubit, BookDetailState>(
        listener: (context, state) {
          if (state is! BookDetailLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          if (state is BookDetailError || state is BookDetailOffline) {
            _failure = state;
          }
          final failure = _failure;
          final shown =
              _retrying && state is BookDetailLoading && failure != null
              ? failure
              : state;
          final book = switch (shown) {
            BookDetailLoaded(:final bookDetail) => BookView.online(
              bookDetail,
              fallbackTitle: widget.title,
            ),
            BookDetailOfflineLoaded(:final offlineBook) => BookView.offline(
              offlineBook,
            ),
            _ => null,
          };
          return HudaScaffold(
            title: book?.title ?? widget.title,
            actions: [
              IconButton(
                tooltip: l10n.share,
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: book == null ? null : () => _share(context),
              ),
            ],
            body: HudaRevealScope(
              child: HudaStateSwitcher(
                stateKey: _stateKey(shown),
                child: book != null
                    ? _BookLayout(
                        book: book,
                        bookId: widget.bookId,
                        controller: controller,
                        onRead: () => _read(shown),
                        onDownload: shown is BookDetailLoaded
                            ? () => controller.downloadBook(shown)
                            : null,
                        onRemove: () => _confirmRemove(context, shown),
                      )
                    : _state(context, shown),
              ),
            ),
          );
        },
      ),
    );
  }

  Object _stateKey(BookDetailState state) => switch (state) {
    BookDetailLoaded(:final bookDetail) => 'loaded-${bookDetail.id}',
    BookDetailOfflineLoaded() => 'saved',
    BookDetailError() => 'error',
    BookDetailOffline() => 'offline',
    _ => 'loading',
  };

  Widget _state(BuildContext context, BookDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    return switch (state) {
      BookDetailError(:final error) => HudaStateView(
        identity: booksIdentity,
        mark: HudaStateMark.alert,
        title: error.contains('There is no Data')
            ? l10n.booksLanguageUnavailable
            : l10n.booksDetailError,
        actions: [
          HudaRetryButton(onRetry: _retry, retrying: _retrying),
          if (controller.selectedLanguage != null && !_retrying)
            TextButton(
              onPressed: () => controller.handleLanguageSelected(null),
              child: Text(l10n.booksShowOriginal),
            ),
        ],
      ),
      BookDetailOffline() => HudaOfflineState(
        message: l10n.booksDetailOffline,
        onRetry: _retry,
        retrying: _retrying,
      ),
      _ => const BookPageSkeleton(),
    };
  }

  Future<void> _read(BookDetailState state) async {
    if (state is BookDetailLoaded) {
      await controller.handlePrimaryAction(state);
    } else if (state is BookDetailOfflineLoaded) {
      await controller.handleOfflinePrimaryAction(state);
    }
  }

  void _onDownload(BuildContext context, DownloadManagerState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is DownloadInProgress && state.progress.bookId == widget.bookId) {
      controller.handleDownloadStateChanged(true, state.progress.progress);
    } else if (state is DownloadCompleted && state.bookId == widget.bookId) {
      controller.handleDownloadStateChanged(false, 1.0);
      showHudaToast(context, message: l10n.bookDownloadedSuccessfully);
    } else if (state is DownloadError && state.bookId == widget.bookId) {
      controller.handleDownloadStateChanged(false, 0.0);
      final detail = context.read<BookDetailCubit>().state;
      showHudaToast(
        context,
        kind: HudaToastKind.failed,
        message: l10n.booksDownloadFailed,
        actionLabel: detail is BookDetailLoaded ? l10n.retry : null,
        onAction: detail is BookDetailLoaded
            ? () => controller.downloadBook(detail)
            : null,
      );
    }
  }

  Future<void> _share(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var busy = false;
    return showHudaSheet<void>(
      context: context,
      title: l10n.shareBookTitle(widget.title),
      maxDialogWidth: 440,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final space = sheetContext.tokens.space;
          return Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!PlatformUtils.isLinux) ...[
                  HudaShareOption(
                    icon: Icons.picture_as_pdf_rounded,
                    label: busy ? l10n.preparingPdfForSharing : l10n.shareAsPdf,
                    lit: true,
                    busy: busy,
                    onTap: () async {
                      setSheet(() => busy = true);
                      await controller.shareAsPdf();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                  SizedBox(height: space.sm),
                ],
                HudaShareOption(
                  icon: Icons.notes_rounded,
                  label: l10n.shareInMessage,
                  onTap: busy
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          controller.shareAsMessage();
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    BookDetailState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final remove = await showHudaSheet<bool>(
      context: context,
      title: l10n.booksRemoveDownloadTitle,
      maxDialogWidth: 440,
      builder: (sheetContext) {
        final space = sheetContext.tokens.space;
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(bottom: space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.booksRemoveDownloadBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: space.lg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: space.sm,
                runSpacing: space.sm,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.booksRemove),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (remove != true || !context.mounted) return;
    HudaHaptics.light(context);
    await controller.deleteOfflineBook(widget.bookId);
    // Offline, the page showed the saved copy: now there is none.
    if (state is BookDetailOfflineLoaded && mounted) {
      controller.retryBookDetail();
    }
  }
}

/// The page's layout for a loaded book: one column on phones, the binding
/// beside the details from 840 wide and on open folds, the binding above
/// a tabletop fold.
class _BookLayout extends StatelessWidget {
  const _BookLayout({
    required this.book,
    required this.bookId,
    required this.controller,
    required this.onRead,
    required this.onDownload,
    required this.onRemove,
  });

  final BookView book;
  final int bookId;
  final BookDetailController controller;
  final VoidCallback onRead;
  final VoidCallback? onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final binding = BookBindingHero(book: book, seed: bookId);
    final actions = BookActions(
      book: book,
      downloaded: book.savedOn != null || controller.isBookDownloaded,
      downloading: controller.isDownloading,
      progress: controller.downloadProgress,
      onRead: onRead,
      onDownload: kIsWeb ? null : onDownload,
      onRemove: onRemove,
    );
    final details = BookDetails(
      book: book,
      selectedLanguage: controller.selectedLanguage,
      onLanguage: book.savedOn == null
          ? controller.handleLanguageSelected
          : null,
      originalLanguage: controller.language,
      onFile: controller.handleAttachmentTap,
      onSavedFile: controller.handleOfflineAttachmentTap,
    );

    Widget column(List<Widget> children, {double maxWidth = 680}) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
    Widget scroll(Widget child, {bool top = true}) => SingleChildScrollView(
      padding: context.scrollPadding(
        EdgeInsets.fromLTRB(
          space.gutter(MediaQuery.sizeOf(context).width),
          top ? space.md : space.sm,
          space.gutter(MediaQuery.sizeOf(context).width),
          space.xxl,
        ),
      ),
      child: child,
    );

    if (TabletopSplit.applies(context)) {
      return TabletopSplit(
        top: Center(
          child: Padding(
            padding: EdgeInsets.all(space.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: binding,
            ),
          ),
        ),
        bottom: Builder(
          builder: (context) =>
              scroll(column([actions, SizedBox(height: space.xl), details])),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Short windows (phone landscape) put them side by side sooner,
        // with a wider binding pane so the title page keeps its words.
        final short = context.windowClass.isCompactHeight;
        final minWidth = short ? 760.0 : 840.0;
        final twoPanes = AdaptivePanes.showsTwoPanes(
          constraints.maxWidth,
          FoldInfo.of(context),
          twoPaneMinWidth: minWidth,
        );
        if (twoPanes) {
          return AdaptivePanes(
            twoPaneMinWidth: minWidth,
            minPrimaryWidth: short ? 400 : 320,
            maxPrimaryWidth: 580,
            primaryFraction: 0.42,
            primary: Builder(
              builder: (context) => scroll(
                column([
                  binding,
                  SizedBox(height: space.lg),
                  HudaReveal(index: 1, child: actions),
                ], maxWidth: 520),
              ),
            ),
            secondary: Builder(
              builder: (context) =>
                  scroll(column([HudaReveal(index: 2, child: details)])),
            ),
          );
        }
        return scroll(
          column([
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: binding,
              ),
            ),
            SizedBox(height: space.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: HudaReveal(index: 1, child: actions),
              ),
            ),
            SizedBox(height: space.xl),
            HudaReveal(index: 2, child: details),
          ]),
        );
      },
    );
  }
}
