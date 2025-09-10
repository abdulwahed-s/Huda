import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isDark;

  const NavigationButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? context.primaryColor : Colors.grey[400],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.0.h),
        elevation: isEnabled ? 2 : 0,
      ),
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 18.sp),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: "Amiri",
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
