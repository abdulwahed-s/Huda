import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class QuranLoadingState extends StatelessWidget {
  const QuranLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              context.primaryColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Loading Quran...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
