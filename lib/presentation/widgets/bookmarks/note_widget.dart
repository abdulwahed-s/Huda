import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class NoteWidget extends StatelessWidget {
  final String note;
  final Color displayColor;
  final bool isDark;

  const NoteWidget({
    super.key,
    required this.note,
    required this.displayColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      children: [
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                displayColor.withValues(alpha: isDark ? 0.15 : 0.08),
                displayColor.withValues(alpha: isDark ? 0.10 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: displayColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  size: 18.r,
                  color: displayColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Note',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: displayColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: isDark
                            ? appColors.darkText.withValues(alpha: 0.9)
                            : appColors.lightText,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

