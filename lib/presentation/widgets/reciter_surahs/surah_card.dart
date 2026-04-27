import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/reciter_surahs/surah_card_actions.dart';
import 'package:huda/presentation/widgets/reciter_surahs/surah_card_info.dart';
import 'package:huda/presentation/widgets/reciter_surahs/surah_card_number_badge.dart';

class SurahCard extends StatelessWidget {
  final String surahNum;
  final int intNum;
  final String surahName;
  final bool downloaded;
  final double? progress;
  final bool isDownloading;
  final bool isPlaying;
  final bool isLoading;
  final int itemIndex;
  final ThemeData theme;
  final bool isArabic;
  final AppLocalizations l10n;
  final AnimationController listAnimController;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const SurahCard({
    super.key,
    required this.surahNum,
    required this.intNum,
    required this.surahName,
    required this.downloaded,
    required this.progress,
    required this.isDownloading,
    required this.isPlaying,
    required this.isLoading,
    required this.itemIndex,
    required this.theme,
    required this.isArabic,
    required this.l10n,
    required this.listAnimController,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> entranceAnim = itemIndex < 14
        ? CurvedAnimation(
            parent: listAnimController,
            curve: Interval(
              (itemIndex * 0.055).clamp(0.0, 0.7),
              ((itemIndex * 0.055) + 0.3).clamp(0.1, 1.0),
              curve: Curves.easeOutCubic,
            ),
          )
        : const AlwaysStoppedAnimation(1.0);

    return AnimatedBuilder(
      animation: entranceAnim,
      builder: (context, child) => Opacity(
        opacity: entranceAnim.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - entranceAnim.value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: isPlaying
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isPlaying
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isPlaying ? 1.5 : 1.0,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: onPlay,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    SurahCardNumberBadge(
                      surahNum: surahNum,
                      isPlaying: isPlaying,
                      theme: theme,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: SurahCardInfo(
                        surahName: surahName,
                        intNum: intNum,
                        isPlaying: isPlaying,
                        isArabic: isArabic,
                        isDownloading: isDownloading,
                        progress: progress,
                        theme: theme,
                        l10n: l10n,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SurahCardActions(
                      isLoading: isLoading,
                      isPlaying: isPlaying,
                      downloaded: downloaded,
                      isDownloading: isDownloading,
                      progress: progress,
                      theme: theme,
                      onPlay: onPlay,
                      onDownload: onDownload,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
