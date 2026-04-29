import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String _surahTitle(QuranPlayerPlaying state, int index) {
  if (index < 0 || index >= state.surahNumbers.length) return '';
  final sNum = state.surahNumbers[index];
  final match = state.jsonData
      .where((e) => e['id'].toString() == sNum.toString())
      .toList();
  return match.isNotEmpty ? match.first['name'].toString() : 'Surah $sNum';
}

class PlayerBarWidget extends StatelessWidget {
  const PlayerBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBarCubit, PlayerBarVisibility>(
      builder: (context, barState) {
        if (barState == PlayerBarVisibility.hidden) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
          builder: (context, playerState) {
            if (playerState is! QuranPlayerPlaying) {
              return const SizedBox.shrink();
            }
            return _MiniPlayer(state: playerState);
          },
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final QuranPlayerPlaying state;
  const _MiniPlayer({required this.state});

  void _openSheet(BuildContext context) {
    final playerCubit = context.read<QuranPlayerCubit>();
    final barCubit = context.read<PlayerBarCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: playerCubit),
          BlocProvider.value(value: barCubit),
        ],
        child: _ExpandedPlayerSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _openSheet(context),
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! < -300) {
          _openSheet(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: state.audioPlayer.positionStream,
                builder: (context, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = state.audioPlayer.duration ?? Duration.zero;
                  final frac = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return LinearProgressIndicator(
                    value: frac,
                    minHeight: 2.5,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                  );
                },
              ),
              Container(
                height: 62.h,
                color: theme.colorScheme.primaryContainer,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.library_music_rounded,
                            color: theme.colorScheme.primary, size: 22.sp),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: StreamBuilder<int?>(
                          stream: state.audioPlayer.currentIndexStream,
                          builder: (context, snapshot) {
                            final idx = snapshot.data ?? 0;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _surahTitle(state, idx),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.reciter.name.toString(),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded,
                            size: 24.sp,
                            color: theme.colorScheme.onPrimaryContainer),
                        onPressed: () => state.audioPlayer.seekToPrevious(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: 4.w),
                      StreamBuilder<PlayerState>(
                        stream: state.audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return IconButton(
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 38.sp,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              playing
                                  ? state.audioPlayer.pause()
                                  : state.audioPlayer.play();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),
                      SizedBox(width: 4.w),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded,
                            size: 24.sp,
                            color: theme.colorScheme.onPrimaryContainer),
                        onPressed: () => state.audioPlayer.seekToNext(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: 2.w),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18.sp,
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.6)),
                        onPressed: () {
                          state.audioPlayer.stop();
                          context.read<PlayerBarCubit>().hide();
                          context.read<QuranPlayerCubit>().closePlayer();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedPlayerSheet extends StatelessWidget {
  final QuranPlayerPlaying state;
  const _ExpandedPlayerSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 28.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    l10n.quranAudio,
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 22.sp),
                    onPressed: () {
                      state.audioPlayer.stop();
                      context.read<PlayerBarCubit>().hide();
                      context.read<QuranPlayerCubit>().closePlayer();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            Container(
              height: 220.w,
              width: 220.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(Icons.library_music_rounded,
                  size: 80.sp, color: theme.colorScheme.primary),
            ),
            const Spacer(flex: 2),
            StreamBuilder<int?>(
              stream: state.audioPlayer.currentIndexStream,
              builder: (context, snapshot) {
                final idx = snapshot.data ?? 0;
                final title = _surahTitle(state, idx);
                final trackInfo = '${idx + 1} / ${state.surahNumbers.length}';
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 24.sp, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${state.reciter.name} · ${state.moshaf.name}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      trackInfo,
                      style: TextStyle(
                          fontSize: 12.sp, color: theme.colorScheme.outline),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24.h),
            _SeekBar(audioPlayer: state.audioPlayer),
            SizedBox(height: 12.h),
            _MainControls(audioPlayer: state.audioPlayer),
            SizedBox(height: 8.h),
            _SecondaryControls(audioPlayer: state.audioPlayer),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _SeekBar({required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        final duration = audioPlayer.duration ?? Duration.zero;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble()
                      : 0,
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1,
                  onChanged: (v) =>
                      audioPlayer.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position),
                        style: TextStyle(
                            fontSize: 12.sp, color: theme.colorScheme.outline)),
                    Text(_formatDuration(duration),
                        style: TextStyle(
                            fontSize: 12.sp, color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _MainControls({required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            isRtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
            size: 36.sp,
          ),
          onPressed: () => audioPlayer.seekToPrevious(),
        ),
        SizedBox(width: 8.w),
        IconButton(
          icon: Icon(
            isRtl ? Icons.forward_10_rounded : Icons.replay_10_rounded,
            size: 32.sp,
          ),
          onPressed: () {
            final newPos = audioPlayer.position - const Duration(seconds: 10);
            audioPlayer.seek(newPos.isNegative ? Duration.zero : newPos);
          },
        ),
        SizedBox(width: 12.w),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 68.sp,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () =>
                    playing ? audioPlayer.pause() : audioPlayer.play(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            );
          },
        ),
        SizedBox(width: 12.w),
        IconButton(
          icon: Icon(
            isRtl ? Icons.replay_10_rounded : Icons.forward_10_rounded,
            size: 32.sp,
          ),
          onPressed: () {
            final dur = audioPlayer.duration ?? Duration.zero;
            final newPos = audioPlayer.position + const Duration(seconds: 10);
            audioPlayer.seek(newPos > dur ? dur : newPos);
          },
        ),
        SizedBox(width: 8.w),
        IconButton(
          icon: Icon(
            isRtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
            size: 36.sp,
          ),
          onPressed: () => audioPlayer.seekToNext(),
        ),
      ],
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _SecondaryControls({required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<bool>(
            stream: audioPlayer.shuffleModeEnabledStream,
            builder: (context, snapshot) {
              final on = snapshot.data ?? false;
              return IconButton(
                icon: Icon(Icons.shuffle_rounded,
                    size: 22.sp,
                    color: on
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline),
                onPressed: () => audioPlayer.setShuffleModeEnabled(!on),
              );
            },
          ),
          StreamBuilder<LoopMode>(
            stream: audioPlayer.loopModeStream,
            builder: (context, snapshot) {
              final mode = snapshot.data ?? LoopMode.off;
              return IconButton(
                icon: Icon(
                  mode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  size: 22.sp,
                  color: mode != LoopMode.off
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                onPressed: () {
                  const modes = [
                    LoopMode.off,
                    LoopMode.all,
                    LoopMode.one,
                  ];
                  audioPlayer.setLoopMode(
                      modes[(modes.indexOf(mode) + 1) % modes.length]);
                },
              );
            },
          ),
          StreamBuilder<double>(
            stream: audioPlayer.speedStream,
            builder: (context, snapshot) {
              final speed = snapshot.data ?? 1.0;
              return _SpeedChip(
                currentSpeed: speed,
                onChanged: (s) => audioPlayer.setSpeed(s),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onChanged;
  const _SpeedChip({required this.currentSpeed, required this.onChanged});

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = currentSpeed != 1.0;

    return PopupMenuButton<double>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (_) => _speeds
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(
                  '${s}x',
                  style: TextStyle(
                    fontWeight:
                        s == currentSpeed ? FontWeight.bold : FontWeight.normal,
                    color: s == currentSpeed ? theme.colorScheme.primary : null,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isCustom
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          '${currentSpeed}x',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isCustom
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
