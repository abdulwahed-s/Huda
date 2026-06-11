import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';

class AudiobookControls extends StatefulWidget {
  final AudioPlayer player;
  final AudiobookPlayerCubit cubit;

  const AudiobookControls({
    super.key,
    required this.player,
    required this.cubit,
  });

  @override
  State<AudiobookControls> createState() => _AudiobookControlsState();
}

class _AudiobookControlsState extends State<AudiobookControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        (isDark ? context.darkText : context.lightText).withValues(alpha: 0.75);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<int?>(
          stream: widget.player.currentIndexStream,
          builder: (context, snap) {
            final enabled = widget.player.hasPrevious;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.35,
              child: IconButton(
                iconSize: 30.sp,
                icon: Icon(
                  isRtl
                      ? Icons.skip_next_rounded
                      : Icons.skip_previous_rounded,
                  color: secondaryColor,
                ),
                onPressed: enabled ? widget.cubit.previousChapter : null,
              ),
            );
          },
        ),
        _skipButton(
          context,
          flip: isRtl,
          onTap: () => widget.cubit.skipBackward(),
          color: secondaryColor,
        ),
        _buildPlayPause(context),
        _skipButton(
          context,
          flip: !isRtl,
          onTap: () => widget.cubit.skipForward(const Duration(seconds: 15)),
          color: secondaryColor,
        ),
        StreamBuilder<int?>(
          stream: widget.player.currentIndexStream,
          builder: (context, snap) {
            final enabled = widget.player.hasNext;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.35,
              child: IconButton(
                iconSize: 30.sp,
                icon: Icon(
                  isRtl
                      ? Icons.skip_previous_rounded
                      : Icons.skip_next_rounded,
                  color: secondaryColor,
                ),
                onPressed: enabled ? widget.cubit.nextChapter : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayPause(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snap) {
        final playerState = snap.data;
        final processing = playerState?.processingState;
        final playing = playerState?.playing ?? false;
        final isLoading = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) {
            _pressCtrl.reverse();
            if (!isLoading) {
              playing ? widget.cubit.pause() : widget.cubit.resume();
            }
          },
          onTapCancel: () => _pressCtrl.reverse(),
          child: ScaleTransition(
            scale: _pressScale,
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.72),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.42),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(22.w),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        size: 40.sp,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _skipButton(
    BuildContext context, {
    required bool flip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30.r),
      splashColor: context.primaryColor.withValues(alpha: 0.15),
      highlightColor: context.primaryColor.withValues(alpha: 0.08),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scaleX: flip ? -1.0 : 1.0,
              child: Icon(Icons.replay_rounded, size: 36.sp, color: color),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '15',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
