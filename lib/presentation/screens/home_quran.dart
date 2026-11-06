import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/quran/surah_builder.dart';
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/surah_screen.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';

/// The Quran's front screen: the 114 surahs, where the reader stopped, and
/// a search over surah names and the ayat's words. Landing tier; the
/// header's star medallion draws itself in as it opens. See
/// `design/features/quran/brief.md`.
class HomeQuran extends StatefulWidget {
  const HomeQuran({super.key});

  /// Content is capped at this width and centered, with the header.
  static const double maxContentWidth = 1280;

  @override
  State<HomeQuran> createState() => _HomeQuranState();
}

/// An ayah found by its words.
typedef _AyahHit = ({int surah, int ayah, String text});

class _HomeQuranState extends State<HomeQuran> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<QuranModel> _surahHits = const [];
  List<_AyahHit> _ayahHits = const [];
  Map<String, dynamic>? _lastRead;

  /// After a tap on Retry, until the cubit answers.
  bool _retrying = false;

  static const _maxAyahHits = 20;

  @override
  void initState() {
    super.initState();
    _lastRead = _readLastRead();
    context.read<QuranCubit>().loadQuran();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _readLastRead() {
    try {
      return getIt<ReadingPositionService>().getLastReadSummary();
    } catch (_) {
      return null;
    }
  }

  void _retry() {
    setState(() => _retrying = true);
    context.read<QuranCubit>().loadQuran();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _applySearch('');
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _applySearch(query),
    );
  }

  void _applySearch(String query) {
    final state = context.read<QuranCubit>().state;
    final surahs = state is QuranLoaded ? state.surahs : const <QuranModel>[];
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _surahHits = const [];
        _ayahHits = const [];
      });
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    final lower = q.toLowerCase();
    final normalized = TextUtils.removeDiacriticsAndNormalize(lower);
    bool contains(String? s) => s != null && s.toLowerCase().contains(lower);
    final surahHits = surahs.where((s) {
      return contains(s.localizedName(language)) ||
          (s.names?.values.any(contains) ?? false) ||
          (s.translits?.values.any(contains) ?? false) ||
          contains(s.transliteration) ||
          contains(s.englishName) ||
          contains(s.englishNameTranslation) ||
          s.number.toString().contains(q) ||
          TextUtils.removeDiacriticsAndNormalize(
            s.name ?? '',
          ).contains(normalized);
    }).toList();

    // Ayat whose words match, outside the surahs already found by name.
    final ayahHits = <_AyahHit>[];
    final matched = {for (final s in surahHits) s.number};
    final arabicQuery = TextUtils.removeDiacriticsAndNormalize(q);
    try {
      final ayat = SurahBuilder.buildAllSurahAyahs();
      for (final entry in ayat.entries) {
        if (ayahHits.length >= _maxAyahHits) break;
        if (matched.contains(entry.key)) continue;
        for (final ayah in entry.value) {
          if (ayahHits.length >= _maxAyahHits) break;
          final text = ayah.text;
          if (text == null) continue;
          if (TextUtils.removeDiacriticsAndNormalize(
                text,
              ).contains(arabicQuery) ||
              text.toLowerCase().contains(lower)) {
            ayahHits.add((
              surah: entry.key,
              ayah: ayah.numberInSurah ?? 0,
              text: text,
            ));
          }
        }
      }
    } catch (error) {
      debugPrint('Quran search over ayat failed: $error');
    }

    setState(() {
      _query = q;
      _surahHits = surahHits;
      _ayahHits = ayahHits;
    });
  }

  void _clearSearch() {
    _search.clear();
    _applySearch('');
  }

  Future<void> _open(
    BuildContext tileContext,
    QuranModel surah, {
    int? ayah,
    bool restore = false,
    bool flash = false,
  }) async {
    await pushFromCard(
      tileContext,
      (_) => SurahScreen.route(
        surahInfo: surah,
        scrollToAyah: ayah,
        flashAyah: flash,
        shouldRestorePosition: restore,
      ),
    );
    if (mounted) setState(() => _lastRead = _readLastRead());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return HudaRevealScope(
      child: BlocConsumer<QuranCubit, QuranState>(
        listener: (context, state) {
          if (state is! QuranLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          // While retrying, the failure stays with "Retrying…".
          final shown = _retrying && state is QuranLoading
              ? QuranError('')
              : state;
          Widget landing(List<Widget> slivers) => QuranIlluminate(
            builder: (context, draw) => HudaLandingScaffold(
              leading: canPop ? const BackButton() : null,
              eyebrow: l10n.surahIndexSubtitle,
              title: l10n.quran,
              art: (style) => QuranMedallionPainter(style: style, drawOf: draw),
              contentMaxWidth: HomeQuran.maxContentWidth,
              slivers: slivers,
            ),
          );
          if (TabletopSplit.applies(context) && shown is! QuranError) {
            return TabletopSplit(
              top: landing([
                _Page(tight: true, children: _top(context, shown)),
              ]),
              bottom: CustomScrollView(
                slivers: [_Page(children: _index(context, shown))],
              ),
            );
          }
          return landing([
            _Page(
              children: [
                ..._top(context, shown),
                SliverHudaStateSwitcher(
                  stateKey: _stateKey(shown),
                  sliver: SliverMainAxisGroup(slivers: _index(context, shown)),
                ),
              ],
            ),
          ]);
        },
      ),
    );
  }

  Object _stateKey(QuranState state) => switch (state) {
    QuranError() => 'error',
    QuranLoaded() => _query.isEmpty ? 'index' : 'search:$_query',
    _ => 'loading',
  };

  /// The search field and, when not searching, where the reader stopped.
  List<Widget> _top(BuildContext context, QuranState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final lastRead = _lastRead;
    final surahs = state is QuranLoaded ? state.surahs : const <QuranModel>[];
    final lastSurah = lastRead?['surahNumber'] as int?;
    final language = Localizations.localeOf(context).languageCode;
    final showContinue =
        _query.isEmpty &&
        lastSurah != null &&
        lastSurah >= 1 &&
        lastSurah <= surahs.length;
    return [
      SliverPadding(
        padding: EdgeInsets.only(top: space.lg),
        sliver: SliverToBoxAdapter(
          child: QuranLeadingHalf(
            child: HudaSearchField(
              key: const ValueKey('quran-search'),
              controller: _search,
              onChanged: _onSearch,
              hintText: l10n.quranSearchHint,
            ),
          ),
        ),
      ),
      if (showContinue)
        SliverPadding(
          padding: EdgeInsets.only(top: space.md),
          sliver: SliverToBoxAdapter(
            child: HudaReveal(
              child: QuranLeadingHalf(
                child: QuranContinueCard(
                  surah: QuranSurahRef.of(surahs[lastSurah - 1], language),
                  ayah: lastRead!['ayahNumber'] as int? ?? 1,
                  onTap: (card) =>
                      _open(card, surahs[lastSurah - 1], restore: true),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  /// Tiles at least this wide: one column on phones, two on portrait
  /// tablets and in phone landscape, three or four wider.
  static double _minTileWidth(BuildContext context) => AdaptiveGrid.tileWidth(
    context,
    context.windowClass.isCompactHeight ? 280 : 320,
  );

  List<Widget> _index(BuildContext context, QuranState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final language = Localizations.localeOf(context).languageCode;
    Widget label(String text, {int reveal = 0}) => SliverPadding(
      padding: EdgeInsets.only(top: space.lg, bottom: space.xs),
      sliver: SliverToBoxAdapter(
        child: HudaReveal(index: reveal, child: HudaSectionHeader(text)),
      ),
    );
    Widget grid(int count, IndexedWidgetBuilder builder) => Builder(
      builder: (context) => SliverAdaptiveGrid(
        minTileWidth: _minTileWidth(context),
        spacing: space.sm,
        itemCount: count,
        itemBuilder: builder,
      ),
    );

    switch (state) {
      case QuranError():
        return [
          SliverFillRemaining(
            hasScrollBody: true,
            child: HudaErrorState(
              identity: quranIdentity,
              message: l10n.quranLoadError,
              onRetry: _retry,
              retrying: _retrying,
            ),
          ),
        ];
      case QuranLoaded(:final surahs):
        if (_query.isEmpty) {
          return [
            label(l10n.surahsLabel),
            grid(
              surahs.length,
              (context, i) => HudaReveal(
                index: i + 1,
                child: QuranSurahTile(
                  surah: QuranSurahRef.of(surahs[i], language),
                  onTap: (tile) => _open(tile, surahs[i]),
                ),
              ),
            ),
          ];
        }
        if (_surahHits.isEmpty && _ayahHits.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: true,
              child: HudaEmptyState(
                identity: quranIdentity,
                title: l10n.surahNoResults,
                message: l10n.tryDifferentSearch,
                actionLabel: l10n.athkarClearSearch,
                onAction: _clearSearch,
              ),
            ),
          ];
        }
        return [
          if (_surahHits.isNotEmpty) ...[
            label(l10n.surahsLabel),
            grid(
              _surahHits.length,
              (context, i) => QuranSurahTile(
                surah: QuranSurahRef.of(_surahHits[i], language),
                onTap: (tile) => _open(tile, _surahHits[i]),
              ),
            ),
          ],
          if (_ayahHits.isNotEmpty) ...[
            label(l10n.quranAyatSection),
            grid(_ayahHits.length, (context, i) {
              final hit = _ayahHits[i];
              return QuranAyahHitTile(
                surah: QuranSurahRef.of(surahs[hit.surah - 1], language),
                ayah: hit.ayah,
                text: hit.text,
                query: _query,
                onTap: (tile) => _open(
                  tile,
                  surahs[hit.surah - 1],
                  ayah: hit.ayah,
                  flash: true,
                ),
              );
            }),
          ],
        ];
      default:
        return [
          label(l10n.surahsLabel),
          grid(8, (context, i) => QuranSurahTileSkeleton(announce: i == 0)),
        ];
    }
  }
}

/// The page's content column: the gutters and side insets, capped at
/// [HomeQuran.maxContentWidth] and centered, ending above the bottom inset.
class _Page extends StatelessWidget {
  const _Page({required this.children, this.tight = false});

  final List<Widget> children;

  /// Above a tabletop band: no bottom inset.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final gutter = space.gutter(width);
        final extra = math.max(0.0, (width - HomeQuran.maxContentWidth) / 2);
        final side = gutter + extra;
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(side, 0, side, tight ? space.md : space.xl),
        );
        return SliverPadding(
          padding: tight ? padding.copyWith(bottom: space.md) : padding,
          sliver: SliverMainAxisGroup(slivers: children),
        );
      },
    );
  }
}
