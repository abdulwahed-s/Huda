import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomVersesSection extends StatelessWidget {
  final List<String> customVerses;
  final bool isLoadingVerses;
  final VoidCallback onRefresh;
  final Function(String, int) onRemoveVerse;
  final VoidCallback onClearAll;
  final bool isDark;

  const CustomVersesSection({
    super.key,
    required this.customVerses,
    required this.isLoadingVerses,
    required this.onRefresh,
    required this.onRemoveVerse,
    required this.onClearAll,
    required this.isDark,
  });

  String _extractVerseText(String verse) {
    if (verse.contains('\n(')) {
      return verse.split('\n(')[0];
    }
    return verse;
  }

  String _extractReference(String verse) {
    if (verse.contains('\n(') && verse.endsWith(')')) {
      final parts = verse.split('\n(');
      if (parts.length > 1) {
        return parts[1].replaceAll(')', '');
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.customVerses,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18.sp,
                  ),
                  tooltip: AppLocalizations.of(context)!.refreshVerses,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (customVerses.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.versesAdded(customVerses.length),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
          SizedBox(height: 12.h),
          if (isLoadingVerses)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppLocalizations.of(context)!.loadingVerses,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            )
          else if (customVerses.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 40.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppLocalizations.of(context)!.noCustomVersesYet,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Amiri',
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    AppLocalizations.of(context)!.visitSurahScreenToAddVerses,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                      height: 1.4,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...List.generate(customVerses.length, (index) {
                  final verse = customVerses[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withAlpha(13),
                          Theme.of(context).colorScheme.primary.withAlpha(5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withAlpha(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      _extractVerseText(verse),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        height: 1.8,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Amiri',
                                      ),
                                    ),
                                  ),
                                  if (_extractReference(verse).isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(26),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Text(
                                        _extractReference(verse),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Amiri',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(26),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: IconButton(
                                onPressed: () => onRemoveVerse(verse, index),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: Colors.red[600],
                                tooltip: AppLocalizations.of(context)!.remove,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (customVerses.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear_all_rounded),
                      label: Text(
                        AppLocalizations.of(context)!.clearAllCustomVerses,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}