import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class QuranErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const QuranErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'Error Loading Quran',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 16.sp),
            label: Text(AppLocalizations.of(context)!.retry,
                style: TextStyle(fontSize: 13.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 103, 43, 93),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
