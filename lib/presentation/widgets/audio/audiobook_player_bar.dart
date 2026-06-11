import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/presentation/screens/audiobook_now_playing_screen.dart';





class AudiobookPlayerBar extends StatelessWidget {
  const AudiobookPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiobookBarCubit, AudiobookBarVisibility>(
      builder: (context, barState) {
        if (barState == AudiobookBarVisibility.hidden) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<AudiobookPlayerCubit, AudiobookPlayerState>(
          builder: (context, playerState) {
            if (playerState is! AudiobookPlayerPlaying) {
              return const SizedBox.shrink();
            }
            return _MiniPill(state: playerState);
          },
        );
      },
    );
  }
}

class _MiniPill extends StatelessWidget {
  final AudiobookPlayerPlaying state;
  const _MiniPill({required this.state});

  void _openFullScreen(BuildContext context) {
    final playerCubit = context.read<AudiobookPlayerCubit>();
    final barCubit = context.read<AudiobookBarCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: playerCubit),
            BlocProvider.value(value: barCubit),
          ],
          child: const AudiobookNowPlayingScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = state.audioPlayer;

    return Padding(
      padding: EdgeInsets.only(
        left: 12.w,
        right: 12.w,
        bottom: 12.h + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _openFullScreen(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? context.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                _buildProgressPlayButton(context, player),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<int?>(
                        stream: player.currentIndexStream,
                        builder: (context, snap) {
                          final idx = snap.data ?? 0;
                          final chapter = (idx >= 0 && idx < state.tracks.length)
                              ? state.tracks[idx].description
                              : state.title;
                          return Text(
                            chapter.isNotEmpty ? chapter : state.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                              color:
                                  isDark ? context.darkText : context.lightText,
                            ),
                          );
                        },
                      ),
                      Text(
                        state.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: (isDark ? context.darkText : context.lightText)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.forward_30_rounded,
                      color: context.primaryColor),
                  onPressed: () =>
                      context.read<AudiobookPlayerCubit>().skipForward(),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: (isDark ? context.darkText : context.lightText)
                          .withValues(alpha: 0.6)),
                  onPressed: () {
                    context.read<AudiobookPlayerCubit>().closePlayer();
                    context.read<AudiobookBarCubit>().hide();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPlayButton(BuildContext context, AudioPlayer player) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        final frac = dur.inMilliseconds > 0
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        return SizedBox(
          width: 44.w,
          height: 44.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44.w,
                height: 44.w,
                child: CircularProgressIndicator(
                  value: frac,
                  strokeWidth: 2.5,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(context.primaryColor),
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, ps) {
                  final playing = ps.data?.playing ?? false;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 26.sp,
                    icon: Icon(
                      playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: context.primaryColor,
                    ),
                    onPressed: () {
                      final cubit = context.read<AudiobookPlayerCubit>();
                      playing ? cubit.pause() : cubit.resume();
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
