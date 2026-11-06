import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_folio_card.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_share_sheet.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';

/// Where a reader was, kept by the screen that owns it, so folding,
/// unfolding or resizing (a new layout builds a new reader) returns to the
/// same page and place.
///
/// The place on a page is kept by `PageStorage` (each page has its own
/// key), so a screen that wants it across layouts gives them one bucket.
class HadithReaderMemory {
  int page = 1;
}

/// A book's hadith, one page at a time: the book's header (its rule inks
/// in as it opens), the hadith as folios under their bab rubrics, and the
/// pager after the last one. Reads the [HadithDetailsCubit] above it,
/// whose first page its creator has asked for.
///
/// Used full screen on phones and in the reader pane on wide windows; on
/// tabletop the header sits above the band and the hadith below it.
class HadithReader extends StatefulWidget {
  const HadithReader({
    super.key,
    required this.collection,
    required this.book,
    required this.memory,
    this.overlayContext,
  });

  final HadithCollectionRef collection;
  final HadithBookRef book;
  final HadithReaderMemory memory;

  /// Where the share sheet opens: a context that sees the fold (outside
  /// `AdaptivePanes`, which hides it from its panes). Defaults to this
  /// reader's.
  final BuildContext? overlayContext;

  /// The hadith column's width.
  static const double measure = 720;

  @override
  State<HadithReader> createState() => _HadithReaderState();
}

class _HadithReaderState extends State<HadithReader> {
  bool _retrying = false;
  HadithDetailsState? _failure;

  /// The shown page's scroll position: back to its top before the next
  /// page comes, so the app bar's scrolled-under tint clears with it.
  ScrollPosition? _position;

  void _fetch(int page) => context
      .read<HadithDetailsCubit>()
      .fetchHadithDetails(widget.book.number, widget.collection.slug, page);

  void _retry() {
    setState(() => _retrying = true);
    _fetch(widget.memory.page);
  }

  void _goTo(int page) {
    // The new page has its own place, at its top.
    final position = _position;
    if (position != null && position.hasPixels && position.pixels > 0) {
      position.jumpTo(0);
    }
    widget.memory.page = page;
    _fetch(page);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HadithDetailsCubit, HadithDetailsState>(
      listener: (context, state) {
        if (state is! HadithDetailsLoading && _retrying) {
          setState(() => _retrying = false);
        }
      },
      builder: (context, state) {
        if (state is HadithDetailsError) _failure = state;
        final failure = _failure;
        final shown =
            _retrying && state is HadithDetailsLoading && failure != null
            ? failure
            : state;
        final model = shown is HadithDetailsLoaded ? shown.hadithDetail : null;
        final page = model == null ? widget.memory.page : _pageOf(model);
        final pages = model == null ? null : _pagesOf(model);
        final header = HadithBookHeader(
          collection: widget.collection,
          book: widget.book,
          page: page,
          pages: pages,
          compact: context.windowClass.isCompactHeight,
        );
        if (TabletopSplit.applies(context)) {
          return TabletopSplit(
            top: _column(context, [HudaReveal(child: header)], top: true),
            bottom: _content(context, shown, model, header: null),
          );
        }
        return _content(context, shown, model, header: header);
      },
    );
  }

  static int _pageOf(HadithDetailsModel model) =>
      model.previous == null ? 1 : model.previous! + 1;

  static int _pagesOf(HadithDetailsModel model) {
    final total = model.total ?? 0;
    final limit = model.limit ?? 0;
    return limit > 0 && total > limit ? (total / limit).ceil() : 1;
  }

