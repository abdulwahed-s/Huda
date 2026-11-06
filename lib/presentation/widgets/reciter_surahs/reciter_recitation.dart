import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';

/// One surah of a recitation.
@immutable
class RecitationSurah {
  const RecitationSurah({
    required this.index,
    required this.number,
    required this.name,
  });

  /// Its place in the recitation's playlist.
  final int index;
  final int number;
  final String name;
}

/// The surahs of [moshaf], named from the catalog's [jsonData].
List<RecitationSurah> recitationSurahs(Moshaf moshaf, List jsonData) {
  final numbers = moshaf.surahList.toString().split(',');
  return [
    for (var i = 0; i < numbers.length; i++)
      () {
        final match = jsonData
            .where((el) => el['id'].toString() == numbers[i])
            .toList();
        return RecitationSurah(
          index: i,
          number: int.tryParse(numbers[i]) ?? 0,
          name: match.isNotEmpty
              ? match.first['name'].toString()
              : 'Surah ${numbers[i]}',
        );
      }(),
  ];
}

/// A reciter's recitation: its plate (the vine, the counts and Download
/// all), the search, and its surahs (tap to play, download each). The page on phones and the detail pane beside the
/// reciters on wide windows; [showName] puts the reciter's name on the
/// plate where no app bar says it.
class ReciterRecitationView extends StatefulWidget {
  const ReciterRecitationView({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.jsonData,
    this.showName = false,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final List jsonData;
  final bool showName;

  @override
  State<ReciterRecitationView> createState() => _ReciterRecitationViewState();
}

class _ReciterRecitationViewState extends State<ReciterRecitationView> {
  final _search = TextEditingController();
  String _query = '';
  late List<RecitationSurah> _surahs = recitationSurahs(
    widget.moshaf,
    widget.jsonData,
  );
  String? _dir;
  Set<int> _downloaded = const {};

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  @override
  void didUpdateWidget(ReciterRecitationView old) {
    super.didUpdateWidget(old);
    if (old.moshaf.id != widget.moshaf.id ||
        old.reciter.id != widget.reciter.id) {
      _surahs = recitationSurahs(widget.moshaf, widget.jsonData);
      _refreshDownloads();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final dir = await context.read<QuranPlayerCubit>().getDownloadDirPath();
    if (!mounted) return;
    _dir = dir;
    _refreshDownloads();
  }

  void _refreshDownloads() {
    final dir = _dir;
    if (dir == null || !Directory(dir).existsSync()) return;
    final cubit = context.read<QuranPlayerCubit>();
    setState(() {
      _downloaded = {
        for (final s in _surahs)
          if (cubit.isDownloaded(
            widget.reciter,
            widget.moshaf,
            s.number.toString(),
            dir,
          ))
            s.number,
      };
    });
  }

  List<RecitationSurah> get _shown {
    if (_query.isEmpty) return _surahs;
    final normalized = quran.normalise(_query);
    final lower = _query.toLowerCase();
    return [
      for (final s in _surahs)
        if (quran.normalise(s.name).contains(normalized) ||
            (s.number > 0 &&
                quran
                    .getSurahNameEnglish(s.number)
                    .toLowerCase()
                    .contains(lower)) ||
            s.number.toString().contains(_query))
          s,
    ];
  }

  void _play(RecitationSurah surah) {
    context.read<QuranPlayerCubit>().startPlaying(
      moshaf: widget.moshaf,
      reciter: widget.reciter,
      suraNumber: surah.number,
      initialIndex: surah.index,
      jsonData: widget.jsonData,
    );
    context.read<PlayerBarCubit>().show();
  }

  void _download(RecitationSurah surah) {
    final number = surah.number.toString();
    context.read<QuranPlayerCubit>().downloadSurah(
      reciter: widget.reciter,
      moshaf: widget.moshaf,
      suraNumber: number,
      url: '${widget.moshaf.server}/${number.padLeft(3, "0")}.mp3',
    );
  }

  void _downloadAll() {
    context.read<QuranPlayerCubit>().downloadAllSurahs(
      reciter: widget.reciter,
      moshaf: widget.moshaf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = space.gutter(width);
    final shown = _shown;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    return BlocListener<DownloadProgressCubit, DownloadProgressState>(
      // A surah finished: its mark and the plate's lobe fill in.
      listenWhen: (a, b) =>
          a.progress.length != b.progress.length ||
          a.batchProgress.length != b.batchProgress.length,
      listener: (_, _) => _refreshDownloads(),
      child: BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
        builder: (context, playerState) => _Playback(
          state: playerState,
          reciter: widget.reciter,
          moshaf: widget.moshaf,
          builder: (context, playingIndex, busyIndex, isPlaying) {
            final head = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HudaReveal(
                  child: RecitationPlate(
                    reciter: widget.reciter,
                    moshaf: widget.moshaf,
                    surahs: _surahs,
                    downloaded: _downloaded,
                    showName: widget.showName,
                    onDownloadAll: _downloadAll,
                  ),
                ),
                if (_surahs.length > 8) ...[
                  SizedBox(height: space.md),
                  HudaReveal(
                    index: 1,
                    child: HudaSearchField(
                      controller: _search,
                      hintText: l10n.searchSurahHint,
                      onChanged: (q) => setState(() => _query = q),
                    ),
                  ),
                ],
              ],
            );
            final list = <Widget>[
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: HudaStateView(
                    identity: quranAudioIdentity,
                    title: l10n.noResultsFound,
                  ),
                )
              else
                SliverPadding(
                  padding: context.scrollPadding(
                    EdgeInsets.fromLTRB(gutter, 0, gutter, space.xl),
                  ),
                  sliver: SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 960,
                    sliver:
                        BlocBuilder<
                          DownloadProgressCubit,
                          DownloadProgressState
                        >(
                          builder: (context, dl) => SliverAdaptiveGrid(
                            minTileWidth: 300 * scale,
                            spacing: space.sm,
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final surah = shown[i];
                              final progress = dl.getSurahProgress(
                                widget.reciter.id,
                                widget.moshaf.id,
                                surah.number.toString(),
                              );
                              final row = RecitationSurahRow(
                                surah: surah,
                                playing: playingIndex == surah.index,
                                sounding:
                                    playingIndex == surah.index && isPlaying,
                                busy: busyIndex == surah.index,
                                downloaded: _downloaded.contains(surah.number),
                                progress: progress != null && progress < 1
                                    ? progress
                                    : null,
                                onPlay: () => _play(surah),
                                onDownload: () => _download(surah),
                              );
                              return i < 6
                                  ? HudaReveal(index: i + 2, child: row)
                                  : row;
                            },
                          ),
                        ),
                  ),
                ),
            ];
            final fold = FoldInfo.of(context);
            final insets = MediaQuery.paddingOf(context);
            if (fold.isTabletop) {
              // The plate and the search above the fold, the surahs below.
              return QuranAudioTabletop(
                head: head,
                slivers: [
                  SliverPadding(padding: EdgeInsets.only(top: space.md)),
                  ...list,
                ],
              );
            }
            if (fold.isBook) {
              // The plate and the search on one side of the fold, the
              // surahs on the other.
              final size = MediaQuery.sizeOf(context);
              final rtl = Directionality.of(context) == TextDirection.rtl;
              final leading = rtl ? size.width - fold.end : fold.start;
              final trailing = rtl ? fold.start : size.width - fold.end;
              MediaQueryData side(double w, {required bool start}) =>
                  MediaQuery.of(context).copyWith(
                    size: Size(w, size.height),
                    displayFeatures: const [],
                    padding: start == !rtl
                        ? insets.copyWith(right: 0)
                        : insets.copyWith(left: 0),
                  );
              return Row(
                children: [
                  SizedBox(
                    width: leading,
                    child: MediaQuery(
                      data: side(leading, start: true),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          space.md,
                          gutter,
                          space.md + insets.bottom,
                        ),
                        child: head,
                      ),
                    ),
                  ),
                  SizedBox(width: size.width - leading - trailing),
                  SizedBox(
                    width: trailing,
                    child: MediaQuery(
                      data: side(trailing, start: false),
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.only(top: space.md),
                          ),
                          ...list,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              key: PageStorageKey(
                'recitation-${widget.reciter.id}-${widget.moshaf.id}',
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    gutter + insets.left,
                    space.md,
                    gutter + insets.right,
                    space.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: head,
                      ),
                    ),
                  ),
                ),
                ...list,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Which surah of this recitation plays, which is loading, and whether
/// it's sounding, from the player's state and streams.
class _Playback extends StatelessWidget {
  const _Playback({
    required this.state,
    required this.reciter,
    required this.moshaf,
    required this.builder,
  });

  final QuranPlayerState state;
  final Reciter reciter;
  final Moshaf moshaf;
  final Widget Function(
    BuildContext context,
    int? playingIndex,
    int? busyIndex,
    bool isPlaying,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final preparing =
        state is QuranPlayerLoading &&
        state.reciterId == reciter.id &&
        state.moshafId == moshaf.id;
    final player =
        state is QuranPlayerPlaying &&
            state.reciter.id == reciter.id &&
            state.moshaf.id == moshaf.id
        ? state.audioPlayer
        : null;
    // The same two stream builders whatever the player is doing (null
    // streams while it plays something else), so the page below keeps its
    // state: the plate's vine grows in once, not again on every surah
    // (owner round 2).
    return StreamBuilder<int?>(
      stream: player?.currentIndexStream,
      builder: (context, indexSnap) {
        final index = player == null
            ? null
            : indexSnap.data ?? player.currentIndex;
        return StreamBuilder<PlayerState>(
          stream: player?.playerStateStream,
          builder: (context, snap) {
            if (player == null) {
              return builder(
                context,
                null,
                preparing ? state.initialIndex : null,
                false,
              );
            }
            final ps = snap.data;
            final busy =
                ps?.processingState == ProcessingState.loading ||
                ps?.processingState == ProcessingState.buffering;
            return builder(
              context,
              index,
              busy ? index : null,
              ps?.playing ?? player.playing,
            );
          },
        );
      },
    );
  }
}

/// Caps a sliver's cross axis, centered (content at a readable width on
/// wide windows).
class SliverCrossAxisConstrained extends StatelessWidget {
  const SliverCrossAxisConstrained({
    super.key,
    required this.maxCrossAxisExtent,
    required this.sliver,
  });

  final double maxCrossAxisExtent;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final extra = constraints.crossAxisExtent - maxCrossAxisExtent;
        if (extra <= 0) return sliver;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: extra / 2),
          sliver: sliver,
        );
      },
    );
  }
}

