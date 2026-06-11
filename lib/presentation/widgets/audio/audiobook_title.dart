import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';




class AudiobookTitle extends StatelessWidget {
  final AudioPlayer player;
  final String title;
  final String author;
  final List<AudioTrack> tracks;
  final bool isDark;

  const AudiobookTitle({
    super.key,
    required this.player,
    required this.title,
    required this.author,
    required this.tracks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? context.darkText : context.lightText;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        children: [
          StreamBuilder<int?>(
            stream: player.currentIndexStream,
            builder: (context, snap) {
              final idx = snap.data ?? 0;
              final chapter = (idx >= 0 && idx < tracks.length)
                  ? tracks[idx].description
                  : '';
              return Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      chapter.isNotEmpty ? chapter : title,
                      key: ValueKey(idx),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                          .chapterProgress(idx + 1, tracks.length),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.primaryColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 6.h),
          Text(
            author,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              color: textColor.withValues(alpha: 0.65),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
