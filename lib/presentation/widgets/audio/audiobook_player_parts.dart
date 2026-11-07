import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_parts.dart';
import 'package:huda/presentation/widgets/audio/audio_format.dart';
import 'package:huda/presentation/widgets/audio/audiobook_bar.dart';
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The recording's swatch at full size, its plait the book: an eye per
/// chapter, the ones heard filled, the current one ringed and filling as
/// it plays. It weaves in as the player opens and weaves forward on each
/// new chapter.
class AudiobookPlayerArt extends StatelessWidget {
  const AudiobookPlayerArt({
    super.key,
    required this.state,
    required this.index,
    this.maxWidth = 320,
  });

  final AudiobookPlayerPlaying state;
  final int index;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final player = state.audioPlayer;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (context, snap) {
          final dur = player.duration ?? Duration.zero;
          final at = snap.data ?? player.position;
          return AudiobookSwatch(
            seed: state.audiobookId,
            chapters: state.tracks.length,
            current: index,
            fraction: dur.inMilliseconds > 0
                ? at.inMilliseconds / dur.inMilliseconds
                : 0,
            weaveIn: true,
          );
        },
      ),
    );
  }
}

/// The recording's title as an eyebrow, the chapter's title (cross-fading
/// on a new chapter), then "Chapter n of m · author".
class AudiobookPlayerTitles extends StatelessWidget {
  const AudiobookPlayerTitles({
    super.key,
    required this.state,
    required this.index,
    this.compact = false,
  });

  final AudiobookPlayerPlaying state;
  final int index;

  /// Short windows: a smaller chapter title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final line = [
      l10n.chapterProgress(index + 1, state.tracks.length),
      if (state.author.isNotEmpty) state.author,
      if (state.isOffline) l10n.audiobookDownloaded,
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaEyebrow(state.title),
        SizedBox(height: space.xs),
        HudaStateSwitcher(
          stateKey: index,
          sequential: true,
          child: Text(
            chapterTitle(context, state, index),
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: compact
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: space.xs),
        Text(
          line,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.onChromeMuted,
          ),
        ),
      ],
    );
  }
}

/// The seek slider, with how much is buffered, and the times under it.
class AudiobookSeek extends StatefulWidget {
  const AudiobookSeek({super.key, required this.player, required this.onSeek});

  final AudioPlayer player;
  final ValueChanged<Duration> onSeek;

  @override
  State<AudiobookSeek> createState() => _AudiobookSeekState();
}

