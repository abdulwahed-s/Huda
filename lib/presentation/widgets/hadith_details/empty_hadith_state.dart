import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class EmptyHadithState extends StatelessWidget {
  final bool isDark;

  const EmptyHadithState({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]?.withValues(alpha: 0.3)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 80.sp,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            AppLocalizations.of(context)!.noHadithsFound,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              AppLocalizations.of(context)!.noHadithsFoundChapter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
