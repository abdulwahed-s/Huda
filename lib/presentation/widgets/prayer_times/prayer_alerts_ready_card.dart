import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/services/mac_prayer_bridge.dart';
import 'package:huda/core/services/mac_prayer_experience.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';

/// Everything that can stop prayer alerts from arriving, in the order the
/// user should fix them. Each is explained before anything is asked.
enum PrayerReadinessKind {
  notifications,
  prayerChannels,
  exactAlarms,
  battery,
  alarmPermission,
  macBanners,
  macLogin,
  windowsStartup,
  linuxStartup,
}

@immutable
class PrayerReadinessItem {
  const PrayerReadinessItem({
    required this.kind,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.warning,
  });

  final PrayerReadinessKind kind;
  final IconData icon;
  final String title;
  final String message;
  final PrayerSetupAction action;
  final ({String title, String text, IconData icon})? warning;
}

/// The platform state readiness depends on, read from the existing bridges.
@immutable
class PrayerReadinessInputs {
  const PrayerReadinessInputs({
    this.access,
    this.ios,
    this.mac,
    this.windows,
    this.linux,
  });

  final NotificationAccess? access;
  final IOSPrayerStatus? ios;
  final MacPrayerStatus? mac;
  final WindowsPrayerTaskbarStatus? windows;
  final LinuxPrayerTrayStatus? linux;
}

class PrayerReadinessActions {
  const PrayerReadinessActions({
    required this.requestNotifications,
    required this.openNotificationSettings,
    required this.openPrayerChannelSettings,
    required this.requestExactAlarms,
    required this.requestBatteryOptimization,
    required this.requestAlarms,
    required this.openAppleSettings,
    required this.openMacNotificationSettings,
    required this.openMacLoginSettings,
    required this.startWithWindows,
    required this.openWindowsStartupSettings,
    required this.startLinuxAtLogin,
  });

  final Future<void> Function() requestNotifications;
  final Future<void> Function() openNotificationSettings;
  final Future<void> Function() openPrayerChannelSettings;
  final Future<void> Function() requestExactAlarms;
  final Future<void> Function() requestBatteryOptimization;
  final Future<void> Function() requestAlarms;
  final Future<void> Function() openAppleSettings;
  final Future<void> Function() openMacNotificationSettings;
  final Future<void> Function() openMacLoginSettings;
  final Future<void> Function() startWithWindows;
  final Future<void> Function() openWindowsStartupSettings;
  final Future<void> Function() startLinuxAtLogin;
}

