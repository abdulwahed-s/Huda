import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SheetDragHandle extends StatelessWidget {
  final bool isDark;

  const SheetDragHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}
