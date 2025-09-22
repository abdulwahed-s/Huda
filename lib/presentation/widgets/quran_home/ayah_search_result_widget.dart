import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/search_result_model.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AyahSearchResultWidget extends StatelessWidget {
  final AyahSearchResult ayahResult;
  final VoidCallback onTap;

  const AyahSearchResultWidget({
    super.key,
    required this.ayahResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${ayahResult.surahNumber}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ayahResult.surahName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ayahResult.surahEnglishName,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'آية ${ayahResult.ayahNumber}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              RichText(
                text:
                    _buildHighlightedText(context, ayahResult.highlightedText),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(BuildContext context, String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 16.sp,
        height: 1.8,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Amiri',
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
