import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';

class EventsSectionWidget extends StatelessWidget {
  final List<HijriEvent> events;
  final BuildContext parentContext;
  final bool isDark;
  final Function(HijriEvent) onEditEvent;
  final Function(HijriEvent) onDeleteEvent;
  final BuildContext context;

  const EventsSectionWidget({
    super.key,
    required this.events,
    required this.parentContext,
    required this.isDark,
    required this.onEditEvent,
    required this.onDeleteEvent,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape ? double.infinity : 0.25.sh,
      ),
      child: events.isEmpty
          ? _buildEmptyEventsPlaceholder(isLandscape)
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            ),
    );
  }

  Widget _buildEmptyEventsPlaceholder(bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: isLandscape ? 12.h : 24.w,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 40.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.noEventsForThisDate,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              fontFamily: "Amiri",
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context)!.tapPlusButtonToAddEvent,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
              fontFamily: "Amiri",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(HijriEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? context.darkTabBackground : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: (8.r).clamp(0, double.infinity),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3.w, color: Color(event.colorValue)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                                fontFamily: "Amiri",
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEditEvent(event);
                              } else if (value == 'delete') {
                                onDeleteEvent(event);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16.w),
                                    SizedBox(width: 8.w),
                                    Text(AppLocalizations.of(context)!
                                        .editEvent),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 16.w, color: Colors.red),
                                    SizedBox(width: 8.w),
                                    Text(AppLocalizations.of(context)!
                                        .deleteEvent),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(
                              Icons.more_vert,
                              size: 16.w,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (event.description.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                            fontFamily: "Amiri",
                          ),
                        ),
                      ],
                      if (!event.isAllDay && event.startTime != null) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12.w,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              event.endTime != null
                                  ? '${event.startTime!.format(context)} - ${event.endTime!.format(context)}'
                                  : event.startTime!.format(context),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                                fontFamily: "Amiri",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
