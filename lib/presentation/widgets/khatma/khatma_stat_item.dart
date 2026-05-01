import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KhatmaStatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData? icon;

  const KhatmaStatItem({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? Colors.white : Colors.black87);
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15.sp, color: c.withValues(alpha: 0.55)),
          SizedBox(height: 3.h),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 19.sp,
            fontWeight: FontWeight.w900,
            color: c,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
