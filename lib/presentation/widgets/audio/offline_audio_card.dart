import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:huda/l10n/app_localizations.dart';

class OfflineAudioCard extends StatelessWidget {
  final OfflineAudiobookModel audiobook;
  final bool isDark;

  const OfflineAudioCard({
    super.key,
    required this.audiobook,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final author =
        audiobook.preparedBy.isNotEmpty ? (audiobook.preparedBy.first.title ?? '') : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoute.audioDetail,
              arguments: {
                'audioId': audiobook.id.toString(),
                'language': audiobook.language,
                'title': audiobook.title,
              },
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade500,
                        Colors.green.shade700,
                      ],
                    ),
                  ),
                  child: Icon(Icons.download_done_rounded,
                      color: Colors.white, size: 30.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        audiobook.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          color: isDark ? context.darkText : context.lightText,
                          height: 1.3,
                        ),
                      ),
                      if (author.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: (isDark ? context.darkText : context.lightText)
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      SizedBox(height: 6.h),
                      Text(
                        '${audiobook.tracks.length} ${AppLocalizations.of(context)!.chapters}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: (isDark ? context.darkText : context.lightText)
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
