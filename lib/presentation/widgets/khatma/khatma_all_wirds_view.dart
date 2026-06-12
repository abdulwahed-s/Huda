import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaAllWirdsView extends StatelessWidget {
  final TextDirection textDirection;
  final int totalDays;
  final int currentDayIndex;
  final bool isSetupMode;
  final VoidCallback onBack;
  final String Function(int dayIndex) rangeLabelForDay;
  final ValueChanged<int>? onDayTap;

  const KhatmaAllWirdsView({
    super.key,
    required this.textDirection,
    required this.totalDays,
    required this.currentDayIndex,
    required this.isSetupMode,
    required this.onBack,
    required this.rangeLabelForDay,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: textDirection,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 6.h,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: totalDays + 1,
        itemBuilder: (c, i) {
          if (i == 0) {
            return KhatmaTopTitle(
              title: l10n.khatmaAllWirds,
              onBack: onBack,
              textDirection: textDirection,
            );
          }
          final dayIdx = i - 1;
          final isDone = !isSetupMode && dayIdx < currentDayIndex;
          final isCurrent = !isSetupMode && dayIdx == currentDayIndex;

          return _WirdDayTile(
            dayIndex: dayIdx,
            isDone: isDone,
            isCurrent: isCurrent,
            accent: accent,
            isDark: isDark,
            rangeLabel: rangeLabelForDay(dayIdx),
            onTap: isSetupMode ? () => onDayTap?.call(dayIdx) : null,
          );
        },
      ),
    );
  }
}

class _WirdDayTile extends StatelessWidget {
  final int dayIndex;
  final bool isDone;
  final bool isCurrent;
  final Color accent;
  final bool isDark;
  final String rangeLabel;
  final VoidCallback? onTap;

  const _WirdDayTile({
    required this.dayIndex,
    required this.isDone,
    required this.isCurrent,
    required this.accent,
    required this.isDark,
    required this.rangeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final badgeColor = isDone
        ? Colors.green.shade500
        : isCurrent
            ? accent
            : (isDark ? Colors.white24 : Colors.black12);

    final badgeChild = isDone
        ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
        : Text(
            '${dayIndex + 1}',
            style: TextStyle(
              color: isCurrent
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
            ),
          );

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
      decoration: BoxDecoration(
        color: isCurrent
            ? accent.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCurrent
              ? accent.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        leading: Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor),
          child: Center(child: badgeChild),
        ),
        title: Text(
          l10n.khatmaDailyWirdOf(dayIndex + 1),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.sp,
            color:
                isCurrent ? accent : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text(
          rangeLabel,
          style: TextStyle(
            height: 1.4,
            fontWeight: FontWeight.w700,
            fontSize: 11.sp,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
