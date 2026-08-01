import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationFeature {
  prayerTimes,
  hijriCalendar,
  reminders,
  khatma,
}

/// Shows the actions needed before a notification-based feature can work.
///
/// Contextual pages hide this section once they are correctly configured. The
/// notification settings page passes [showConfiguredStatus] so it can continue
/// to show the current setup status after everything is enabled.
class NotificationRequirementsSection extends StatefulWidget {
  const NotificationRequirementsSection({
    super.key,
    required this.feature,
    this.showConfiguredStatus = false,
    this.onNotificationEnabled,
    this.bottomSpacing = 0,
  });

  final NotificationFeature feature;
  final bool showConfiguredStatus;
  final Future<void> Function()? onNotificationEnabled;
  final double bottomSpacing;

  @override
  State<NotificationRequirementsSection> createState() =>
      _NotificationRequirementsSectionState();
}

class _NotificationRequirementsSectionState
    extends State<NotificationRequirementsSection> with WidgetsBindingObserver {
  bool _hasLoaded = false;
  bool _notificationsEnabled = false;
  bool _batteryOptimizationExempted = true;
  bool _notificationNeedsSettings = false;
  bool _isRequestInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PermissionHandlers.accessSettingsChanges.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    PermissionHandlers.accessSettingsChanges.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final cubit = context.read<NotificationsCubit>();
    final notificationsEnabled = await cubit.getIsNotificationEnabled();
    final batteryOptimizationExempted = PlatformUtils.isAndroid
        ? await cubit.getIsBatteryOptimizationExempted()
        : true;

    var notificationNeedsSettings = false;
    if (!notificationsEnabled &&
        (PlatformUtils.isAndroid || PlatformUtils.isIOS)) {
      final status = await Permission.notification.status;
      notificationNeedsSettings =
          status.isPermanentlyDenied || status.isRestricted;
    }

    if (!mounted) return;

    final shouldReschedule =
        _hasLoaded && !_notificationsEnabled && notificationsEnabled;
    setState(() {
      _hasLoaded = true;
      _notificationsEnabled = notificationsEnabled;
      _batteryOptimizationExempted = batteryOptimizationExempted;
      _notificationNeedsSettings = notificationNeedsSettings;
      _isRequestInProgress = false;
    });

    if (shouldReschedule && mounted) {
      await widget.onNotificationEnabled?.call();
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_isRequestInProgress) return;
    setState(() => _isRequestInProgress = true);
    await PermissionHandlers.requestNotificationPermission(context);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    if (_isRequestInProgress) return;
    setState(() => _isRequestInProgress = true);
    await PermissionHandlers.requestBatteryOptimization(context);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) return const SizedBox.shrink();

    final needsNotification = !_notificationsEnabled;
    final needsBatteryOptimization =
        PlatformUtils.isAndroid && !_batteryOptimizationExempted;

    if (!needsNotification && !needsBatteryOptimization) {
      if (!widget.showConfiguredStatus) return const SizedBox.shrink();
      return _StatusSection(
        child: _ConfiguredNotificationStatus(
          showBatteryStatus: PlatformUtils.isAndroid,
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final feature = _featureContentFor(l10n, theme, widget.feature);
    final batteryAccent = theme.colorScheme.secondary;

    final panel = _NotificationSetupPanel(
      title: needsNotification ? feature.title : l10n.batteryOptimizationTitle,
      description: needsNotification
          ? feature.description
          : l10n.batteryOptimizationDescription,
      icon: needsNotification ? feature.icon : Icons.battery_alert_outlined,
      accent: needsNotification ? feature.accent : batteryAccent,
      notificationActionLabel: needsNotification
          ? (_notificationNeedsSettings
              ? l10n.openSettings
              : l10n.enableNotifications)
          : null,
      notificationNeedsSettings: _notificationNeedsSettings,
      onNotificationPressed:
          needsNotification ? _requestNotificationPermission : null,
      batteryTitle: needsNotification && needsBatteryOptimization
          ? l10n.batteryOptimizationTitle
          : null,
      batteryDescription: needsNotification && needsBatteryOptimization
          ? l10n.batteryOptimizationDescription
          : null,
      batteryActionLabel:
          needsBatteryOptimization ? l10n.keepRemindersReliable : null,
      batteryAccent: batteryAccent,
      onBatteryPressed: needsBatteryOptimization
          ? _requestBatteryOptimizationExemption
          : null,
      isLoading: _isRequestInProgress,
    );

    if (!widget.showConfiguredStatus) {
      return _withBottomSpacing(panel);
    }
    return _StatusSection(child: panel);
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
  ThemeData theme,
  NotificationFeature feature,
) {
  switch (feature) {
    case NotificationFeature.prayerTimes:
      return _NotificationFeatureContent(
        title: l10n.prayerTimesPermissionTitle,
        description: l10n.prayerTimesPermissionDescription,
        icon: Icons.mosque_outlined,
        accent: theme.colorScheme.primary,
      );
    case NotificationFeature.hijriCalendar:
      return _NotificationFeatureContent(
        title: l10n.calendarPermissionTitle,
        description: l10n.calendarPermissionDescription,
        icon: Icons.event_available_outlined,
        accent: theme.colorScheme.secondary,
      );
    case NotificationFeature.reminders:
      return _NotificationFeatureContent(
        title: l10n.remindersPermissionTitle,
        description: l10n.remindersPermissionDescription,
        icon: Icons.notifications_active_outlined,
        accent: theme.colorScheme.primary,
      );
    case NotificationFeature.khatma:
      return _NotificationFeatureContent(
        title: l10n.khatmaPermissionTitle,
        description: l10n.khatmaPermissionDescription,
        icon: Icons.auto_stories_outlined,
        accent: theme.colorScheme.primary,
      );
  }
}

class _NotificationFeatureContent {
  const _NotificationFeatureContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.status,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10.h),
        child,
      ],
    );
  }
}

