import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_calendar_event.dart';

class IslamicEventsSectionWidget extends StatelessWidget {
  const IslamicEventsSectionWidget({
    super.key,
    required this.events,
    required this.isDark,
  });

  final List<IslamicCalendarEvent> events;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, isLandscape ? 4.h : 8.h),
      child: Column(
        children: [
          for (final event in events)
            _IslamicEventCard(event: event, isDark: isDark),
        ],
      ),
    );
  }
}

class _IslamicEventCard extends StatelessWidget {
  const _IslamicEventCard({required this.event, required this.isDark});

  final IslamicCalendarEvent event;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(AppLocalizations.of(context)!, event.eventKey);

    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark
              ? event.color.withValues(alpha: 0.14)
              : event.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: event.color.withValues(alpha: isDark ? 0.42 : 0.28),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(event.icon, color: event.color, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations localizations, String eventKey) {
    return switch (eventKey) {
      'ramadan' => localizations.calendarEventFirstDayRamadan,
      'last_ten_ramadan' => localizations.eventLastTenRamadan,
      'eid_al_fitr' => localizations.calendarEventEidAlFitr,
      'eid_al_adha' => localizations.calendarEventEidAlAdha,
      'day_of_arafah' => localizations.eventDayOfArafah,
      'first_ten_dhul_hijjah' => localizations.eventFirstTenDhulHijjah,
      'ashura' => localizations.eventAshura,
      'days_of_tashreeq' => localizations.eventDaysTashreeq,
      _ => localizations.eventSpecialOccasion,
    };
  }
}
