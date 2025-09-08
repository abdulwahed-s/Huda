import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final bool isDark;

  const ErrorState({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.0.h),
          Text(
            'Error loading hadith books',
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: 'Amiri',
              color:
                  isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
            ),
          ),
          SizedBox(height: 8.0.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Amiri',
              color: Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }
}
