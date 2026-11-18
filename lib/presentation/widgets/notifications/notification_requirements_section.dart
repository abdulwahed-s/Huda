import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';

enum NotificationFeature { prayerTimes, hijriCalendar, reminders, khatma }

/// Shows the actions needed before a notification-based feature can work.
///
/// Contextual pages hide this section once they are correctly configured. The
/// notification settings page passes [showConfiguredStatus] so it can continue
/// to show the current setup status after everything is enabled.
///
/// Drawn in Lantern: a card led by a lit lamp (an invitation) with the lit
/// button for the first thing to allow, and quiet rows for the rest.
class NotificationRequirementsSection extends StatefulWidget {
  const NotificationRequirementsSection({
    super.key,
    required this.feature,
    this.showConfiguredStatus = false,
    this.onNotificationEnabled,
    this.bottomSpacing = 0,
    this.controller,
  });

  final NotificationFeature feature;
  final bool showConfiguredStatus;
  final Future<void> Function()? onNotificationEnabled;
  final double bottomSpacing;

  /// A controller the page already owns (it keeps it and disposes it);
  /// otherwise the section makes its own.
  final NotificationAccessController? controller;

  @override
  State<NotificationRequirementsSection> createState() =>
      _NotificationRequirementsSectionState();
}

class _NotificationRequirementsSectionState
    extends State<NotificationRequirementsSection> {
  late final NotificationAccessController _controller;
  late final bool _owned = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        NotificationAccessController(
          cubit: context.read<NotificationsCubit>(),
          onAccessGained: widget.onNotificationEnabled,
        );
    _controller.addListener(_onAccessChanged);
  }

  @override
  void didUpdateWidget(covariant NotificationRequirementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_owned) _controller.onAccessGained = widget.onNotificationEnabled;
  }

  @override
  void dispose() {
    _controller.removeListener(_onAccessChanged);
    if (_owned) _controller.dispose();
    super.dispose();
  }

  void _onAccessChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final access = _controller.access;
    if (access == null) return const SizedBox.shrink();
    if (access.isReady && !widget.showConfiguredStatus) {
      return const SizedBox.shrink();
    }
    return _withBottomSpacing(
      access.isReady
          ? NotificationsReadyStatus(detailed: PlatformUtils.isAndroid)
          : _panel(context, access),
    );
  }

  Widget _panel(BuildContext context, NotificationAccess access) {
    final l10n = AppLocalizations.of(context)!;
    final feature = _featureContentFor(l10n, widget.feature);
    final requirements = <_SetupRequirement>[
      if (access.needsNotification)
        _SetupRequirement(
          title: feature.title,
          description: feature.description,
          icon: feature.icon,
          actionLabel: access.notificationNeedsSettings
              ? l10n.openSettings
              : l10n.enableNotifications,
          actionIcon: access.notificationNeedsSettings
              ? Icons.settings_outlined
              : Icons.notifications_active_outlined,
          // This card is the explanation; a tap goes straight to the prompt
          // or, when only the user can allow it, to the system settings.
          onPressed: access.notificationNeedsSettings
              ? _controller.openNotificationSettings
              : () => _controller.requestNotifications(context, explain: false),
        ),
      if (access.needsBatteryOptimization)
        _SetupRequirement(
          title: l10n.batteryOptimizationTitle,
          description: access.needsExactAlarms
              ? l10n.batteryOptimizationExactAlarmDescription
              : l10n.batteryOptimizationDescription,
          icon: Icons.battery_alert_outlined,
          actionLabel: l10n.keepRemindersReliable,
          actionIcon: Icons.battery_saver_outlined,
          onPressed: () => _controller.requestBatteryOptimization(context),
        ),
      if (access.needsExactAlarms)
        _SetupRequirement(
          title: l10n.exactAlarmTitle,
          description: l10n.exactAlarmDescription,
          icon: Icons.alarm_on_outlined,
          actionLabel: l10n.allowExactAlarms,
          actionIcon: Icons.alarm_add_outlined,
          onPressed: () => _controller.requestExactAlarms(context),
        ),
    ];
    return _NotificationSetupPanel(
      primary: requirements.first,
      more: requirements.skip(1).toList(),
      busy: _controller.isRequestInProgress,
    );
  }

  Widget _withBottomSpacing(Widget child) {
    if (widget.bottomSpacing == 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpacing),
      child: child,
    );
  }
}

