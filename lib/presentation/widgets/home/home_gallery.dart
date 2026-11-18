import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:prayer_time_plus/prayer_time_plus.dart' show Prayer;

/// The gallery: Home's tools in a grid whose columns follow the space
/// (even across a fold, the middle gap on the crease). Classic shows them
/// as square plates; the focused styles ([medallions]) as round medallions,
/// smaller, under what the style leads with. Quran Kit unfolds its tools
/// under its row; "View More" (only when tools were moved there) unfolds
/// the rest into the same grid, right after it, filling its row first.
/// Both remember being open across a fold, a rotation or a resize.
class HomeGallery extends StatefulWidget {
  const HomeGallery({
    super.key,
    required this.tools,
    required this.more,
    required this.actions,
    this.lead = const [],
    this.medallions = false,
    this.lampOffset = 0,
    this.showPrayerLine = true,
    this.spansFold = true,
    this.skip = 0,
    this.take,
  });

  /// The tools on Home, in the person's order, and the ones in View More.
  final List<HomeFeatureDefinition> tools;
  final List<HomeFeatureDefinition> more;
  final HomeActions actions;

  /// Tiles that come first (Quran Journey's Quran tools).
  final List<Widget> lead;

  /// Round medallions (the focused styles) instead of square plates.
  final bool medallions;

  /// Where the lamplighter is when it reaches this gallery's first plate.
  final int lampOffset;

  /// The Prayer plate says when the next prayer is (off where the page
  /// already shows it).
  final bool showPrayerLine;

  /// Whether the grid crosses the window's fold (false inside a pane).
  final bool spansFold;

  /// Shows only part of the gallery (a tabletop half): [skip] tiles, then
  /// at most [take].
  final int skip;
  final int? take;

  /// A medallion tile's narrowest width at 100% text.
  static double medallionWidth(BuildContext context) =>
      context.windowClass.isCompact || context.windowClass.isCompactHeight
      ? 80
      : 96;

  @override
  State<HomeGallery> createState() => _HomeGalleryState();
}

