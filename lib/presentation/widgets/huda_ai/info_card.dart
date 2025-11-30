import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final bool isTablet;

  const InfoCard({
    super.key,
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isTablet ? 16.0 : 12.w;
    final borderRadius = isTablet ? 16.0 : 12.r;
    final iconContainerPadding = isTablet ? 10.0 : 8.w;
    final iconBorderRadius = isTablet ? 10.0 : 8.r;
    final iconSize = isTablet ? 24.0 : 20.sp;
    final spacing1 = isTablet ? 12.0 : 8.h;
    final spacing2 = isTablet ? 6.0 : 4.h;
    final titleSize = isTablet ? 15.0 : 12.sp;
    final subtitleSize = isTablet ? 12.0 : 10.sp;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
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
            padding: EdgeInsets.all(iconContainerPadding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(iconBorderRadius),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
          SizedBox(height: spacing1),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: spacing2),
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleSize,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
                fontFamily: 'Amiri',
                height: 1.3,
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
