import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class RamadanHeaderWidget extends StatelessWidget {
  final bool isRamadan;
  final int currentDay;
  final int daysUntilRamadan;
  final bool isDark;

  const RamadanHeaderWidget({
    super.key,
    required this.isRamadan,
    required this.currentDay,
    required this.daysUntilRamadan,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = isDark ? context.primaryLightColor : context.primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  primary.withValues(alpha: 0.25),
                  primary.withValues(alpha: 0.10),
                ]
              : [
                  primary.withValues(alpha: 0.12),
                  primary.withValues(alpha: 0.04),
                ],
        ),
        border: isDark
            ? null
            : Border.all(
                color: primary.withValues(alpha: 0.08),
                width: 1,
              ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '🌙',
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            isRamadan
                ? l10n.ramadanDayLabel(currentDay)
                : l10n.daysUntilRamadan(daysUntilRamadan),
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (isRamadan) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$currentDay / 30',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
