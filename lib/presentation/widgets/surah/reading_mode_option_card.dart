import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/qcf_font_service.dart';
import 'package:huda/l10n/app_localizations.dart';

class ReadingModeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool requiresFonts;
  final bool isDark;
  final Color accent;
  final QcfFontService? fontService;
  final VoidCallback onTap;

  const ReadingModeOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.requiresFonts,
    required this.isDark,
    required this.accent,
    required this.onTap,
    this.fontService,
  });

  @override
  Widget build(BuildContext context) {
    if (fontService != null) {
      return StreamBuilder<QcfFontDownloadState>(
        stream: fontService!.stateStream,
        initialData: fontService!.currentState,
        builder: (context, _) => _buildCard(context),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final fontsReady = fontService?.areFontsReady ?? true;
    final previouslyDownloaded = fontService?.wasPreviouslyDownloaded ?? false;
    final currentStatus = fontService?.currentState.status;
    final fontsBeingProcessed = currentStatus == QcfFontStatus.downloading ||
        currentStatus == QcfFontStatus.extracting ||
        currentStatus == QcfFontStatus.loading;

    final needsDownload = requiresFonts &&
        !fontsReady &&
        !previouslyDownloaded &&
        !fontsBeingProcessed;

    final showDownloadProgress = requiresFonts &&
        !fontsReady &&
        fontsBeingProcessed &&
        !previouslyDownloaded &&
        fontService != null;

    final isInitLoading = requiresFonts &&
        !fontsReady &&
        previouslyDownloaded &&
        fontsBeingProcessed;

    final sizeLabel = fontService?.packType.sizeLabel ?? '~50 MB';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: isDark ? 0.13 : 0.08)
              : (isDark ? const Color(0xFF252525) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.55)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6.r),
                    child: Icon(icon, color: accent),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF252525) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 9.sp,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? accent
                    : (isDark ? Colors.white70 : const Color(0xFF444444)),
                height: 1.3,
              ),
            ),
            if (needsDownload) ...[
              SizedBox(height: 5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 9.sp,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      sizeLabel,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isInitLoading) ...[
              SizedBox(height: 6.h),
              SizedBox(
                width: 14.sp,
                height: 14.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (showDownloadProgress) ...[
              SizedBox(height: 8.h),
              StreamBuilder<QcfFontDownloadState>(
                stream: fontService!.stateStream,
                initialData: fontService!.currentState,
                builder: (context, snapshot) {
                  final state =
                      snapshot.data ?? const QcfFontDownloadState.idle();
                  if (state.status == QcfFontStatus.idle) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: state.status == QcfFontStatus.downloading
                              ? state.progress
                              : null,
                          minHeight: 3.h,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        state.status == QcfFontStatus.downloading
                            ? '${(state.progress * 100).toInt()}%'
                            : state.status == QcfFontStatus.extracting
                                ? AppLocalizations.of(context)!
                                    .fontExtractingLabel
                                : AppLocalizations.of(context)!
                                    .fontLoadingLabel,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
