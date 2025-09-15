import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const InfoCard({
    super.key,
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 20.sp, 
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Flexible(
            
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp, 
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 4.h), 
          Flexible(
            
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp, 
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
                fontFamily: 'Amiri',
                height: 1.2, 
              ),
              textAlign: TextAlign.center,
              maxLines: 3, 
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
