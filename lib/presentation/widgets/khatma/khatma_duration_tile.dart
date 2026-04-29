import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class KhatmaDurationTile extends StatelessWidget {
  final int days;
  final String title;
  final String? subtitle;
  final int? pagesPerDay;
  final VoidCallback onTap;
  final TextDirection textDirection;

  const KhatmaDurationTile({
    super.key,
    required this.days,
    required this.title,
    this.subtitle,
    this.pagesPerDay,
    required this.onTap,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;
    final sub = subtitle ??
        (pagesPerDay != null ? l10n.khatmaDailyWirdPages(pagesPerDay!) : '');
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      leading: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            '$days',
            style: TextStyle(
              color: accent,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
      ),
      subtitle: sub.isNotEmpty
          ? Text(
              sub,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            )
          : null,
      trailing: Icon(
        textDirection == TextDirection.rtl
            ? Icons.arrow_back_ios_new_rounded
            : Icons.arrow_forward_ios_rounded,
        size: 14.sp,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}
