import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class OptionsButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const OptionsButton({
    super.key,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      margin: EdgeInsets.only(right: 16.w, left: 8.w),
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isDark
                ? appColors.darkCardBackground.withValues(alpha: 0.5)
                : appColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Icon(
              Icons.more_vert,
              size: 20.r,
              color: isDark ? appColors.darkText : appColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
