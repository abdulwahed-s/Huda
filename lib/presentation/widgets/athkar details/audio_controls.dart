import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioControls extends StatelessWidget {
  final String? audioUrl;
  final int index;
  final ColorScheme colorScheme;
  final bool isCurrentlyPlaying;
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final Future<void> Function(String?) onPlayAudio;
  final Future<void> Function(Duration)? onSeek;

  const AudioControls({
    super.key,
    required this.audioUrl,
    required this.index,
    required this.colorScheme,
    required this.isCurrentlyPlaying,
    required this.isPlaying,
    required this.audioDuration,
    required this.audioPosition,
    required this.onPlayAudio,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => onPlayAudio(audioUrl),
                  icon: Icon(
                    isCurrentlyPlaying && isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 24.w,
                  ),
                  padding: EdgeInsets.all(12.w),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.audio,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (isCurrentlyPlaying)
                      Text(
                        isPlaying
                            ? AppLocalizations.of(context)!.playing
                            : AppLocalizations.of(context)!.stopped,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.sp,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isCurrentlyPlaying) ...[
            SizedBox(height: 12.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                trackHeight: 4.h,
              ),
              child: Slider(
                min: 0,
                max: audioDuration.inMilliseconds.toDouble(),
                value: audioPosition.inMilliseconds
                    .clamp(0, audioDuration.inMilliseconds)
                    .toDouble(),
                onChanged: (value) {
                  if (onSeek != null) {
                    onSeek!(Duration(milliseconds: value.toInt()));
                  }
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(audioPosition),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    _formatDuration(audioDuration),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
