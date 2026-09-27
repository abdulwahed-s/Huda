import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';

enum PrayerAttentionTone { error, warning, info }

enum PrayerAttentionKind {
  updating,
  workflow,
  batteryOptimization,
  exactAlarms,
}

@immutable
class PrayerAttentionAction {
  const PrayerAttentionAction({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;

  final Future<void> Function()? onPressed;
}

@immutable
class PrayerAttentionItem {
  const PrayerAttentionItem({
    required this.kind,
    required this.tone,
    required this.rank,
    required this.icon,
    required this.title,
    required this.message,
    this.details = const [],
    this.primary,
    this.secondary,
    this.busy = false,
    this.offline = false,
    this.countryCandidates = const [],
  });

  final PrayerAttentionKind kind;
  final PrayerAttentionTone tone;

  final int rank;
  final IconData icon;
  final String title;
  final String message;
  final List<({IconData icon, String text})> details;
  final PrayerAttentionAction? primary;
  final PrayerAttentionAction? secondary;
  final bool busy;
  final bool offline;

  final List<String> countryCandidates;
}

class PrayerAttentionCallbacks {
  const PrayerAttentionCallbacks({
    required this.retryWorkflow,
    required this.openWorkflowSettings,
    required this.requestBatteryOptimization,
    required this.requestExactAlarms,
  });

  final Future<void> Function() retryWorkflow;
  final Future<void> Function(Set<PrayerWorkflowIssue> issues)
  openWorkflowSettings;
  final Future<void> Function() requestBatteryOptimization;
  final Future<void> Function() requestExactAlarms;
}

List<PrayerAttentionItem> buildPrayerAttentionItems({
  required AppLocalizations l10n,
  required PrayerTimesLoaded state,
  required NotificationAccess? access,
  required PrayerAttentionCallbacks callbacks,
  bool canChooseCountry = true,
}) {
  final alertsOn = access?.notificationsEnabled ?? false;
  final updating =
      state.updating &&
      !state.workflowRetrying &&
      !state.notificationScheduleRetrying;
  final items = <PrayerAttentionItem>[
    if (updating)
      PrayerAttentionItem(
        kind: PrayerAttentionKind.updating,
        tone: PrayerAttentionTone.info,
        rank: 6,
        icon: Icons.sync_rounded,
        title: l10n.prayerUpdatingTitle,
        message: l10n.prayerUpdatingMessage,
        busy: true,
      )
    else
      ?_workflowItem(l10n, state, callbacks, canChooseCountry),
    if (alertsOn && access!.needsBatteryOptimization)
      PrayerAttentionItem(
        kind: PrayerAttentionKind.batteryOptimization,
        tone: PrayerAttentionTone.warning,
        rank: 4,
        icon: Icons.battery_alert_outlined,
        title: l10n.batteryOptimizationTitle,
        message: access.needsExactAlarms
            ? l10n.batteryOptimizationExactAlarmDescription
            : l10n.batteryOptimizationDescription,
        primary: PrayerAttentionAction(
          label: l10n.keepRemindersReliable,
          icon: Icons.battery_saver_outlined,
          onPressed: callbacks.requestBatteryOptimization,
        ),
        secondary: access.needsExactAlarms
            ? PrayerAttentionAction(
                label: l10n.exactAlarmTitle,
                icon: Icons.alarm_add_outlined,
                onPressed: callbacks.requestExactAlarms,
              )
            : null,
      )
    else if (alertsOn && access!.needsExactAlarms)
      PrayerAttentionItem(
        kind: PrayerAttentionKind.exactAlarms,
        tone: PrayerAttentionTone.warning,
        rank: 4,
        icon: Icons.alarm_on_outlined,
        title: l10n.exactAlarmTitle,
        message: l10n.exactAlarmDescription,
        primary: PrayerAttentionAction(
          label: l10n.allowExactAlarms,
          icon: Icons.alarm_add_outlined,
          onPressed: callbacks.requestExactAlarms,
        ),
      ),
  ];
  final indexed = items.indexed.toList()
    ..sort(
      (a, b) => a.$2.rank != b.$2.rank
          ? a.$2.rank.compareTo(b.$2.rank)
          : a.$1.compareTo(b.$1),
    );
  return [for (final entry in indexed) entry.$2];
}

enum PrayerAlertTone { ready, info, warning, error }

@immutable
class PrayerAlertStatus {
  const PrayerAlertStatus({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    this.highlight,
    this.action,
    this.busy = false,
  });

  final PrayerAlertTone tone;
  final IconData icon;
  final String title;
  final String message;

  final String? highlight;
  final PrayerAttentionAction? action;
  final bool busy;
}

PrayerAlertStatus? buildPrayerAlertStatus({
  required AppLocalizations l10n,
  required PrayerTimesLoaded state,
  required NotificationAccess? access,
  required String Function(DateTime date) formatDate,
  required bool isIOS,
  required Future<void> Function() onEnableNotifications,
  required Future<void> Function() onRetry,
}) {
  final schedule = state.notificationSchedule;
  final retrying = state.notificationScheduleRetrying;
  final notificationsOff =
      access?.needsNotification ??
      schedule?.status == PrayerScheduleStatus.permissionDenied;
  if (notificationsOff) {
    final settings = access?.notificationNeedsSettings ?? false;
    return PrayerAlertStatus(
      tone: PrayerAlertTone.warning,
      icon: Icons.notifications_off_outlined,
      title: l10n.prayerNotificationsOffTitle,
      message: l10n.prayerNotificationsOffMessage,
      action: PrayerAttentionAction(
        label: settings ? l10n.openSettings : l10n.prayerNotificationsTurnOn,
        icon: settings
            ? Icons.settings_outlined
            : Icons.notifications_active_outlined,
        onPressed: onEnableNotifications,
      ),
    );
  }

  final coverage = schedule?.coverageUntil;
  String withPrevious(String message) =>
      state.previousLocationNotifications && coverage != null
      ? '$message ${l10n.prayerPreviousCoverage}'
      : message;
  final retry = PrayerAttentionAction(
    label: l10n.prayerNotificationRetry,
    icon: Icons.refresh_rounded,
    onPressed: onRetry,
  );
  PrayerAlertStatus status({
    required PrayerAlertTone tone,
    required IconData icon,
    required String title,
    required String message,
    String? highlight,
    PrayerAttentionAction? action,
  }) => PrayerAlertStatus(
    tone: tone,
    icon: icon,
    title: retrying ? l10n.prayerNotificationRetrying : title,
    message: message,
    highlight: highlight,
    action: retrying ? null : action,
    busy: retrying,
  );
  final updating = state.updating && !retrying;
  PrayerAlertStatus problem({
    required IconData icon,
    required String message,
  }) => updating
      ? PrayerAlertStatus(
          tone: PrayerAlertTone.info,
          icon: Icons.sync_rounded,
          title: l10n.prayerNotificationRetrying,
          message: l10n.prayerUpdatingMessage,
          busy: true,
        )
      : status(
          tone: PrayerAlertTone.error,
          icon: icon,
          title: l10n.prayerNotificationIssueTitle,
          message: message,
          action: retry,
        );

  switch (_scheduleView(state)) {
    case _ScheduleView.permissionDenied:
      return null;
    case _ScheduleView.hidden:
      return retrying
          ? PrayerAlertStatus(
              tone: PrayerAlertTone.info,
              icon: Icons.notifications_active_outlined,
              title: l10n.prayerNotificationRetrying,
              message: l10n.prayerUpdatingMessage,
              busy: true,
            )
          : null;
    case _ScheduleView.verificationPending:
      return status(
        tone: PrayerAlertTone.info,
        icon: Icons.hourglass_top_rounded,
        title: l10n.prayerNotificationsWaitingTitle,
        message: withPrevious(l10n.prayerNotificationsWaitingMessage),
      );
    case _ScheduleView.unsupported:
      return status(
        tone: PrayerAlertTone.info,
        icon: Icons.notifications_none_rounded,
        title: l10n.prayerNotificationIssueTitle,
        message: l10n.prayerNotificationsUnsupported,
      );
    case _ScheduleView.bridged:
      return problem(
        icon: Icons.cloud_off_rounded,
        message: l10n.prayerNotificationsBridgedUntil(formatDate(coverage!)),
      );
    case _ScheduleView.issue:
      final expired =
          coverage != null &&
          coverage.isBefore(
            DateTime.now().subtract(const Duration(minutes: 1)),
          );
      return problem(
        icon: Icons.notifications_paused_outlined,
        message: withPrevious(
          expired
              ? l10n.prayerNotificationsCoverageExpired
              : _issueMessage(l10n, schedule?.message),
        ),
      );
    case _ScheduleView.noneScheduled:
      return problem(
        icon: Icons.notifications_paused_outlined,
        message: l10n.prayerNotificationsNoneScheduled,
      );
    case _ScheduleView.ready:
      return status(
        tone: PrayerAlertTone.ready,
        icon: Icons.notifications_active_rounded,
        title: l10n.prayerNotificationsScheduledTitle,
        message: isIOS
            ? l10n.prayerNotificationsIosReminder
            : l10n.prayerNotificationsCoverageReminder,
        highlight: l10n.prayerNotificationsScheduledUntil(
          formatDate(coverage!),
        ),
      );
  }
}

PrayerAttentionItem? _workflowItem(
  AppLocalizations l,
  PrayerTimesLoaded state,
  PrayerAttentionCallbacks callbacks,
  bool canChooseCountry,
) {
  final issues = state.workflowIssues.difference(const {
    PrayerWorkflowIssue.notifications,
  });
  if (issues.isEmpty) return null;

  final offline = state.online == false;
  final retrying = state.workflowRetrying;
  final verification = issues.contains(PrayerWorkflowIssue.verification);
  final location = issues.contains(PrayerWorkflowIssue.location);
  final failed =
      issues.contains(PrayerWorkflowIssue.storage) ||
      issues.contains(PrayerWorkflowIssue.calculation);
  final localityOnly =
      issues.length == 1 && issues.contains(PrayerWorkflowIssue.locality);
  final localRecovery = issues.any(
    (issue) =>
        issue != PrayerWorkflowIssue.locality &&
        issue != PrayerWorkflowIssue.verification,
  );
  final canRetry = !offline || localRecovery;

  final icon = verification
      ? Icons.location_searching_rounded
      : location
      ? Icons.location_disabled_rounded
      : failed
      ? Icons.error_outline_rounded
      : localityOnly
      ? Icons.place_outlined
      : offline
      ? Icons.cloud_off_rounded
      : Icons.sync_problem_rounded;

  final countryCandidates = canChooseCountry
      ? state.countryCandidates
      : const <String>[];
  final summary = countryCandidates.isNotEmpty
      ? l.prayerCountryQuestionHint
      : verification
      ? (offline
            ? l.prayerVerificationGuidance
            : l.prayerVerificationRetryGuidance)
      : issues.contains(PrayerWorkflowIssue.locality)
      ? l.prayerUpdatesGuidance
      : l.prayerUpdatesLocalGuidance;

  return PrayerAttentionItem(
    kind: PrayerAttentionKind.workflow,
    tone: failed
        ? PrayerAttentionTone.error
        : localityOnly || (verification && !location)
        ? PrayerAttentionTone.info
        : PrayerAttentionTone.warning,
    rank: failed
        ? 0
        : location || countryCandidates.isNotEmpty
        ? 3
        : 5,
    icon: icon,
    title: verification
        ? l.prayerVerificationPending
        : l.prayerUpdatesIncomplete,
    message: summary,
    details: [
      if (location)
        (icon: Icons.location_disabled_rounded, text: l.prayerLocationPending),
      if (issues.contains(PrayerWorkflowIssue.locality))
        (icon: Icons.place_outlined, text: l.prayerDetailsPending),
      if (issues.contains(PrayerWorkflowIssue.storage))
        (icon: Icons.save_outlined, text: l.prayerSavingPending),
      if (issues.contains(PrayerWorkflowIssue.calculation))
        (icon: Icons.calculate_outlined, text: l.prayerCalculationPending),
      if (issues.contains(PrayerWorkflowIssue.nativeCandidate))
        (icon: Icons.travel_explore_rounded, text: l.prayerNativePending),
      if (issues.contains(PrayerWorkflowIssue.widget))
        (icon: Icons.widgets_outlined, text: l.prayerWidgetPending),
    ],
    primary: canRetry
        ? PrayerAttentionAction(
            label: retrying ? l.prayerIssueRetrying : l.retry,
            icon: retrying
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            onPressed: retrying ? null : callbacks.retryWorkflow,
          )
        : null,
    secondary: location
        ? PrayerAttentionAction(
            label: l.openSettings,
            icon: Icons.settings_outlined,
            onPressed: () => callbacks.openWorkflowSettings(issues),
          )
        : null,
    busy: retrying,
    offline: offline,
    countryCandidates: countryCandidates,
  );
}

enum _ScheduleView {
  hidden,
  permissionDenied,
  verificationPending,
  unsupported,
  bridged,
  issue,
  noneScheduled,
  ready,
}

_ScheduleView _scheduleView(PrayerTimesLoaded state) {
  final schedule = state.notificationSchedule;
  if (schedule == null) return _ScheduleView.hidden;
  final status = schedule.status;
  final coverage = schedule.coverageUntil;
  final coverageExpired =
      coverage != null &&
      coverage.isBefore(DateTime.now().subtract(const Duration(minutes: 1)));
  if (status == PrayerScheduleStatus.permissionDenied) {
    return _ScheduleView.permissionDenied;
  }
  if (schedule.message ==
      PrayerNotificationScheduler.verificationPendingMessage) {
    return _ScheduleView.verificationPending;
  }
  if (status == PrayerScheduleStatus.unsupported) {
    return _ScheduleView.unsupported;
  }
  if (schedule.message == PrayerScheduleResult.localBridgeMessage &&
      coverage != null) {
    return _ScheduleView.bridged;
  }
  if (coverageExpired || _isIssue(status)) return _ScheduleView.issue;
  if (coverage == null) {
    return schedule.pendingCount > 0
        ? _ScheduleView.hidden
        : _ScheduleView.noneScheduled;
  }
  return _ScheduleView.ready;
}

bool _isIssue(PrayerScheduleStatus? status) =>
    status == PrayerScheduleStatus.failed ||
    status == PrayerScheduleStatus.degraded ||
    status == PrayerScheduleStatus.deferred ||
    status == PrayerScheduleStatus.locationUnavailable;

String _issueMessage(AppLocalizations l10n, String? code) => switch (code) {
  PrayerPushErrorCode.settingsChanged => l10n.prayerNotificationSettingsChanged,
  PrayerPushErrorCode.busy => l10n.prayerNotificationSyncBusy,
  PrayerPushErrorCode.unavailable => l10n.prayerNotificationSyncUnavailable,
  PrayerPushErrorCode.verificationFailed =>
    l10n.prayerNotificationSyncVerificationFailed,
  _ => l10n.prayerNotificationIssueMessage,
};