class _HomeGalleryState extends State<HomeGallery>
    with TickerProviderStateMixin {
  static const _kitKey = 'home-quran-kit-open';
  static const _moreKey = 'home-view-more-open';

  bool _kitOpen = false;
  bool _moreOpen = false;

  // One controller per unfold, run forward to open and back to close, so
  // both ways move the same: the panel or the extra rows open by height
  // and fade, View More's tiles arrive one after another and leave in
  // reverse.
  late final AnimationController _kit = AnimationController(vsync: this)
    ..addStatusListener(_settled);
  late final AnimationController _more = AnimationController(vsync: this)
    ..addStatusListener(_settled);
  bool _restored = false;

  void _settled(AnimationStatus status) {
    // Closed: drop what was kept on screen while it folded away.
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = context.tokens;
    final duration = tokens.motion.of(context, tokens.motion.long);
    _kit.duration = duration;
    _more.duration = duration;
    if (_restored) return;
    _restored = true;
    final storage = PageStorage.maybeOf(context);
    _kitOpen =
        storage?.readState(context, identifier: _kitKey) as bool? ?? _kitOpen;
    _moreOpen =
        storage?.readState(context, identifier: _moreKey) as bool? ?? _moreOpen;
    _kit.value = _kitOpen ? 1 : 0;
    _more.value = _moreOpen ? 1 : 0;
  }

  @override
  void dispose() {
    _kit.dispose();
    _more.dispose();
    super.dispose();
  }

  void _toggle(String key) {
    final kit = key == _kitKey;
    setState(() {
      if (kit) {
        _kitOpen = !_kitOpen;
      } else {
        _moreOpen = !_moreOpen;
      }
    });
    final controller = kit ? _kit : _more;
    final open = kit ? _kitOpen : _moreOpen;
    if (controller.duration == Duration.zero) {
      controller.value = open ? 1 : 0;
    } else if (open) {
      controller.forward();
    } else {
      controller.reverse();
    }
    final storage = PageStorage.maybeOf(context);
    storage?.writeState(context, _kitOpen, identifier: _kitKey);
    storage?.writeState(context, _moreOpen, identifier: _moreKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final round = widget.medallions;
    Widget plate(
      HeaderArtBuilder art, {
      int index = 0,
      bool highlighted = false,
    }) => HomePlate(
      art: art,
      index: index,
      highlighted: highlighted,
      round: round,
    );
    final all = <Widget>[...widget.lead];
    var kitIndex = -1;
    var lamp = widget.lampOffset + widget.lead.length;
    for (final tool in widget.tools) {
      final index = lamp++;
      if (tool.id == HomeFeatureId.quranKit) {
        kitIndex = all.length;
        all.add(
          HomeToolTile(
            key: const ValueKey('home-tool-quranKit'),
            title: tool.title,
            plate: plate(
              homeToolArt(tool.id),
              index: index,
              highlighted: _kitOpen,
            ),
            medallion: round,
            expanded: _kitOpen,
            onTap: () => _toggle(_kitKey),
          ),
        );
        continue;
      }
      all.add(
        HomeToolTile(
          key: ValueKey('home-tool-${tool.id.name}'),
          title: tool.title,
          plate: plate(homeToolArt(tool.id), index: index),
          medallion: round,
          meta: tool.id == HomeFeatureId.prayerTimes && widget.showPrayerLine
              ? const HomeNextPrayerLine()
              : null,
          onTap: tool.onTap,
        ),
      );
    }
    int? revealFrom;
    if (widget.more.isNotEmpty) {
      all.add(
        HomeToolTile(
          key: const ValueKey('home-view-more'),
          title: l10n.viewMore,
          plate: HomeMorePlate(
            tools: widget.more,
            index: lamp,
            highlighted: _moreOpen,
            round: round,
          ),
          medallion: round,
          expanded: _moreOpen,
          onTap: () => _toggle(_moreKey),
        ),
      );
      // Open (or still folding away): the rest follow in the same grid,
      // filling View More's row before starting a new one.
      if (_moreOpen || !_more.isDismissed) {
        revealFrom = all.length;
        for (final tool in widget.more) {
          all.add(
            HomeToolTile(
              key: ValueKey('home-tool-${tool.id.name}'),
              title: tool.title,
              plate: plate(homeToolArt(tool.id)),
              medallion: round,
              onTap: tool.onTap,
            ),
          );
        }
      }
    }
    // The columns are counted for the closed grid, so opening View More
    // never changes them.
    final closed = revealFrom ?? all.length;

    final start = widget.skip.clamp(0, all.length);
    final end = math.min(all.length, start + (widget.take ?? all.length));
    final tiles = all.sublist(start, end);
    final localKit = kitIndex >= start && kitIndex < end
        ? kitIndex - start
        : -1;
    final localReveal = revealFrom == null
        ? null
        : math.max(0, revealFrom - start);
    final kitShown = _kitOpen || !_kit.isDismissed;
    return HomeGrid(
      key: const ValueKey('home-feature-grid'),
      spansFold: widget.spansFold,
      minTileWidth: round ? HomeGallery.medallionWidth(context) : null,
      maxColumns: round ? 6 : 10,
      tiles: tiles,
      balanceCount: math.min(tiles.length, math.max(0, closed - start)),
      revealFrom: localReveal,
      reveal: localReveal == null ? null : _more,
      unfoldAfter: localKit >= 0 ? localKit : null,
      unfold: localKit >= 0 && kitShown
          ? HomeUnfold(
              animation: _kit,
              child: HomeQuranKitPanel(actions: widget.actions),
            )
          : null,
    );
  }
}

/// One tool: its plate over its name (and, for Prayer, when the next
/// prayer is). The whole tile is the button; it presses in and shows ink.
/// [expanded] marks a tile that unfolds something (Quran Kit, View More):
/// a chevron beside the name turns with it.
class HomeToolTile extends StatelessWidget {
  const HomeToolTile({
    super.key,
    required this.title,
    required this.plate,
    required this.onTap,
    this.meta,
    this.expanded,
    this.medallion = false,
  });

  final String title;
  final Widget plate;
  final VoidCallback onTap;
  final Widget? meta;
  final bool? expanded;

  /// A round medallion (the focused styles): smaller than a plate.
  final bool medallion;

  /// The widest a plate gets (smaller on short windows); wider tiles
  /// center it.
  static double maxPlate(BuildContext context) =>
      context.windowClass.isCompactHeight ? 88 : 132;

  /// The widest a medallion gets.
  static double maxMedallion(BuildContext context) =>
      context.windowClass.isCompact || context.windowClass.isCompactHeight
      ? 64
      : 76;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final expanded = this.expanded;
    final meta = this.meta;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 104;
        final style =
            (wide ? theme.textTheme.titleSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: theme.colorScheme.onSurface);
        final label = Text.rich(
          TextSpan(
            children: [
              TextSpan(text: title),
              if (expanded != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: tokens.motion.of(context, tokens.motion.short),
                    curve: tokens.motion.standard,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
        // A word wider than the tile (a long German name, large text) never
        // breaks inside: the label lays out at that word's width and the
        // block scales down to the tile. One measurement, no retrying.
        final room = constraints.maxWidth - tokens.space.xxs * 2;
        final word = _longestWord(context, title, style);
        final fitted = word <= room
            ? label
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(width: word + 1, child: label),
              );
        return Semantics(
          button: true,
          expanded: expanded,
          child: HudaPressable(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: tokens.radius.control,
                child: Padding(
                  padding: EdgeInsets.all(tokens.space.xxs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: medallion
                              ? maxMedallion(context)
                              : maxPlate(context),
                        ),
                        child: plate,
                      ),
                      SizedBox(height: tokens.space.xs),
                      fitted,
                      if (meta != null) ...[
                        SizedBox(height: tokens.space.xxs / 2),
                        meta,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The width of [title]'s longest word in [style] at the text scale (an
/// expand chevron included).
double _longestWord(BuildContext context, String title, TextStyle? style) {
  final scaler = MediaQuery.textScalerOf(context);
  var widest = 0.0;
  for (final word in title.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest;
}

/// Rows of tiles: as many columns as fit [minTileWidth] (widened with the
/// text scale), an even count with a fold and the middle gap on the crease
/// when the grid crosses it ([spansFold]; it assumes it's centered in the
/// window, as Home's grids are). [unfold] sits full width under the row
/// holding the tile at [unfoldAfter].
class HomeGrid extends StatelessWidget {
  const HomeGrid({
    super.key,
    required this.tiles,
    this.unfold,
    this.unfoldAfter,
    this.minTileWidth,
    this.maxColumns = 10,
    this.spansFold = true,
    this.rowGap,
    this.balanceCount,
    this.revealFrom,
    this.reveal,
  });

  final List<Widget> tiles;
  final Widget? unfold;
  final int? unfoldAfter;

  /// How many tiles the rows are balanced for: the closed grid's, so tiles
  /// that unfold into it never change its columns. All of them when null.
  final int? balanceCount;

  /// Tiles from [revealFrom] on come and go with [reveal] (View More's):
  /// each fades and grows in turn (and leaves in reverse), and the rows
  /// made only of them open and close by height.
  final int? revealFrom;
  final Animation<double>? reveal;

  /// Between rows; the medium space when null.
  final double? rowGap;

  /// Defaults to [defaultTileWidth].
  final double? minTileWidth;
  final int maxColumns;
  final bool spansFold;

  /// Plates on phones stay phone-sized (four across); wider windows get
  /// larger ones rather than a field of small ones.
  /// Short windows (phone and Duo landscape) keep them small too, so more
  /// than a row shows.
  static double defaultTileWidth(BuildContext context) {
    final window = context.windowClass;
    return window.isCompact || window.isCompactHeight ? 76 : 112;
  }

  /// How many columns a grid of [width] gets.
  static int columnsFor(
    BuildContext context,
    double width, {
    double? minTileWidth,
    int maxColumns = 10,
    bool spansFold = true,
    int? itemCount,
  }) {
    final fold = spansFold ? FoldInfo.of(context) : FoldInfo.none;
    final foldGap = fold.splitsHorizontally ? fold.end - fold.start : 0.0;
    final most = AdaptiveGrid.columns(
      width: width - foldGap,
      minTileWidth: _scaled(context, minTileWidth ?? defaultTileWidth(context)),
      spacing: _spacing(context, width),
      maxColumns: maxColumns,
      preferEven: fold.hasFold,
    );
    final n = itemCount;
    // One row or less keeps the full count (a short row stays in place).
    if (n == null || n <= most) return most;
    // Balanced rows: six tools in a five-column space sit 3 + 3, not 5 + 1.
    final rows = (n / most).ceil();
    var columns = (n / rows).ceil();
    if (fold.hasFold && columns.isOdd && columns < most) columns++;
    return columns;
  }

  /// A tile's minimum width at the text scale: labels are short words
  /// under a plate, so tiles widen almost with the text (two across on a
  /// phone at 200%), unlike `AdaptiveGrid.tileWidth`'s half pace.
  static double _scaled(BuildContext context, double base) {
    final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    return base * (1 + (scale - 1).clamp(0.0, 1.0) * 0.85);
  }

  static double _spacing(BuildContext context, double width) {
    final space = context.tokens.space;
    return width >= 600 ? space.md : space.sm;
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fold = spansFold ? FoldInfo.of(context) : FoldInfo.none;
        final foldGap = fold.splitsHorizontally ? fold.end - fold.start : 0.0;
        final spacing = _spacing(context, width);
        final columns = columnsFor(
          context,
          width,
          minTileWidth: minTileWidth,
          maxColumns: maxColumns,
          spansFold: spansFold,
          itemCount: balanceCount ?? tiles.length,
        );
        final reveal = this.reveal;
        final from = reveal == null ? null : revealFrom;
        Widget tile(int index) {
          final child = tiles[index];
          if (from == null || index < from) return child;
          final order = math.min(index - from, 8);
          final begin = order * 0.05;
          final t = reveal!.drive(
            CurveTween(
              curve: Interval(
                begin,
                math.min(1.0, begin + 0.6),
                curve: Curves.easeInOutCubic,
              ),
            ),
          );
          return FadeTransition(
            opacity: t,
            child: ScaleTransition(
              scale: t.drive(Tween<double>(begin: 0.88, end: 1)),
              child: child,
            ),
          );
        }

        final middle = columns.isEven && fold.splitsHorizontally
            ? columns ~/ 2
            : -1;
        final rows = (tiles.length / columns).ceil();
        final unfoldRow = unfoldAfter == null ? -1 : unfoldAfter! ~/ columns;
        // The first row made only of revealed tiles: from it on, the rows
        // open and close by height together.
        final firstRevealRow = from == null ? rows : (from / columns).ceil();
        final children = <Widget>[];
        final revealed = <Widget>[];
        for (var row = 0; row < rows; row++) {
          final into = row >= firstRevealRow ? revealed : children;
          if (row > 0) into.add(SizedBox(height: rowGap ?? space.md));
          final cells = <Widget>[];
          for (var column = 0; column < columns; column++) {
            if (column > 0) {
              cells.add(
                SizedBox(width: column == middle ? spacing + foldGap : spacing),
              );
            }
            final index = row * columns + column;
            cells.add(
              Expanded(
                child: index < tiles.length
                    ? tile(index)
                    : const SizedBox.shrink(),
              ),
            );
          }
          into.add(
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells),
          );
          if (row == unfoldRow && unfold != null) into.add(unfold!);
        }
        if (revealed.isNotEmpty) {
          // A curve that's its own mirror in time, so folding away moves
          // exactly as opening did, backwards.
          children.add(
            SizeTransition(
              sizeFactor: reveal!.drive(
                CurveTween(curve: Curves.easeInOutCubic),
              ),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: revealed,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      },
    );
  }
}

/// Something a tile unfolds (the Quran Kit's tools) under the tile's
/// row: it opens by height and fades in with [animation], and closes the
/// same way back (instant under reduce motion).
class HomeUnfold extends StatelessWidget {
  const HomeUnfold({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A curve that's its own mirror in time: closing moves exactly as
    // opening did, backwards.
    return SizeTransition(
      key: const ValueKey('home-unfold'),
      sizeFactor: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(
            curve: const Interval(0.15, 0.85, curve: Curves.easeInOut),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: context.tokens.space.md),
          child: child,
        ),
      ),
    );
  }
}

/// The View More plate: the first four tools inside it, small, as lamps
/// behind a door.
class HomeMorePlate extends StatelessWidget {
  const HomeMorePlate({
    super.key,
    required this.tools,
    this.index = 0,
    this.highlighted = false,
    this.round = false,
  });

  final List<HomeFeatureDefinition> tools;
  final int index;
  final bool highlighted;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final arts = [
      for (final tool in tools) homeToolArt(tool.id),
    ].take(4).toList();
    return HomePlate(
      index: index,
      highlighted: highlighted,
      round: round,
      art: (style) => _QuartetPainter(style: style, arts: arts),
    );
  }
}

class _QuartetPainter extends CustomPainter {
  _QuartetPainter({required this.style, required this.arts});

  final OrnamentStyle style;
  final List<CustomPainter Function(OrnamentStyle)> arts;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 2;
    final pad = cell * 0.12;
    final inner = OrnamentStyle(
      color: style.color,
      render: style.render,
      stroke: math.max(0.8, style.stroke * 0.75),
    );
    // Too small for the arts (a chip's plate): four little lamps.
    if (cell - pad * 2 < 18) {
      for (var i = 0; i < 4; i++) {
        final center = Offset(
          (i % 2) * cell + cell / 2,
          (i ~/ 2) * cell + cell / 2,
        );
        final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: cell * 0.62,
            height: cell * 0.62,
          ),
          Radius.circular(cell * 0.14),
        );
        style.draw(canvas, Path()..addRRect(box));
        canvas.drawCircle(center, cell * 0.1, style.fill());
      }
      return;
    }
    for (var i = 0; i < arts.length && i < 4; i++) {
      final origin = Offset((i % 2) * cell + pad, (i ~/ 2) * cell + pad);
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      arts[i](inner).paint(canvas, Size.square(cell - pad * 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_QuartetPainter old) =>
      old.style != style || old.arts.length != arts.length;
}

/// Quran Kit unfolded: the Quran, its recitations, the radio and
/// bookmarks, then where the person left off.
class HomeQuranKitPanel extends StatelessWidget {
  const HomeQuranKitPanel({
    super.key,
    required this.actions,
    this.showReading = true,
  });

  final HomeActions actions;

  /// Quran Journey shows the last read in its own card.
  final bool showReading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('home-quran-kit-panel'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: tokens.radius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeQuranTools(actions: actions),
            SizedBox(height: tokens.space.md),
            HomeContinueRows(actions: actions, showReading: showReading),
          ],
        ),
      ),
    );
  }
}

/// The Quran's four tools as small plates.
class HomeQuranTools extends StatelessWidget {
  const HomeQuranTools({super.key, required this.actions});

  final HomeActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tools = [
      (HomeQuranTool.quran, l10n.quran, actions.openQuran),
      (HomeQuranTool.audio, l10n.quranAudio, actions.openAudio),
      (HomeQuranTool.radio, l10n.quranRadio, actions.openRadio),
      (HomeQuranTool.bookmarks, l10n.bookmarks, actions.openBookmarks),
    ];
    return HomeGrid(
      spansFold: false,
      maxColumns: 4,
      minTileWidth: 64,
      tiles: [
        for (final (tool, title, onTap) in tools)
          HomeToolTile(
            key: ValueKey('home-quran-${tool.name}'),
            title: title,
            plate: HomePlate(art: homeQuranToolArt(tool)),
            onTap: onTap,
          ),
      ],
    );
  }
}

/// Where the person left off: the last ayah read, the last reciter, the
/// last station, each one tap away; a quiet line when there's nothing yet.
class HomeContinueRows extends StatelessWidget {
  const HomeContinueRows({
    super.key,
    required this.actions,
    this.showReading = true,
    this.eyebrow,
    this.hideWhenEmpty = false,
  });

  final HomeActions actions;
  final bool showReading;

  /// Above the rows; "Pick up where you left off" when null.
  final String? eyebrow;

  /// Nothing at all, rather than a quiet line, when there's nothing yet.
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final data = state is HomeLoaded ? state : null;
        final summary = data?.lastReadSummary;
        final audio = data?.lastQuranAudio;
        final station = data?.lastRadioStation;
        final rows = <Widget>[
          if (showReading &&
              data?.hasLastReadPosition == true &&
              summary != null)
            _ContinueRow(
              key: const ValueKey('home-continue-reading'),
              tool: HomeQuranTool.quran,
              title: l10n.continueHome,
              meta:
                  '${quran.getSurahNameLocalized(summary['surahNumber'] as int, locale)}'
                  ' · ${l10n.ayahNumber(summary['ayahNumber'] as int? ?? 1)}',
              onTap: () => actions.openLastRead(summary),
            ),
          if (data?.hasLastQuranAudio == true && audio != null)
            _ContinueRow(
              key: const ValueKey('home-continue-listening'),
              tool: HomeQuranTool.audio,
              title: l10n.continueListening,
              meta: audio.reciterName,
              onTap: () => actions.openLastReciter(audio),
            ),
          if (data?.hasLastRadioStation == true && station != null)
            _ContinueRow(
              key: const ValueKey('home-continue-radio'),
              tool: HomeQuranTool.radio,
              title: l10n.continueRadio,
              meta: station.stationName,
              onTap: () => actions.openLastStation(station),
            ),
        ];
        final Widget body;
        if (rows.isEmpty && hideWhenEmpty) {
          body = const SizedBox(
            key: ValueKey('home-continue-hidden'),
            width: double.infinity,
          );
        } else if (rows.isEmpty) {
          body = Text(
            key: const ValueKey('home-continue-none'),
            l10n.noRecentActivityHome,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        } else {
          body = Column(
            key: ValueKey(rows.length),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              HudaEyebrow(eyebrow ?? l10n.continueActivityPrompt),
              SizedBox(height: tokens.space.xs),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Side by side once each row gets about 280.
                  final across = math.max(
                    1,
                    math.min(rows.length, (constraints.maxWidth / 280).floor()),
                  );
                  if (across == 1) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rows,
                    );
                  }
                  return Wrap(
                    spacing: tokens.space.xs,
                    runSpacing: tokens.space.xs,
                    children: [
                      for (final row in rows)
                        SizedBox(
                          width:
                              (constraints.maxWidth -
                                  tokens.space.xs * (across - 1)) /
                              across,
                          child: row,
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        }
        return HudaStateSwitcher(stateKey: rows.length, child: body);
      },
    );
  }
}

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({
    super.key,
    required this.tool,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final HomeQuranTool tool;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: context.tokens.radius.control,
      child: HudaContentRow(
        leading: HomePlate(art: homeQuranToolArt(tool), size: 40),
        title: title,
        meta: meta,
        onTap: onTap,
      ),
    );
  }
}

/// Under the Prayer plate: the next prayer and its time ("Asr 4:22 PM").
/// Nothing until there are times.
class HomeNextPrayerLine extends StatelessWidget {
  const HomeNextPrayerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is! PrayerTimesLoaded) return const SizedBox.shrink();
        return HomeNextPrayerBuilder(
          state: state,
          builder: (context, next) {
            if (next == null || next.started) return const SizedBox.shrink();
            final theme = Theme.of(context);
            final l10n = AppLocalizations.of(context)!;
            final time = next.tomorrow
                ? l10n.remindersNextTomorrow(next.time)
                : next.time;
            return Text(
              '${next.name} $time',
              key: const ValueKey('home-next-prayer-line'),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
        );
      },
    );
  }
}