  /// A scrolling column at the measure, centered in the space it has.
  Widget _column(
    BuildContext context,
    List<Widget> children, {
    bool top = false,
    Key? key,
  }) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = space.gutter(constraints.maxWidth);
        return ListView(
          key: key,
          padding: top
              ? EdgeInsets.fromLTRB(gutter, space.md, gutter, space.md)
              : context.scrollPadding(
                  EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
                ),
          children: [
            for (final child in children)
              ReadableWidth(maxWidth: HadithReader.measure, child: child),
          ],
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    HadithDetailsState shown,
    HadithDetailsModel? model, {
    required Widget? header,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final head = [if (header != null) HudaReveal(child: header)];
    // The states keep to the room under the header, so their actions
    // rest on screen. One lead per state at every size: the system's lamp
    // for a failure, the folio for empty.
    if (shown is HadithDetailsError) {
      return _state(
        context,
        'error',
        head,
        HudaErrorState(
          message: l10n.hadithLoadError,
          onRetry: _retry,
          retrying: _retrying,
        ),
      );
    }
    if (model != null && (model.data ?? const []).isEmpty) {
      return _state(
        context,
        'empty',
        head,
        HudaEmptyState(identity: hadithIdentity, title: l10n.hadithBookEmpty),
      );
    }
    final List<Widget> children;
    if (model != null) {
      final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
      final entries = [for (final data in model.data!) HadithEntry.of(data)];
      final page = _pageOf(model);
      final pages = _pagesOf(model);
      String? lastBab;
      final items = <Widget>[];
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        // A bab heads the hadith under it once, not on every one.
        final bab = entry.bab(arabicUi: arabicUi);
        final gap = i == 0 ? space.xl : space.md;
        if (bab != null && bab != lastBab) {
          items.add(
            HudaReveal(
              index: math.min(i + 1, 6),
              child: Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? space.lg : space.xxl,
                  bottom: space.md,
                ),
                child: HadithRubric(title: bab),
              ),
            ),
          );
        } else {
          items.add(SizedBox(height: gap));
        }
        lastBab = bab ?? lastBab;
        items.add(
          HudaReveal(
            index: math.min(i + 1, 6),
            child: HadithFolioCard(
              key: ValueKey('hadith-${entry.number}'),
              entry: entry,
              onShare: () => shareHadith(
                widget.overlayContext ?? context,
                entry: entry,
                collection: widget.collection,
                book: widget.book,
              ),
            ),
          ),
        );
      }
      children = [
        ...head,
        ...items,
        if (pages > 1) ...[
          SizedBox(height: space.xl),
          HadithPager(
            page: page,
            pages: pages,
            onPrevious: page > 1 ? () => _goTo(page - 1) : null,
            onNext: page < pages ? () => _goTo(page + 1) : null,
          ),
        ],
      ];
    } else {
      // Loading: the header stays, cards in the shape of what's coming.
      children = [
        ...head,
        SizedBox(height: space.xl),
        const HadithFolioCardSkeleton(announce: true),
        SizedBox(height: space.md),
        const HadithFolioCardSkeleton(),
        SizedBox(height: space.md),
        const HadithFolioCardSkeleton(),
      ];
    }
    final key = model == null ? 'loading' : 'loaded-${_pageOf(model)}';
    // Sequential: one page's text fades out before the next comes in, so
    // two pages never overlap.
    return HudaStateSwitcher(
      stateKey: key,
      sequential: true,
      alignment: Alignment.topCenter,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (model != null && notification.depth == 0) {
            final scrollable = Scrollable.maybeOf(notification.context!);
            _position = scrollable?.position;
          }
          return false;
        },
        child: _column(
          context,
          children,
          key: model == null
              ? null
              : PageStorageKey(
                  'hadith-reader-${widget.book.number}-${_pageOf(model)}',
                ),
        ),
      ),
    );
  }

  /// A full-page state under the book's header, in the room that's left:
  /// the state scrolls and keeps its actions above the bottom inset.
  Widget _state(
    BuildContext context,
    String key,
    List<Widget> head,
    Widget state,
  ) {
    final space = context.tokens.space;
    return HudaStateSwitcher(
      stateKey: key,
      sequential: true,
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = space.gutter(constraints.maxWidth);
          final insets = MediaQuery.paddingOf(context);
          return CustomScrollView(
            slivers: [
              if (head.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    gutter + insets.left,
                    space.md,
                    gutter + insets.right,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: ReadableWidth(
                      maxWidth: HadithReader.measure,
                      child: head.single,
                    ),
                  ),
                ),
              SliverFillRemaining(hasScrollBody: true, child: state),
            ],
          );
        },
      ),
    );
  }
}

