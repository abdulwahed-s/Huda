import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class SelectedDateInfoWidget extends StatelessWidget {
  final HijriCalendar selectedHijri;
  final DateTime focusedGregorian;
  final bool isDark;
  final BuildContext context;

  const SelectedDateInfoWidget({
    super.key,
    required this.selectedHijri,
    required this.focusedGregorian,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.12),
            context.primaryColor.withValues(alpha: 0.06),
            context.primaryVariantColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primaryColor.withValues(alpha: 0.2),
                  context.primaryColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Icon(
              Icons.event_note_rounded,
              color: context.primaryColor,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedHijri.hDay} ${_getHijriMonthName(selectedHijri.hMonth)} ${selectedHijri.hYear} هـ',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: "Amiri",
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${focusedGregorian.day} ${_getGregorianMonthName(focusedGregorian.month)} ${focusedGregorian.year} م',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    fontFamily: "Amiri",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHijriMonthName(int month) {
    final localizations = AppLocalizations.of(context)!;
    final months = [
      localizations.muharram,
      localizations.safar,
      localizations.rabiAlAwwal,
      localizations.rabiAlThani,
      localizations.jumadaAlAwwal,
      localizations.jumadaAlThani,
      localizations.rajab,
      localizations.shaban,
      localizations.ramadan,
      localizations.shawwal,
      localizations.dhuAlQidah,
      localizations.dhuAlHijjah
    ];
    return months[month - 1];
  }

  String _getGregorianMonthName(int month) {
    final localizations = AppLocalizations.of(context)!;
    final months = [
      localizations.january,
      localizations.february,
      localizations.march,
      localizations.april,
      localizations.may,
      localizations.june,
      localizations.july,
      localizations.august,
      localizations.september,
      localizations.october,
      localizations.november,
      localizations.december
    ];
    return months[month - 1];
  }
}
