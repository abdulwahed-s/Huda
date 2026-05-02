import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/screens/khatma_page.dart';

class KhatmaTabContent extends StatelessWidget {
  final bool isDark;
  final String title;

  const KhatmaTabContent({
    super.key,
    required this.isDark,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        const Expanded(child: KhatmaPage()),
      ],
    );
  }
}