List<PrayerReadinessItem> buildPrayerReadinessItems({
  required AppLocalizations l10n,
  required PrayerReadinessInputs inputs,
  required PrayerReadinessActions actions,
}) {
  final access = inputs.access;
  final items = <PrayerReadinessItem>[];
  if (access == null) return items;

  if (access.needsNotification) {
    final settings = access.notificationNeedsSettings;
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.notifications,
        icon: Icons.notifications_active_rounded,
        title: l10n.prayerSetupAlertsTitle,
        message: l10n.prayerSetupAlertsIntro,
        warning: settings
            ? (
                title: l10n.prayerNotificationsOffTitle,
                text: l10n.prayerReadyNotificationsBlocked,
                icon: Icons.notifications_off_outlined,
              )
            : null,
        action: settings
            ? PrayerSetupAction(
                l10n.openSettings,
                Icons.settings_outlined,
                actions.openNotificationSettings,
              )
            : PrayerSetupAction(
                l10n.prayerSetupAlertsAllow,
                Icons.notifications_active_outlined,
                actions.requestNotifications,
              ),
      ),
    );
    // Everything below depends on notifications being allowed.
    return items;
  }

  if (!access.prayerChannelsAllowed) {
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.prayerChannels,
        icon: Icons.notifications_paused_rounded,
        title: l10n.prayerReadyChannelsTitle,
        message: l10n.prayerReadyChannelsMessage,
        action: PrayerSetupAction(
          l10n.openSettings,
          Icons.settings_outlined,
          actions.openPrayerChannelSettings,
        ),
      ),
    );
  }
  if (access.needsExactAlarms) {
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.exactAlarms,
        icon: Icons.alarm_on_rounded,
        title: l10n.prayerReadyExactTitle,
        message: l10n.prayerReadyExactMessage,
        action: PrayerSetupAction(
          l10n.prayerReadyAllow,
          Icons.alarm_add_outlined,
          actions.requestExactAlarms,
        ),
      ),
    );
  }
  if (access.needsBatteryOptimization) {
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.battery,
        icon: Icons.battery_charging_full_rounded,
        title: l10n.prayerSetupReliableTitle,
        message: l10n.prayerSetupReliableIntro,
        action: PrayerSetupAction(
          l10n.keepRemindersReliable,
          Icons.battery_saver_outlined,
          actions.requestBatteryOptimization,
        ),
      ),
    );
  }

  final ios = inputs.ios;
  if (ios != null &&
      ios.supportsAlarms &&
      ios.alarmAuthorization != 'authorized' &&
      ios.policies.values.any(
        (policy) => policy['reason'] == 'alarmPermission',
      )) {
    final denied = ios.alarmAuthorization == 'denied';
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.alarmPermission,
        icon: Icons.alarm_rounded,
        title: l10n.prayerReadyAlarmTitle,
        message: l10n.prayerReadyAlarmMessage,
        action: denied
            ? PrayerSetupAction(
                l10n.openSettings,
                Icons.settings_outlined,
                actions.openAppleSettings,
              )
            : PrayerSetupAction(
                l10n.prayerReadyAllow,
                Icons.alarm_add_outlined,
                actions.requestAlarms,
              ),
      ),
    );
  }

  final mac = inputs.mac;
  if (mac != null) {
    if (mac.notificationAlertStyle == 'none') {
      items.add(
        PrayerReadinessItem(
          kind: PrayerReadinessKind.macBanners,
          icon: Icons.web_asset_rounded,
          title: l10n.prayerReadyBannersTitle,
          message: l10n.prayerReadyBannersMessage,
          action: PrayerSetupAction(
            l10n.openSettings,
            Icons.settings_outlined,
            actions.openMacNotificationSettings,
          ),
        ),
      );
    }
    final livePlayback =
        mac.experience.enabled &&
        mac.experience.mode != MacPrayerReminderMode.silent;
    if (livePlayback &&
        (mac.startupState == 'requiresApproval' ||
            mac.experience.startAtLogin && mac.startupState != 'enabled')) {
      items.add(
        PrayerReadinessItem(
          kind: PrayerReadinessKind.macLogin,
          icon: Icons.login_rounded,
          title: l10n.prayerReadyLoginTitle,
          message: l10n.prayerReadyLoginMessage,
          action: PrayerSetupAction(
            l10n.macPrayerLoginSettings,
            Icons.settings_outlined,
            actions.openMacLoginSettings,
          ),
        ),
      );
    }
  }

  final windows = inputs.windows;
  if (windows != null && windows.helperAvailable && !windows.startupEnabled) {
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.windowsStartup,
        icon: Icons.restart_alt_rounded,
        title: l10n.prayerReadyWindowsStartupTitle,
        message: l10n.prayerReadyWindowsStartupMessage,
        action: windows.startupBlocked
            ? PrayerSetupAction(
                l10n.windowsPrayerOpenStartupSettings,
                Icons.settings_outlined,
                actions.openWindowsStartupSettings,
              )
            : PrayerSetupAction(
                l10n.prayerReadyTurnOn,
                Icons.power_settings_new_rounded,
                actions.startWithWindows,
              ),
      ),
    );
  }

  final linux = inputs.linux;
  if (linux != null &&
      linux.serviceAvailable &&
      linux.startupKnown &&
      !linux.startupEnabled) {
    items.add(
      PrayerReadinessItem(
        kind: PrayerReadinessKind.linuxStartup,
        icon: Icons.restart_alt_rounded,
        title: l10n.prayerReadyLinuxStartupTitle,
        message: l10n.prayerReadyLinuxStartupMessage,
        action: PrayerSetupAction(
          l10n.prayerReadyTurnOn,
          Icons.power_settings_new_rounded,
          actions.startLinuxAtLogin,
        ),
      ),
    );
  }
  return items;
}

/// One explained step at a time to get prayer alerts working, shown on
/// Prayer Times after the times. "Not now" hides a step for good; the alert
/// status keeps saying what is off.
class PrayerAlertsReadyCard extends StatefulWidget {
  const PrayerAlertsReadyCard({
    super.key,
    required this.access,
    required this.cache,
  });

  final NotificationAccessController access;
  final CacheHelper cache;

  static const _snoozePrefix = 'prayer_ready_snoozed_';

  /// Answers from the previous setup checklist still count.
  static bool snoozed(CacheHelper cache, PrayerReadinessKind kind) {
    bool flag(String key) => cache.getData(key: key) == true;
    return flag('$_snoozePrefix${kind.name}') ||
        kind == PrayerReadinessKind.notifications &&
            flag('prayer_setup_alerts_answered') ||
        kind == PrayerReadinessKind.battery &&
            flag('prayer_setup_reliability_answered');
  }

  /// Whether the card shows an item of this kind right now.
  static bool showing(
    CacheHelper cache,
    List<PrayerReadinessItem> items,
    PrayerReadinessKind kind,
  ) => items
      .where((item) => !snoozed(cache, item.kind))
      .any((item) => item.kind == kind);

  @override
  State<PrayerAlertsReadyCard> createState() => _PrayerAlertsReadyCardState();
}