/// The recitation's plate: night chrome with the reciter (in a pane), the
/// riwaya, the vine (growing in once as it opens) and Download all with its
/// progress.
class RecitationPlate extends StatefulWidget {
  const RecitationPlate({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.surahs,
    required this.downloaded,
    required this.showName,
    required this.onDownloadAll,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final List<RecitationSurah> surahs;
  final Set<int> downloaded;

  final bool showName;
  final VoidCallback onDownloadAll;

  @override
  State<RecitationPlate> createState() => _RecitationPlateState();
}

class _RecitationPlateState extends State<RecitationPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _trace = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.tokens.motion;
    if (motion.of(context, motion.long) == Duration.zero) {
      _trace.value = 1;
    } else {
      _trace.animateTo(1, curve: motion.standard);
    }
  }

  @override
  void dispose() {
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final downloadedCount = widget.downloaded.length;
    final total = widget.surahs.length;
    // Short windows keep the plate low so the surahs show under it.
    final short = MediaQuery.sizeOf(context).height < 480;

    final meta = [
      l10n.quranAudioSurahCount(total),
      if (downloadedCount > 0 && downloadedCount < total)
        l10n.quranAudioDownloadedCount(downloadedCount),
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: tokens.chromeGradient,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          space.lg,
          short ? space.sm : space.lg,
          space.lg,
          short ? space.xs : space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showName) ...[
              Text(
                widget.reciter.name.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: tokens.onChrome,
                ),
              ),
              SizedBox(height: space.xxs),
            ],
            Text(
              widget.moshaf.name.toString(),
              style:
                  (widget.showName
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                        color: widget.showName
                            ? tokens.onChromeMuted
                            : tokens.onChrome,
                      ),
            ),
            SizedBox(height: short ? space.xs : space.md),
            Ornament(
              size: Size(double.infinity, short ? 32 : 48),
              painter: ArabesqueVinePainter(
                style: OrnamentStyle.of(context, onChrome: true),
                textDirection: Directionality.of(context),
                growth: _trace,
              ),
            ),
            SizedBox(height: space.sm),
            BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
              builder: (context, dl) {
                final batch = dl.getBatchProgress(
                  widget.reciter.id,
                  widget.moshaf.id,
                );
                final running = batch != null && !batch.isDone;
                final all = downloadedCount >= total && total > 0;
                final metaText = Text(
                  running
                      ? l10n.quranAudioDownloadingCount(
                          batch.completed,
                          batch.total,
                        )
                      : meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.onChromeMuted,
                  ),
                );
                final Widget action;
                if (running) {
                  action = SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: batch.fraction,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                      color: tokens.gilt,
                      backgroundColor: tokens.onChromeMuted.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  );
                } else if (all) {
                  action = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_done_rounded,
                        size: 20,
                        color: tokens.gilt,
                      ),
                      SizedBox(width: space.xs),
                      Text(
                        l10n.quranAudioAllDownloaded,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.onChrome,
                        ),
                      ),
                    ],
                  );
                } else {
                  action = OutlinedButton.icon(
                    key: const ValueKey('quran-audio-download-all'),
                    onPressed: widget.onDownloadAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.onChrome,
                      side: BorderSide(
                        color: tokens.onChromeMuted.withValues(alpha: 0.6),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(l10n.downloadAll),
                  );
                }
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: space.md,
                  runSpacing: space.xs,
                  children: [metaText, action],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A surah of the recitation: its number (the voice glyph while it plays,
/// the lamp while it loads), name and verses, and its download: a button,
/// the progress, or a mark once it's on the device. Tapping plays it.
class RecitationSurahRow extends StatelessWidget {
  const RecitationSurahRow({
    super.key,
    required this.surah,
    required this.playing,
    required this.sounding,
    required this.busy,
    required this.downloaded,
    required this.progress,
    required this.onPlay,
    required this.onDownload,
  });

  final RecitationSurah surah;
  final bool playing;
  final bool sounding;
  final bool busy;
  final bool downloaded;
  final double? progress;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = tokens.motion;
    final active = playing || busy;
    final progress = this.progress;

    final Widget leading = busy
        ? const HudaLampSpinner(key: ValueKey('busy'), size: 22)
        : playing
        ? QuranVoiceGlyph(key: const ValueKey('voice'), playing: sounding)
        : Text(
            '${surah.number}',
            key: const ValueKey('number'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );

    final Widget trailing;
    if (progress != null) {
      trailing = SizedBox.square(
        key: const ValueKey('progress'),
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: tokens.lit,
              backgroundColor: scheme.outlineVariant,
            ),
          ),
        ),
      );
    } else if (downloaded) {
      trailing = SizedBox.square(
        key: const ValueKey('done'),
        dimension: 48,
        child: Tooltip(
          message: l10n.downloaded,
          child: Icon(
            Icons.download_done_rounded,
            size: 22,
            color: scheme.primary,
            semanticLabel: l10n.downloaded,
          ),
        ),
      );
    } else {
      trailing = IconButton(
        key: const ValueKey('download'),
        tooltip: l10n.downloadSurah,
        onPressed: onDownload,
        icon: const Icon(Icons.download_rounded),
        color: scheme.onSurfaceVariant,
      );
    }

    return AnimatedContainer(
      duration: motion.of(context, motion.medium),
      curve: motion.standard,
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          onTap: onPlay,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.xs,
                space.xs,
                space.xxs,
                space.xs,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: motion.of(context, motion.short),
                        child: leading,
                      ),
                    ),
                  ),
                  SizedBox(width: space.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          surah.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: active ? scheme.primary : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          busy
                              ? l10n.quranAudioPreparing
                              : surah.number > 0
                              ? l10n.verseCountLabel(
                                  quran.getVerseCount(surah.number),
                                )
                              : '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (progress != null) ...[
                          SizedBox(height: space.xxs),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: motion.of(context, motion.short),
                    child: trailing,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
