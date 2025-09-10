import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/hadith_details/navigation_buttons.dart';
import 'package:huda/presentation/widgets/hadith_details/page_indicator.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final bool isDark;
  final String chapterId;
  final String bookId;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.isDark,
    required this.chapterId,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0.w),
      margin: EdgeInsets.only(top: 16.0.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          PageIndicator(
            currentPage: currentPage,
            lastPage: lastPage,
            isDark: isDark,
          ),
          SizedBox(height: 16.0.h),
          NavigationButtons(
            currentPage: currentPage,
            lastPage: lastPage,
            isDark: isDark,
            chapterId: chapterId,
            bookId: bookId,
          ),
        ],
      ),
    );
  }
}
