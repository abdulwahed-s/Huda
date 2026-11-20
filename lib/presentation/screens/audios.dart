import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/cubit/audios/audios_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/audios_response.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/audio_detail.dart';
import 'package:huda/presentation/widgets/audio/audiobook_bar.dart';
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_library_parts.dart';
import 'package:huda/presentation/widgets/books/books_library_parts.dart'
    show BooksPager;
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';

class AudiosScreen extends StatefulWidget {
  const AudiosScreen({super.key});

  static const double maxContentWidth = 1280;

  @override
  State<AudiosScreen> createState() => _AudiosScreenState();
}

class _AudiosScreenState extends State<AudiosScreen> {
  String? _language;
  final _top = GlobalKey();

  bool _retrying = false;
  AudiosState? _failure;

  String get _appLanguage =>
      context.read<LocalizationCubit>().state.locale.languageCode;

  @override
  void initState() {
    super.initState();
    _language = _appLanguage;
    context.read<AudiosCubit>().fetchAudios(_language!, 1, _appLanguage);
    context.read<AudioLanguagesCubit>().fetchLanguages(_appLanguage);
  }

  void _fetch(int page) {
    context.read<AudiosCubit>().fetchAudios(
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
      final motion = context.tokens.motion;
      Scrollable.ensureVisible(
        top,
        duration: motion.of(context, motion.medium),
        curve: motion.standard,
      );
    }
  }

  void _retry() {
    setState(() => _retrying = true);
    _fetch(1);
    context.read<AudioLanguagesCubit>().fetchLanguages(_appLanguage);
  }

  static bool _isLoading(AudiosState state) =>
      state is AudiosLoading ||
      state is AudiosOfflineLoading ||
      state is AudiosInitial;

  static bool _isOffline(AudiosState state) =>
      state is AudiosOfflineLoaded ||
      state is AudiosOfflineEmpty ||
      state is AudiosOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return AudiobookBar.dock(
      child: HudaRevealScope(
        child: BlocConsumer<AudiosCubit, AudiosState>(
          listener: (context, state) {
            if (state is AudiosLoaded &&
                state.audiosResponse.data.isEmpty &&
                _language != null) {
              setState(() => _language = null);
              _fetch(1);
            }
            if (!_isLoading(state) && _retrying) {
              setState(() => _retrying = false);
            }
          },
          builder: (context, state) {
            if (state is AudiosError || _isOffline(state)) _failure = state;
            final failure = _failure;
            final shown = _retrying && _isLoading(state) && failure != null
                ? failure
                : state;
            return HudaDrawIn(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.linear,
              builder: (context, draw) => HudaLandingScaffold(
                leading: canPop ? const BackButton() : null,
                eyebrow: l10n.audios,
                title: l10n.audiobooks,
                art: (style) =>
                    AudiobookHangingRibbonsPainter(style: style, draw: draw),
                contentMaxWidth: AudiosScreen.maxContentWidth,
                slivers: [
                  _Page(
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
      ),
    );
  }

  Object _stateKey(AudiosState state) => switch (state) {
    AudiosLoaded(:final audiosResponse) =>
      'page-${audiosResponse.links.currentPage}-$_language',
    AudiosOfflineLoaded() => 'offline',
    AudiosOfflineEmpty() => 'offline-empty',
    AudiosOffline() => 'offline-failed',
    AudiosError() => 'error',
    _ => 'loading',
  };

  Widget _body(BuildContext context, AudiosState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: child,
      ),
    );
    return switch (state) {
      AudiosLoaded(:final audiosResponse) => SliverMainAxisGroup(
        slivers: [
          _Tiles(
            count: audiosResponse.data.length,
            tile: (context, i) => _onlineTile(audiosResponse.data[i]),
          ),
          if (audiosResponse.links.pagesNumber > 1)
            SliverPadding(
              padding: EdgeInsets.only(top: space.xl),
              sliver: SliverToBoxAdapter(
                child: BooksPager(
                  page: audiosResponse.links.currentPage,
                  pages: audiosResponse.links.pagesNumber,
                  onPage: _changePage,
                ),
              ),
            ),
        ],
      ),
      AudiosOfflineLoaded(:final offlineAudios) => SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(bottom: space.lg),
            sliver: SliverToBoxAdapter(
              child: AudiobooksOfflineNotice(
                count: offlineAudios.length,
                onRetry: _retry,
                retrying: _retrying,
              ),
            ),
          ),
          _Tiles(
            count: offlineAudios.length,
            tile: (context, i) => _offlineTile(offlineAudios[i]),
          ),
        ],
      ),
      AudiosOfflineEmpty() => fill(
        HudaStateView(
          identity: audiobooksIdentity,
          title: l10n.noOfflineAudiobooks,
          message: l10n.audiobooksDownloadWhenOnline,
          actions: [HudaRetryButton(onRetry: _retry, retrying: _retrying)],
        ),
      ),
      AudiosOffline() => fill(
        HudaOfflineState(onRetry: _retry, retrying: _retrying),
      ),
      AudiosError() => fill(
        HudaErrorState(
          identity: audiobooksIdentity,
          message: l10n.audiobooksLoadError,
          onRetry: _retry,
          retrying: _retrying,
        ),
      ),
      _ => _Tiles(
        count: 12,
        tile: (context, i) => AudiobookSwatchSkeleton(announce: i == 0),
        reveal: false,
      ),
    };
  }

