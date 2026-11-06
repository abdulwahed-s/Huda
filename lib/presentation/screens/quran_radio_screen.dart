import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/design/huda_audio_dock.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';
import 'package:huda/presentation/widgets/quran_radio/radio_parts.dart';

/// Quran Radio: the live stations under the open voiceprint, a list on
/// phones and a grid on wider windows, with the station that's on pinned
/// at the bottom.
class QuranRadioScreen extends StatefulWidget {
  const QuranRadioScreen({super.key});

  @override
  State<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends State<QuranRadioScreen>
{
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _retrying = false;
  late final QuranRadioCubit _radio;

  @override
  void initState() {
    super.initState();
    // Kept for dispose, when the context can't be read any more.
    _radio = context.read<QuranRadioCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_radio.state is QuranRadioInitial) _fetch();
  }

  void _fetch() {
    final langCode = Localizations.localeOf(context).languageCode;
    _radio.fetchRadios(langCode);
  }

  void _retry() {
    setState(() => _retrying = true);
    _fetch();
  }

  Future<void> _play(RadioStation station) async {
    try {
      await _radio.playStation(station);
    } catch (e) {
      if (mounted) {
        showHudaToast(
          context,
          message: AppLocalizations.of(context)!.unexpectedError,
          kind: HudaToastKind.failed,
        );
      }
    }
  }

  @override
  void dispose() {
    _radio.saveCurrentStation();
    _search.dispose();
    super.dispose();
  }

  static RadioStatus? _statusOf(QuranRadioLoaded state, RadioStation station) {
    if (state.currentlyPlaying?.id != station.id) return null;
    if (state.isBuffering) return RadioStatus.connecting;
    return state.isPlaying ? RadioStatus.live : RadioStatus.paused;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<QuranRadioCubit, QuranRadioState>(
      listener: (context, state) {
        if (state is! QuranRadioLoading && _retrying) {
          setState(() => _retrying = false);
        }
      },
      builder: (context, state) {
        final loaded = state is QuranRadioLoaded ? state : null;
        final current = loaded?.currentlyPlaying;
        return HudaRevealScope(
          child: HudaAudioDock(
            visible: current != null,
            bar: current == null
                ? const SizedBox.shrink()
                : RadioBar(
                    station: current,
                    status: _statusOf(loaded!, current)!,
                    onPlayPause: () => _play(current),
                    onStop: _radio.stopStation,
                  ),
            // The vine grows in as the radio opens.
            child: HudaDrawIn(
              builder: (context, grow) => TabletopSplit.applies(context)
                  ? HudaScaffold(
                      title: l10n.quranRadio,
                      // The band and the search above the fold, the
                      // stations below it.
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
                                open: true,
                                growth: grow,
                                textDirection: Directionality.of(context),
                              ),
                            ),
                            if (_showSearch(state)) _searchField(context),
                          ],
                        ),
                        slivers: _slivers(context, state, withSearch: false),
                      ),
                    )
                  : HudaLandingScaffold(
                      title: l10n.quranRadio,
                      leading:
                          ModalRoute.of(context)?.impliesAppBarDismissal ??
                              false
                          ? const BackButton()
                          : null,
                      art: (style) => ArabesqueVinePainter(
                        style: style,
                        coils: 2,
                        open: true,
                        growth: grow,
                        leadingSpace: 0.1,
                        textDirection: Directionality.of(context),
                      ),
                      contentMaxWidth: 1200,
                      slivers: _slivers(context, state),
                    ),
            ),
          ),
        );
      },
    );
  }

  static bool _showSearch(QuranRadioState state) =>
      state is QuranRadioLoaded || state is QuranRadioLoading;

  Widget _searchField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final field = Padding(
      padding: EdgeInsets.symmetric(vertical: space.md),
      child: HudaReveal(
        child: HudaSearchField(
          controller: _search,
          hintText: l10n.searchRadio,
          onChanged: (q) => setState(() => _query = q),
        ),
      ),
    );
    // On a half-open book the field keeps to the leading side, like the
    // first column of stations below it.
    final fold = FoldInfo.of(context);
    if (!fold.isBook) return field;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final gutter = space.gutter(size.width);
    final side = rtl ? size.width - fold.end : fold.start;
    final width = side - gutter - (rtl ? insets.right : insets.left) - space.sm;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(width: width.clamp(0.0, double.infinity), child: field),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    QuranRadioState state, {
    bool withSearch = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = space.gutter(width);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final insets = MediaQuery.paddingOf(context);

    Widget capped(Widget sliver) => SliverPadding(
      padding: EdgeInsets.fromLTRB(
        gutter + insets.left,
        0,
        gutter + insets.right,
        0,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final extra = constraints.crossAxisExtent - 1200;
          return extra <= 0
              ? sliver
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: extra / 2),
                  sliver: sliver,
                );
        },
      ),
    );

    final tileWidth = 280 * scale;
    final Widget body;
    if (state is QuranRadioError && !_retrying) {
      final offline = state.message == 'No internet connection';
      body = SliverFillRemaining(
        hasScrollBody: true,
        child: offline
            ? HudaOfflineState(onRetry: _retry, retrying: _retrying)
            : HudaErrorState(
                title: l10n.radioLoadFailed,
                message: l10n.unexpectedError,
                identity: quranRadioIdentity,
                onRetry: _retry,
                retrying: _retrying,
              ),
      );
    } else if (state is QuranRadioLoaded) {
      final q = _query.toLowerCase();
      final radios = [
        for (final r in state.radios)
          if (r.name.toString().toLowerCase().contains(q)) r,
      ];
      body = radios.isEmpty
          ? SliverFillRemaining(
              hasScrollBody: true,
              child: HudaStateView(
                identity: quranRadioIdentity,
                title: l10n.noResultsFound,
              ),
            )
          : capped(
              SliverAdaptiveGrid(
                minTileWidth: tileWidth,
                spacing: space.sm,
                itemCount: radios.length,
                itemBuilder: (context, i) {
                  final station = radios[i];
                  final tile = RadioStationTile(
                    station: station,
                    status: _statusOf(state, station),
                    onTap: () => _play(station),
                  );
                  return i < 5 ? HudaReveal(index: i + 1, child: tile) : tile;
                },
              ),
            );
    } else {
      // Loading, retrying, or not started.
      body = capped(
        SliverAdaptiveGrid(
          minTileWidth: tileWidth,
          spacing: space.sm,
          itemCount: 8,
          itemBuilder: (_, _) => const RadioStationSkeleton(),
        ),
      );
    }

    return [
      if (withSearch && _showSearch(state))
        capped(SliverToBoxAdapter(child: _searchField(context)))
      else
        SliverPadding(padding: EdgeInsets.only(top: space.md)),
      body,
      SliverPadding(
        padding: context.scrollPadding(EdgeInsets.only(bottom: space.xl)),
      ),
    ];
  }
}
