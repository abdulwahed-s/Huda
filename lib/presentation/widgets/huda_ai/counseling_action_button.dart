import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CounselingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const CounselingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(38),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              icon,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
