import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/l10n/app_localizations.dart';

class SurahCardInfo extends StatelessWidget {
  final String surahName;
  final int intNum;
  final bool isPlaying;
  final bool isArabic;
  final bool isDownloading;
  final double? progress;
  final ThemeData theme;
  final AppLocalizations l10n;

  const SurahCardInfo({
    super.key,
    required this.surahName,
    required this.intNum,
    required this.isPlaying,
    required this.isArabic,
    required this.isDownloading,
    required this.progress,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          surahName,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
            color: isPlaying
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontFamily: isArabic ? 'Amiri' : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          '${quran.getVerseCount(intNum)} ${l10n.verses}',
          style: TextStyle(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isDownloading) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3.h,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${((progress ?? 0) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