  Widget _onlineTile(AudioItem audio) => AudiobookTile(
    seed: audio.id,
    title: audio.title,
    author: _author([for (final p in audio.preparedBy) (p.type, p.title)]),
    chapters: audio.numAttachments,
    onTap: (card) => _open(
      card,
      id: audio.id,
      language: audio.translatedLanguage,
      title: audio.title,
    ),
  );

  Widget _offlineTile(OfflineAudiobookModel audio) => AudiobookTile(
    seed: audio.id,
    title: audio.title,
    author: _author([for (final p in audio.preparedBy) (p.type, p.title)]),
    chapters: audio.tracks.length,
    downloaded: true,
    onTap: (card) =>
        _open(card, id: audio.id, language: audio.language, title: audio.title),
  );

  static String? _author(List<(String, String?)> people) {
    for (final (type, name) in people) {
      if (type == 'author' && (name ?? '').isNotEmpty) return name;
    }
    for (final (_, name) in people) {
      if ((name ?? '').isNotEmpty) return name;
    }
    return null;
  }

  void _open(
    BuildContext card, {
    required int id,
    required String language,
    required String title,
  }) {
    pushFromCard(
      card,
      (_) =>
          AudioDetailScreen.page(audioId: id, language: language, title: title),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        final width = constraints.crossAxisExtent;
        final gutter = space.gutter(width);
        final extra = math.max(0.0, (width - AudiosScreen.maxContentWidth) / 2);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter + insets.left + extra,
            space.md,
            gutter + insets.right + extra,
            space.xxl + insets.bottom,
          ),
          sliver: SliverMainAxisGroup(slivers: children),
        );
      },
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({
    required this.state,
    required this.language,
    required this.onLanguage,
  });

  final AudiosState state;
  final String? language;
  final ValueChanged<String?> onLanguage;

  static double _cardWidth(BuildContext context) {
    final fold = FoldInfo.of(context);
    if (!fold.avoided || !fold.splitsHorizontally) return double.infinity;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final width = MediaQuery.sizeOf(context).width;
    final insets = MediaQuery.paddingOf(context);
    final gutter = context.tokens.space.gutter(width);
    final leading = rtl
        ? width - fold.end - insets.right
        : fold.start - insets.left;
    return math.max(240.0, leading - gutter * 2);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final offline =
        state is AudiosOfflineLoaded ||
        state is AudiosOfflineEmpty ||
        state is AudiosOffline;
    final lastPlayed = getIt<AudioProgressService>().getLastPlayed();
    final showContinue =
        lastPlayed != null && lastPlayed.title != null && state is AudiosLoaded;
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
                  constraints: BoxConstraints(maxWidth: _cardWidth(context)),
                  child: AudiobookContinueCard(
                    progress: lastPlayed,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoute.audioDetail,
                      arguments: {
                        'audioId': lastPlayed.audiobookId.toString(),
                        'language': context
                            .read<LocalizationCubit>()
                            .state
                            .locale
                            .languageCode,
                        'title': lastPlayed.title,
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: space.lg),
          ],
          if (!offline)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AudiobooksLanguageChip(
                selected: language,
                onSelected: onLanguage,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.count, required this.tile, this.reveal = true});

  final int count;
  final Widget Function(BuildContext context, int i) tile;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final minTileWidth = AdaptiveGrid.tileWidth(
      context,
      context.windowClass.isCompactHeight
          ? 150
          : context.windowClass.width >= WindowWidthClass.expanded
          ? 184
          : 150,
    );
    return SliverAdaptiveGrid(
      minTileWidth: minTileWidth,
      spacing: space.md,
      maxColumns: 8,
      itemCount: count,
      itemBuilder: (context, i) => reveal
          ? HudaReveal(index: i, child: tile(context, i))
          : tile(context, i),
    );
  }
}
