import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RevelationTypeBadge extends StatelessWidget {
  final String revelationType;

  const RevelationTypeBadge({
    super.key,
    required this.revelationType,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = revelationType == 'Meccan';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMeccan
              ? [Colors.amber[300]!, Colors.orange[400]!]
              : [Colors.blue[300]!, Colors.indigo[400]!],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: (isMeccan ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 3.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isMeccan ? 'assets/images/mecca.svg' : 'assets/images/madina.svg',
            width: 10.w,
            height: 10.h,
          ),
          SizedBox(width: 2.w),
          Text(
            revelationType,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