class _AudiobookSeekState extends State<AudiobookSeek> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final player = widget.player;
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) => StreamBuilder<Duration>(
        stream: player.bufferedPositionStream,
        builder: (context, buffered) {
          final total = (player.duration ?? Duration.zero).inMilliseconds
              .toDouble();
          final at = (snap.data ?? player.position).inMilliseconds
              .toDouble()
              .clamp(0.0, total > 0 ? total : 0.0);
          final value = _drag ?? at;
          final ahead = (buffered.data ?? Duration.zero).inMilliseconds
              .toDouble()
              .clamp(value, total > 0 ? total : value);
          final style = theme.textTheme.labelMedium?.copyWith(
            color: tokens.onChromeMuted,
            fontWeight: FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  inactiveTrackColor: tokens.onChromeMuted.withValues(
                    alpha: 0.22,
                  ),
                  secondaryActiveTrackColor: tokens.onChromeMuted.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: Slider(
                min: 0,
                max: total > 0 ? total : 1,
                value: total > 0 ? value : 0,
                secondaryTrackValue: total > 0 ? ahead : null,
                semanticFormatterCallback: (v) =>
                    formatAudioDuration(Duration(milliseconds: v.round())),
                onChanged: total > 0 ? (v) => setState(() => _drag = v) : null,
                onChangeEnd: total > 0
                    ? (v) {
                        widget.onSeek(Duration(milliseconds: v.round()));
                        setState(() => _drag = null);
                      }
                    : null,
              ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.lg),
                child: Row(
                  children: [
                    Text(
                      formatAudioDuration(
                        Duration(milliseconds: value.round()),
                      ),
                      style: style,
                    ),
                    const Spacer(),
                    Text(
                      formatAudioDuration(
                        Duration(milliseconds: total.round()),
                      ),
                      style: style,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Previous chapter, back 15 seconds, play or pause (lit), forward 15
/// seconds, next chapter. Mirrored in RTL.
class AudiobookTransport extends StatelessWidget {
  const AudiobookTransport({
    super.key,
    required this.player,
    required this.cubit,
  });

  final AudioPlayer player;
  final AudiobookPlayerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return StreamBuilder<int?>(
      stream: player.currentIndexStream,
      builder: (context, _) => StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (context, snap) {
          final ps = snap.data;
          final playing = ps?.playing ?? player.playing;
          final busy =
              ps?.processingState == ProcessingState.loading ||
              ps?.processingState == ProcessingState.buffering;
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.audiobooksPreviousChapter,
                  iconSize: 28,
                  onPressed: player.hasPrevious ? cubit.previousChapter : null,
                  icon: Icon(
                    rtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                _Skip(
                  forward: false,
                  tooltip: l10n.audiobooksBack15,
                  onPressed: () => cubit.skipBackward(),
                ),
                const SizedBox(width: 12),
                AudiobookPlayButton(
                  playing: playing,
                  busy: busy,
                  size: 72,
                  onPressed: () => playing ? cubit.pause() : cubit.resume(),
                ),
                const SizedBox(width: 12),
                _Skip(
                  forward: true,
                  tooltip: l10n.audiobooksForward15,
                  onPressed: () =>
                      cubit.skipForward(const Duration(seconds: 15)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.audiobooksNextChapter,
                  iconSize: 28,
                  onPressed: player.hasNext ? cubit.nextChapter : null,
                  icon: Icon(
                    rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A 15-second skip: the circular arrow with the seconds in it.
class _Skip extends StatelessWidget {
  const _Skip({
    required this.forward,
    required this.tooltip,
    required this.onPressed,
  });

  final bool forward;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final flip = forward != rtl;
    final digits = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(15);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: SizedBox.square(
        dimension: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.flip(
              flipX: flip,
              child: const Icon(Icons.replay_rounded, size: 32),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                digits,
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed and the sleep timer as two quiet pills (the timer lit while it
/// runs, with what's left); each opens its sheet.
class AudiobookPlayerOptions extends StatelessWidget {
  const AudiobookPlayerOptions({
    super.key,
    required this.player,
    required this.cubit,
    this.sheetContext,
  });

  final AudioPlayer player;
  final AudiobookPlayerCubit cubit;

  /// Opens the sheets: a context outside the player's panes, so they see
  /// the whole window (a dialog on wide windows, centered across a flat
  /// fold) rather than one pane.
  final BuildContext? sheetContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final opener = sheetContext ?? context;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: space.sm,
      runSpacing: space.sm,
      children: [
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snap) {
            final speed = snap.data ?? player.speed;
            return Tooltip(
              message: l10n.playbackSpeed,
              child: Semantics(
                button: true,
                label: '${l10n.playbackSpeed}: ${speedLabel(context, speed)}',
                excludeSemantics: true,
                child: OutlinedButton.icon(
                  key: const ValueKey('audiobook-speed'),
                  onPressed: () =>
                      showAudiobookSpeedSheet(opener, cubit, speed),
                  icon: const Icon(Icons.speed_rounded, size: 20),
                  label: Text(speedLabel(context, speed)),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<Duration?>(
          valueListenable: cubit.sleepRemaining,
          builder: (context, remaining, _) {
            final label = remaining == null
                ? l10n.sleepTimer
                : remaining.isNegative
                ? l10n.endOfChapter
                : formatAudioDuration(remaining);
            void open() => showAudiobookSleepSheet(opener, cubit);
            if (remaining == null) {
              return OutlinedButton.icon(
                key: const ValueKey('audiobook-sleep'),
                onPressed: open,
                icon: const Icon(Icons.bedtime_outlined, size: 20),
                label: Text(label),
              );
            }
            return Semantics(
              label: remaining.isNegative
                  ? l10n.audiobooksSleepEndOfChapter
                  : l10n.audiobooksSleepPausesIn(label),
              button: true,
              excludeSemantics: true,
              child: FilledButton.icon(
                key: const ValueKey('audiobook-sleep'),
                onPressed: open,
                icon: const Icon(Icons.bedtime_rounded, size: 20),
                label: Text(
                  label,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "1.25×" in the locale's numerals.
String speedLabel(BuildContext context, double speed) {
  final format = intl.NumberFormat(
    '0.##',
    Localizations.localeOf(context).toLanguageTag(),
  );
  return '${format.format(speed)}×';
}

const List<double> audiobookSpeeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// The speeds as lit choice chips; choosing one sets it and closes.
Future<void> showAudiobookSpeedSheet(
  BuildContext context,
  AudiobookPlayerCubit cubit,
  double current,
) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.playbackSpeed,
    maxDialogWidth: 440,
    builder: (sheet) {
      final space = sheet.tokens.space;
      return Padding(
        padding: EdgeInsets.only(bottom: space.sm),
        child: Wrap(
          spacing: space.sm,
          runSpacing: space.sm,
          children: [
            for (final speed in audiobookSpeeds)
              ChoiceChip(
                label: Text(speedLabel(sheet, speed)),
                selected: speed == current,
                showCheckmark: false,
                onSelected: (_) {
                  HudaHaptics.selection(sheet);
                  cubit.setSpeed(speed);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}

/// The sleep timer: what it does now, the times as lit choice chips and
/// End of chapter; Turn off while it runs.
Future<void> showAudiobookSleepSheet(
  BuildContext context,
  AudiobookPlayerCubit cubit,
) {
  final l10n = AppLocalizations.of(context)!;
  const minutes = [5, 15, 30, 45, 60];
  return showHudaSheet<void>(
    context: context,
    title: l10n.sleepTimer,
    maxDialogWidth: 440,
    builder: (sheet) => ValueListenableBuilder<Duration?>(
      valueListenable: cubit.sleepRemaining,
      builder: (sheet, remaining, _) {
        final space = sheet.tokens.space;
        final theme = Theme.of(sheet);
        final chosen = cubit.initialSleepDuration?.inMinutes;
        final endOfChapter = remaining != null && remaining.isNegative;
        void done() {
          HudaHaptics.selection(sheet);
          Navigator.of(sheet).pop();
        }

        return Padding(
          padding: EdgeInsets.only(bottom: space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (remaining != null) ...[
                Text(
                  endOfChapter
                      ? l10n.audiobooksSleepEndOfChapter
                      : l10n.audiobooksSleepPausesIn(
                          formatAudioDuration(remaining),
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: space.md),
              ],
              Wrap(
                spacing: space.sm,
                runSpacing: space.sm,
                children: [
                  for (final m in minutes)
                    ChoiceChip(
                      label: Text(l10n.sleepTimerMinutes(m)),
                      selected:
                          remaining != null && !endOfChapter && chosen == m,
                      showCheckmark: false,
                      onSelected: (_) {
                        cubit.startSleepTimer(Duration(minutes: m));
                        done();
                      },
                    ),
                  ChoiceChip(
                    avatar: const Icon(
                      Icons.bookmark_outline_rounded,
                      size: 18,
                    ),
                    label: Text(l10n.endOfChapter),
                    selected: endOfChapter,
                    showCheckmark: false,
                    onSelected: (_) {
                      cubit.startEndOfChapterTimer();
                      done();
                    },
                  ),
                ],
              ),
              if (remaining != null) ...[
                SizedBox(height: space.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () {
                      cubit.cancelSleepTimer();
                      Navigator.of(sheet).pop();
                    },
                    icon: const Icon(Icons.timer_off_outlined),
                    label: Text(l10n.audiobooksSleepOff),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// The chapters in the player: a section header and a row per chapter;
/// a tap plays that chapter.
class AudiobookPlayerChapters extends StatelessWidget {
  const AudiobookPlayerChapters({
    super.key,
    required this.state,
    required this.index,
    required this.cubit,
    this.currentKey,
  });

  final AudiobookPlayerPlaying state;
  final int index;
  final AudiobookPlayerCubit cubit;

  /// On the current row, so a pane can scroll it into view.
  final Key? currentKey;

  @override
  Widget build(BuildContext context) {
    final player = state.audioPlayer;
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? player.playing;
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HudaSectionHeader(
              l10n.chapters,
              trailing: Text(
                l10n.audiobooksChapterCount(state.tracks.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.tokens.onChromeMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            for (var i = 0; i < state.tracks.length; i++)
              AudiobookChapterRow(
                key: i == index ? currentKey : null,
                index: i,
                track: state.tracks[i],
                current: i == index,
                playing: i == index && playing,
                onTap: () {
                  if (i == index) {
                    playing ? cubit.pause() : cubit.resume();
                  } else {
                    cubit.seekToIndex(i);
                  }
                },
              ),
          ],
        );
      },
    );
  }
}
