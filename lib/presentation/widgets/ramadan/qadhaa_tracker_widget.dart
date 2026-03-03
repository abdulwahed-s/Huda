import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/ramadan/ramadan_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class QadhaaTrackerWidget extends StatelessWidget {
  final List<RamadanDayInfo> ramadanDays;
  final int fastedCount;
  final int missedCount;
  final int currentDay;
  final bool isRamadan;
  final bool isDark;
  final Function(int dayNumber, String status) onSetStatus;

  const QadhaaTrackerWidget({
    super.key,
    required this.ramadanDays,
    required this.fastedCount,
    required this.missedCount,
    required this.currentDay,
    required this.isRamadan,
    required this.isDark,
    required this.onSetStatus,
  });

  String _getLocalizedDayOfWeek(String dayName, AppLocalizations l10n) {
    switch (dayName) {
      case 'Sunday':
        return l10n.sunday;
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      default:
        return dayName;
    }
  }

  bool _isDayEditable(RamadanDayInfo day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDate = DateTime(
        day.gregorianDate.year, day.gregorianDate.month, day.gregorianDate.day);
    return !dayDate.isAfter(today);
  }

  void _showInfoDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 32.w),
                    Expanded(
                      child: Text(
                        l10n.qadhaaInfoTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 1,
                ),
                SizedBox(height: 16.h),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(
                          context: context,
                          title: l10n.qadhaaInfoQ1Title,
                          icon: Icons.help_outline_rounded,
                          iconColor: Colors.blue.shade400,
                          children: [
                            _buildSectionBody(l10n.qadhaaInfoQ1Body),
                          ],
                        ),
                        _buildInfoCard(
                          context: context,
                          title: l10n.qadhaaInfoQ2Title,
                          icon: Icons.rule_rounded,
                          iconColor: Colors.orange.shade400,
                          children: [
                            _buildSectionBody(l10n.qadhaaInfoQ2Body1),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                l10n.qadhaaInfoQ2Verse,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Amiri",
                                  color: isDark
                                      ? Colors.amber.shade400
                                      : Colors.orange.shade800,
                                  height: 1.8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildSectionBody(l10n.qadhaaInfoQ2Body2),
                          ],
                        ),
                        _buildInfoCard(
                          context: context,
                          title: l10n.qadhaaInfoQ3Title,
                          icon: Icons.event_available_rounded,
                          iconColor: Colors.green.shade400,
                          children: [
                            _buildSectionBody(l10n.qadhaaInfoQ3Body),
                          ],
                        ),
                        _buildInfoCard(
                          context: context,
                          title: l10n.qadhaaInfoQ4Title,
                          icon: Icons.volunteer_activism_rounded,
                          iconColor: Colors.purple.shade400,
                          children: [
                            _buildSectionBody(l10n.qadhaaInfoQ4Body1),
                            SizedBox(height: 8.h),
                            _buildSectionBody(l10n.qadhaaInfoQ4Body2),
                          ],
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.5,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = isDark ? context.primaryLightColor : context.primaryColor;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: isDark
            ? null
            : Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: primary,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      l10n.qadhaaDays,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (missedCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$missedCount',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showInfoDialog(context, l10n),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18.sp,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        count: fastedCount,
                        label: l10n.fastedStatus,
                        color: const Color(0xFF22C55E),
                        primary: primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildStatChip(
                        count: missedCount,
                        label: l10n.missedStatus,
                        color: const Color(0xFFEF4444),
                        primary: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
          ...ramadanDays.map((day) {
            final isCurrentDay = isRamadan && day.dayNumber == currentDay;
            final isFuture = !_isDayEditable(day);

            return Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: isCurrentDay
                    ? (isDark
                        ? primary.withValues(alpha: 0.12)
                        : primary.withValues(alpha: 0.05))
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? primary.withValues(alpha: 0.15)
                          : isFuture
                              ? Colors.transparent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight:
                            isCurrentDay ? FontWeight.bold : FontWeight.w600,
                        color: isCurrentDay
                            ? primary
                            : isFuture
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedDayOfWeek(day.dayOfWeek, l10n),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isCurrentDay
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCurrentDay
                                ? primary
                                : isFuture
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${day.gregorianDate.year}-${day.gregorianDate.month.toString().padLeft(2, '0')}-${day.gregorianDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isCurrentDay
                                ? primary.withValues(alpha: 0.7)
                                : isFuture
                                    ? (isDark ? Colors.white24 : Colors.black26)
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFuture)
                    _buildStatusIcon(day.status,
                        enabled: false, primary: primary)
                  else
                    PopupMenuButton<String>(
                      onSelected: (status) =>
                          onSetStatus(day.dayNumber, status),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'fasted',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: const Color(0xFF22C55E), size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(l10n.fastedStatus),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'missed',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_rounded,
                                  color: const Color(0xFFEF4444), size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(l10n.missedStatus),
                            ],
                          ),
                        ),
                      ],
                      icon: _buildStatusIcon(day.status,
                          enabled: true, primary: primary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required int count,
    required String label,
    required Color color,
    required Color primary,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status,
      {required bool enabled, required Color primary}) {
    final double opacity = enabled ? 1.0 : 0.35;
    switch (status) {
      case 'fasted':
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF22C55E),
              size: 22.sp,
            ),
          ),
        );
      case 'missed':
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              size: 22.sp,
            ),
          ),
        );
      default:
        return Opacity(
          opacity: opacity,
          child: Icon(
            Icons.radio_button_unchecked,
            color: isDark ? Colors.white30 : Colors.grey[400],
            size: 22.sp,
          ),
        );
    }
  }
}
