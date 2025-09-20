import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineStateCard extends StatelessWidget {
  final String section;
  final VoidCallback onRetry;

  const OfflineStateCard({
    super.key,
    required this.section,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.orange,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'You\'re Offline',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Cannot load $section while offline',
              style: TextStyle(
                color: Colors.orange.withValues(alpha: 0.8),
                fontSize: 14.sp,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 18.sp),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
