import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' show PlayerState;
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audio_detail/audio_detail_cubit.dart';
import 'package:huda/cubit/audiobook_download/audiobook_download_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/data/services/audiobook_download_service.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_parts.dart';
import 'package:huda/presentation/widgets/audio/audiobook_bar.dart';
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart'
    show bookLanguageName;
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';

/// A recording's page: its swatch (an eye per chapter, those heard
/// filled), the title, Play or Resume and Download, what it is about and
/// its chapters. Standard tier; the ribbon weaves in as the page opens.
/// Two panes from 840 wide and on open folds, the hero above a tabletop
/// fold. The bar of what's playing is pinned under it. See
/// `design/features/audiobooks/brief.md`.
class AudioDetailScreen extends StatefulWidget {
  const AudioDetailScreen({
    super.key,
    required this.audioId,
    required this.language,
    required this.title,
  });

  final int audioId;
  final String language;
  final String title;

  /// The page with its cubits and the Lantern theme, as the route opens
  /// it. The player's cubits come from the app.
  static Widget page({
    required int audioId,
    required String language,
    required String title,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider<AudioDetailCubit>(create: (_) => AudioDetailCubit()),
      BlocProvider<AudiobookDownloadCubit>(
        create: (_) => AudiobookDownloadCubit(
          downloadService: getIt<AudiobookDownloadService>(),
          offlineService: getIt<OfflineAudiobooksService>(),
        ),
      ),
    ],
    child: AudioDetailScreen(
      audioId: audioId,
      language: language,
      title: title,
    ),
  );

  @override
  State<AudioDetailScreen> createState() => _AudioDetailScreenState();
}

