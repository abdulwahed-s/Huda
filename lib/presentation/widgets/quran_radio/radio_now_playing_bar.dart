import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/data/models/radio_station_model.dart';

class RadioNowPlayingBar extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final bool isBuffering;
  final AnimationController pulseController;
  final String nowPlayingLabel;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const RadioNowPlayingBar({
    super.key,
    required this.station,
    required this.isPlaying,
    required this.isBuffering,
    required this.pulseController,
    required this.nowPlayingLabel,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(
                theme.colorScheme.primary, theme.colorScheme.secondary, 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            AnimatedBuilder(
              animation: pulseController,
              builder: (_, child) => Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.14 + 0.09 * pulseController.value,
                  ),
                ),
                child: child,
              ),
              child: Icon(
                Icons.radio_rounded,
                color: theme.colorScheme.onPrimary,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nowPlayingLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    station.name.toString(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (isBuffering)
              Padding(
                padding: EdgeInsets.all(10.w),
                child: SizedBox(
                  width: 22.sp,
                  height: 22.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              )
            else
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.all(10.r),
                  minimumSize: Size(40.r, 40.r),
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    size: 24.sp,
                  ),
                ),
                onPressed: onPlayPause,
              ),
            SizedBox(width: 2.w),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                size: 22.sp,
              ),
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}
