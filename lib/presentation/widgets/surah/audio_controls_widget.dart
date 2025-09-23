import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:huda/core/theme/theme_extension.dart';

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
    return Column(
      children: [
        // Progress bar
        if (totalDuration.inMilliseconds > 0)
          Column(
            children: [
              Slider(
                value: totalDuration.inMilliseconds > 0
                    ? (currentPosition.inMilliseconds /
                            totalDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) {
                  onUserSeekingChanged(true);
                  onSeek(value);
                },
                onChangeEnd: (value) {
                  onUserSeekingChanged(false);
                },
                activeColor: context.primaryColor,
                inactiveColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFFE0D7E0),
                thumbColor: context.primaryColor,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 12.h),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous button
            Container(
              decoration: BoxDecoration(
                color: currentIndex > 0
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: IconButton(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: Icon(
                  Icons.skip_previous,
                  color: currentIndex > 0
                      ? context.primaryColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey),
                  size: 22.sp,
                ),
              ),
            ),
            // Play/Pause button
            Container(
              decoration: BoxDecoration(
                gradient: isPlayButtonEnabled
                    ? LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: isPlayButtonEnabled
                    ? null
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey),
                shape: BoxShape.circle,
                boxShadow: isPlayButtonEnabled
                    ? [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: isPlayButtonEnabled ? onPlayPause : null,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
            ),
            // Next button
            Container(
              decoration: BoxDecoration(
                color: currentIndex < totalAyahs - 1
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: IconButton(
                onPressed: currentIndex < totalAyahs - 1 ? onNext : null,
                icon: Icon(
                  Icons.skip_next,
                  color: currentIndex < totalAyahs - 1
                      ? context.primaryColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey),
                  size: 22.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
