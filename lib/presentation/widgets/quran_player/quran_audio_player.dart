import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:just_audio/just_audio.dart';

import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';

/// Opens the full player over the current screen: it rises from the bar.
Future<void> showQuranAudioPlayer(BuildContext context) {
  final player = context.read<QuranPlayerCubit>();
  final bar = context.read<PlayerBarCubit>();
  final navigator = Navigator.of(context);
  // The page reads Lantern tokens from the opener's route-level scope.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final motion = context.tokens.motion;
  final duration = motion.of(context, motion.long);
  return navigator.push(
    PageRouteBuilder<void>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => themes.wrap(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: player),
            BlocProvider.value(value: bar),
          ],
          child: const QuranAudioPlayerPage(),
        ),
      ),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: motion.emphasized,
          reverseCurve: motion.emphasized.flipped,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

/// The full player, a night focus screen: the surah's name in the
/// Mushaf's calligraphy between two vines, which surah of the recitation,
/// the reciter, the seek slider, and the transport. Side by side
/// on wide and landscape windows, split at a half-open fold (book: art and
/// controls on either side; tabletop: art above, controls below).
class QuranAudioPlayerPage extends StatefulWidget {
  const QuranAudioPlayerPage({super.key});

  @override
  State<QuranAudioPlayerPage> createState() => _QuranAudioPlayerPageState();
}

