import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class PrayerNotificationScheduleBanner extends StatelessWidget {
  const PrayerNotificationScheduleBanner({
    super.key,
    required this.state,
    required this.onRetry,
    this.isIOS,
  });

  final PrayerTimesLoaded state;
  final Future<void> Function() onRetry;
  final bool? isIOS;

  @override
  Widget build(BuildContext context) {
    final schedule = state.notificationSchedule;
    final retrying = state.notificationScheduleRetrying;
    if (schedule == null && !retrying) {
      return const SizedBox.shrink();
    }

    final coverage = schedule?.coverageUntil;
    final coverageExpired =
        coverage != null &&
        coverage.isBefore(DateTime.now().subtract(const Duration(minutes: 1)));
    final hasIssue = coverageExpired || _isIssue(schedule?.status);
    if (!hasIssue && coverage == null) return const SizedBox.shrink();
    if (!hasIssue &&
        !retrying &&
        schedule?.status != PrayerScheduleStatus.scheduled &&
        schedule?.status != PrayerScheduleStatus.upToDate) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: _ScheduleBannerCard(
          key: ValueKey((hasIssue, retrying, coverage)),
          hasIssue: hasIssue,
          retrying: retrying,
          coverage: coverage,
          messageCode: schedule?.message,
          onRetry: onRetry,
          showIosReminder: isIOS ?? PlatformUtils.isIOS,
        ),
      ),
    );
  }

  bool _isIssue(PrayerScheduleStatus? status) {
    return status == PrayerScheduleStatus.failed ||
        status == PrayerScheduleStatus.degraded ||
        status == PrayerScheduleStatus.deferred ||
        status == PrayerScheduleStatus.locationUnavailable;
  }
}

class _ScheduleBannerCard extends StatelessWidget {
  const _ScheduleBannerCard({
    super.key,
    required this.hasIssue,
    required this.retrying,
    required this.coverage,
    required this.messageCode,
    required this.onRetry,
    required this.showIosReminder,
  });

  final bool hasIssue;
  final bool retrying;
  final DateTime? coverage;
  final String? messageCode;
  final Future<void> Function() onRetry;
  final bool showIosReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = hasIssue ? colors.error : colors.primary;
    final background = colors.surfaceContainerLow;
    final foreground = colors.onSurface;
    final title = retrying
        ? l10n.prayerNotificationRetrying
        : hasIssue
        ? l10n.prayerNotificationIssueTitle
        : l10n.prayerNotificationsScheduledTitle;
    final message = hasIssue
        ? _issueMessage(l10n)
        : _coverageMessage(context, l10n);

    return Semantics(
      button: hasIssue && !retrying,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasIssue && !retrying ? onRetry : null,
          borderRadius: BorderRadius.circular(18.r),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 10.w, 12.h),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: retrying
                      ? SizedBox.square(
                          dimension: 18.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Icon(
                          hasIssue
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_active_rounded,
                          color: accent,
                          size: 20.sp,
                        ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      if (!hasIssue && showIosReminder) ...[
                        SizedBox(height: 5.h),
                        Text(
                          l10n.prayerNotificationsIosReminder,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foreground.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasIssue && !retrying)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 8.w),
                    child: TextButton.icon(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        backgroundColor: accent.withValues(alpha: 0.08),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 7.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                      ),
                      icon: Icon(Icons.refresh_rounded, size: 16.sp),
                      label: Text(
                        l10n.prayerNotificationRetry,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _coverageMessage(BuildContext context, AppLocalizations l10n) {
    final date = coverage;
    if (date == null) return l10n.prayerNotificationIssueMessage;
    final formatted = MaterialLocalizations.of(
      context,
    ).formatMediumDate(date.isUtc ? date.toLocal() : date);
    final scheduledUntil = l10n.prayerNotificationsScheduledUntil(formatted);
    if (showIosReminder) return scheduledUntil;
    return '$scheduledUntil ${l10n.prayerNotificationsCoverageReminder}';
  }

  String _issueMessage(AppLocalizations l10n) {
    final date = coverage;
    if (date != null && date.isBefore(DateTime.now())) {
      return l10n.prayerNotificationsCoverageExpired;
    }
    return switch (messageCode) {
      PrayerPushErrorCode.settingsChanged =>
        l10n.prayerNotificationSettingsChanged,
      PrayerPushErrorCode.busy => l10n.prayerNotificationSyncBusy,
      PrayerPushErrorCode.unavailable => l10n.prayerNotificationSyncUnavailable,
      PrayerPushErrorCode.verificationFailed =>
        l10n.prayerNotificationSyncVerificationFailed,
      _ => l10n.prayerNotificationIssueMessage,
    };
  }
}