/// The prayer Home points to: its name, its time on the place's clock, the
/// moment itself, whether it has just begun ([started], the minutes since
/// in [minutesSince]), and whether it falls on the place's next day
/// ([tomorrow]: Fajr after Isha).
typedef HomeNextPrayer = ({
  Prayer prayer,
  String name,
  String time,
  DateTime instant,
  bool started,
  int minutesSince,
  bool tomorrow,
});

/// Builds with the prayer Home points to. While today has one left it's
/// today's next ([homeNextPrayer]); after Isha it's what the prayer cubit
/// counts down to, as the Prayer page shows it: Isha while it has just
/// begun, then tomorrow's Fajr. Null only until the cubit first answers.
class HomeNextPrayerBuilder extends StatefulWidget {
  const HomeNextPrayerBuilder({
    super.key,
    required this.state,
    required this.builder,
  });

  final PrayerTimesLoaded state;
  final Widget Function(BuildContext context, HomeNextPrayer? next) builder;

  @override
  State<HomeNextPrayerBuilder> createState() => _HomeNextPrayerBuilderState();
}

class _HomeNextPrayerBuilderState extends State<HomeNextPrayerBuilder> {
  StreamSubscription<NextPrayerCountdown>? _subscription;
  NextPrayerCountdown? _later;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(HomeNextPrayerBuilder old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _follow();
  }

