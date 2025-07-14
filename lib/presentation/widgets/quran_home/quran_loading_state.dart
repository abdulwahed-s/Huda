import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranLoadingState extends StatelessWidget {
  const QuranLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 103, 43, 93),
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
                  ?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
