import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';

class CalendarGridWidget extends StatelessWidget {
  final HijriCalendar focusedHijri;
  final HijriCalendarState state;
  final bool isDark;
  final HijriCalendar? selectedHijri;
  final Function(HijriCalendar, DateTime) onDateSelected;
  final void Function(BuildContext) onAddEvent;
  final BuildContext context;

  const CalendarGridWidget({
    super.key,
    required this.focusedHijri,
    required this.state,
    required this.isDark,
    required this.selectedHijri,
    required this.onDateSelected,
    required this.onAddEvent,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalMargin = isLandscape ? 8.w : 16.w;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        color: isDark ? context.darkTabBackground : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.06),
            blurRadius: (28.r).clamp(0, double.infinity),
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? context.primaryColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: (8.r).clamp(0, double.infinity),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          children: [
            _buildCalendarHeader(context),
            _buildHijriCalendarGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 12.w : 20.w;
    final verticalPadding = isLandscape ? 12.h : 16.h;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  context.primaryColor.withValues(alpha: 0.03),
                  Colors.grey.withValues(alpha: 0.02),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.15),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getHijriMonthName(focusedHijri.hMonth)} ${focusedHijri.hYear} هـ',
                  style: TextStyle(
                    fontSize: isLandscape ? 16.sp : 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.3,
                    fontFamily: "Amiri",
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_getGregorianMonthName(_getGregorianDateFromHijri(focusedHijri).month)} ${_getGregorianDateFromHijri(focusedHijri).year} م',
                  style: TextStyle(
                    fontSize: isLandscape ? 11.sp : 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontFamily: "Amiri",
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: isDark ? Colors.white70 : context.primaryColor,
              size: isLandscape ? 18.w : 20.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriCalendarGrid(BuildContext context) {
    return Column(
      children: [
        _buildDaysOfWeekHeader(),
        _buildHijriMonthGrid(context),
      ],
    );
  }

  Widget _buildDaysOfWeekHeader() {
    final localizations = AppLocalizations.of(context)!;
    final dayNames = [
      localizations.localeName == 'ar' ? 'الأحد' : 'Sun',
      localizations.localeName == 'ar' ? 'الإثنين' : 'Mon',
      localizations.localeName == 'ar' ? 'الثلاثاء' : 'Tue',
      localizations.localeName == 'ar' ? 'الأربعاء' : 'Wed',
      localizations.localeName == 'ar' ? 'الخميس' : 'Thu',
      localizations.localeName == 'ar' ? 'الجمعة' : 'Fri',
      localizations.localeName == 'ar' ? 'السبت' : 'Sat',
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  Colors.grey.withValues(alpha: 0.02),
                  Colors.grey.withValues(alpha: 0.05),
                  Colors.grey.withValues(alpha: 0.02),
                ],
        ),
      ),
      child: Row(
        children: dayNames.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isWeekend = index == 5 || index == 6;
          return Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 3.w),
                decoration: BoxDecoration(
                  color: isWeekend
                      ? (isDark
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    color: isWeekend
                        ? (isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700)
                        : (isDark ? Colors.white : Colors.grey.shade700),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.sp,
                    letterSpacing: 0.2,
                    fontFamily: "Amiri",
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHijriMonthGrid(BuildContext context) {
    final daysInMonth =
        _getDaysInHijriMonth(focusedHijri.hYear, focusedHijri.hMonth);
    final firstDayHijri = HijriCalendar()
      ..hYear = focusedHijri.hYear
      ..hMonth = focusedHijri.hMonth
      ..hDay = 1;

    final firstDayGregorian = _getGregorianDateFromHijri(firstDayHijri);
    final firstDayWeekday =
        firstDayGregorian.weekday == 7 ? 0 : firstDayGregorian.weekday;

    final weeks = <Widget>[];
    final days = <Widget>[];

    for (int i = 0; i < firstDayWeekday; i++) {
      days.add(Container(height: 40.h));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentHijri = HijriCalendar()
        ..hYear = focusedHijri.hYear
        ..hMonth = focusedHijri.hMonth
        ..hDay = day;

      final gregorianDateTime = _getGregorianDateFromHijri(currentHijri);
      final events = state.events[currentHijri.toString()] ?? [];

      days.add(_buildCurrentMonthDay(
        currentHijri,
        gregorianDateTime,
        events.cast<HijriEvent>(),
      ));

      if (days.length == 7) {
        weeks.add(Row(children: days.map((d) => Expanded(child: d)).toList()));
        days.clear();
      }
    }

    if (days.isNotEmpty) {
      while (days.length < 7) {
        days.add(Container(height: 40.h));
      }
      weeks.add(Row(children: days.map((d) => Expanded(child: d)).toList()));
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final gridPadding = isLandscape ? 6.w : 8.w;

    return Padding(
      padding: EdgeInsets.all(gridPadding),
      child: Column(children: weeks),
    );
  }

  Widget _buildCurrentMonthDay(
    HijriCalendar hijriDate,
    DateTime gregorianDate,
    List<HijriEvent> events,
  ) {
    final isSelected = selectedHijri?.toString() == hijriDate.toString();
    final isToday = _isSameDay(gregorianDate, DateTime.now());
    final isWeekend = gregorianDate.weekday == DateTime.friday ||
        gregorianDate.weekday == DateTime.saturday;

    return GestureDetector(
      onTap: () => onDateSelected(hijriDate, gregorianDate),
      onLongPress: () => onAddEvent(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 40.h,
        margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: _getDayBackgroundColor(isSelected, isToday, isWeekend),
          border: _getDayBorder(isSelected, isToday, isWeekend),
          boxShadow: _getDayBoxShadow(isSelected, isToday),
        ),
        child: Stack(
          children: [
            if (isSelected || isToday)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primaryColor,
                            context.primaryColor.withValues(alpha: 0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primaryColor.withValues(alpha: 0.15),
                            context.primaryColor.withValues(alpha: 0.08),
                          ],
                        ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${hijriDate.hDay}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _getDayTextColor(isSelected, isToday, isWeekend),
                      height: 1.1,
                      fontFamily: "Amiri",
                    ),
                  ),
                  if (events.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    _buildEventIndicators(events),
                  ],
                ],
              ),
            ),
            if (events.isNotEmpty)
              Positioned(
                top: 3.h,
                right: 3.w,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: events.length == 1
                        ? Color(events.first.colorValue)
                        : context.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (events.length == 1
                                ? Color(events.first.colorValue)
                                : context.primaryColor)
                            .withValues(alpha: 0.6),
                        blurRadius: 4.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventIndicators(List<HijriEvent> events) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (events.length == 1) _buildEventDot(events.first, size: 5),
        if (events.length == 2) ...[
          _buildEventDot(events[0], size: 4),
          SizedBox(width: 2.w),
          _buildEventDot(events[1], size: 4),
        ],
        if (events.length >= 3) ...[
          _buildEventDot(events[0], size: 3),
          SizedBox(width: 1.w),
          _buildEventDot(events[1], size: 3),
          SizedBox(width: 1.w),
          Container(
            width: 3.w,
            height: 3.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.white70 : Colors.grey.shade600)
                      .withValues(alpha: 0.4),
                  blurRadius: 2.r,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventDot(HijriEvent event, {double size = 5}) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.w / 2),
        color: Color(event.colorValue),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 0.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(event.colorValue).withValues(alpha: 0.6),
            blurRadius: (size * 1.5).w,
            spreadRadius: 0.5.w,
          ),
        ],
      ),
    );
  }

  Color _getDayBackgroundColor(bool isSelected, bool isToday, bool isWeekend) {
    if (isSelected) return Colors.transparent;
    if (isToday) return Colors.transparent;
    if (isWeekend) {
      return isDark
          ? Colors.orange.withValues(alpha: 0.05)
          : Colors.orange.withValues(alpha: 0.03);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.grey.withValues(alpha: 0.01);
  }

  Border? _getDayBorder(bool isSelected, bool isToday, bool isWeekend) {
    if (isToday && !isSelected) {
      return Border.all(
        color: context.primaryColor.withValues(alpha: 0.6),
        width: 2.w,
      );
    } else if (isWeekend && !isSelected && !isToday) {
      return Border.all(
        color: (isDark ? Colors.orange.shade300 : Colors.orange.shade600)
            .withValues(alpha: 0.3),
        width: 1.w,
      );
    } else if (isSelected) {
      return Border.all(
        color: context.primaryColor.withValues(alpha: 0.8),
        width: 2.w,
      );
    }
    return Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.08),
      width: 0.5.w,
    );
  }

  List<BoxShadow>? _getDayBoxShadow(bool isSelected, bool isToday) {
    if (isSelected) {
      return [
        BoxShadow(
          color: context.primaryColor.withValues(alpha: 0.4),
          blurRadius: 12.r,
          offset: const Offset(0, 6),
          spreadRadius: 1.r,
        ),
        BoxShadow(
          color: context.primaryColor.withValues(alpha: 0.2),
          blurRadius: 24.r,
          offset: const Offset(0, 12),
          spreadRadius: 0,
        ),
      ];
    } else if (isToday) {
      return [
        BoxShadow(
          color: context.primaryColor.withValues(alpha: 0.25),
          blurRadius: 8.r,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 4.r,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];
    }
  }

  Color _getDayTextColor(bool isSelected, bool isToday, bool isWeekend) {
    if (isSelected) return Colors.white;
    if (isToday) return context.primaryColor;
    if (isWeekend) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    }
    return isDark ? Colors.white : Colors.black87;
  }

  int _getDaysInHijriMonth(int year, int month) {
    if (month.isOdd) return 30;
    if (month == 12 && _isHijriLeapYear(year)) return 30;
    return 29;
  }

  bool _isHijriLeapYear(int year) => ((year * 11) + 14) % 30 < 11;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _getGregorianDateFromHijri(HijriCalendar hijriDate) {
    try {
      final today = DateTime.now();
      final todayHijri = HijriCalendar.fromDate(today);
      final yearDiff = (hijriDate.hYear - todayHijri.hYear) * 354;
      final monthDiff = (hijriDate.hMonth - todayHijri.hMonth) * 29;
      final dayDiff = hijriDate.hDay - todayHijri.hDay;
      final totalDayDiff = yearDiff + monthDiff + dayDiff;
      return today.add(Duration(days: totalDayDiff));
    } catch (e) {
      debugPrint('Date conversion error: $e');
      return DateTime.now();
    }
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
