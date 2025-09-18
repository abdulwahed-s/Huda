import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class PageJumpSection extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  const PageJumpSection({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.onPageChanged,
  });

  @override
  State<PageJumpSection> createState() => _PageJumpSectionState();
}

class _PageJumpSectionState extends State<PageJumpSection> {
  final TextEditingController _pageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.grey.shade800.withValues(alpha: 0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.jumpTo,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white70 : Colors.grey.shade700,
              fontFamily: 'Amiri',
            ),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: 80.w,
            child: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Amiri',
              ),
              decoration: InputDecoration(
                hintText: '${widget.currentPage}',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: context.primaryColor),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              final pageNum = int.tryParse(_pageController.text);
              if (pageNum != null &&
                  pageNum >= 1 &&
                  pageNum <= widget.totalPages) {
                widget.onPageChanged(pageNum);
                _pageController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.go,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
