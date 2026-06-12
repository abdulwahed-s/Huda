import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audio_detail_track_tile.dart';

class AudioDetailTrackList extends StatelessWidget {
  final List<AudioTrack> tracks;
  final bool isDark;
  final int currentIndex;
  final bool isPlaying;
  final ValueChanged<int> onTrackTap;

  const AudioDetailTrackList({
    super.key,
    required this.tracks,
    required this.isDark,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return _EmptyChapters(isDark: isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? context.darkCardBackground.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: tracks.asMap().entries.map((entry) {
            final idx = entry.key;
            final track = entry.value;
            final isLast = idx == tracks.length - 1;
            final isCurrent = idx == currentIndex;
            return Column(
              children: [
                AudioDetailTrackTile(
                  index: idx,
                  track: track,
                  isDark: isDark,
                  isCurrentTrack: isCurrent,
                  isPlaying: isCurrent && isPlaying,
                  onTap: () => onTrackTap(idx),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 60.w,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  final bool isDark;
  const _EmptyChapters({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = (isDark ? context.darkText : context.lightText);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(Icons.music_off_rounded,
                size: 48.sp, color: color.withValues(alpha: 0.3)),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context)!.noChapters,
              style: TextStyle(
                fontSize: 14.sp,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
