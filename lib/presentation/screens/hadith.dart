import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/hadith/hadith_cubit.dart';
import 'package:huda/data/models/hadith_books_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hadith/hadith_collection_tile.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';

class Hadith extends StatefulWidget {
  const Hadith({super.key});

  static const double maxContentWidth = 1280;

  @override
  State<Hadith> createState() => _HadithState();
}

class _HadithState extends State<Hadith> {
  bool _retrying = false;
  HadithState? _failure;

  void _retry() {
    setState(() => _retrying = true);
    context.read<HadithCubit>().fetchHadithBooks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return HudaRevealScope(
      child: BlocConsumer<HadithCubit, HadithState>(
        listener: (context, state) {
          if (state is! HadithLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          if (state is HadithError || state is HadithOffline) {
            _failure = state;
          }
          final failure = _failure;
          final shown = _retrying && state is HadithLoading && failure != null
              ? failure
              : state;
          Widget landing(List<Widget> slivers) => HadithInk(
            builder: (context, ink) => HudaLandingScaffold(
              leading: canPop ? const BackButton() : null,
              eyebrow: l10n.hadithCollections,
              title: l10n.hadith,
              art: (style) => HadithFolioPainter(style: style, inkOf: ink),
              contentMaxWidth: Hadith.maxContentWidth,
              slivers: slivers,
            ),
          );
          if (TabletopSplit.applies(context) &&
              (shown is HadithLoaded || shown is HadithLoading)) {
            final loaded = shown is HadithLoaded ? shown : null;
            return TabletopSplit(
              top: landing([
                _Page(
                  tight: true,
                  children: loaded == null
                      ? [_skeletonGrid(6, maxColumns: 3)]
                      : _sections(context, loaded.hadithBooks, _Part.six),
                ),
              ]),
              bottom: CustomScrollView(
                slivers: [
                  _Page(
                    children: loaded == null
                        ? [_skeletonLabel(), _skeletonGrid(9)]
                        : _sections(context, loaded.hadithBooks, _Part.rest),
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

  Object _stateKey(HadithState state) => switch (state) {
    HadithLoaded() => 'loaded',
    HadithError() => 'error',
    HadithOffline() => 'offline',
    _ => 'loading',
  };

  Widget _body(BuildContext context, HadithState state) {
    final l10n = AppLocalizations.of(context)!;
    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: true, child: child);
    return switch (state) {
      HadithLoaded(:final hadithBooks) => _Page(
        children: _sections(context, hadithBooks, _Part.all),
      ),
      HadithError() => fill(
        HudaErrorState(
          message: l10n.hadithLoadError,
          onRetry: _retry,
          retrying: _retrying,
        ),
      ),
      HadithOffline() => fill(
        HudaOfflineState(onRetry: _retry, retrying: _retrying),
      ),
      _ => _Page(
        children: [
          _skeletonLabel(),
          _skeletonGrid(6, maxColumns: 3),
          _skeletonLabel(),
          _skeletonGrid(9),
        ],
      ),
    };
  }

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

  Widget _skeletonGrid(int count, {int maxColumns = 4}) => Builder(
    builder: (context) => SliverAdaptiveGrid(
      minTileWidth: _minTileWidth(context),
      spacing: context.tokens.space.md,
      maxColumns: maxColumns,
      itemCount: count,
      itemBuilder: (context, i) =>
          HadithCollectionTileSkeleton(announce: i == 0),
    ),
  );

  static double _minTileWidth(BuildContext context) => AdaptiveGrid.tileWidth(
    context,
    context.windowClass.isCompactHeight ? 260 : 300,
  );

  List<Widget> _sections(
    BuildContext context,
    HadithBooksModel model,
    _Part part,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final language = Localizations.localeOf(context).languageCode;
    final all = [
      for (final data in model.data ?? const <Data>[])
        HadithCollectionRef.of(data, language),
    ];
    final bySlug = {for (final c in all) c.slug: c};
    final six = [for (final slug in hadithSixBooks) ?bySlug[slug]];
    final rest = [
      for (final c in all)
        if (!hadithSixBooks.contains(c.slug)) c,
    ];

    Widget grid(
      List<HadithCollectionRef> items, {
      int revealFrom = 0,
      int maxColumns = 4,
    }) => Builder(
      builder: (context) => SliverAdaptiveGrid(
        minTileWidth: _minTileWidth(context),
        spacing: space.md,
        maxColumns: maxColumns,
        itemCount: items.length,
        itemBuilder: (context, i) => HudaReveal(
          index: revealFrom + i,
          child: HadithCollectionTile(collection: items[i]),
        ),
      ),
    );
    Widget label(String text, {required double top, int reveal = 0}) =>
        SliverPadding(
          padding: EdgeInsets.only(top: top, bottom: space.xs),
          sliver: SliverToBoxAdapter(
            child: HudaReveal(index: reveal, child: HudaSectionHeader(text)),
          ),
        );

    final showSix = six.isNotEmpty && part != _Part.rest;
    final showRest = rest.isNotEmpty && part != _Part.six;
    return [
      if (showSix) ...[
        label(l10n.hadithSixBooks, top: space.lg),
        grid(six, maxColumns: 3),
      ],
      if (showRest) ...[
        label(
          showSix ? l10n.hadithMoreCollections : l10n.hadithCollections,
          top: showSix ? space.xl : space.lg,
          reveal: showSix ? six.length : 0,
        ),
        grid(rest, revealFrom: showSix ? six.length : 0),
      ],
    ];
  }
}

enum _Part { all, six, rest }

class _Page extends StatelessWidget {
  const _Page({required this.children, this.tight = false});

  final List<Widget> children;

  final bool tight;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        final width = constraints.crossAxisExtent;
        final gutter = space.gutter(width);
        final extra = math.max(0.0, (width - Hadith.maxContentWidth) / 2);
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
