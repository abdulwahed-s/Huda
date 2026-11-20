import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_audio_dock.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_player.dart';

class PlayerBarWidget extends StatelessWidget {
  const PlayerBarWidget({super.key});

  static bool showsFor(PlayerBarVisibility bar, QuranPlayerState player) =>
      bar != PlayerBarVisibility.hidden && player is QuranPlayerPlaying;

  static Widget dock({required Widget child}) =>
      BlocListener<QuranPlayerCubit, QuranPlayerState>(
        listenWhen: (_, state) => state is QuranPlayerError,
        listener: (context, _) => showHudaToast(
          context,
          message: AppLocalizations.of(context)!.unexpectedError,
          kind: HudaToastKind.failed,
        ),
        child: BlocBuilder<PlayerBarCubit, PlayerBarVisibility>(
          builder: (context, bar) =>
              BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
                builder: (context, player) => HudaAudioDock(
                  visible: showsFor(bar, player),
                  bar: const PlayerBarWidget(),
                  child: child,
                ),
              ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBarCubit, PlayerBarVisibility>(
      builder: (context, barState) {
        return BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
          builder: (context, playerState) {
            if (!showsFor(barState, playerState)) {
              return const SizedBox.shrink();
            }
            return HudaNight(
              child: _MiniPlayer(state: playerState as QuranPlayerPlaying),
            );
          },
        );
      },
    );
  }
}

void stopQuranPlayer(BuildContext context, QuranPlayerPlaying state) {
  state.audioPlayer.stop();
  context.read<PlayerBarCubit>().hide();
  context.read<QuranPlayerCubit>().closePlayer();
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.state});

  final QuranPlayerPlaying state;

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
      key: const ValueKey('quran-audio-bar'),
      type: MaterialType.transparency,
      child: StreamBuilder<int?>(
        stream: player.currentIndexStream,
        builder: (context, indexSnap) {
          final index = indexSnap.data ?? player.currentIndex ?? 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, posSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = player.duration ?? Duration.zero;
                  final played = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0;
                  return LinearProgressIndicator(
                    value: played,
                    minHeight: 3,
                    color: tokens.gilt,
                    backgroundColor: tokens.onChromeMuted.withValues(
                      alpha: 0.18,
                    ),
                  );
                },
              ),
              SizedBox(height: space.xxs),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.sm + (rtl ? insets.right : insets.left),
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
                    return Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: l10n.quranAudioOpenPlayer,
                            excludeSemantics: false,
                            child: InkWell(
                              key: const ValueKey('quran-audio-bar-open'),
                              borderRadius: BorderRadius.circular(
                                tokens.radius.md,
                              ),
                              onTap: () => showQuranAudioPlayer(context),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: Row(
                                  children: [
                                    QuranVoiceGlyph(
                                      playing: playing && !busy,
                                      color: tokens.gilt,
                                    ),
                                    SizedBox(width: space.sm),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            surahTitleAt(state, index),
                                            style: theme.textTheme.titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            busy
                                                ? l10n.quranAudioPreparing
                                                : state.reciter.name.toString(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: tokens.onChromeMuted,
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
                        ),
                        if (roomy)
                          IconButton(
                            tooltip: l10n.previous,
                            onPressed: player.seekToPrevious,
                            icon: Icon(
                              rtl
                                  ? Icons.skip_next_rounded
                                  : Icons.skip_previous_rounded,
                            ),
                          ),
                        QuranPlayButton(
                          playing: playing,
                          busy: busy,
                          size: 48,
                          onPressed: () =>
                              playing ? player.pause() : player.play(),
                        ),
                        if (roomy)
                          IconButton(
                            tooltip: l10n.next,
                            onPressed: player.seekToNext,
                            icon: Icon(
                              rtl
                                  ? Icons.skip_previous_rounded
                                  : Icons.skip_next_rounded,
                            ),
                          ),
                        IconButton(
                          tooltip: l10n.stop,
                          onPressed: () => stopQuranPlayer(context, state),
                          icon: const Icon(Icons.stop_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuranPlayButton extends StatelessWidget {
  const QuranPlayButton({
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
          key: const ValueKey('quran-audio-play'),
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

int surahNumberAt(QuranPlayerPlaying state, int index) {
  if (index < 0 || index >= state.surahNumbers.length) return state.suraNumber;
  return int.tryParse(state.surahNumbers[index]) ?? state.suraNumber;
}

String surahTitleAt(QuranPlayerPlaying state, int index) {
  final number = surahNumberAt(state, index);
  final match = state.jsonData
      .where((e) => e['id'].toString() == number.toString())
      .toList();
  return match.isNotEmpty ? match.first['name'].toString() : 'Surah $number';
}

class QuranAudioTabletop extends StatelessWidget {
  const QuranAudioTabletop({
    super.key,
    required this.head,
    required this.slivers,
  });

  final Widget head;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return TabletopSplit(
      top: Builder(
        builder: (context) {
          final space = context.tokens.space;
          final media = MediaQuery.of(context);
          final gutter = space.gutter(media.size.width);
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                gutter + media.padding.left,
                space.sm,
                gutter + media.padding.right,
                space.sm,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - space.sm * 2).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: head,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottom: CustomScrollView(slivers: slivers),
    );
  }
}

class QuranAudioArtPlate extends StatelessWidget {
  const QuranAudioArtPlate({
    super.key,
    required this.painter,
    this.height = 96,
  });

  final CustomPainter painter;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: tokens.chromeGradient,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space.xl,
          vertical: tokens.space.lg,
        ),
        child: Ornament(size: Size(double.infinity, height), painter: painter),
      ),
    );
  }
}
