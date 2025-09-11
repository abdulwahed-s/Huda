import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArabicTextContainer extends StatelessWidget {
  final String arabicText;
  final ColorScheme colorScheme;

  const ArabicTextContainer({
    super.key,
    required this.arabicText,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        arabicText,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18.sp,
          height: 2.0,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
