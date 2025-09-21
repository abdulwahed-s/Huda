import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:intl/intl.dart';
import 'package:huda/l10n/app_localizations.dart';

class DateHeader extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final bool isDark;

  const DateHeader({
    super.key,
    required this.currentDate,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.isDark,
  });

  String _getHijriMonthName(int month, BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dateFormat = DateFormat(
        'MMMM d, yyyy', Localizations.localeOf(context).languageCode);
    final hijriDate = HijriCalendar.fromDate(currentDate);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.chevron_left,
                    color: isDark ? colors.darkText : Colors.white,
                    size: 24.sp),
                onPressed: onPreviousPressed,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE',
                                  Localizations.localeOf(context).languageCode)
                              .format(currentDate),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? colors.darkText : Colors.white,
                            fontFamily: "Amiri",
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          '${hijriDate.hDay} ${_getHijriMonthName(hijriDate.hMonth, context)} ${hijriDate.hYear} هـ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? colors.darkText.withValues(alpha: 0.8)
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Amiri",
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 3.h),
                          child: Text(
                            dateFormat.format(currentDate),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isDark
                                  ? colors.darkText.withValues(alpha: 0.6)
                                  : Colors.white70,
                              fontFamily: "Amiri",
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.chevron_right,
                    color: isDark ? colors.darkText : Colors.white,
                    size: 24.sp),
                onPressed: onNextPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
