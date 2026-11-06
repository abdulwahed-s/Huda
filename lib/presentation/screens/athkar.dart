import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/data/models/ahtkar_item_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_category_tile.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/athkar/athkar_tabletop.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The Athkar landing screen: the Hisn al-Muslim chapters, the daily ones
/// first, with the search in the page. Landing tier; the sun rises in the
/// header as it opens. See `design/features/athkar/brief.md`.
class AthkarScreen extends StatefulWidget {
  const AthkarScreen({super.key});

  /// Content is capped at this width and centered, with the header.
  static const double maxContentWidth = 1280;

  @override
  State<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends State<AthkarScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// After a tap on Retry, until the cubit answers: the failure stays on
  /// screen with "Retrying…" instead of turning into a skeleton.
  bool _retrying = false;
  AthkarState? _failure;

  @override
  void initState() {
    super.initState();
    context.read<AthkarCubit>().loadAthkar();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _retrying = true);
    context.read<AthkarCubit>().loadAthkar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return HudaRevealScope(
      child: BlocConsumer<AthkarCubit, AthkarState>(
        listener: (context, state) {
          if (state is! AthkarLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          if (state is AthkarError || state is AthkarOffline) {
            _failure = state;
          }
          final failure = _failure;
          final shown = _retrying && state is AthkarLoading && failure != null
              ? failure
              : state;
          Widget landing(List<Widget> slivers) => AthkarRisingSun(
            builder: (context, rise) => HudaLandingScaffold(
              leading: canPop ? const BackButton() : null,
              eyebrow: l10n.athkarSource,
              title: l10n.athkar,
              art: (style) => AthkarHorizonPainter(style: style, riseOf: rise),
              contentMaxWidth: AthkarScreen.maxContentWidth,
              slivers: slivers,
            ),
          );
          // Tabletop: the search with the daily chapters (or, while
          // searching, every result: the keyboard takes the lower half)
          // above the band; the rest of the chapters below it. Loading
          // takes the same shape.
          final tabletop = AthkarTabletop.applies(context);
          if (tabletop && shown is AthkarLoading) {
            return AthkarTabletop(
              top: landing([
                _AthkarPage(
                  tight: true,
                  children: [_skeletonGrid(4, maxColumns: 2)],
                ),
              ]),
              bottom: CustomScrollView(
                slivers: [
                  _AthkarPage(children: [_skeletonLabel(), _skeletonGrid(18)]),
                ],
              ),
            );
          }
          if (tabletop && shown is AthkarLoaded) {
            final searching = _query.isNotEmpty;
            return AthkarTabletop(
              top: landing([
                _AthkarPage(
                  tight: true,
                  children: [
                    SliverToBoxAdapter(child: _searchField()),
                    ..._chapters(
                      context,
                      shown.athkar,
                      part: searching ? _Part.all : _Part.daily,
                    ),
                  ],
                ),
              ]),
              bottom: CustomScrollView(
                slivers: [
                  if (!searching)
                    _AthkarPage(
                      children: _chapters(
                        context,
                        shown.athkar,
                        part: _Part.rest,
                      ),
                    ),
                ],
              ),
            );
          }
          return landing([
            SliverHudaStateSwitcher(
              stateKey: _stateKey(shown),
              sliver: _body(context, shown),
            ),
          ]);
        },
      ),
    );
  }

  Object _stateKey(AthkarState state) => switch (state) {
    AthkarLoaded() => 'loaded',
    AthkarError() => 'error',
    AthkarOffline() => 'offline',
    _ => 'loading',
  };

