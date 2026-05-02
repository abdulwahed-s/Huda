import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahSegmentOption {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SurahSegmentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
}

class SurahSegmentedControl extends StatelessWidget {
  final List<SurahSegmentOption> options;
  final bool isDark;
  final Color accent;

  const SurahSegmentedControl({
    super.key,
    required this.options,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.all(4.r),
      child: Row(
        children: options.map((opt) {
          return Expanded(
            child: GestureDetector(
              onTap: opt.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: opt.isSelected
                      ? (isDark ? const Color(0xFF303030) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: opt.isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 15.sp,
                      color: opt.isSelected
                          ? accent
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        opt.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: opt.isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: opt.isSelected
                              ? accent
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
