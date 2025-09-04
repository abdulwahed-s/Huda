import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerDivider extends StatelessWidget {
  const PrayerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white30,
      height: 1.h,
      thickness: 1,
    );
  }
}