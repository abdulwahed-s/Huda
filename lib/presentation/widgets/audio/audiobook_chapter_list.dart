import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudiobookChapterList extends StatefulWidget {
  final List<AudioTrack> tracks;
  final AudioPlayer player;
  final AudiobookPlayerCubit cubit;

  const AudiobookChapterList({
    super.key,
    required this.tracks,
    required this.player,
    required this.cubit,
  });

  @override
  State<AudiobookChapterList> createState() => _AudiobookChapterListState();
}

class _AudiobookChapterListState extends State<AudiobookChapterList> {
  final ScrollController _scrollCtrl = ScrollController();
  int _prevIndex = -1;

  static const double _itemH = 68.0;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final target =
          (index * _itemH).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Text(
            AppLocalizations.of(context)!.chapters,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? context.darkText : context.lightText,
            ),
          ),
        ),
        StreamBuilder<int?>(
          stream: widget.player.currentIndexStream,
          builder: (context, snap) {
            final currentIndex = snap.data ?? 0;

            if (currentIndex != _prevIndex) {
              _prevIndex = currentIndex;
              _scrollToIndex(currentIndex);
            }

            return SizedBox(
              height: 320.h,
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: widget.tracks.length,
                itemBuilder: (context, index) =>
                    _buildChapterItem(context, index, currentIndex, isDark),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChapterItem(
      BuildContext context, int index, int currentIndex, bool isDark) {
    final track = widget.tracks[index];
    final isCurrent = index == currentIndex;
    final primaryColor = context.primaryColor;
    final textColor = isDark ? context.darkText : context.lightText;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        splashColor: primaryColor.withValues(alpha: 0.12),
        highlightColor: primaryColor.withValues(alpha: 0.06),
        onTap: () => widget.cubit.seekToIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
            color: isCurrent
                ? primaryColor.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isCurrent
                ? Border(
                    left: isRtl
                        ? BorderSide.none
                        : BorderSide(color: primaryColor, width: 3.w),
                    right: isRtl
                        ? BorderSide(color: primaryColor, width: 3.w)
                        : BorderSide.none,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 32.w,
                height: 32.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.10),
                ),
                child: isCurrent
                    ? Icon(Icons.graphic_eq_rounded,
                        size: 16.sp, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? primaryColor : textColor,
                  ),
                  child: Text(
                    track.description.isNotEmpty
                        ? track.description
                        : AppLocalizations.of(context)!.chapter(index + 1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (track.size.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Text(
                  track.size,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
