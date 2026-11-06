import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/bookmarks/quran_bookmark_card.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';

/// Saved ayat: bookmarks (in their colors), notes and stars. Search and a
/// filter in the page; a tap opens the ayah, ⋮ edits a note or deletes
/// (with Undo). Standard tier. See `design/features/quran/brief.md`.
class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  /// Content is capped at this width and centered.
  static const double maxContentWidth = 1280;

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final _search = TextEditingController();
  String _query = '';

  /// Null shows every kind.
  BookmarkType? _filter;

  /// Cards folding away before their bookmark is removed.
  final _leaving = <String>{};

  /// The last list shown: it stays while a live update reloads (and after
  /// a failed edit), instead of flashing the skeleton.
  List<BookmarkModel>? _shown;
  StreamSubscription<BookmarkChange>? _changes;

  @override
  void initState() {
    super.initState();
    context.read<BookmarksCubit>().loadBookmarks();
    // Saved elsewhere (the reader) while this is open: reload.
    _changes = getIt<BookmarkService>().bookmarkChanges.listen((_) {
      if (mounted) context.read<BookmarksCubit>().loadBookmarks();
    });
  }

  @override
  void dispose() {
    _changes?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _open(BookmarkModel bookmark) {
    Navigator.pushNamed(
      context,
      AppRoute.surahScreen,
      arguments: {
        'surahInfo': QuranSurahRef.index[bookmark.surahNumber - 1],
        'scrollToAyah': bookmark.ayahNumber,
        'shouldRestorePosition': true,
      },
    );
  }

  Future<void> _delete(BookmarkModel bookmark) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BookmarksCubit>();
    HudaHaptics.light(context);
    // The card folds away first, then the list closes over it.
    final fold = context.tokens.motion.of(context, context.tokens.motion.long);
    if (fold > Duration.zero) {
      setState(() => _leaving.add(bookmark.id));
      await Future<void>.delayed(fold);
      if (!mounted) return;
    }
    await cubit.removeBookmark(
      bookmark.surahNumber,
      bookmark.ayahNumber,
      bookmark.type,
    );
    if (!mounted) return;
    setState(() => _leaving.remove(bookmark.id));
    showHudaToast(
      context,
      message: l10n.quranBookmarkDeleted,
      actionLabel: l10n.undo,
      onAction: () => cubit.addBookmark(
        surahNumber: bookmark.surahNumber,
        ayahNumber: bookmark.ayahNumber,
        ayahText: bookmark.ayahText,
        surahName: bookmark.surahName,
        type: bookmark.type,
        color: bookmark.color,
        note: bookmark.note,
        ayahPosition: bookmark.ayahPosition,
      ),
    );
  }

  Future<void> _editNote(BookmarkModel bookmark) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BookmarksCubit>();
    final controller = TextEditingController(text: bookmark.note ?? '');
    final saved = await showHudaSheet<bool>(
      context: context,
      title: l10n.editNote,
      builder: (sheetContext) {
        final space = sheetContext.tokens.space;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bookmark.ayahText,
              textDirection: TextDirection.rtl,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: sheetContext.type.ayah.copyWith(fontSize: 20),
            ),
            SizedBox(height: space.md),
            TextField(
              key: const ValueKey('quran-note-field'),
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: l10n.note),
            ),
            SizedBox(height: space.lg),
            FilledButton.icon(
              key: const ValueKey('quran-note-save'),
              onPressed: () => Navigator.pop(sheetContext, true),
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      await cubit.updateBookmarkNote(
        bookmark.surahNumber,
        bookmark.ayahNumber,
        controller.text.trim(),
      );
      if (mounted) showHudaToast(context, message: l10n.bookmarkUpdated);
    }
    controller.dispose();
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BookmarksCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAllBookmarks),
        content: Text(l10n.clearAllBookmarksConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          // Can't be undone: the error tone, not the lit primary.
          FilledButton(
            key: const ValueKey('quran-clear-all-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      HudaHaptics.light(context);
      await cubit.clearAllBookmarks();
    }
  }

  List<BookmarkModel> _matching(List<BookmarkModel> all) {
    final q = TextUtils.removeDiacriticsAndNormalize(
      _query.trim().toLowerCase(),
    );
    if (q.isEmpty) return all;
    bool has(String? s) =>
        s != null &&
        TextUtils.removeDiacriticsAndNormalize(s.toLowerCase()).contains(q);
    final language = Localizations.localeOf(context).languageCode;
    return [
      for (final b in all)
        if (has(b.ayahText) ||
            has(b.surahName) ||
            has(b.note) ||
            has(QuranSurahRef.number(b.surahNumber, language).title))
          b,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaRevealScope(
      child: BlocBuilder<BookmarksCubit, BookmarksState>(
        builder: (context, state) {
          final all = _shown = switch (state) {
            BookmarksLoaded(:final bookmarks) => bookmarks,
            BookmarkOperationSuccess(:final bookmarks) => bookmarks,
            BookmarksLoading() || BookmarkOperationFailure() => _shown,
            _ => null,
          };
          // The list follows saves live, so there's no Refresh; Clear all
          // is the one action left, asked to confirm.
          final actions = [
            if (all != null && all.isNotEmpty)
              IconButton(
                key: const ValueKey('quran-clear-all'),
                tooltip: l10n.clearAll,
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
          ];
          final whole = _whole(context, state, all);
          if (whole != null) {
            return HudaScaffold(
              title: l10n.bookmarks,
              actions: actions,
              body: whole,
            );
          }
          // Tabletop: the bar, search and filters above the band, the
          // saved ayat below it.
          if (TabletopSplit.applies(context)) {
            return TabletopSplit(
              top: HudaScaffold(
                title: l10n.bookmarks,
                actions: actions,
                body: _page(context, [_controls(context, all)], tight: true),
              ),
              bottom: _page(context, [_results(context, all)]),
            );
          }
          return HudaScaffold(
            title: l10n.bookmarks,
            actions: actions,
            body: _page(context, [
              _controls(context, all),
              _results(context, all),
            ]),
          );
        },
      ),
    );
  }

  /// A state that takes the whole page: the error, or nothing saved yet.
  Widget? _whole(
    BuildContext context,
    BookmarksState state,
    List<BookmarkModel>? all,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (state is BookmarksError) {
      return HudaErrorState(
        identity: quranIdentity,
        message: l10n.errorLoadingBookmarks,
        onRetry: () => context.read<BookmarksCubit>().loadBookmarks(),
      );
    }
    if (all != null && all.isEmpty) {
      return HudaEmptyState(
        identity: quranIdentity,
        title: l10n.noBookmarksYet,
        message: l10n.startBookmarkingFavoriteVerses,
        actionLabel: l10n.browseQuran,
        onAction: () => Navigator.pushNamed(context, AppRoute.homeQuran),
      );
    }
    return null;
  }

  /// The page's column: gutters and insets, capped and centered.
  Widget _page(
    BuildContext context,
    List<Widget> slivers, {
    bool tight = false,
  }) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final side =
            space.gutter(width) +
            math.max(0.0, (width - BookmarksPage.maxContentWidth) / 2);
        final base = EdgeInsets.fromLTRB(
          side,
          space.sm,
          side,
          tight ? space.sm : space.xl,
        );
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: tight ? base : context.scrollPadding(base),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        );
      },
    );
  }

  List<BookmarkModel>? _searched(List<BookmarkModel>? all) =>
      all == null ? null : _matching(all);

  /// Search and the filter chips with their counts: one row when there's
  /// room, the chips scrolling sideways on phones. Kept off a book fold.
  Widget _controls(BuildContext context, List<BookmarkModel>? all) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final searched = _searched(all);
    int count(BookmarkType? type) => (searched ?? const [])
        .where((b) => type == null || b.type == type)
        .length;
    final filters = <(BookmarkType?, IconData, String)>[
      (null, Icons.collections_bookmark_rounded, l10n.all),
      (BookmarkType.bookmark, Icons.bookmark_rounded, l10n.bookmarks),
      (BookmarkType.note, Icons.sticky_note_2_rounded, l10n.notes),
      (BookmarkType.star, Icons.star_rounded, l10n.stars),
    ];
    final search = HudaSearchField(
      key: const ValueKey('quran-bookmarks-search'),
      controller: _search,
      onChanged: (value) => setState(() => _query = value),
      hintText: l10n.searchBookmarksHint,
    );
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, (type, icon, label)) in filters.indexed) ...[
            if (i > 0) SizedBox(width: space.xs),
            ChoiceChip(
              key: ValueKey('quran-filter-${type?.name}'),
              // Lit when chosen: the mark takes the chip's warm text.
              avatar: Icon(
                icon,
                size: 18,
                color: _filter == type ? context.tokens.onChrome : null,
              ),
              label: Text(searched == null ? label : '$label ${count(type)}'),
              selected: _filter == type,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = type),
            ),
          ],
        ],
      ),
    );
    return SliverPadding(
      padding: EdgeInsets.only(bottom: space.md),
      sliver: SliverToBoxAdapter(
        child: QuranLeadingHalf(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >=
                  MediaQuery.textScalerOf(context).scale(720);
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: search),
                    SizedBox(width: space.md),
                    Flexible(child: chips),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  SizedBox(height: space.sm),
                  chips,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The saved ayat for the search and filter, or why there are none.
  Widget _results(BuildContext context, List<BookmarkModel>? all) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final list = _searched(
      all,
    )?.where((b) => _filter == null || b.type == _filter).toList();
    // Two columns from phone landscape, more as the window widens.
    final minTile = AdaptiveGrid.tileWidth(
      context,
      context.windowClass.isCompactHeight ? 280 : 360,
    );
    final Widget results;
    if (list == null) {
      results = SliverAdaptiveGrid(
        minTileWidth: minTile,
        spacing: space.sm,
        maxColumns: 3,
        itemCount: 4,
        itemBuilder: (_, i) => QuranBookmarkCardSkeleton(announce: i == 0),
      );
    } else if (list.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      final (title, message) = searching
          ? (l10n.surahNoResults, l10n.tryDifferentSearch)
          : switch (_filter) {
              BookmarkType.note => (
                l10n.noNotesYet,
                l10n.addNotesToFavoriteVerses,
              ),
              BookmarkType.star => (
                l10n.noStarredVersesYet,
                l10n.starImportantVerses,
              ),
              _ => (l10n.noBookmarksYet, l10n.startBookmarkingFavoriteVerses),
            };
      // The rest of the page, bounded: the empty state centres itself in a
      // scroll view and needs a height (in a plain box it threw and left
      // every filter blank until the screen reopened; owner round 2).
      results = SliverFillRemaining(
        hasScrollBody: true,
        child: Padding(
          padding: EdgeInsets.only(top: space.lg),
          child: HudaEmptyState(
            identity: quranIdentity,
            title: title,
            message: message,
            actionLabel: searching ? l10n.athkarClearSearch : null,
            onAction: searching
                ? () {
                    _search.clear();
                    setState(() => _query = '');
                  }
                : null,
          ),
        ),
      );
    } else {
      results = SliverAdaptiveGrid(
        minTileWidth: minTile,
        spacing: space.sm,
        maxColumns: 3,
        equalHeights: false,
        itemCount: list.length,
        // Keyed by bookmark: a card keeps its own state as the filter
        // changes which cards are shown.
        itemBuilder: (context, i) => HudaReveal(
          key: ValueKey(list[i].id),
          index: i,
          child: _FoldAway(
            leaving: _leaving.contains(list[i].id),
            child: QuranBookmarkCard(
              bookmark: list[i],
              onOpen: () => _open(list[i]),
              onAction: (action) => switch (action) {
                QuranBookmarkAction.editNote => _editNote(list[i]),
                QuranBookmarkAction.delete => _delete(list[i]),
              },
            ),
          ),
        ),
      );
    }
    // The saved ayat arrive from their skeleton; a filter or search swaps
    // the cards at once (the chip answers the tap), with no dimming between
    // lists; a deleted card folds away on its own (owner round 1).
    return SliverHudaStateSwitcher(
      stateKey: list == null ? 'loading' : 'loaded',
      sliver: results,
    );
  }
}

/// A card closing to nothing, as a deleted bookmark leaves: it fades over
/// the first half while its height closes over the whole (long, ease in
/// and out), so the cards below visibly move up into its place.
class _FoldAway extends StatelessWidget {
  const _FoldAway({required this.leaving, required this.child});

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final duration = tokens.motion.of(context, tokens.motion.long);
    return ClipRect(
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        heightFactor: leaving ? 0 : 1,
        child: AnimatedOpacity(
          duration: duration,
          curve: const Interval(0, 0.5, curve: Curves.easeOut),
          opacity: leaving ? 0 : 1,
          child: child,
        ),
      ),
    );
  }
}
