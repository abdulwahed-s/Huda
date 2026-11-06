import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/athkar_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// Where a dhikr's audio is: not this one, or this one playing or paused
/// at [position] of [duration].
@immutable
class AthkarCardAudio {
  const AthkarCardAudio({
    this.current = false,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool current;
  final bool playing;
  final Duration position;
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is AthkarCardAudio &&
      other.current == current &&
      other.playing == playing &&
      other.position == position &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(current, playing, position, duration);
}

/// One dhikr. Tapping the card says it once: the medallion's petals light
/// and its numeral counts down. Once done it folds into a one-line row
/// ([folded]); tapping the row opens it again.
class AthkarDhikrCard extends StatelessWidget {
  const AthkarDhikrCard({
    super.key,
    required this.dhikr,
    required this.remaining,
    required this.total,
    required this.folded,
    required this.showTranslation,
    required this.audio,
    required this.onCount,
    required this.onUnfold,
    required this.onReset,
    required this.onShare,
    this.onPlay,
    this.onSeek,
  });

  final AthkarDetailModel dhikr;
  final int remaining;
  final int total;
  final bool folded;
  final bool showTranslation;
  final AthkarCardAudio audio;
  final VoidCallback onCount;
  final VoidCallback onUnfold;
  final VoidCallback onReset;
  final VoidCallback onShare;

  /// Null when the dhikr has no audio.
  final VoidCallback? onPlay;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    // Continue: the card folds and opens in place, shrinking while it
    // cross-fades, so the cards below move up instead of jumping.
    const motion = HudaMotion();
    final duration = motion.of(context, motion.long);
    // Reduce motion: swap at once (a zero-length size animation throws).
    if (duration == Duration.zero) {
      return folded ? _folded(context) : _open(context);
    }
    return AnimatedCrossFade(
      duration: duration,
      firstCurve: motion.standard,
      secondCurve: motion.standard,
      sizeCurve: motion.emphasized,
      alignment: Alignment.topCenter,
      crossFadeState: folded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: _open(context),
      secondChild: _folded(context),
    );
  }

  Widget _folded(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: l10n.done,
      child: HudaCard(
        onTap: onUnfold,
        padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.xs),
        child: Row(
          children: [
            AthkarMedallion(remaining: 0, total: total, size: 36),
            SizedBox(width: space.md),
            Expanded(
              child: Text(
                dhikr.arabicText ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: context.type.arabicLabel.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: space.xs),
            Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _open(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arabic = dhikr.arabicText ?? '';
    final translation = showTranslation
        ? (dhikr.translatedText ?? '').trim()
        : '';
    final done = remaining <= 0;
    final status = done
        ? l10n.done
        : remaining == total
        ? l10n.athkarRepeatTimes(total)
        : l10n.athkarLeft(remaining);
    // Short athkar read best centered; long ones from the start (never
    // justified: narrow columns and large text open wide gaps).
    final short = arabic.length <= 90;
    final onPlay = this.onPlay;

    return Semantics(
      value: status,
      hint: done ? null : l10n.athkarTapToCount,
      // A faint press over the Arabic instead of an ink splash flooding it
      // on every tap (owner round 1); the press-in and the medallion
      // answer the tap.
      child: Theme(
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: scheme.primary.withValues(alpha: 0.04),
        ),
        child: HudaCard(
          onTap: done ? null : onCount,
          padding: EdgeInsets.fromLTRB(space.md, space.md, space.md, space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AthkarMedallion(remaining: remaining, total: total),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        status,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: done
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (remaining < total)
                    IconButton(
                      tooltip: l10n.reset,
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                  IconButton(
                    tooltip: l10n.share,
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
              SizedBox(height: space.md),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: space.xs),
                child: Text(
                  arabic,
                  textAlign: short ? TextAlign.center : TextAlign.start,
                  textDirection: TextDirection.rtl,
                  style: context.type.dhikr,
                ),
              ),
              if (translation.isNotEmpty) ...[
                SizedBox(height: space.sm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: space.xs),
                  child: Text(
                    translation,
                    textAlign: short ? TextAlign.center : TextAlign.start,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (onPlay != null) ...[
                SizedBox(height: space.md),
                _AudioRow(audio: audio, onPlay: onPlay, onSeek: onSeek),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Listen, and while this dhikr's audio is loaded, where it is.
class _AudioRow extends StatelessWidget {
  const _AudioRow({required this.audio, required this.onPlay, this.onSeek});

  final AthkarCardAudio audio;
  final VoidCallback onPlay;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final playing = audio.current && audio.playing;
    final total = audio.duration.inMilliseconds;
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final button = IconButton.filledTonal(
      tooltip: playing ? l10n.pause : l10n.play,
      onPressed: onPlay,
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
    return Row(
      children: [
        button,
        SizedBox(width: space.xs),
        if (!audio.current)
          Expanded(
            child: Text(
              l10n.athkarListen,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          Text(_time(audio.position), style: muted),
          Expanded(
            child: Slider(
              max: total <= 0 ? 1 : total.toDouble(),
              value: total <= 0
                  ? 0
                  : audio.position.inMilliseconds.clamp(0, total).toDouble(),
              onChanged: total <= 0 || onSeek == null
                  ? null
                  : (value) => onSeek!(Duration(milliseconds: value.round())),
            ),
          ),
          Text(_time(audio.duration), style: muted),
        ],
      ],
    );
  }

  static String _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}
