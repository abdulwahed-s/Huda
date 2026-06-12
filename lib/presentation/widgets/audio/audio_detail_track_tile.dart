import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioDetailTrackTile extends StatefulWidget {
  final int index;
  final AudioTrack track;
  final bool isDark;
  final bool isCurrentTrack;
  final bool isPlaying;
  final VoidCallback onTap;

  const AudioDetailTrackTile({
    super.key,
    required this.index,
    required this.track,
    required this.isDark,
    required this.isCurrentTrack,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<AudioDetailTrackTile> createState() => _AudioDetailTrackTileState();
}

class _AudioDetailTrackTileState extends State<AudioDetailTrackTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => _ctrl.reverse(),
          onTapUp: (_) {
            _ctrl.forward();
            widget.onTap();
          },
          onTapCancel: () => _ctrl.forward(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                _TrackNumber(
                  index: widget.index,
                  isDark: widget.isDark,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.description.isNotEmpty
                            ? widget.track.description
                            : AppLocalizations.of(context)!
                                .chapter(widget.index + 1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark
                              ? context.darkText
                              : context.lightText,
                        ),
                      ),
                      if (widget.track.size.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          widget.track.size,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: (widget.isDark
                                    ? context.darkText
                                    : context.lightText)
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  widget.isCurrentTrack && widget.isPlaying
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  color: context.primaryColor.withValues(alpha: 0.7),
                  size: 26.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackNumber extends StatelessWidget {
  final int index;
  final bool isDark;

  const _TrackNumber({required this.index, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.primaryColor.withValues(alpha: 0.1),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: context.primaryColor,
        ),
      ),
    );
  }
}
