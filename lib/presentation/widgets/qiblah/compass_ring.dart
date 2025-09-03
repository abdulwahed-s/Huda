import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompassRing extends StatelessWidget {
  final bool isDark;

  const CompassRing({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      height: 320.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(4, (index) {
            final angle = index * 90.0;
            final radians = angle * (math.pi / 180);
            final x = math.cos(radians - math.pi / 2) * 140.w;
            final y = math.sin(radians - math.pi / 2) * 140.w;

            return Positioned(
              left: 160.w + x - 12.w,
              top: 160.w + y - 12.w,
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ['N', 'E', 'S', 'W'][index],
                    style: TextStyle(
                      fontFamily: "Amiri",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
