import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KhatmaGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color accent;

  const KhatmaGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.75)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(999.r),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          minimumSize: const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999.r),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20.sp),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
        ),
      ),
    );
  }
}