/// The open book's header: which book (its number as the eyebrow, its
/// names), the hadith it covers and the page, over a ruled band that inks
/// itself in from the middle when the book opens.
class HadithBookHeader extends StatelessWidget {
  const HadithBookHeader({
    super.key,
    required this.collection,
    required this.book,
    this.page = 1,
    this.pages,
    this.compact = false,
  });

  final HadithCollectionRef collection;
  final HadithBookRef book;
  final int page;

  /// Null while the page loads.
  final int? pages;

  /// Short windows: no eyebrow, one line of meta.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final first = book.firstHadith;
    final last = book.lastHadith;
    final meta = [
      if (first != null && last != null) l10n.hadithRange('$first', '$last'),
      if ((pages ?? 1) > 1) l10n.hadithPageOf(page, pages!),
    ].join('  ·  ');
    final arabic = book.arabicTitle;
    final rule = HadithInk(
      duration: const Duration(milliseconds: 700),
      builder: (context, ink) => SizedBox(
        height: 12,
        width: double.infinity,
        child: Ornament(
          painter: _InkRulePainter(
            style: OrnamentStyle.of(context),
            inkOf: ink,
          ),
        ),
      ),
    );
    // Short windows: one line, so the hadith start on the first screen.
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  // Arabic first, when it differs from the title.
                  if (!arabicUi && arabic != null && arabic != book.title)
                    TextSpan(
                      text: '$arabic  ·  ',
                      style: context.type.arabicLabel.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  TextSpan(
                    text: book.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    TextSpan(
                      text: '  ·  $meta',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: space.xs),
          rule,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          HudaEyebrow(
            book.number == 'introduction'
                ? collection.title
                : l10n.hadithBookNumber(book.shownNumber),
          ),
          SizedBox(height: space.xs),
        ],
        if (!arabicUi && arabic != null && arabic != book.title)
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: context.type.arabicTitle.copyWith(color: scheme.onSurface),
          ),
        Semantics(
          header: true,
          child: Text(
            book.title,
            style:
                (compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(color: scheme.onSurface),
          ),
        ),
        if (meta.isNotEmpty) ...[
          SizedBox(height: space.xxs),
          AnimatedSwitcher(
            duration: context.tokens.motion.of(
              context,
              context.tokens.motion.medium,
            ),
            child: Text(
              meta,
              key: ValueKey(meta),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        SizedBox(height: space.md),
        rule,
      ],
    );
  }
}

/// The header's ruled band: a gilt double rule drawn out from its middle,
/// with a small seal where the ink starts.
class _InkRulePainter extends CustomPainter {
  _InkRulePainter({required this.style, required this.inkOf})
    : super(repaint: inkOf);

  final OrnamentStyle style;
  final ValueListenable<double> inkOf;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(inkOf.value);
    final mid = size.width / 2;
    final y = size.height / 2;
    final half = mid * t;
    final line = style.copyWith(stroke: style.stroke * 0.8).line;
    for (final dy in [-2.5, 2.5]) {
      canvas
        ..drawLine(Offset(mid - half, y + dy), Offset(mid - 9, y + dy), line)
        ..drawLine(Offset(mid + 9, y + dy), Offset(mid + half, y + dy), line);
    }
    canvas.drawCircle(Offset(mid, y), 4.5, line);
    canvas.drawCircle(Offset(mid, y), 2, style.fill());
  }

  @override
  bool shouldRepaint(_InkRulePainter old) =>
      old.style != style || old.inkOf != inkOf;
}

/// After a page's last hadith: the page and the way to the previous and
/// next ones. Next is lit; it's where reading goes.
class HadithPager extends StatelessWidget {
  const HadithPager({
    super.key,
    required this.page,
    required this.pages,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    // Chevrons mirror themselves in RTL (matchTextDirection).
    const back = Icons.chevron_left_rounded;
    const forward = Icons.chevron_right_rounded;
    return Semantics(
      container: true,
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.center,
        overflowSpacing: space.sm,
        spacing: space.sm,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('hadith-previous-page'),
            onPressed: onPrevious,
            icon: const Icon(back),
            label: Text(l10n.previous),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: space.sm),
            child: Text(
              l10n.hadithPageOf(page, pages),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.icon(
            key: const ValueKey('hadith-next-page'),
            onPressed: onNext,
            icon: const Icon(forward),
            label: Text(l10n.next),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}
