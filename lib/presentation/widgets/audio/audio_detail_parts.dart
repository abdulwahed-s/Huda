import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audiobook_download/audiobook_download_cubit.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audiobook_bar.dart'
    show AudiobookPlaitGlyph;
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The recording at the head of its page: its swatch with an eye per
/// chapter (those heard filled, the one to resume ringed; it weaves in as
/// the page opens), the title, who prepared it, how many chapters and the
/// language.
class AudioDetailHero extends StatelessWidget {
  const AudioDetailHero({
    super.key,
    required this.seed,
    required this.title,
    required this.author,
    required this.chapters,
    required this.current,
    required this.fraction,
    required this.language,
    this.downloaded = false,
    this.swatchWidth = 360,
  });

  /// The swatch's largest width (smaller on short windows).
  final double swatchWidth;
  final int seed;
  final String title;
  final String author;
  final int chapters;

  /// The chapter playing or to resume; null before the first listen.
  final int? current;
  final double fraction;
  final String? language;
  final bool downloaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final meta = [
      if (chapters > 0) l10n.audiobooksChapterCount(chapters),
      if (language != null && language!.isNotEmpty) language!,
      if (downloaded) l10n.audiobookDownloaded,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: swatchWidth),
            child: AudiobookSwatch(
              seed: seed,
              chapters: chapters > 0 ? chapters : null,
              current: chapters > 0 ? (current ?? -1) : null,
              fraction: fraction,
              weaveIn: true,
              semanticLabel: current != null && chapters > 0
                  ? l10n.chapterProgress(current! + 1, chapters)
                  : null,
            ),
          ),
        ),
        SizedBox(height: space.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (author.isNotEmpty) ...[
          SizedBox(height: space.xs),
          Text(
            author,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (meta.isNotEmpty) ...[
          SizedBox(height: space.xs),
          Text(
            meta,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

/// Play (or Resume chapter n, or Pause) and the download control, side by
/// side; stacked when the row is narrow for the text size. A failed
/// download says so under them with Retry.
class AudioDetailActions extends StatelessWidget {
  const AudioDetailActions({
    super.key,
    required this.audioId,
    required this.playLabel,
    required this.playIcon,
    required this.onPlay,
    required this.onDownload,
    required this.onRemove,
  });

  final int audioId;
  final String playLabel;
  final IconData playIcon;
  final VoidCallback? onPlay;

  /// Null when the recording can't be downloaded (its details aren't
  /// loaded, or the platform can't).
  final VoidCallback? onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return BlocBuilder<AudiobookDownloadCubit, AudiobookDownloadState>(
      builder: (context, download) {
        final play = FilledButton.icon(
          key: const ValueKey('audiobook-play-page'),
          onPressed: onPlay,
          icon: Icon(playIcon),
          label: Text(playLabel, textAlign: TextAlign.center),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
        );
        final save = _DownloadButton(
          state: download,
          onDownload: onDownload,
          onCancel: () =>
              context.read<AudiobookDownloadCubit>().cancel(audioId),
          onRemove: onRemove,
        );
        final failed =
            download.error != null &&
            !download.isDownloading &&
            !download.isDownloaded;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow =
                    constraints.maxWidth <
                    MediaQuery.textScalerOf(context).scale(340);
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      play,
                      SizedBox(height: space.sm),
                      save,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: play),
                    SizedBox(width: space.sm),
                    Expanded(flex: 2, child: save),
                  ],
                );
              },
            ),
            if (failed && onDownload != null) ...[
              SizedBox(height: space.sm),
              HudaStatusBanner(
                status: HudaStatus.failed,
                message: l10n.audiobooksDownloadFailed,
                onRetry: onDownload,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.state,
    required this.onDownload,
    required this.onCancel,
    required this.onRemove,
  });

  final AudiobookDownloadState state;
  final VoidCallback? onDownload;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final motion = context.tokens.motion;
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, onPressed, tooltip) = state.isDownloading
        ? (
            SizedBox.square(
              key: const ValueKey('downloading'),
              dimension: 18,
              child: CircularProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                strokeWidth: 2.5,
                backgroundColor: scheme.primary.withValues(alpha: 0.16),
              ),
            ),
            '${(state.progress * 100).round()}%',
            onCancel,
            l10n.audiobooksCancelDownload,
          )
        : state.isDownloaded
        ? (
            const Icon(Icons.download_done_rounded, key: ValueKey('done')),
            l10n.audiobookDownloaded,
            onRemove,
            l10n.booksRemoveDownloadTitle,
          )
        : (
            const Icon(Icons.download_rounded, key: ValueKey('download')),
            l10n.download,
            onDownload,
            l10n.download,
          );
    final semantics = state.isDownloading
        ? '${l10n.audiobooksDownloadingPercent((state.progress * 100).round().toString())}, ${l10n.audiobooksCancelDownload}'
        : label;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        child: OutlinedButton.icon(
        key: const ValueKey('audiobook-download'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
        icon: AnimatedSwitcher(
          duration: motion.of(context, motion.short),
          child: icon,
        ),
        label: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// What the recording is about: a few lines, then Read more.
class AudioDetailAbout extends StatefulWidget {
  const AudioDetailAbout({super.key, required this.text});

  final String text;

  @override
  State<AudioDetailAbout> createState() => _AudioDetailAboutState();
}

class _AudioDetailAboutState extends State<AudioDetailAbout> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudaSectionHeader(l10n.aboutThisAudio),
        LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 4,
            )..layout(maxWidth: constraints.maxWidth);
            final long = painter.didExceedMaxLines;
            painter.dispose();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: tokens.motion.of(context, tokens.motion.medium),
                  curve: tokens.motion.standard,
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    widget.text,
                    style: style,
                    maxLines: _open || !long ? null : 4,
                    overflow: _open || !long ? null : TextOverflow.ellipsis,
                  ),
                ),
                if (long)
                  TextButton(
                    onPressed: () => setState(() => _open = !_open),
                    child: Text(_open ? l10n.readLess : l10n.readMore),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The recording's chapters: number, title and size; the one playing
/// lit with its state. Tap a chapter to play it; tap the one playing to
/// pause or resume it.
class AudioDetailChapters extends StatelessWidget {
  const AudioDetailChapters({
    super.key,
    required this.tracks,
    required this.current,
    required this.playing,
    required this.onTap,
    this.resume = -1,
  });

  final List<AudioTrack> tracks;

  /// The chapter listening stopped at, marked while nothing plays it.
  final int resume;

  /// The chapter the player is on (this recording only), or -1.
  final int current;
  final bool playing;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaSectionHeader(
          l10n.chapters,
          trailing: tracks.isEmpty
              ? null
              : Text(
                  l10n.audiobooksChapterCount(tracks.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
        if (tracks.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: space.lg),
            child: Text(
              l10n.noChapters,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < tracks.length; i++)
            AudiobookChapterRow(
              index: i,
              track: tracks[i],
              current: i == current,
              playing: i == current && playing,
              resume: current < 0 && i == resume,
              onTap: () => onTap(i),
            ),
      ],
    );
  }
}

/// One chapter: its number (or, when it's the one playing, a lit mark),
/// its title and size, and what a tap does at the end.
class AudiobookChapterRow extends StatelessWidget {
  const AudiobookChapterRow({
    super.key,
    required this.index,
    required this.track,
    required this.current,
    required this.playing,
    required this.onTap,
    this.resume = false,
  });

  final int index;
  final AudioTrack track;
  final bool current;
  final bool playing;

  /// Where listening stopped: a bookmark instead of the number.
  final bool resume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final title = track.description.trim().isNotEmpty
        ? track.description.trim()
        : l10n.chapter(index + 1);
    final accent = scheme.primary;
    return Semantics(
      button: true,
      selected: current,
      label: '${l10n.chapter(index + 1)}: $title',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          onTap: onTap,
          child: AnimatedContainer(
            duration: tokens.motion.of(context, tokens.motion.medium),
            curve: tokens.motion.standard,
            constraints: const BoxConstraints(minHeight: 56),
            padding: EdgeInsets.symmetric(
              horizontal: space.sm,
              vertical: space.xs,
            ),
            decoration: BoxDecoration(
              color: current
                  ? accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.radius.md),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: current
                      ? const Center(child: AudiobookPlaitGlyph(fraction: 1))
                      : resume
                      ? Icon(Icons.bookmark_rounded, size: 20, color: accent)
                      : Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
                SizedBox(width: space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (current
                                    ? theme.textTheme.titleSmall
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(color: current ? accent : null),
                      ),
                      if (track.size.isNotEmpty)
                        Text(
                          track.size,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: space.xs),
                Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: current ? accent : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's skeleton while the recording loads: the swatch, the title,
/// the buttons and a few chapter rows.
class AudioDetailSkeleton extends StatelessWidget {
  const AudioDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return HudaSkeleton(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: const AspectRatio(
                    aspectRatio: AudiobookSwatch.aspect,
                    child: HudaSkeletonBlock(height: double.infinity),
                  ),
                ),
              ),
              SizedBox(height: space.lg),
              HudaSkeletonLines(lines: 2, style: theme.textTheme.headlineSmall),
              SizedBox(height: space.lg),
              const HudaSkeletonBlock(height: 52),
              SizedBox(height: space.xl),
              for (var i = 0; i < 4; i++) ...[
                const HudaSkeletonBlock(height: 48),
                SizedBox(height: space.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
