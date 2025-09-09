import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: EdgeInsets.all(10.0.w),
            constraints: BoxConstraints(
              minWidth: 44.w,
              minHeight: 44.h,
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
