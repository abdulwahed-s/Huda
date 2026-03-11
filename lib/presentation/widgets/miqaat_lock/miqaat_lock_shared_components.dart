import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SharedCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final Widget child;
  final Color? accentColor;

  const SharedCard({
    super.key,
    required this.theme,
    required this.isDark,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: isDark
            ? null
            : Border.all(
                color: (accentColor ?? Colors.black).withValues(alpha: 0.06),
                width: 1,
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;
  final Color primary;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.theme,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: primary),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final ThemeData theme;
  final bool isDark;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.hintColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36.sp,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.hintColor,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class AddButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final String? subtitle;

  const AddButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: primary, size: 20.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: primary.withValues(alpha: 0.5), size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}