class _PrayerAlertsReadyCardState extends State<PrayerAlertsReadyCard> {
  bool _busy = false;

  Listenable get _sources => Listenable.merge([
    widget.access,
    if (PlatformUtils.isIOS) IOSPrayerBridge.status,
    if (PlatformUtils.isMacOS) MacPrayerBridge.status,
    if (PlatformUtils.isWindows) WindowsPrayerTaskbarBridge.status,
    if (PlatformUtils.isLinux) LinuxPrayerTrayBridge.status,
  ]);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      debugPrint('Prayer readiness action failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await widget.access.refresh();
  }

  Future<void> _snooze(PrayerReadinessKind kind) async {
    await widget.cache.saveData(
      key: '${PrayerAlertsReadyCard._snoozePrefix}${kind.name}',
      value: true,
    );
    if (mounted) setState(() {});
  }

  Future<void> _reconcile() async {
    if (getIt.isRegistered<PrayerNotificationScheduler>()) {
      await getIt<PrayerNotificationScheduler>().reconcile(
        reason: 'prayer-readiness',
        force: true,
      );
    }
  }

  PrayerReadinessActions _actions(BuildContext context) =>
      PrayerReadinessActions(
        requestNotifications: () =>
            widget.access.requestNotifications(context, explain: false),
        openNotificationSettings: widget.access.openNotificationSettings,
        openPrayerChannelSettings: widget.access.openPrayerChannelSettings,
        requestExactAlarms: () => widget.access.requestExactAlarms(context),
        requestBatteryOptimization: () =>
            widget.access.requestBatteryOptimization(context),
        requestAlarms: () async {
          await IOSPrayerBridge.requestAlarms();
          await _reconcile();
        },
        openAppleSettings: () async {
          await IOSPrayerBridge.openSettings();
        },
        openMacNotificationSettings: MacPrayerBridge.openNotificationSettings,
        openMacLoginSettings: MacPrayerBridge.openLoginSettings,
        startWithWindows: () async {
          final preferences = await WindowsPrayerTaskbarBridge.getPreferences();
          await WindowsPrayerTaskbarBridge.setPreferences(
            preferences.copyWith(startWithWindows: true),
          );
        },
        openWindowsStartupSettings:
            WindowsPrayerTaskbarBridge.openStartupSettings,
        startLinuxAtLogin: () => LinuxPrayerTrayBridge.setPreferences(
          LinuxPrayerTrayBridge.preferences.value.copyWith(startAtLogin: true),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sources,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final pending =
            buildPrayerReadinessItems(
                  l10n: l10n,
                  inputs: PrayerReadinessInputs(
                    access: widget.access.access,
                    ios: PlatformUtils.isIOS
                        ? IOSPrayerBridge.status.value
                        : null,
                    mac: PlatformUtils.isMacOS
                        ? MacPrayerBridge.status.value
                        : null,
                    windows: PlatformUtils.isWindows
                        ? WindowsPrayerTaskbarBridge.status.value
                        : null,
                    linux: PlatformUtils.isLinux
                        ? LinuxPrayerTrayBridge.status.value
                        : null,
                  ),
                  actions: _actions(context),
                )
                .where(
                  (item) =>
                      !PrayerAlertsReadyCard.snoozed(widget.cache, item.kind),
                )
                .toList();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: pending.isEmpty
              ? const SizedBox(
                  key: ValueKey('prayer-ready-done'),
                  width: double.infinity,
                )
              : Padding(
                  key: ValueKey('prayer-ready-${pending.first.kind.name}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReadyStep(
                    item: pending.first,
                    remaining: pending.length,
                    busy: _busy,
                    onAction: () => _run(pending.first.action.onPressed),
                    onNotNow: () => _snooze(pending.first.kind),
                  ),
                ),
        );
      },
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({
    required this.item,
    required this.remaining,
    required this.busy,
    required this.onAction,
    required this.onNotNow,
  });

  final PrayerReadinessItem item;
  final int remaining;
  final bool busy;
  final Future<void> Function() onAction;
  final Future<void> Function() onNotNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.prayerReadyTitle,
      child: PrayerSetupActiveStep(
        number: 1,
        total: remaining,
        heading: remaining > 1
            ? l10n.prayerReadyStepsLeft(remaining)
            : l10n.prayerReadyTitle,
        busy: busy,
        step: PrayerSetupStep(
          icon: item.icon,
          title: item.title,
          status: PrayerSetupStepStatus.active,
          summary: item.message,
          message: item.message,
          warning: item.warning,
          primary: PrayerSetupAction(
            item.action.label,
            item.action.icon,
            onAction,
          ),
          links: [
            PrayerSetupAction(
              l10n.permissionExplainerNotNow,
              Icons.close_rounded,
              onNotNow,
            ),
          ],
        ),
      ),
    );
  }
}
