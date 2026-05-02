import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color accent;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20.h, 0, 12.h),
      child: Row(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 14.sp, color: accent),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
