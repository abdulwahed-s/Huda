import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HadithText extends StatelessWidget {
  final String text;
  final bool isDark;
  final String currentLanguageCode;

  const HadithText({
    super.key,
    required this.text,
    required this.isDark,
    required this.currentLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.0.sp,
          fontFamily: "Amiri",
          height: 1.6,
          color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
        ),
        textAlign:
            currentLanguageCode == "ar" ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
