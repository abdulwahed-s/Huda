import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/audio/audio_format.dart';

class AudiobookScrubber extends StatefulWidget {
  final AudioPlayer player;
  final ValueChanged<Duration> onSeek;

  const AudiobookScrubber({
    super.key,
    required this.player,
    required this.onSeek,
  });

  @override
  State<AudiobookScrubber> createState() => _AudiobookScrubberState();
}

class _AudiobookScrubberState extends State<AudiobookScrubber> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    final textColor = isDark ? context.darkText : context.lightText;

    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snap) {
        final position = snap.data ?? Duration.zero;
        final duration = widget.player.duration ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        final currentMs = _dragValue ??
            position.inMilliseconds
                .toDouble()
                .clamp(0.0, maxMs > 0 ? maxMs : 0.0);

        return Column(
          children: [
            StreamBuilder<Duration>(
              stream: widget.player.bufferedPositionStream,
              builder: (context, bufSnap) {
                final buffered = bufSnap.data ?? Duration.zero;
                final bufferedMs = buffered.inMilliseconds
                    .toDouble()
                    .clamp(0.0, maxMs > 0 ? maxMs : 0.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (maxMs > 0)
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final thumbPad = 8.r * 2;
                          final trackWidth =
                              (constraints.maxWidth - thumbPad * 2)
                                  .clamp(0.0, double.infinity);
                          final bufferedFraction =
                              (bufferedMs / maxMs).clamp(0.0, 1.0);
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: thumbPad),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Container(
                                height: 6.h,
                                width: trackWidth * bufferedFraction,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6.h,
                        activeTrackColor: primaryColor,
                        inactiveTrackColor:
                            primaryColor.withValues(alpha: 0.08),
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withValues(alpha: 0.18),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.r,
                          pressedElevation: 6,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 18.r,
                        ),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        min: 0.0,
                        max: maxMs > 0 ? maxMs : 1.0,
                        value: maxMs > 0 ? currentMs : 0.0,
                        onChanged: maxMs > 0
                            ? (v) => setState(() => _dragValue = v)
                            : null,
                        onChangeEnd: maxMs > 0
                            ? (v) {
                                widget
                                    .onSeek(Duration(milliseconds: v.round()));
                                setState(() => _dragValue = null);
                              }
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatAudioDuration(
                        Duration(milliseconds: currentMs.round())),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    formatAudioDuration(duration),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: textColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
