import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/books/page_indicator.dart';
import 'package:huda/presentation/widgets/books/page_jump_section.dart';
import 'package:huda/presentation/widgets/books/pagination_buttons.dart';

class PaginationSection extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  const PaginationSection({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          PageIndicator(
            currentPage: currentPage,
            totalPages: totalPages,
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          PaginationButtons(
            currentPage: currentPage,
            totalPages: totalPages,
            isDark: isDark,
            onPageChanged: onPageChanged,
          ),
          if (totalPages > 10) ...[
            SizedBox(height: 20.h),
            PageJumpSection(
              currentPage: currentPage,
              totalPages: totalPages,
              isDark: isDark,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      ),
    );
  }
}
