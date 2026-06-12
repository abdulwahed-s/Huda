import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioDetailProgressBanner extends StatelessWidget {
  final AudiobookProgress progress;
  final bool isDark;

  const AudioDetailProgressBanner({
    super.key,
    required this.progress,
    required this.isDark,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (progress.trackCount ?? 1) > 1
        ? ((progress.trackIndex) / ((progress.trackCount ?? 1) - 1))
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 14.sp, color: context.primaryColor),
              SizedBox(width: 6.w),
              Text(
                AppLocalizations.of(context)!.continueListening,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(progress.position),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: context.primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4.h,
              backgroundColor: context.primaryColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(context.primaryColor),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.chapter(progress.trackIndex + 1),
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark
                  ? context.darkText.withValues(alpha: 0.6)
                  : context.lightText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