  Widget _body(BuildContext context, AthkarState state) {
    final l10n = AppLocalizations.of(context)!;
    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: true, child: child);
    return switch (state) {
      AthkarLoaded(:final athkar) => _AthkarPage(
        children: [
          SliverToBoxAdapter(child: _searchField()),
          ..._chapters(context, athkar),
        ],
      ),
      AthkarError() => fill(
        HudaErrorState(
          identity: athkarIdentity,
          message: l10n.athkarLoadError,
          onRetry: _retry,
          retrying: _retrying,
        ),
      ),
      AthkarOffline() => fill(
        HudaOfflineState(onRetry: _retry, retrying: _retrying),
      ),
      // The page's real shape: the search, "Every day", and a long run of
      // chapters (Hisn al-Muslim has over a hundred), not a short list.
      _ => _AthkarPage(
        children: [
          const SliverToBoxAdapter(
            child: HudaSkeleton(
              announce: false,
              child: HudaSkeletonBlock(height: 56),
            ),
          ),
          _skeletonLabel(),
          _skeletonGrid(4, maxColumns: 2),
          _skeletonLabel(),
          _skeletonGrid(18),
        ],
      ),
    };
  }

  /// A section label's place while loading.
  Widget _skeletonLabel() => Builder(
    builder: (context) {
      final space = context.tokens.space;
      return SliverPadding(
        padding: EdgeInsets.only(top: space.lg, bottom: space.sm),
        sliver: const SliverToBoxAdapter(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: HudaSkeleton(
              child: HudaSkeletonBlock(width: 120, height: 12),
            ),
          ),
        ),
      );
    },
  );

  /// Loading tiles in the chapters' grid.
  Widget _skeletonGrid(int count, {int maxColumns = 4}) => Builder(
    builder: (context) => SliverAdaptiveGrid(
      minTileWidth: _minTileWidth(context),
      spacing: context.tokens.space.md,
      maxColumns: maxColumns,
      itemCount: count,
      itemBuilder: (context, i) =>
          AthkarCategoryTileSkeleton(announce: i == 0),
    ),
  );

  /// Tiles at least this wide, so long titles don't wrap into narrow
  /// columns (owner round 1): one column on phones, two on portrait
  /// tablets, three on landscape tablets and laptops. Short windows (phone
  /// and Duo-cover landscape) take two narrower ones.
  static double _minTileWidth(BuildContext context) => AdaptiveGrid.tileWidth(
    context,
    context.windowClass.isCompactHeight ? 260 : 320,
  );

  /// The search, the page's full width (owner round 1). On a half-open
  /// vertical fold (book) it keeps to the leading half, off the crease.
  Widget _searchField() => LayoutBuilder(
    builder: (context, constraints) {
      final fold = FoldInfo.of(context);
      var cap = double.infinity;
      if (fold.isBook) {
        // The page is centered in the window.
        final window = MediaQuery.sizeOf(context).width;
        final left = (window - constraints.maxWidth) / 2;
        final gap = context.tokens.space.md / 2;
        final leading = Directionality.of(context) == TextDirection.rtl
            ? left + constraints.maxWidth - fold.end
            : fold.start - left;
        cap = math.min(cap, leading - gap);
      }
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(200.0, cap)),
          child: AthkarSearchField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
      );
    },
  );

  /// The chapters under the search: the daily ones, then the rest; or the
  /// search results.
  List<Widget> _chapters(
    BuildContext context,
    List<AthkarItem> athkar, {
    _Part part = _Part.all,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final query = _query.toLowerCase();

    Widget grid(
      List<AthkarItem> items, {
      int revealFrom = 0,
      int maxColumns = 4,
    }) => Builder(
      // Sized by the space the grid is in (a tabletop half, not the
      // window).
      builder: (context) => SliverAdaptiveGrid(
        minTileWidth: _minTileWidth(context),
        spacing: space.md,
        maxColumns: maxColumns,
        itemCount: items.length,
        itemBuilder: (context, i) => HudaReveal(
          index: revealFrom + i,
          child: AthkarCategoryTile(item: items[i]),
        ),
      ),
    );
    Widget label(Widget child, {double top = 0}) => SliverPadding(
      padding: EdgeInsets.only(top: top, bottom: space.xs),
      sliver: SliverToBoxAdapter(child: child),
    );

    if (query.isNotEmpty) {
      final results = [
        for (final item in athkar)
          if (item.titleAr.toLowerCase().contains(query) ||
              item.titleEn.toLowerCase().contains(query))
            item,
      ];
      if (results.isEmpty) {
        // Right under the field, so it shows on short windows too; the
        // field's × clears the search.
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: HudaEmptyState(
                identity: athkarIdentity,
                title: l10n.noResultsFound,
                message: l10n.tryDifferentSearch,
              ),
            ),
          ),
        ];
      }
      return [
        label(
          Semantics(
            liveRegion: true,
            child: HudaSectionHeader(l10n.searchResultsFound(results.length)),
          ),
          top: space.lg,
        ),
        grid(results),
      ];
    }

    final byId = {for (final item in athkar) item.id: item};
    final daily = [for (final id in athkarDailyChapters) ?byId[id]];
    final others = [
      for (final item in athkar)
        if (!athkarDailyChapters.contains(item.id)) item,
    ];
    final showDaily = daily.isNotEmpty && part != _Part.rest;
    final showOthers = others.isNotEmpty && part != _Part.daily;
    return [
      if (showDaily) ...[
        label(HudaSectionHeader(l10n.athkarDaily), top: space.lg),
        // Two by two: the four daily chapters stay wide and even.
        grid(daily, maxColumns: 2),
      ],
      if (showOthers) ...[
        label(
          HudaSectionHeader(l10n.athkarOccasions),
          top: showDaily ? space.xl : space.lg,
        ),
        grid(others, revealFrom: showDaily ? daily.length : 0),
      ],
    ];
  }
}

/// Which chapters a part of a split (tabletop) page shows.
enum _Part { all, daily, rest }

/// The page's content column: the gutters and side insets, capped at
/// [AthkarScreen.maxContentWidth] and centered, ending above the bottom
/// inset.
class _AthkarPage extends StatelessWidget {
  const _AthkarPage({required this.children, this.tight = false});

  final List<Widget> children;

  /// Above a tabletop band: tighter top and bottom, no bottom inset.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        final width = constraints.crossAxisExtent;
        final gutter = space.gutter(width);
        final extra = math.max(0.0, (width - AthkarScreen.maxContentWidth) / 2);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter + insets.left + extra,
            tight ? space.sm : space.lg,
            gutter + insets.right + extra,
            tight ? space.sm : space.xxl + insets.bottom,
          ),
          sliver: SliverMainAxisGroup(slivers: children),
        );
      },
    );
  }
}