  /// Listens to the cubit's countdown only while today has nothing left.
  void _follow() {
    final today = homeNextPrayer(context, widget.state);
    if (today != null) {
      _subscription?.cancel();
      _subscription = null;
      _later = null;
      return;
    }
    _subscription ??= context
        .read<PrayerTimesCubit>()
        .getNextPrayerCountdown()
        .listen((countdown) {
          if (!mounted) return;
          if (countdown.prayer == null || countdown.instant == null) return;
          final last = _later;
          // Rebuild only when the prayer, its moment or the minute changes.
          if (last != null &&
              last.prayer == countdown.prayer &&
              last.instant == countdown.instant &&
              last.isPastPrayer == countdown.isPastPrayer &&
              last.secondsPassed ~/ 60 == countdown.secondsPassed ~/ 60) {
            return;
          }
          setState(() => _later = countdown);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = homeNextPrayer(context, widget.state);
    if (today != null) {
      return widget.builder(context, (
        prayer: today.prayer,
        name: today.name,
        time: today.time,
        instant: today.instant,
        started: false,
        minutesSince: 0,
        tomorrow: false,
      ));
    }
    final later = _later;
    if (later == null) return widget.builder(context, null);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final instant = later.instant!;
    final zone = context.read<PrayerTimesCubit>().prayerTimeZoneId;
    DateTime clock(DateTime at) => zone == null
        ? at.toLocal()
        : PrayerTimeZoneService.wallClockAtInstant(at.toUtc(), zone);
    final wall = clock(instant);
    final now = clock(HomeClock.now());
    final tomorrow = DateTime(
      wall.year,
      wall.month,
      wall.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
    return widget.builder(context, (
      prayer: later.prayer!,
      name: localizedPrayerName(l10n, later.prayer!),
      time: DateFormat.jm(locale).format(wall),
      instant: instant.toUtc(),
      started: later.isPastPrayer,
      minutesSince: later.secondsPassed ~/ 60,
      tomorrow: tomorrow,
    ));
  }
}

/// Today's next prayer after now (Sunrise isn't a prayer): its name, its
/// time on the place's clock and the moment itself. Null after Isha.
({Prayer prayer, String name, String time, DateTime instant})? homeNextPrayer(
  BuildContext context,
  PrayerTimesLoaded state,
) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();
  final now = HomeClock.now().toUtc();
  for (final prayer in const [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ]) {
    final instant = PrayerTimesCalculator.adjustedInstantFor(
      state.prayerTimes,
      prayer,
      state.offsets,
    );
    if (instant == null || !instant.isAfter(now)) continue;
    final time = homePrayerWallTime(context, state, prayer, instant);
    return (
      prayer: prayer,
      name: localizedPrayerName(l10n, prayer),
      time: DateFormat.jm(locale).format(time),
      instant: instant,
    );
  }
  return null;
}

/// A prayer's time on the place's own clock.
DateTime homePrayerWallTime(
  BuildContext context,
  PrayerTimesLoaded state,
  Prayer prayer,
  DateTime instant,
) {
  final local = PrayerTimesCalculator.adjustedTimeFor(
    state.prayerTimes,
    prayer,
    state.offsets,
  );
  if (local != null) return local;
  final zone = context.read<PrayerTimesCubit>().prayerTimeZoneId;
  return zone == null
      ? instant.toLocal()
      : PrayerTimeZoneService.wallClockAtInstant(instant, zone);
}
