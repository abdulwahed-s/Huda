import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/audiobook_now_playing_screen.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/design/huda_audio_dock.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

Future<void> showAudiobookPlayer(BuildContext context) {
  final player = context.read<AudiobookPlayerCubit>();
  final bar = context.read<AudiobookBarCubit>();
  final navigator = Navigator.of(context);
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
          child: const AudiobookNowPlayingScreen(),
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

void stopAudiobook(BuildContext context) {
  context.read<AudiobookPlayerCubit>().closePlayer();
  context.read<AudiobookBarCubit>().hide();
}

class AudiobookBar extends StatelessWidget {
  const AudiobookBar({super.key});

  static bool showsFor(
    AudiobookBarVisibility bar,
    AudiobookPlayerState player,
  ) =>
      bar == AudiobookBarVisibility.visible && player is AudiobookPlayerPlaying;

  static Widget dock({required Widget child}) =>
      BlocBuilder<AudiobookBarCubit, AudiobookBarVisibility>(
        builder: (context, bar) =>
            BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
              builder: (context, player) => HudaAudioDock(
                visible: showsFor(bar, player),
                bar: const AudiobookBar(),
                child: child,
              ),
            ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
      builder: (context, state) {
        if (state is! AudiobookPlayerPlaying) return const SizedBox.shrink();
        return HudaNight(child: _Bar(state: state));
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.state});

  final AudiobookPlayerPlaying state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final insets = MediaQuery.paddingOf(context);
    final player = state.audioPlayer;
    final roomy =
        MediaQuery.sizeOf(context).width - insets.horizontal >=
        380 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    return Material(
      key: const ValueKey('audiobook-bar'),
      type: MaterialType.transparency,
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (context, posSnap) {
          final pos = posSnap.data ?? player.position;
          final dur = player.duration ?? Duration.zero;
          final played = dur.inMilliseconds > 0
              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;
          return InkWell(
            key: const ValueKey('audiobook-bar-open'),
            excludeFromSemantics: true,
            onTap: () => showAudiobookPlayer(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: played,
                  minHeight: 3,
                  color: tokens.gilt,
                  backgroundColor: tokens.onChromeMuted.withValues(alpha: 0.18),
                ),
                SizedBox(height: space.xxs),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    space.md + (rtl ? insets.right : insets.left),
                    0,
                    space.xs + (rtl ? insets.left : insets.right),
                    space.xs + insets.bottom,
                  ),
                  child: StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snap) {
                      final ps = snap.data;
                      final playing = ps?.playing ?? player.playing;
                      final busy =
                          ps?.processingState == ProcessingState.loading ||
                          ps?.processingState == ProcessingState.buffering;
                      return StreamBuilder<int?>(
                        stream: player.currentIndexStream,
                        builder: (context, indexSnap) {
                          final index =
                              indexSnap.data ?? player.currentIndex ?? 0;
                          return Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  label: l10n.quranAudioOpenPlayer,
                                  onTap: () => showAudiobookPlayer(context),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 56,
                                    ),
                                    child: Row(
                                      children: [
                                        AudiobookPlaitGlyph(fraction: played),
                                        SizedBox(width: space.sm),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                chapterTitle(
                                                  context,
                                                  state,
                                                  index,
                                                ),
                                                style:
                                                    theme.textTheme.titleSmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                busy
                                                    ? l10n.quranAudioPreparing
                                                    : state.title,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          tokens.onChromeMuted,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_up_rounded,
                                          size: 20,
                                          color: tokens.onChromeMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AudiobookPlayButton(
                                playing: playing,
                                busy: busy,
                                size: 48,
                                onPressed: () {
                                  final cubit = context
                                      .read<AudiobookPlayerCubit>();
                                  playing ? cubit.pause() : cubit.resume();
                                },
                              ),
                              if (roomy)
                                IconButton(
                                  tooltip: l10n.audiobooksForward30,
                                  onPressed: () => context
                                      .read<AudiobookPlayerCubit>()
                                      .skipForward(),
                                  icon: const Icon(Icons.forward_30_rounded),
                                ),
                              IconButton(
                                tooltip: l10n.stop,
                                onPressed: () => stopAudiobook(context),
                                icon: const Icon(Icons.stop_rounded),
                              ),
                            ],
                          );
                        },
                      );
                    },
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

String chapterTitle(
  BuildContext context,
  AudiobookPlayerPlaying state,
  int index,
) {
  if (index >= 0 && index < state.tracks.length) {
    final name = state.tracks[index].description.trim();
    if (name.isNotEmpty) return name;
    return AppLocalizations.of(context)!.chapter(index + 1);
  }
  return state.title;
}

class AudiobookPlaitGlyph extends StatelessWidget {
  const AudiobookPlaitGlyph({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: ClipRect(
        child: SizedBox(
          width: 40,
          height: 20,
          child: CustomPaint(
            painter: AudiobookRibbonPainter(
              style: OrnamentStyle(
                color: tokens.gilt,
                render: OrnamentRender.line,
                stroke: tokens.stroke.fine,
              ),
              window: const RibbonWindow(eyes: 3, start: -1),
              chapters: 1,
              heard: fraction,
              fill: tokens.gilt,
              fadeEnds: true,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class AudiobookPlayButton extends StatelessWidget {
  const AudiobookPlayButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.busy = false,
    this.size = 48,
  });

  final bool playing;
  final bool busy;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final motion = context.tokens.motion;
    final icon = busy
        ? HudaLampSpinner(
            key: const ValueKey('busy'),
            size: size * 0.42,
            color: Theme.of(context).colorScheme.onPrimary,
          )
        : Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            size: size * 0.5,
          );
    return SizedBox.square(
      dimension: size,
      child: Tooltip(
        message: playing ? l10n.pause : l10n.play,
        child: FilledButton(
          key: const ValueKey('audiobook-play'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: CircleBorder(
              side: BorderSide(
                color: context.tokens.onChrome.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
          onPressed: onPressed,
          child: AnimatedSwitcher(
            duration: motion.of(context, motion.short),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
