import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, size: 16.r, color: color),
          ),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }
}

