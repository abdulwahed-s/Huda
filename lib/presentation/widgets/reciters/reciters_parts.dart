import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';

/// Reciters that share a first letter, in catalog order.
class ReciterGroup {
  const ReciterGroup(this.letter, this.reciters);

  final String letter;
  final List<Reciter> reciters;
}

List<ReciterGroup> groupReciters(List<Reciter> reciters) {
  final groups = <ReciterGroup>[];
  for (final reciter in reciters) {
    final letter = reciter.letter?.toString() ?? '';
    if (groups.isEmpty || groups.last.letter != letter) {
      groups.add(ReciterGroup(letter, [reciter]));
    } else {
      groups.last.reciters.add(reciter);
    }
  }
  return groups;
}

/// A reciter and their recitations (riwayat): the name, then a row per
/// recitation with its count of surahs, how many are on the device, and
/// Play from the beginning. Tapping a row opens the recitation; on wide
/// windows the open one is [selected].
class ReciterCard extends StatelessWidget {
  const ReciterCard({
    super.key,
    required this.reciter,
    this.letter,
    required this.suwar,
    required this.downloadedCount,
    required this.selected,
    required this.onOpen,
    required this.showChevron,
  });

  final Reciter reciter;

  /// The letter, on the first card that starts with it, where cards flow in
  /// several columns without letter headings.
  final String? letter;
  final List suwar;
  final int Function(Moshaf moshaf) downloadedCount;
  final Moshaf? selected;
  final void Function(Moshaf moshaf) onOpen;

  /// Rows push a page (phones), rather than fill a pane.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(space.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.sm,
                space.sm,
                space.sm,
                space.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (letter != null) HudaEyebrow(letter!, header: true),
                  Text(
                    reciter.name.toString(),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            for (final moshaf in reciter.moshaf)
              RiwayaRow(
                reciter: reciter,
                moshaf: moshaf,
                suwar: suwar,
                downloaded: downloadedCount(moshaf),
                selected: selected?.id == moshaf.id,
                showChevron: showChevron,
                onOpen: () => onOpen(moshaf),
              ),
          ],
        ),
      ),
    );
  }
}

/// One recitation of a reciter: its name, counts or download progress,
/// and Play from the beginning (the voice glyph while it plays).
class RiwayaRow extends StatelessWidget {
  const RiwayaRow({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.suwar,
    required this.downloaded,
    required this.selected,
    required this.showChevron,
    required this.onOpen,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final List suwar;
  final int downloaded;
  final bool selected;
  final bool showChevron;
  final VoidCallback onOpen;

  int get _total => moshaf.surahList.toString().split(',').length;

  void _playFromStart(BuildContext context) {
    context.read<QuranPlayerCubit>().startPlaying(
      moshaf: moshaf,
      reciter: reciter,
      suraNumber: -1,
      initialIndex: 0,
      jsonData: suwar,
    );
    context.read<PlayerBarCubit>().show();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = tokens.motion;
    final total = _total;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        onTap: onOpen,
        child: AnimatedContainer(
          duration: motion.of(context, motion.short),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(tokens.radius.md),
          ),
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsetsDirectional.fromSTEB(
            space.sm,
            space.xs,
            0,
            space.xs,
          ),
          child: Semantics(
            selected: selected,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moshaf.name.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurface,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                      BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
                        builder: (context, dl) {
                          final batch = dl.getBatchProgress(
                            reciter.id,
                            moshaf.id,
                          );
                          final running = batch != null && !batch.isDone;
                          final meta = running
                              ? l10n.quranAudioDownloadingCount(
                                  batch.completed,
                                  batch.total,
                                )
                              : [
                                  l10n.quranAudioSurahCount(total),
                                  if (downloaded > 0)
                                    downloaded >= total
                                        ? l10n.quranAudioAllDownloaded
                                        : l10n.quranAudioDownloadedCount(
                                            downloaded,
                                          ),
                                ].join(' · ');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                meta,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              if (running)
                                Padding(
                                  padding: EdgeInsets.only(top: space.xxs),
                                  child: LinearProgressIndicator(
                                    value: batch.fraction,
                                    minHeight: 3,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
                  builder: (context, state) {
                    final preparing =
                        state is QuranPlayerLoading &&
                        state.reciterId == reciter.id &&
                        state.moshafId == moshaf.id;
                    final playing =
                        state is QuranPlayerPlaying &&
                        state.reciter.id == reciter.id &&
                        state.moshaf.id == moshaf.id;
                    final Widget child;
                    if (preparing) {
                      child = const SizedBox.square(
                        key: ValueKey('busy'),
                        dimension: 48,
                        child: Center(child: HudaLampSpinner(size: 22)),
                      );
                    } else if (playing) {
                      child = SizedBox.square(
                        key: const ValueKey('voice'),
                        dimension: 48,
                        child: Center(
                          child: StreamBuilder(
                            stream: state.audioPlayer.playerStateStream,
                            builder: (context, snap) => QuranVoiceGlyph(
                              playing:
                                  snap.data?.playing ??
                                  state.audioPlayer.playing,
                            ),
                          ),
                        ),
                      );
                    } else {
                      child = IconButton(
                        key: const ValueKey('play'),
                        tooltip: l10n.quranAudioPlayFromStart,
                        onPressed: () => _playFromStart(context),
                        color: scheme.primary,
                        icon: const Icon(Icons.play_circle_outline_rounded),
                      );
                    }
                    return AnimatedSwitcher(
                      duration: motion.of(context, motion.short),
                      child: child,
                    );
                  },
                ),
                if (showChevron)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: space.xs),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A letter heading the reciters that start with it.
class ReciterLetter extends StatelessWidget {
  const ReciterLetter(this.letter, {super.key});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(space.xxs, space.lg, 0, space.xs),
      child: Row(
        children: [
          HudaEyebrow(letter, header: true),
          SizedBox(width: space.sm),
          Expanded(
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton reciter cards while the catalog loads.
class ReciterCardSkeleton extends StatelessWidget {
  const ReciterCardSkeleton({super.key, this.rows = 1});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(space.md),
        child: HudaSkeleton(
          announce: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HudaSkeletonLines(lines: 1, style: theme.textTheme.titleMedium),
              for (var i = 0; i < rows; i++) ...[
                SizedBox(height: space.md),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  child: HudaSkeletonLines(
                    lines: 2,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide windows, before a recitation is chosen: the voiceprint large on a
/// chrome plate, and what to do.
class ChooseRecitationPane extends StatelessWidget {
  const ChooseRecitationPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // A roomy pane (laptops, large tablets) gets a larger plate.
        final large =
            constraints.maxWidth >= 640 && constraints.maxHeight >= 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(space.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - space.xl * 2).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: large ? 640 : 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HudaReveal(
                      child: QuranAudioArtPlate(
                        height: large ? 180 : 120,
                        painter: ArabesqueVinePainter(
                        style: OrnamentStyle.of(context, onChrome: true),
                        coils: 2,
                        textDirection: Directionality.of(context),
                      ),
                      ),
                    ),
                    SizedBox(height: space.xl),
                    HudaReveal(
                      index: 1,
                      child: Text(
                        l10n.quranAudioChooseTitle,
                        style: large
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: space.xs),
                    HudaReveal(
                      index: 2,
                      child: Text(
                        l10n.quranAudioChooseMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