class _QuranAudioPlayerPageState extends State<QuranAudioPlayerPage>
    with SingleTickerProviderStateMixin {
  /// The vines growing in as the player opens (the signature motion).
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _traced = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once, as the player opens; a new surah doesn't redraw them (owner
    // round 1).
    if (_traced) return;
    _traced = true;
    _trace();
  }

  void _trace() {
    final motion = context.tokens.motion;
    if (motion.of(context, motion.long) == Duration.zero) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaNight(
      child: BlocConsumer<QuranPlayerCubit, QuranPlayerState>(
        listener: (context, state) {
          // Stopped from elsewhere (the notification, another audio).
          if (state is QuranPlayerInitial || state is QuranPlayerError) {
            _close();
          }
        },
        builder: (context, state) {
          final playing = state is QuranPlayerPlaying ? state : null;
          return HudaImmersiveScaffold(
            leading: IconButton(
              tooltip: l10n.quranAudioHidePlayer,
              onPressed: _close,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            actions: [
              if (playing != null)
                IconButton(
                  tooltip: l10n.stop,
                  onPressed: () {
                    stopQuranPlayer(context, playing);
                    _close();
                  },
                  icon: const Icon(Icons.stop_rounded),
                ),
            ],
            body: playing == null
                ? const Center(child: HudaLampSpinner(size: 32))
                : StreamBuilder<int?>(
                    stream: playing.audioPlayer.currentIndexStream,
                    builder: (context, snap) {
                      final index =
                          snap.data ?? playing.audioPlayer.currentIndex ?? 0;
                      return _PlayerBody(
                        state: playing,
                        index: index,
                        reveal: _reveal,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.state,
    required this.index,
    required this.reveal,
  });

  final QuranPlayerPlaying state;
  final int index;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final space = context.tokens.space;
    final fold = FoldInfo.of(context);
    final sideChrome = HudaChromeFrame.hasSideChrome(context);
    // The bar floats over the page; content starts below it.
    final top = media.padding.top + (sideChrome ? space.md : kToolbarHeight);
    final pad = EdgeInsets.fromLTRB(
      media.padding.left + space.lg,
      top,
      media.padding.right + space.lg,
      media.padding.bottom + space.lg,
    );
    final size = media.size;

    final art = _PlayerArt(state: state, index: index, reveal: reveal);
    final controls = _PlayerControls(state: state, index: index);

    if (TabletopSplit.applies(context)) {
      // Things to look at above the fold, controls below it.
      return TabletopSplit(
        top: Padding(
          padding: EdgeInsets.fromLTRB(pad.left, top, pad.right, space.md),
          child: Center(child: FittedBox(child: art)),
        ),
        bottom: _Scrolling(
          padding: EdgeInsets.fromLTRB(
            pad.left,
            space.md,
            pad.right,
            pad.bottom,
          ),
          child: controls,
        ),
      );
    }

    // A vertical fold splits art and controls at the crease, flat too, so
    // nothing moves when the device bends.
    if (fold.hasFold && fold.splitsHorizontally && size.width >= 640) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final leading = rtl ? size.width - fold.end : fold.start;
      final trailing = rtl ? fold.start : size.width - fold.end;
      return Row(
        children: [
          SizedBox(
            width: leading,
            child: _Scrolling(
              padding: pad.copyWith(right: space.lg, left: space.lg),
              child: art,
            ),
          ),
          SizedBox(width: size.width - leading - trailing),
          SizedBox(
            width: trailing,
            child: _Scrolling(
              padding: pad.copyWith(left: space.lg, right: space.lg),
              child: controls,
            ),
          ),
        ],
      );
    }

    final wide = size.width >= 640 && size.width > size.height * 1.05;
    if (wide) {
      return Padding(
        padding: EdgeInsets.only(left: pad.left, right: pad.right),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _Scrolling(
                padding: EdgeInsets.only(top: top, bottom: pad.bottom),
                child: art,
              ),
            ),
            SizedBox(width: space.xl),
            Expanded(
              flex: 6,
              child: _Scrolling(
                padding: EdgeInsets.only(top: top, bottom: pad.bottom),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: controls,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _Scrolling(
      padding: pad,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.shortestSide >= 600 ? 720 : 560,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            SizedBox(height: size.height >= 760 ? space.huge : space.lg),
            controls,
          ],
        ),
      ),
    );
  }
}

/// Centers [child] in the room it has, and scrolls when it doesn't fit.
class _Scrolling extends StatelessWidget {
  const _Scrolling({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The surah's name in the Mushaf's calligraphy, then which surah of the
/// recitation, its name and the reciter.
class _PlayerArt extends StatelessWidget {
  const _PlayerArt({
    required this.state,
    required this.index,
    required this.reveal,
  });

  final QuranPlayerPlaying state;
  final int index;

  /// Grows the vines in (the signature motion).
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final surah = surahNumberAt(state, index);
    final large = MediaQuery.sizeOf(context).shortestSide >= 600;
    final short = MediaQuery.sizeOf(context).height < 700;
    // The vine above the name and below the reciter, growing in.
    Widget vine() => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: large ? 420 : 300),
      child: Ornament(
        size: Size(double.infinity, large ? 48 : (short ? 28 : 36)),
        painter: ArabesqueVinePainter(
          style: OrnamentStyle.of(context, onChrome: true),
          textDirection: Directionality.of(context),
          growth: reveal,
        ),
      ),
    );
    // The vines stay; only the surah's name and titles fade to the next.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        vine(),
        SizedBox(height: space.md),
        HudaStateSwitcher(
          stateKey: surah,
          sequential: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuranSurahCalligraphy(
                number: surah,
                size: large ? 148 : (short ? 60 : 76),
                color: tokens.gilt,
              ),
              SizedBox(height: space.lg),
              HudaEyebrow(
                l10n.quranAudioSurahOfTotal(
                  index + 1,
                  state.surahNumbers.length,
                ),
                color: tokens.gilt,
              ),
              SizedBox(height: space.xs),
              Text(
                surahTitleAt(state, index),
                style:
                    (large
                            ? theme.textTheme.displaySmall
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(color: tokens.onChrome),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: space.xxs),
              Text(
                state.reciter.name.toString(),
                style:
                    (large
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleSmall)
                        ?.copyWith(color: tokens.onChrome),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                state.moshaf.name.toString(),
                style:
                    (large
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.bodySmall)
                        ?.copyWith(color: tokens.onChromeMuted),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(height: space.md),
        vine(),
      ],
    );
  }
}

/// The seek slider with the times, the transport, and shuffle, repeat and
/// speed.
class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.state, required this.index});

  final QuranPlayerPlaying state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final player = state.audioPlayer;
    final large = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuranSeekBand(player: player),
        SizedBox(height: space.lg),
        LayoutBuilder(
          builder: (context, constraints) => StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snap) {
              // Narrow columns (the Duo closed in landscape) keep one row.
              final tight = constraints.maxWidth < 340;
              final ps = snap.data;
              final playing = ps?.playing ?? player.playing;
              final busy =
                  ps?.processingState == ProcessingState.loading ||
                  ps?.processingState == ProcessingState.buffering;
              return Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: tight ? 0 : space.xs,
                children: [
                  IconButton(
                    tooltip: l10n.previous,
                    iconSize: large ? 40 : 32,
                    onPressed: player.seekToPrevious,
                    icon: Icon(
                      rtl
                          ? Icons.skip_next_rounded
                          : Icons.skip_previous_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.quranAudioBack10,
                    iconSize: large ? 36 : 28,
                    onPressed: () {
                      final to = player.position - const Duration(seconds: 10);
                      player.seek(to.isNegative ? Duration.zero : to);
                    },
                    icon: Icon(
                      rtl ? Icons.forward_10_rounded : Icons.replay_10_rounded,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tight ? 0 : space.sm,
                    ),
                    child: QuranPlayButton(
                      playing: playing,
                      busy: busy,
                      size: tight ? 56 : (large ? 88 : 72),
                      onPressed: () => playing ? player.pause() : player.play(),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.quranAudioForward10,
                    iconSize: large ? 36 : 28,
                    onPressed: () {
                      final end = player.duration ?? Duration.zero;
                      final to = player.position + const Duration(seconds: 10);
                      player.seek(to > end ? end : to);
                    },
                    icon: Icon(
                      rtl ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.next,
                    iconSize: large ? 40 : 32,
                    onPressed: player.seekToNext,
                    icon: Icon(
                      rtl
                          ? Icons.skip_previous_rounded
                          : Icons.skip_next_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: space.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: space.xl,
          runSpacing: space.xs,
          children: [
            StreamBuilder<bool>(
              stream: player.shuffleModeEnabledStream,
              builder: (context, snap) {
                final on = snap.data ?? false;
                return _Toggle(
                  tooltip: l10n.quranAudioShuffle,
                  icon: Icons.shuffle_rounded,
                  on: on,
                  onPressed: () {
                    HudaHaptics.selection(context);
                    player.setShuffleModeEnabled(!on);
                  },
                );
              },
            ),
            StreamBuilder<LoopMode>(
              stream: player.loopModeStream,
              builder: (context, snap) {
                final mode = snap.data ?? LoopMode.off;
                const modes = [LoopMode.off, LoopMode.all, LoopMode.one];
                return _Toggle(
                  tooltip: switch (mode) {
                    LoopMode.off => l10n.quranAudioRepeatOff,
                    LoopMode.all => l10n.quranAudioRepeatAll,
                    LoopMode.one => l10n.quranAudioRepeatOne,
                  },
                  icon: mode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  on: mode != LoopMode.off,
                  onPressed: () {
                    HudaHaptics.selection(context);
                    player.setLoopMode(
                      modes[(modes.indexOf(mode) + 1) % modes.length],
                    );
                  },
                );
              },
            ),
            StreamBuilder<double>(
              stream: player.speedStream,
              builder: (context, snap) => _SpeedButton(
                speed: snap.data ?? 1.0,
                onChanged: player.setSpeed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A two-state player option: lit while on.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.tooltip,
    required this.icon,
    required this.on,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      toggled: on,
      child: IconButton(
        tooltip: tooltip,
        isSelected: on,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: tokens.onChromeMuted,
          backgroundColor: on ? tokens.lit : null,
        ),
        color: on ? tokens.onChrome : tokens.onChromeMuted,
        icon: Icon(icon),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final format = NumberFormat(
      '0.##',
      Localizations.localeOf(context).toString(),
    );
    String label(double s) => '${format.format(s)}×';
    final custom = speed != 1.0;
    return PopupMenuButton<double>(
      tooltip: l10n.playbackSpeed,
      initialValue: speed,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in _speeds)
          CheckedPopupMenuItem(
            value: s,
            checked: s == speed,
            child: Text(label(s)),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space.md,
              vertical: tokens.space.xs,
            ),
            decoration: BoxDecoration(
              color: custom ? tokens.lit : null,
              borderRadius: BorderRadius.circular(tokens.radius.md),
              border: Border.all(
                color: custom ? tokens.lit : theme.colorScheme.outline,
              ),
            ),
            child: Text(
              label(speed),
              style: theme.textTheme.labelLarge?.copyWith(
                color: custom ? tokens.onChrome : tokens.onChromeMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The seek control: a lit slider with the times under it. Material's
/// slider brings TalkBack and VoiceOver steps and the arrow keys; it reads
/// the position as a time.
class QuranSeekBand extends StatefulWidget {
  const QuranSeekBand({super.key, required this.player});

  final AudioPlayer player;

  @override
  State<QuranSeekBand> createState() => _QuranSeekBandState();
}

class _QuranSeekBandState extends State<QuranSeekBand> {
  double? _dragging;

  static String _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final large = MediaQuery.sizeOf(context).shortestSide >= 600;
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snap) {
        final position = snap.data ?? widget.player.position;
        final duration = widget.player.duration ?? Duration.zero;
        final ms = duration.inMilliseconds;
        final value =
            _dragging ??
            (ms > 0 ? position.inMilliseconds.clamp(0, ms).toDouble() : 0.0);
        final shown = Duration(milliseconds: value.round());
        final timeStyle =
            (large ? theme.textTheme.labelLarge : theme.textTheme.labelMedium)
                ?.copyWith(
                  color: tokens.onChromeMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.quranAudioPosition,
              // Lit in the warm on-chrome tone: the theme's lit fill is
              // the chrome itself and vanishes on the night page.
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: large ? 6 : 4,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: large ? 10 : 8,
                  ),
                  activeTrackColor: tokens.onChrome,
                  thumbColor: tokens.onChrome,
                  overlayColor: tokens.onChrome.withValues(alpha: 0.12),
                ),
                child: Slider(
                  // A quiet track on the night chrome (the theme's own one
                  // reads warm there).
                  inactiveColor: tokens.onChromeMuted.withValues(alpha: 0.25),
                  value: value,
                  max: ms > 0 ? ms.toDouble() : 1,
                  semanticFormatterCallback: (v) =>
                      '${_time(Duration(milliseconds: v.round()))} / ${_time(duration)}',
                  onChanged: ms > 0
                      ? (v) => setState(() => _dragging = v)
                      : null,
                  onChangeEnd: (v) {
                    setState(() => _dragging = null);
                    widget.player.seek(Duration(milliseconds: v.round()));
                  },
                ),
              ),
            ),
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.lg),
                child: Row(
                  children: [
                    Text(_time(shown), style: timeStyle),
                    const Spacer(),
                    Text(_time(duration), style: timeStyle),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
