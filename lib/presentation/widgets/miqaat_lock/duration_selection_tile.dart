import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class DurationSelectionTile extends StatelessWidget {
  final int? duration;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCustom;

  const DurationSelectionTile({
    super.key,
    required this.duration,
    required this.isSelected,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = context.primaryColor;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected
              ? activeColor.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.transparent
                  : theme.dividerColor.withValues(alpha: 0.5)),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isCustom
                        ? l10n.customDuration
                        : '$duration ${l10n.minutes}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? activeColor
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 14.sp),
                  )
                else if (isCustom)
                  Icon(Icons.chevron_right_rounded,
                      color: theme.hintColor.withValues(alpha: 0.5),
                      size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