_NotificationFeatureContent _featureContentFor(
  AppLocalizations l10n,
  NotificationFeature feature,
) => switch (feature) {
  NotificationFeature.prayerTimes => _NotificationFeatureContent(
    title: l10n.prayerTimesPermissionTitle,
    description: l10n.prayerTimesPermissionDescription,
    icon: Icons.mosque_outlined,
  ),
  NotificationFeature.hijriCalendar => _NotificationFeatureContent(
    title: l10n.calendarPermissionTitle,
    description: l10n.calendarPermissionDescription,
    icon: Icons.event_available_outlined,
  ),
  NotificationFeature.reminders => _NotificationFeatureContent(
    title: l10n.remindersPermissionTitle,
    description: l10n.remindersPermissionDescription,
    icon: Icons.notifications_active_outlined,
  ),
  NotificationFeature.khatma => _NotificationFeatureContent(
    title: l10n.khatmaPermissionTitle,
    description: l10n.khatmaPermissionDescription,
    icon: Icons.auto_stories_outlined,
  ),
};

class _NotificationFeatureContent {
  const _NotificationFeatureContent({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _SetupRequirement {
  const _SetupRequirement({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.actionIcon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onPressed;
}

class _NotificationSetupPanel extends StatelessWidget {
  const _NotificationSetupPanel({
    required this.primary,
    required this.more,
    required this.busy,
  });

  final _SetupRequirement primary;
  final List<_SetupRequirement> more;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget spinner(Color color) => HudaLampSpinner(size: 18, color: color);
    return Semantics(
      container: true,
      child: HudaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lit: an invitation, not a fault.
                HudaLamp(
                  size: 40,
                  child: Icon(primary.icon, size: 20, color: tokens.gilt),
                ),
                SizedBox(width: space.sm),
                Expanded(
                  child: _Text(
                    title: primary.title,
                    description: primary.description,
                    titleStyle: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: space.md),
            FilledButton.icon(
              onPressed: busy ? null : primary.onPressed,
              icon: busy
                  ? spinner(scheme.onPrimary)
                  : Icon(primary.actionIcon, size: 20),
              label: Text(primary.actionLabel, textAlign: TextAlign.center),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            for (final requirement in more) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: space.md),
                child: const Divider(height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudaIconMark(requirement.icon),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: _Text(
                      title: requirement.title,
                      description: requirement.description,
                      titleStyle: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              OutlinedButton.icon(
                onPressed: busy ? null : requirement.onPressed,
                icon: busy
                    ? spinner(scheme.primary)
                    : Icon(requirement.actionIcon, size: 20),
                label: Text(
                  requirement.actionLabel,
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.title,
    required this.description,
    required this.titleStyle,
  });

  final String title;
  final String description;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        SizedBox(height: context.tokens.space.xxs),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Everything needed is allowed: one lamp-led line, lit. [detailed] adds
/// Android's exact alarms and battery lines under it.
class NotificationsReadyStatus extends StatelessWidget {
  const NotificationsReadyStatus({super.key, this.detailed = false});

  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget line(String title, String description) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title, style: theme.textTheme.titleSmall),
          const TextSpan(text: '\n'),
          TextSpan(
            text: description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HudaLamp(
            size: 36,
            child: Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: tokens.gilt,
            ),
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                line(
                  l10n.notificationsReadyTitle,
                  l10n.notificationsReadyDescription,
                ),
                if (detailed) ...[
                  SizedBox(height: space.xs),
                  line(
                    l10n.exactAlarmsReadyTitle,
                    l10n.exactAlarmsReadyDescription,
                  ),
                  SizedBox(height: space.xs),
                  line(
                    l10n.batteryOptimizationReadyTitle,
                    l10n.batteryOptimizationReadyDescription,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
