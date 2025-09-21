import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class CalendarHeaderWidget extends StatelessWidget {
  final Animation<double> animation;
  final HijriCalendar focusedHijri;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool isDark;
  final BuildContext context;

  const CalendarHeaderWidget({
    super.key,
    required this.animation,
    required this.focusedHijri,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20.h * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          context.primaryColor.withValues(alpha: 0.15),
                          context.primaryColor.withValues(alpha: 0.08),
                          context.primaryVariantColor.withValues(alpha: 0.12),
                        ]
                      : [
                          context.primaryLightColor.withValues(alpha: 0.12),
                          context.primaryLightColor.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.1),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 8),
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20.r,
                  ),
                  BoxShadow(
                    offset: const Offset(0, 4),
                    color: context.primaryColor
                        .withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 12.r,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHijriMonthName(focusedHijri.hMonth),
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 0.5,
                              fontFamily: "Amiri",
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${focusedHijri.hYear} هـ',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontFamily: "Amiri",
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: IconButton(
                              onPressed: onPreviousMonth,
                              icon: Icon(
                                Icons.chevron_left,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 28.w,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: IconButton(
                              onPressed: onNextMonth,
                              icon: Icon(
                                Icons.chevron_right,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 28.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
}
