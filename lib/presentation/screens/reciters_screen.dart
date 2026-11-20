import 'dart:io';

import 'package:flutter/material.dart';

import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';
import 'package:huda/presentation/widgets/reciter_surahs/reciter_recitation.dart';
import 'package:huda/presentation/widgets/reciters/reciter_catalog.dart';
import 'package:huda/presentation/widgets/reciters/reciters_parts.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key, this.source = const ReciterCatalogSource()});

  final ReciterCatalogSource source;

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  List<Reciter> _reciters = const [];
  List _suwar = const [];
  bool _loading = true;
  bool _offline = false;
  bool _failed = false;
  bool _retrying = false;
  String _query = '';
  String? _dir;

  Set<String> _files = const {};
  final _search = TextEditingController();
  final _nested = GlobalKey<NavigatorState>();
  final _storage = PageStorageBucket();

  (Reciter, Moshaf)? _open;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _init();
  }

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final online = await widget.source.isOnline();
    if (!mounted) return;
    _offline = !online;
    final dir = await widget.source.downloadDir();
    if (!mounted) return;
    _dir = dir;
    _listFiles();
    await _fetch();
  }

  String _langCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? 'eng' : code;
  }

  Future<void> _fetch() async {
    ReciterCatalog? catalog;
    var failed = false;
    try {
      catalog = await widget.source.load(_langCode(context), online: !_offline);
      failed = catalog == null && !_offline;
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _reciters = catalog?.reciters ?? const [];
      _suwar = catalog?.suwar ?? const [];
      _failed = failed;
      _loading = false;
      _retrying = false;
    });
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await _init();
  }

  void _listFiles() {
    final dir = _dir;
    if (dir == null || !Directory(dir).existsSync()) return;
    _files = {
      for (final f in Directory(dir).listSync()) f.path.split('/').last,
    };
  }

  int _downloadedCount(Reciter reciter, Moshaf moshaf) {
    final prefix = '${reciter.name}-${moshaf.id}-';
    return _files.where((f) => f.startsWith(prefix)).length;
  }

  List<Reciter> get _shown {
    var base = _reciters;
    if (_offline) {
      base = [
        for (final r in _reciters)
          if (r.moshaf.any((m) => _downloadedCount(r, m) > 0))
            Reciter(
              id: r.id,
              name: r.name,
              letter: r.letter,
              moshaf: [
                for (final m in r.moshaf)
                  if (_downloadedCount(r, m) > 0) m,
              ],
            ),
      ];
    }
    final q = _query.toLowerCase();
    if (q.isEmpty) return base;
    return [
      for (final r in base)
        if (r.name.toString().toLowerCase().contains(q)) r,
    ];
  }

  void _openRecitation(Reciter reciter, Moshaf moshaf) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = (reciter, moshaf));
  }

  void _closeRecitation() {
    if (_open == null) return;
    setState(() {
      _open = null;
      _listFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stateOnly = !_loading && (_failed || (_offline && _reciters.isEmpty));
    final wide =
        AdaptivePanes.showsTwoPanes(width, FoldInfo.of(context)) &&
        !context.windowClass.isCompactHeight &&
        !stateOnly;
    return HudaRevealScope(
      child: PageStorage(
        bucket: _storage,
        child: PlayerBarWidget.dock(
          child: wide ? _wide(context) : _narrow(context),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = _open;
    return HudaScaffold(
      title: l10n.quranAudio,
      body: AdaptivePanes(
        minPrimaryWidth: 360,
        primary: CustomScrollView(
          key: const PageStorageKey('reciters-index'),
          slivers: _index(context, wide: true).all,
        ),
        secondary: HudaStateSwitcher(
          stateKey: open == null ? '' : '${open.$1.id}-${open.$2.id}',
          sequential: true,
          alignment: Alignment.topCenter,
          child: open == null
              ? const ChooseRecitationPane()
              : ReciterRecitationView(
                  key: ValueKey('recitation-${open.$1.id}-${open.$2.id}'),
                  reciter: open.$1,
                  moshaf: open.$2,
                  jsonData: _suwar,
                  showName: true,
                ),
        ),
      ),
    );
  }

  Widget _narrow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = _open;
    return NavigatorPopHandler<Object?>(
      enabled: open != null,
      onPopWithResult: (_) => _nested.currentState?.maybePop(),
      child: Navigator(
        key: _nested,
        pages: [
          MaterialPage<void>(
            key: const ValueKey('reciters-index'),
            child: PageStorage(
              bucket: _storage,
              child: HudaDrawIn(
                builder: (context, grow) {
                  final index = _index(context, wide: false);
                  if (TabletopSplit.applies(context)) {
                    return HudaScaffold(
                      title: l10n.quranAudio,
                      leading: _leaveButton,
                      body: QuranAudioTabletop(
                        head: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QuranAudioArtPlate(
                              painter: ArabesqueVinePainter(
                                style: OrnamentStyle.of(
                                  context,
                                  onChrome: true,
                                ),
                                textDirection: Directionality.of(context),
                                growth: grow,
                              ),
                            ),
                            ...index.head,
                          ],
                        ),
                        slivers: index.body,
                      ),
                    );
                  }
                  return HudaLandingScaffold(
                    title: l10n.quranAudio,
                    art: (style) => ArabesqueVinePainter(
                      style: style,
                      coils: 2,
                      leadingSpace: 0.1,
                      growth: grow,
                      textDirection: Directionality.of(context),
                    ),
                    leading: _leaveButton,
                    contentMaxWidth: 960,
                    slivers: index.all,
                  );
                },
              ),
            ),
          ),
          if (open != null)
            MaterialPage<void>(
              key: ValueKey('recitation-${open.$1.id}-${open.$2.id}'),
              child: PageStorage(
                bucket: _storage,
                child: HudaRevealScope(
                  child: HudaScaffold(
                    title: open.$1.name.toString(),
                    body: ReciterRecitationView(
                      reciter: open.$1,
                      moshaf: open.$2,
                      jsonData: _suwar,
                    ),
                  ),
                ),
              ),
            ),
        ],
        onDidRemovePage: (page) {
          if (page.key != const ValueKey('reciters-index')) {
            _closeRecitation();
          }
        },
      ),
    );
  }

  Widget? get _leaveButton {
    final canLeave = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    if (!canLeave) return null;
    return BackButton(onPressed: () => Navigator.of(context).maybePop());
  }

  _Index _index(BuildContext context, {required bool wide}) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = wide ? space.md : space.gutter(width);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final pad = EdgeInsets.fromLTRB(
      gutter + MediaQuery.paddingOf(context).left,
      0,
      gutter + MediaQuery.paddingOf(context).right,
      0,
    );

    Widget capped(Widget sliver) => SliverPadding(
      padding: pad,
      sliver: SliverCrossAxisConstrained(
        maxCrossAxisExtent: 960,
        sliver: sliver,
      ),
    );

    final hasList = !_loading && _reciters.isNotEmpty;
    final head = <Widget>[
      if (hasList || _loading)
        Padding(
          padding: EdgeInsets.only(top: space.md),
          child: HudaReveal(
            child: HudaSearchField(
              controller: _search,
              hintText: l10n.searchReciters,
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
        ),
      if (_offline && hasList)
        Padding(
          padding: EdgeInsets.only(top: space.sm),
          child: HudaStatusBanner(
            status: _retrying ? HudaStatus.retrying : HudaStatus.failed,
            message: l10n.quranAudioOfflineNote,
            onRetry: _retry,
          ),
        ),
    ];

    final Widget body;
    if (_loading && !_retrying) {
      body = capped(
        SliverPadding(
          padding: EdgeInsets.only(top: space.lg),
          sliver: SliverAdaptiveGrid(
            minTileWidth: 300 * scale,
            spacing: space.sm,
            itemCount: 6,
            itemBuilder: (_, i) => ReciterCardSkeleton(rows: i.isEven ? 1 : 2),
          ),
        ),
      );
    } else if (_failed) {
      body = SliverFillRemaining(
        hasScrollBody: true,
        child: HudaErrorState(
          title: l10n.quranAudioLoadFailed,
          message: l10n.unexpectedError,
          identity: quranAudioIdentity,
          onRetry: _retry,
          retrying: _retrying,
        ),
      );
    } else if (_offline && _reciters.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: true,
        child: HudaOfflineState(
          message: l10n.connectToDownload,
          onRetry: _retry,
          retrying: _retrying,
        ),
      );
    } else {
      final shown = _shown;
      if (shown.isEmpty) {
        body = SliverFillRemaining(
          hasScrollBody: true,
          child: HudaStateView(
            identity: quranAudioIdentity,
            title: l10n.noResultsFound,
          ),
        );
      } else {
        final groups = groupReciters(shown);
        final selected = wide ? _open : null;
        Widget card(Reciter reciter, {String? letter}) => ReciterCard(
          reciter: reciter,
          letter: letter,
          suwar: _suwar,
          downloadedCount: (m) => _downloadedCount(reciter, m),
          selected: selected?.$1.id == reciter.id ? selected?.$2 : null,
          showChevron: !wide,
          onOpen: (m) => _openRecitation(reciter, m),
        );
        Widget reveal(int order, Widget child) =>
            order < 6 ? HudaReveal(index: order, child: child) : child;
        final columns = AdaptiveGrid.columns(
          width: (wide ? 440 : width) - pad.horizontal,
          minTileWidth: 300 * scale,
          spacing: space.sm,
        );
        if (columns > 1) {
          final firsts = {for (final g in groups) g.reciters.first.id};
          body = capped(
            SliverPadding(
              padding: EdgeInsets.only(top: space.lg),
              sliver: SliverAdaptiveGrid(
                minTileWidth: 300 * scale,
                spacing: space.sm,
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final reciter = shown[i];
                  return reveal(
                    i + 1,
                    card(
                      reciter,
                      letter: firsts.contains(reciter.id)
                          ? reciter.letter.toString()
                          : null,
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          final starts = <int>[];
          var count = 1;
          for (final group in groups) {
            starts.add(count);
            count += group.reciters.length;
          }
          body = SliverMainAxisGroup(
            slivers: [
              for (final (g, group) in groups.indexed) ...[
                capped(SliverToBoxAdapter(child: ReciterLetter(group.letter))),
                capped(
                  SliverList.separated(
                    itemCount: group.reciters.length,
                    separatorBuilder: (_, _) => SizedBox(height: space.sm),
                    itemBuilder: (context, i) =>
                        reveal(starts[g] + i, card(group.reciters[i])),
                  ),
                ),
              ],
            ],
          );
        }
      }
    }

    return _Index(
      head: head,
      wrap: (child) => capped(SliverToBoxAdapter(child: child)),
      body: [
        body,
        SliverPadding(
          padding: context.scrollPadding(EdgeInsets.only(bottom: space.xl)),
        ),
      ],
    );
  }
}

class _Index {
  const _Index({required this.head, required this.wrap, required this.body});

  final List<Widget> head;
  final Widget Function(Widget box) wrap;
  final List<Widget> body;

  List<Widget> get all => [for (final h in head) wrap(h), ...body];
}
