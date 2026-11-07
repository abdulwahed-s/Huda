import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_push_service.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';

enum PrayerAttentionTone { error, warning, info }

/// Prayer-time problems the user can feel and fix. Location is not one of
/// them (the saved place stays in use; the Location sheet changes it), and
/// notification access lives in the readiness card
/// (prayer_alerts_ready_card.dart). Routine updating shows on the sky card's
/// place line, not here.
enum PrayerAttentionKind { workflow }

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
  const PrayerAttentionCallbacks({required this.retryWorkflow});

  final Future<void> Function() retryWorkflow;
}

List<PrayerAttentionItem> buildPrayerAttentionItems({
  required AppLocalizations l10n,
  required PrayerTimesLoaded state,
  required PrayerAttentionCallbacks callbacks,
  bool canChooseCountry = true,
}) => [?_workflowItem(l10n, state, callbacks, canChooseCountry)];

/// One problem, its words and icon, most severe first.
typedef _Problem = ({
  PrayerWorkflowIssue issue,
  IconData icon,
  String title,
  String message,
});

PrayerAttentionItem? _workflowItem(
  AppLocalizations l,
  PrayerTimesLoaded state,
  PrayerAttentionCallbacks callbacks,
  bool canChooseCountry,
) {
  final issues = state.workflowIssues;
  final problems = <_Problem>[
    if (issues.contains(PrayerWorkflowIssue.storage))
      (
        issue: PrayerWorkflowIssue.storage,
        icon: Icons.save_outlined,
        title: l.prayerFixSavingTitle,
        message: l.prayerFixSavingMessage,
      ),
    if (issues.contains(PrayerWorkflowIssue.calculation))
      (
        issue: PrayerWorkflowIssue.calculation,
        icon: Icons.calculate_outlined,
        title: l.prayerFixCalculationTitle,
        message: l.prayerFixCalculationMessage,
      ),
    if (issues.contains(PrayerWorkflowIssue.verification))
      (
        issue: PrayerWorkflowIssue.verification,
        icon: Icons.travel_explore_rounded,
        title: l.prayerFixCheckTitle,
        message: l.prayerFixCheckMessage,
      ),
    if (issues.contains(PrayerWorkflowIssue.widget))
      (
        issue: PrayerWorkflowIssue.widget,
        icon: Icons.widgets_outlined,
        title: l.prayerFixWidgetTitle,
        message: l.prayerFixWidgetMessage,
      ),
  ];
  final countryCandidates = canChooseCountry
      ? state.countryCandidates
      : const <String>[];
  if (problems.isEmpty && countryCandidates.isEmpty) return null;

  final retrying = state.workflowRetrying;
  final failed = problems.any(
    (p) =>
        p.issue == PrayerWorkflowIssue.storage ||
        p.issue == PrayerWorkflowIssue.calculation,
  );
  final lead = problems.isEmpty ? null : problems.first;
  final onlyCheck =
      problems.length == 1 && lead!.issue == PrayerWorkflowIssue.verification;
  // The strip asks the country question itself, under the message.
  final title = retrying
      ? l.prayerRetryingTitle
      : lead?.title ?? l.prayerFixCheckTitle;
  final message = countryCandidates.isNotEmpty
      ? l.prayerCountryQuestionHint
      : lead!.message;

  return PrayerAttentionItem(
    kind: PrayerAttentionKind.workflow,
    tone: failed
        ? PrayerAttentionTone.error
        : countryCandidates.isNotEmpty
        ? PrayerAttentionTone.warning
        : PrayerAttentionTone.info,
    rank: failed ? 0 : 3,
    icon: countryCandidates.isNotEmpty ? Icons.flag_outlined : lead!.icon,
    title: title,
    message: message,
    details: [
      // The rest, by name; the lead one is the card's own words.
      for (final p in problems.skip(1)) (icon: p.icon, text: p.title),
    ],
    // While the user's retry runs, the title says so; no second button.
    primary: problems.isEmpty || retrying
        ? null
        : PrayerAttentionAction(
            label: onlyCheck ? l.prayerFixCheckAction : l.retry,
            icon: Icons.refresh_rounded,
            onPressed: callbacks.retryWorkflow,
          ),
    busy: retrying,
    countryCandidates: countryCandidates,
  );
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

/// What a schedule result means to the user, one case per message.
enum PrayerAlertProblem {
  /// Scheduled and working.
  none,

  /// Scheduled, but Android may deliver a few minutes late.
  late,

  /// Waiting until the place is verified.
  waitingForPlace,

  /// iOS needs one online handoff of older server-sent alerts.
  needsOnline,

  /// Set through a date; later alerts need one online update.
  bridged,

  /// Huda's other reminders use every slot the device allows.
  noRoom,

  /// Settings changed while scheduling; scheduling again fixes it.
  settingsChanged,

  /// The server was busy.
  busy,

  /// The server couldn't be reached.
  serverUnavailable,

  /// The schedule couldn't be checked.
  verificationFailed,

  /// The device's own scheduling failed.
  localFailure,

  /// The schedule ran out.
  expired,

  /// Nothing scheduled yet.
  noneScheduled,

  /// The device has no prayer alerts at all.
  unsupported,

  /// Something else; Retry is still the next step.
  failed,
}

const _noRoomMessages = {
  'zero-local-capacity',
  'insufficient-safe-capacity',
  'No prayer alarm capacity is available.',
};

/// Null while there's nothing to say (no result yet, notifications off,
/// still being prepared).
PrayerAlertProblem? prayerAlertProblemOf(
  PrayerScheduleResult? schedule, {
  DateTime? now,
}) {
  if (schedule == null) return null;
  final status = schedule.status;
  final message = schedule.message;
  final coverage = schedule.coverageUntil;
  final clock = now ?? DateTime.now();
  if (status == PrayerScheduleStatus.permissionDenied) return null;
  if (message == PrayerNotificationScheduler.verificationPendingMessage) {
    return PrayerAlertProblem.waitingForPlace;
  }
  if (status == PrayerScheduleStatus.unsupported) {
    return PrayerAlertProblem.unsupported;
  }
  if (message == PrayerScheduleResult.localBridgeMessage && coverage != null) {
    return PrayerAlertProblem.bridged;
  }
  final expired =
      coverage != null &&
      coverage.isBefore(clock.subtract(const Duration(minutes: 1)));
  final issue =
      status == PrayerScheduleStatus.failed ||
      status == PrayerScheduleStatus.degraded ||
      status == PrayerScheduleStatus.deferred ||
      status == PrayerScheduleStatus.locationUnavailable;
  if (issue) {
    return switch (message) {
      PrayerScheduleResult.migrationPendingMessage =>
        PrayerAlertProblem.needsOnline,
      PrayerScheduleResult.localFailureMessage =>
        PrayerAlertProblem.localFailure,
      PrayerPushErrorCode.settingsChanged => PrayerAlertProblem.settingsChanged,
      PrayerPushErrorCode.busy => PrayerAlertProblem.busy,
      PrayerPushErrorCode.unavailable => PrayerAlertProblem.serverUnavailable,
      PrayerPushErrorCode.verificationFailed =>
        PrayerAlertProblem.verificationFailed,
      final m when _noRoomMessages.contains(m) => PrayerAlertProblem.noRoom,
      _ when expired => PrayerAlertProblem.expired,
      _ => PrayerAlertProblem.failed,
    };
  }
  if (expired) return PrayerAlertProblem.expired;
  if (coverage == null) {
    return schedule.pendingCount > 0 ? null : PrayerAlertProblem.noneScheduled;
  }
  return message == PrayerScheduleResult.inexactMessage
      ? PrayerAlertProblem.late
      : PrayerAlertProblem.none;
}

PrayerAlertStatus? buildPrayerAlertStatus({
  required AppLocalizations l10n,
  required PrayerTimesLoaded state,
  required NotificationAccess? access,
  required String Function(DateTime date) formatDate,
  required bool isIOS,
  required Future<void> Function() onEnableNotifications,
  required Future<void> Function() onRetry,
  Future<void> Function()? onAllowExactAlarms,
  bool notificationsAskedElsewhere = false,
}) {
  final schedule = state.notificationSchedule;
  final retrying = state.notificationScheduleRetrying;
  final notificationsOff =
      access?.needsNotification ??
      schedule?.status == PrayerScheduleStatus.permissionDenied;
  if (notificationsOff && notificationsAskedElsewhere) return null;
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

  final problem = prayerAlertProblemOf(schedule);
  final coverage = schedule?.coverageUntil;
  final offline = state.online == false;
  String withPrevious(String message) =>
      state.previousLocationNotifications && coverage != null
      ? '$message ${l10n.prayerAlertsPreviousPlace}'
      : message;

  // After the user's tap: its own words, no button.
  if (retrying) {
    return PrayerAlertStatus(
      tone: PrayerAlertTone.info,
      icon: Icons.notifications_active_outlined,
      title: l10n.prayerRetryingTitle,
      message: l10n.prayerAlertsRetryingMessage,
      busy: true,
    );
  }

  final retry = PrayerAttentionAction(
    label: l10n.prayerNotificationRetry,
    icon: Icons.refresh_rounded,
    onPressed: onRetry,
  );
  // While automatic work runs, a problem shows as updating, not as failed.
  final updating = state.updating;
  PrayerAlertStatus failed(
    String message, {
    IconData icon = Icons.notifications_paused_outlined,
    bool canRetry = true,
  }) => updating
      ? PrayerAlertStatus(
          tone: PrayerAlertTone.info,
          icon: Icons.sync_rounded,
          title: l10n.prayerAlertsUpdatingTitle,
          message: l10n.prayerAlertsUpdatingMessage,
          busy: true,
        )
      : PrayerAlertStatus(
          tone: PrayerAlertTone.error,
          icon: icon,
          title: l10n.prayerAlertsNotScheduledTitle,
          message: withPrevious(message),
          action: canRetry ? retry : null,
        );

  PrayerAlertStatus ready(String message, {PrayerAttentionAction? action}) =>
      PrayerAlertStatus(
        tone: PrayerAlertTone.ready,
        icon: Icons.notifications_active_rounded,
        title: l10n.prayerNotificationsScheduledTitle,
        message: message,
        highlight: l10n.prayerNotificationsScheduledUntil(
          formatDate(coverage!),
        ),
        action: action,
      );

  return switch (problem) {
    null => null,
    PrayerAlertProblem.none => ready(
      isIOS
          ? l10n.prayerNotificationsIosReminder
          : l10n.prayerNotificationsCoverageReminder,
    ),
    // The note's own fix, right there.
    PrayerAlertProblem.late => ready(
      l10n.prayerAlertsLateNote,
      action: onAllowExactAlarms == null
          ? null
          : PrayerAttentionAction(
              label: l10n.allowExactAlarms,
              icon: Icons.alarm_on_rounded,
              onPressed: onAllowExactAlarms,
            ),
    ),
    PrayerAlertProblem.waitingForPlace => PrayerAlertStatus(
      tone: PrayerAlertTone.info,
      icon: Icons.hourglass_top_rounded,
      title: l10n.prayerNotificationsWaitingTitle,
      message: withPrevious(l10n.prayerNotificationsWaitingMessage),
    ),
    PrayerAlertProblem.unsupported => PrayerAlertStatus(
      tone: PrayerAlertTone.info,
      icon: Icons.notifications_none_rounded,
      title: l10n.prayerAlertsUnsupportedTitle,
      message: l10n.prayerAlertsUnsupportedMessage,
    ),
    // Offline, the app finishes it on its own when the connection returns.
    PrayerAlertProblem.needsOnline => failed(
      offline
          ? l10n.prayerAlertsNeedsOnlineOffline
          : l10n.prayerAlertsNeedsOnline,
      icon: Icons.cloud_off_rounded,
      canRetry: !offline,
    ),
    PrayerAlertProblem.bridged => failed(
      offline
          ? l10n.prayerAlertsNeedsOnlineOffline
          : l10n.prayerNotificationsBridgedUntil(formatDate(coverage!)),
      icon: Icons.cloud_off_rounded,
      canRetry: !offline,
    ),
    PrayerAlertProblem.noRoom => failed(l10n.prayerAlertsNoRoom),
    PrayerAlertProblem.settingsChanged => failed(
      l10n.prayerNotificationSettingsChanged,
    ),
    PrayerAlertProblem.busy => failed(l10n.prayerNotificationSyncBusy),
    PrayerAlertProblem.serverUnavailable => failed(
      offline
          ? l10n.prayerAlertsNeedsOnlineOffline
          : l10n.prayerNotificationSyncUnavailable,
      canRetry: !offline,
    ),
    PrayerAlertProblem.verificationFailed => failed(
      l10n.prayerNotificationSyncVerificationFailed,
    ),
    PrayerAlertProblem.localFailure => failed(l10n.prayerAlertsLocalFailure),
    PrayerAlertProblem.expired => failed(
      l10n.prayerNotificationsCoverageExpired,
    ),
    PrayerAlertProblem.noneScheduled => failed(
      l10n.prayerNotificationsNoneScheduled,
    ),
    PrayerAlertProblem.failed => failed(l10n.prayerNotificationIssueMessage),
  };
}