class _NotificationSetupPanel extends StatelessWidget {
  const _NotificationSetupPanel({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.notificationActionLabel,
    required this.notificationNeedsSettings,
    required this.onNotificationPressed,
    required this.batteryTitle,
    required this.batteryDescription,
    required this.batteryActionLabel,
    required this.batteryAccent,
    required this.onBatteryPressed,
    required this.isLoading,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String? notificationActionLabel;
  final bool notificationNeedsSettings;
  final VoidCallback? onNotificationPressed;
  final String? batteryTitle;
  final String? batteryDescription;
  final String? batteryActionLabel;
  final Color batteryAccent;
  final VoidCallback? onBatteryPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final hasNotificationAction = notificationActionLabel != null;
    final hasBatteryAction = batteryActionLabel != null;
    final needsStandaloneBatterySpacing =
        hasBatteryAction && !hasNotificationAction && batteryTitle == null;

    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.42 : 0.24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.3 : 0.16),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: accent, size: 23.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasNotificationAction) ...[
              SizedBox(height: 16.h),
              _SetupActionButton(
                label: notificationActionLabel!,
                icon: notificationNeedsSettings
                    ? Icons.settings_outlined
                    : Icons.notifications_active_outlined,
                color: accent,
                foregroundColor: theme.colorScheme.onPrimary,
                onPressed: onNotificationPressed,
                isLoading: isLoading,
              ),
            ],
            if (hasNotificationAction && hasBatteryAction) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Divider(
                  height: 1,
                  color: onSurface.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
              ),
            ],
            if (batteryTitle != null && batteryDescription != null) ...[
              _BatteryRequirement(
                title: batteryTitle!,
                description: batteryDescription!,
                accent: batteryAccent,
              ),
              SizedBox(height: 12.h),
            ],
            if (needsStandaloneBatterySpacing) SizedBox(height: 16.h),
            if (hasBatteryAction)
              _SetupActionButton(
                label: batteryActionLabel!,
                icon: Icons.battery_saver_outlined,
                color: batteryAccent,
                foregroundColor: theme.colorScheme.onSecondary,
                onPressed: onBatteryPressed,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _BatteryRequirement extends StatelessWidget {
  const _BatteryRequirement({
    required this.title,
    required this.description,
    required this.accent,
  });

  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.battery_alert_outlined, color: accent, size: 20.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupActionButton extends StatelessWidget {
  const _SetupActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Icon(icon, size: 19.sp),
        label: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          minimumSize: Size.fromHeight(48.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: themeTextStyle(context),
        ),
      ),
    );
  }

  TextStyle themeTextStyle(BuildContext context) {
    return (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w700);
  }
}

class _ConfiguredNotificationStatus extends StatelessWidget {
  const _ConfiguredNotificationStatus({required this.showBatteryStatus});

  final bool showBatteryStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final success = Colors.green;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: success.withValues(alpha: isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: success.withValues(alpha: isDark ? 0.38 : 0.2),
        ),
      ),
      child: Column(
        children: [
          _ConfiguredStatusRow(
            icon: Icons.notifications_active_outlined,
            title: AppLocalizations.of(context)!.notificationsReadyTitle,
            description:
                AppLocalizations.of(context)!.notificationsReadyDescription,
            color: success,
          ),
          if (showBatteryStatus) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Divider(
                height: 1,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: isDark ? 0.2 : 0.12),
              ),
            ),
            _ConfiguredStatusRow(
              icon: Icons.battery_charging_full_outlined,
              title:
                  AppLocalizations.of(context)!.batteryOptimizationReadyTitle,
              description: AppLocalizations.of(context)!
                  .batteryOptimizationReadyDescription,
              color: success,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfiguredStatusRow extends StatelessWidget {
  const _ConfiguredStatusRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
