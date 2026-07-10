import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PrayerTimeRow extends StatelessWidget {
  final String prayerName;
  final String time;
  final IconData? icon;
  final String? iconAsset;

  const PrayerTimeRow({
    super.key,
    required this.prayerName,
    required this.time,
    this.icon,
    this.iconAsset,
  }) : assert(icon != null || iconAsset != null);

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.white70;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          if (iconAsset != null)
            SvgPicture(
              AssetBytesLoader(iconAsset!),
              width: 18.sp,
              height: 18.sp,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          else
            Icon(
              icon,
              color: iconColor,
              size: 18.sp,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              prayerName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
