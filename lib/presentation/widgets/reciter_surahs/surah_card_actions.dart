import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahCardActions extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final bool downloaded;
  final bool isDownloading;
  final double? progress;
  final ThemeData theme;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const SurahCardActions({
    super.key,
    required this.isLoading,
    required this.isPlaying,
    required this.downloaded,
    required this.isDownloading,
    required this.progress,
    required this.theme,
    required this.onPlay,
    required this.onDownload,
  });

  Widget _buildDownloadWidget() {
    if (downloaded && !isDownloading) {
      return Icon(
        Icons.download_done_rounded,
        key: const ValueKey('done'),
        size: 22.sp,
        color: Colors.green.shade400,
      );
    }

    if (isDownloading) {
      return SizedBox(
        key: const ValueKey('downloading'),
        width: 22.sp,
        height: 22.sp,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: progress,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return IconButton(
      key: const ValueKey('download'),
      icon: Icon(
        Icons.download_for_offline_rounded,
        size: 26.sp,
        color: theme.colorScheme.secondary,
      ),
      onPressed: onDownload,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 30.sp,
                  height: 30.sp,
                  child: Padding(
                    padding: EdgeInsets.all(3.r),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              : isPlaying
                  ? Padding(
                      key: const ValueKey('eq'),
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        color: theme.colorScheme.primary,
                        size: 26.sp,
                      ),
                    )
                  : IconButton(
                      key: const ValueKey('play'),
                      icon: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 30.sp,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: onPlay,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
        ),
        SizedBox(width: 2.w),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _buildDownloadWidget(),
        ),
      ],
    );
  }
}
