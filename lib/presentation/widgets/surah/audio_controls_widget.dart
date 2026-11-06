import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';

/// The ayah's recitation in its sheet: where it is (a seek bar with the
/// times), then previous, play or pause (lit), next.
class AudioControlsWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final int currentIndex;
  final int totalAyahs;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(double) onSeek;
  final Function(bool) onUserSeekingChanged;
  final bool isPlayButtonEnabled;

  const AudioControlsWidget({
    super.key,
    required this.audioPlayer,
    required this.currentIndex,
    required this.totalAyahs,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
    required this.onSeek,
    required this.onUserSeekingChanged,
    this.isPlayButtonEnabled = true,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final times = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalDuration.inMilliseconds > 0) ...[
          Slider(
            value:
                (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
                    .clamp(0.0, 1.0),
            onChanged: (value) {
              onUserSeekingChanged(true);
              onSeek(value);
            },
            onChangeEnd: (_) => onUserSeekingChanged(false),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(currentPosition), style: times),
                Text(_formatDuration(totalDuration), style: times),
              ],
            ),
          ),
          SizedBox(height: space.xs),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: l10n.previous,
              onPressed: currentIndex > 0 ? onPrevious : null,
              icon: Icon(
                isRtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
              ),
            ),
            SizedBox(width: space.lg),
            SizedBox.square(
              dimension: 64,
              child: FilledButton(
                key: const ValueKey('quran-ayah-play'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                onPressed: isPlayButtonEnabled ? onPlayPause : null,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                  semanticLabel: isPlaying ? l10n.pause : l10n.play,
                ),
              ),
            ),
            SizedBox(width: space.lg),
            IconButton.outlined(
              tooltip: l10n.next,
              onPressed: currentIndex < totalAyahs - 1 ? onNext : null,
              icon: Icon(
                isRtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
