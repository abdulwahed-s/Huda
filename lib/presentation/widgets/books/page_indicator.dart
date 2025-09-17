import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentPage / totalPages;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryColor.withValues(alpha: 0.1),
                context.primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.page} $currentPage ${AppLocalizations.of(context)!.pageOf} $totalPages',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 6.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