class _AudioDetailScreenState extends State<AudioDetailScreen> {
  bool _retrying = false;
  AudioDetailState? _failure;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<AudiobookDownloadCubit>().checkStatus(widget.audioId);
  }

  void _load() => context.read<AudioDetailCubit>().fetchAudioDetail(
    widget.audioId,
    widget.language,
  );

  void _retry() {
    setState(() => _retrying = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AudiobookBar.dock(
      child: BlocListener<AudiobookDownloadCubit, AudiobookDownloadState>(
        listenWhen: (old, state) => !old.isDownloaded && state.isDownloaded,
        listener: (context, _) =>
            showHudaToast(context, message: l10n.audiobookDownloaded),
        child: BlocConsumer<AudioDetailCubit, AudioDetailState>(
          listener: (context, state) {
            if (state is! AudioDetailLoading && _retrying) {
              setState(() => _retrying = false);
            }
          },
          builder: (context, state) {
            if (state is AudioDetailError || state is AudioDetailOffline) {
              _failure = state;
            }
            final failure = _failure;
            final shown =
                _retrying && state is AudioDetailLoading && failure != null
                ? failure
                : state;
            final view = switch (shown) {
              AudioDetailLoaded(:final audioDetail) => _View.online(
                audioDetail,
                fallbackTitle: widget.title,
              ),
              AudioDetailOfflineLoaded(:final offlineAudio) => _View.offline(
                offlineAudio,
              ),
              _ => null,
            };
            return HudaScaffold(
              // The hero names the recording; the bar names the place.
              title: l10n.audios,
              body: HudaRevealScope(
                child: HudaStateSwitcher(
                  stateKey: _stateKey(shown),
                  child: view != null
                      ? _ActivePlayer(
                          audioId: widget.audioId,
                          builder: (context, active) => _Layout(
                            view: view,
                            audioId: widget.audioId,
                            language: widget.language,
                            active: active,
                            onPlay: (index, position) =>
                                _play(context, view, index, position),
                            onRemove: () => _confirmRemove(context, shown),
                          ),
                        )
                      : _state(context, shown),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Object _stateKey(AudioDetailState state) => switch (state) {
    AudioDetailLoaded() => 'loaded',
    AudioDetailOfflineLoaded() => 'saved',
    AudioDetailError() => 'error',
    AudioDetailOffline() => 'offline',
    _ => 'loading',
  };

  Widget _state(BuildContext context, AudioDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return switch (state) {
      AudioDetailError() => HudaErrorState(
        identity: audiobooksIdentity,
        message: l10n.audiobooksDetailError,
        onRetry: _retry,
        retrying: _retrying,
      ),
      AudioDetailOffline() => HudaOfflineState(
        message: l10n.audiobooksDetailOffline,
        onRetry: _retry,
        retrying: _retrying,
      ),
      _ => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: context.scrollPadding(
          EdgeInsets.fromLTRB(
            space.gutter(MediaQuery.sizeOf(context).width),
            space.md,
            space.gutter(MediaQuery.sizeOf(context).width),
            space.xxl,
          ),
        ),
        child: const AudioDetailSkeleton(),
      ),
    };
  }

  void _play(BuildContext context, _View view, int index, Duration? position) {
    context.read<AudiobookPlayerCubit>().startPlaying(
      audiobookId: widget.audioId,
      tracks: view.tracks,
      title: view.title,
      author: view.author,
      artUrl: view.artUrl,
      initialIndex: index,
      initialPosition: position,
      isOffline: false,
    );
    context.read<AudiobookBarCubit>().show();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AudioDetailState state,
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
                l10n.audiobooksRemoveDownloadBody,
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
    await context.read<AudiobookDownloadCubit>().delete(widget.audioId);
    // Offline, the page showed the saved copy: now there is none.
    if (state is AudioDetailOfflineLoaded && mounted) _load();
  }
}

/// What the page shows of a recording, online or saved.
class _View {
  const _View({
    required this.title,
    required this.author,
    required this.description,
    required this.tracks,
    required this.artUrl,
    required this.detail,
    required this.saved,
  });

  factory _View.online(AudioDetailModel d, {required String fallbackTitle}) {
    final people = d.preparedBy ?? const [];
    final full = d.fullDescription ?? '';
    return _View(
      title: (d.title ?? '').isNotEmpty ? d.title! : fallbackTitle,
      author: people.isNotEmpty ? (people.first.title ?? '') : '',
      description: full.isNotEmpty ? full : (d.description ?? ''),
      tracks: d.attachments ?? const [],
      artUrl: d.image,
      detail: d,
      saved: false,
    );
  }

  factory _View.offline(OfflineAudiobookModel o) => _View(
    title: o.title,
    author: o.preparedBy.isNotEmpty ? (o.preparedBy.first.title ?? '') : '',
    description: o.description,
    tracks: [
      for (final t in o.tracks)
        AudioTrack(
          order: t.order,
          size: t.size,
          extensionType: t.extensionType,
          description: t.description,
          url: t.originalUrl,
        ),
    ],
    artUrl: o.imageUrl,
    detail: null,
    saved: true,
  );

  final String title;
  final String author;
  final String description;
  final List<AudioTrack> tracks;
  final String? artUrl;
  final AudioDetailModel? detail;
  final bool saved;
}

/// The player, as far as this recording is concerned: on which chapter it
/// is, whether it plays and how far the chapter has played; null when it
/// plays another recording or nothing.
class _Active {
  const _Active({
    required this.index,
    required this.playing,
    required this.fraction,
  });

  final int index;
  final bool playing;
  final double fraction;
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({required this.audioId, required this.builder});

  final int audioId;
  final Widget Function(BuildContext context, _Active? active) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
      builder: (context, state) {
        // The same tree whether or not this recording plays, so the page
        // (and the ribbon's weave) isn't rebuilt from scratch on Play.
        final player =
            state is AudiobookPlayerPlaying && state.audiobookId == audioId
            ? state.audioPlayer
            : null;
        return StreamBuilder<int?>(
          stream: player?.currentIndexStream,
          builder: (context, index) => StreamBuilder<PlayerState>(
            stream: player?.playerStateStream,
            builder: (context, ps) => StreamBuilder<Duration>(
              stream: player?.positionStream,
              builder: (context, pos) {
                if (player == null) return builder(context, null);
                final dur = player.duration ?? Duration.zero;
                final at = pos.data ?? player.position;
                return builder(
                  context,
                  _Active(
                    index: index.data ?? player.currentIndex ?? 0,
                    playing: ps.data?.playing ?? player.playing,
                    fraction: dur.inMilliseconds > 0
                        ? at.inMilliseconds / dur.inMilliseconds
                        : 0,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The page's layout for a loaded recording: one column on phones, the
/// hero beside the chapters from 840 wide and on open folds (and on short
/// windows from 600), the hero above a tabletop fold.
class _Layout extends StatelessWidget {
  const _Layout({
    required this.view,
    required this.audioId,
    required this.language,
    required this.active,
    required this.onPlay,
    required this.onRemove,
  });

  final _View view;
  final int audioId;
  final String language;
  final _Active? active;
  final void Function(int index, Duration? position) onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final progress = getIt<AudioProgressService>().getProgress(audioId);
    final active = this.active;
    final tracks = view.tracks;

    final (playLabel, playIcon, VoidCallback? onPlayTap) = tracks.isEmpty
        ? (l10n.play, Icons.play_arrow_rounded, null)
        : active != null && active.playing
        ? (
            l10n.pause,
            Icons.pause_rounded,
            () => context.read<AudiobookPlayerCubit>().pause(),
          )
        : active != null
        ? (
            l10n.play,
            Icons.play_arrow_rounded,
            () => context.read<AudiobookPlayerCubit>().resume(),
          )
        : progress != null
        ? (
            l10n.resumeChapter(progress.trackIndex + 1),
            Icons.play_arrow_rounded,
            () => onPlay(progress.trackIndex, progress.position),
          )
        : (l10n.play, Icons.play_arrow_rounded, () => onPlay(0, null));

    Widget heroOf({double swatchWidth = 360}) => AudioDetailHero(
      swatchWidth: swatchWidth,
      seed: audioId,
      title: view.title,
      author: view.author,
      chapters: tracks.length,
      current: active?.index ?? progress?.trackIndex,
      fraction: active?.fraction ?? 0,
      language: bookLanguageName(context, language),
      downloaded: view.saved,
    );
    final hero = heroOf();
    final detail = view.detail;
    final actions = AudioDetailActions(
      audioId: audioId,
      playLabel: playLabel,
      playIcon: playIcon,
      onPlay: onPlayTap,
      onDownload: kIsWeb || detail == null
          ? null
          : () => context.read<AudiobookDownloadCubit>().download(
              detail,
              language,
            ),
      onRemove: onRemove,
    );
    final about = view.description.trim().isEmpty
        ? null
        : AudioDetailAbout(text: view.description.trim());
    final chapters = AudioDetailChapters(
      tracks: tracks,
      current: active?.index ?? -1,
      playing: active?.playing ?? false,
      resume: progress?.trackIndex ?? -1,
      onTap: (i) {
        if (active != null && i == active.index) {
          final cubit = context.read<AudiobookPlayerCubit>();
          active.playing ? cubit.pause() : cubit.resume();
        } else if (active != null) {
          context.read<AudiobookPlayerCubit>().seekToIndex(i);
        } else {
          onPlay(i, null);
        }
      },
    );
    final details = [
      if (about != null) ...[about, SizedBox(height: space.xl)],
      chapters,
    ];

    Widget column(List<Widget> children, {double maxWidth = 680}) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
    Widget scroll(BuildContext context, Widget child) {
      final gutter = space.gutter(MediaQuery.sizeOf(context).width);
      return SingleChildScrollView(
        padding: context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
        ),
        child: child,
      );
    }

    if (TabletopSplit.applies(context)) {
      return TabletopSplit(
        top: Builder(
          builder: (context) => scroll(context, column([hero], maxWidth: 460)),
        ),
        bottom: Builder(
          builder: (context) => scroll(
            context,
            column([actions, SizedBox(height: space.xl), ...details]),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = context.windowClass.isCompactHeight;
        final minWidth = short ? 600.0 : 840.0;
        final twoPanes = AdaptivePanes.showsTwoPanes(
          constraints.maxWidth,
          FoldInfo.of(context),
          twoPaneMinWidth: minWidth,
        );
        if (twoPanes) {
          final media = MediaQuery.of(context);
          // Short windows: the swatch sized to the height and the buttons
          // at the top of the other pane, so Play shows without scrolling.
          final shortSwatch =
              ((media.size.height - kToolbarHeight - media.padding.vertical) *
                      0.42 *
                      AudiobookSwatch.aspect)
                  .clamp(140.0, 300.0);
          final wide = constraints.maxWidth >= 1200;
          final swatch = short ? shortSwatch : (wide ? 440.0 : 360.0);
          final reading = Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: HudaReveal(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (short) ...[actions, SizedBox(height: space.xl)],
                    ...details,
                  ],
                ),
              ),
            ),
          );
          return AdaptivePanes(
            twoPaneMinWidth: minWidth,
            minPrimaryWidth: short ? 300 : 340,
            maxPrimaryWidth: wide ? 600 : 520,
            primaryFraction: 0.42,
            primary: Builder(
              builder: (context) => scroll(
                context,
                column([
                  heroOf(swatchWidth: swatch),
                  if (!short) ...[
                    SizedBox(height: space.lg),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: swatch),
                        child: HudaReveal(index: 1, child: actions),
                      ),
                    ),
                  ],
                ], maxWidth: 520),
              ),
            ),
            secondary: Builder(builder: (context) => scroll(context, reading)),
          );
        }
        return scroll(
          context,
          column([
            hero,
            SizedBox(height: space.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: HudaReveal(index: 1, child: actions),
              ),
            ),
            SizedBox(height: space.xl),
            HudaReveal(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details,
              ),
            ),
          ]),
        );
      },
    );
  }
}
