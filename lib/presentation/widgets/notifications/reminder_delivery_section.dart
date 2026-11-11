import 'package:flutter/material.dart';
import 'package:huda/core/notifications/test_notification.dart';
import 'package:huda/core/notifications/windows_reminder_backend.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/notifications/status_card.dart';
import 'package:intl/intl.dart';

/// Whether reminders reach the user: the desktop companions' status and the
/// test notification.
class ReminderDeliverySection extends StatelessWidget {
  const ReminderDeliverySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (PlatformUtils.isLinux) const _LinuxReminderStatus(),
        if (PlatformUtils.isWindows) const _WindowsReminderStatus(),
        const _TestNotificationCard(),
      ],
    );
  }
}

/// Linux reminders come from Huda's background service.
class _LinuxReminderStatus extends StatelessWidget {
  const _LinuxReminderStatus();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LinuxPrayerTrayStatus>(
      valueListenable: LinuxPrayerTrayBridge.status,
      builder: (context, status, _) {
        final l10n = AppLocalizations.of(context)!;
        final ready = status.serviceAvailable && status.startupEnabled;
        return StatusCard(
          title: ready
              ? l10n.linuxRemindersReady
              : l10n.linuxPrayerTrayStartAtLogin,
          subtitle: ready
              ? l10n.notificationsWillWorkReliably
              : l10n.linuxRemindersNeedService,
          icon: ready ? Icons.event_available : Icons.schedule,
          color: ready ? Colors.green : Colors.orange,
          isEnabled: ready,
          onTap: ready
              ? null
              : () => Navigator.of(context).pushNamed(AppRoute.prayerTimes),
        );
      },
    );
  }
}

/// Windows toasts cannot repeat: the companion renews them while it runs, so
/// reminders keep going only if it starts with Windows. Otherwise this shows
/// when the queued reminders run out.
class _WindowsReminderStatus extends StatelessWidget {
  const _WindowsReminderStatus();

  Future<void> _startWithWindows(BuildContext context) async {
    final failed = AppLocalizations.of(context)!.windowsPrayerError;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final preferences = await WindowsPrayerTaskbarBridge.getPreferences();
      await WindowsPrayerTaskbarBridge.setPreferences(
        preferences.copyWith(startWithWindows: true),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: WindowsReminderBackend.coverage,
      builder: (context, coverage, _) {
        if (coverage == null) return const SizedBox.shrink();
        return ValueListenableBuilder<WindowsPrayerTaskbarStatus>(
          valueListenable: WindowsPrayerTaskbarBridge.status,
          builder: (context, status, _) {
            final l10n = AppLocalizations.of(context)!;
            final ready = status.helperAvailable && status.startupEnabled;
            final until = DateFormat.yMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(coverage.toLocal());
            return StatusCard(
              title: ready
                  ? l10n.windowsRemindersReady
                  : l10n.windowsRemindersQueuedUntil(until),
              subtitle: ready
                  ? l10n.notificationsWillWorkReliably
                  : !status.helperAvailable
                  ? l10n.windowsRemindersOpenHuda
                  : status.startupBlocked
                  ? l10n.windowsPrayerStartupDisabled
                  : l10n.windowsRemindersNeedStartup,
              icon: ready ? Icons.event_available : Icons.schedule,
              color: ready ? Colors.green : Colors.orange,
              isEnabled: ready,
              onTap: ready || !status.helperAvailable
                  ? null
                  : status.startupBlocked
                  ? WindowsPrayerTaskbarBridge.openStartupSettings
                  : () => _startWithWindows(context),
              actionText: status.helperAvailable && status.startupBlocked
                  ? l10n.windowsPrayerOpenStartupSettings
                  : null,
            );
          },
        );
      },
    );
  }
}

/// Sends a notification through the same path as real reminders, and says
/// why when it can't (README decision 6).
class _TestNotificationCard extends StatefulWidget {
  const _TestNotificationCard();

  @override
  State<_TestNotificationCard> createState() => _TestNotificationCardState();
}

class _TestNotificationCardState extends State<_TestNotificationCard> {
  bool _sending = false;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    final outcome = await TestNotification.send(
      title: l10n.testNotificationContentTitle,
      body: l10n.testNotificationContentBody,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    final (message, kind) = switch (outcome) {
      TestNotificationOutcome.scheduled => (
        l10n.testNotificationArrivesSoon,
        HudaSnackBarKind.success,
      ),
      TestNotificationOutcome.mayBeLate => (
        l10n.testNotificationMayBeLate,
        HudaSnackBarKind.warning,
      ),
      TestNotificationOutcome.notificationsOff => (
        l10n.testNotificationNotificationsOff,
        HudaSnackBarKind.warning,
      ),
      TestNotificationOutcome.serviceNotRunning => (
        l10n.testNotificationServiceNotRunning,
        HudaSnackBarKind.warning,
      ),
      TestNotificationOutcome.failed => (
        l10n.testNotificationFailed,
        HudaSnackBarKind.error,
      ),
    };
    HudaSnackBar.show(context, message: message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StatusCard(
      title: l10n.testNotificationTitle,
      subtitle: l10n.testNotificationDescription,
      icon: Icons.notification_add_outlined,
      color: Theme.of(context).colorScheme.primary,
      isEnabled: true,
      onTap: _sending ? null : _send,
      actionText: l10n.testNotificationSend,
    );
  }
}
