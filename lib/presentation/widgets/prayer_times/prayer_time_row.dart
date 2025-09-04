import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerTimeRow extends StatelessWidget {
  final String prayerName;
  final String time;
  final IconData icon;

  const PrayerTimeRow({
    super.key,
    required this.prayerName,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              prayerName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: "Amiri",
                color: Colors.white,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFamily: "Amiri",
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}