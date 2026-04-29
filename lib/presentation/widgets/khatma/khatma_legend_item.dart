import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KhatmaLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const KhatmaLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 6.w),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
