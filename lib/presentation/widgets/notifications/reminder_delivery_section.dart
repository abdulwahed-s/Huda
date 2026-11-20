import 'package:flutter/material.dart';
import 'package:huda/core/notifications/test_notification.dart';
import 'package:huda/core/notifications/windows_reminder_backend.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:intl/intl.dart';

typedef ReminderToast = void Function(String message, {HudaToastKind kind});

class ReminderDeliverySection extends StatelessWidget {
  const ReminderDeliverySection({super.key, required this.toast});

  final ReminderToast toast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(l10n.remindersDeliverySection),
        if (PlatformUtils.isLinux) ...[
          const _LinuxReminderStatus(),
          SizedBox(height: space.sm),
        ],
        if (PlatformUtils.isWindows) ...[
          _WindowsReminderStatus(toast: toast),
          SizedBox(height: space.sm),
        ],
        _TestNotificationCard(toast: toast),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.ready,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final bool ready;
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final action = this.action;
    return HudaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ready)
                HudaLamp(
                  size: 38,
                  child: Icon(icon, size: 20, color: tokens.gilt),
                )
              else
                HudaIconMark(icon),
              SizedBox(width: space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    SizedBox(height: space.xxs),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            SizedBox(height: space.sm),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        ],
      ),
    );
  }
}

class _LinuxReminderStatus extends StatelessWidget {
  const _LinuxReminderStatus();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LinuxPrayerTrayStatus>(
      valueListenable: LinuxPrayerTrayBridge.status,
      builder: (context, status, _) {
        final l10n = AppLocalizations.of(context)!;
        final ready = status.serviceAvailable && status.startupEnabled;
        return _DeliveryCard(
          ready: ready,
          icon: ready ? Icons.event_available_rounded : Icons.schedule_rounded,
          title: ready
              ? l10n.linuxRemindersReady
              : l10n.linuxPrayerTrayStartAtLogin,
          message: ready
              ? l10n.notificationsWillWorkReliably
              : l10n.linuxRemindersNeedService,
          action: ready
              ? null
              : OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoute.prayerTimes),
                  child: Text(l10n.linuxPrayerTrayStartAtLogin),
                ),
        );
      },
    );
  }
}

class _WindowsReminderStatus extends StatelessWidget {
  const _WindowsReminderStatus({required this.toast});

  final ReminderToast toast;

  Future<void> _startWithWindows(BuildContext context) async {
    final failed = AppLocalizations.of(context)!.windowsPrayerError;
    try {
      final preferences = await WindowsPrayerTaskbarBridge.getPreferences();
      await WindowsPrayerTaskbarBridge.setPreferences(
        preferences.copyWith(startWithWindows: true),
      );
    } catch (_) {
      toast(failed, kind: HudaToastKind.failed);
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
            return _DeliveryCard(
              ready: ready,
              icon: ready
                  ? Icons.event_available_rounded
                  : Icons.schedule_rounded,
              title: ready
                  ? l10n.windowsRemindersReady
                  : l10n.windowsRemindersQueuedUntil(until),
              message: ready
                  ? l10n.notificationsWillWorkReliably
                  : !status.helperAvailable
                  ? l10n.windowsRemindersOpenHuda
                  : status.startupBlocked
                  ? l10n.windowsPrayerStartupDisabled
                  : l10n.windowsRemindersNeedStartup,
              action: ready || !status.helperAvailable
                  ? null
                  : status.startupBlocked
                  ? OutlinedButton(
                      onPressed: WindowsPrayerTaskbarBridge.openStartupSettings,
                      child: Text(l10n.windowsPrayerOpenStartupSettings),
                    )
                  : OutlinedButton(
                      onPressed: () => _startWithWindows(context),
                      child: Text(l10n.windowsPrayerStartup),
                    ),
            );
          },
        );
      },
    );
  }
}

class _TestNotificationCard extends StatefulWidget {
  const _TestNotificationCard({required this.toast});

  final ReminderToast toast;

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
        HudaToastKind.done,
      ),
      TestNotificationOutcome.mayBeLate => (
        l10n.testNotificationMayBeLate,
        HudaToastKind.failed,
      ),
      TestNotificationOutcome.notificationsOff => (
        l10n.testNotificationNotificationsOff,
        HudaToastKind.failed,
      ),
      TestNotificationOutcome.serviceNotRunning => (
        l10n.testNotificationServiceNotRunning,
        HudaToastKind.failed,
      ),
      TestNotificationOutcome.failed => (
        l10n.testNotificationFailed,
        HudaToastKind.failed,
      ),
    };
    widget.toast(message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return _DeliveryCard(
      ready: false,
      icon: Icons.notification_add_outlined,
      title: l10n.testNotificationTitle,
      message: l10n.testNotificationDescription,
      action: OutlinedButton.icon(
        key: const ValueKey('reminders-send-test'),
        onPressed: _sending ? null : _send,
        icon: _sending
            ? HudaLampSpinner(size: 18, color: scheme.primary)
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(l10n.testNotificationSend),
      ),
    );
  }
}
