import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_location_monitor.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';

class PrayerTravelSettingsCard extends StatefulWidget {
  const PrayerTravelSettingsCard({super.key, required this.locationMode});

  final PrayerLocationMode locationMode;

  @override
  State<PrayerTravelSettingsCard> createState() =>
      _PrayerTravelSettingsCardState();
}

class _PrayerTravelSettingsCardState extends State<PrayerTravelSettingsCard>
    with WidgetsBindingObserver {
  PrayerLocationMonitoringStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void didUpdateWidget(covariant PrayerTravelSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationMode != widget.locationMode) _reload();
  }

  Future<void> _reload() async {
    final cache = getIt<CacheHelper>();
    await cache.reload();
    final status = await getIt<PrayerLocationMonitor>().currentStatus(
      mode: widget.locationMode,
    );
    if (!mounted) return;
    setState(() {
      _status = status;
    });
  }

  Future<void> _toggle(bool enabled) async {
    setState(() => _busy = true);
    try {
      await getIt<PrayerLocationMonitor>().setEnabled(enabled);
      await _reload();
      if (enabled) await _maybeShowAndroidBackgroundPermissionHelp();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      final cubit = context.read<PrayerTimesCubit>();
      final monitor = getIt<PrayerLocationMonitor>();

      // Retry the actual permission flow as well as the location refresh. This
      // is needed when travel updates were enabled before location access was
      // granted, or when iOS has only granted foreground access so far.
      await monitor.setEnabled(true);
      await cubit.consumeQueuedNativeLocationCandidate();
      await cubit.refreshAutomaticLocationIfNeeded(force: true);
      await cubit.refreshNotificationSchedule();
      await monitor.sync(cubit.locationMode);
      await _reload();
      await _maybeShowAndroidBackgroundPermissionHelp();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRecoverySettings(PrayerBackgroundTravelState state) async {
    if (state == PrayerBackgroundTravelState.unavailable) {
      final opened = await Geolocator.openLocationSettings();
      if (!opened) {
        await getIt<PrayerLocationMonitor>().openAppSettings();
      }
      return;
    }

    if (PlatformUtils.isAndroid &&
        state == PrayerBackgroundTravelState.foregroundOnly) {
      await _showAndroidBackgroundPermissionHelp();
      return;
    }

    await getIt<PrayerLocationMonitor>().openAppSettings();
  }

  Future<void> _maybeShowAndroidBackgroundPermissionHelp() async {
    if (!PlatformUtils.isAndroid ||
        _status?.state != PrayerBackgroundTravelState.foregroundOnly) {
      return;
    }
    await _showAndroidBackgroundPermissionHelp();
  }

  Future<void> _showAndroidBackgroundPermissionHelp() async {
    final monitor = getIt<PrayerLocationMonitor>();
    final systemLabel = await monitor.backgroundPermissionOptionLabel();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.travelPermissionRequired),
        content: Text(
          l10n.travelBackgroundPermissionInstructions(
            systemLabel ?? l10n.travelAllowAllTheTime,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    if (shouldOpen == true) await monitor.openAppSettings();
  }

  Future<void> _selectManualLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ManualLocationSearchDialog(),
    );
    if (!mounted || result == null) return;

    final latitude = result['lat'];
    final longitude = result['lon'];
    if (latitude is! num || longitude is! num) return;

    setState(() => _busy = true);
    try {
      await context.read<PrayerTimesCubit>().setManualLocation(
        latitude.toDouble(),
        longitude.toDouble(),
        cityName: result['name'] as String?,
        countryCode: result['country_code'] as String?,
      );
      await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = _status;
    final visual = _statusVisual(theme, status?.state);
    final needsRecovery = _needsRecovery(status?.state);
    final isSupported =
        status?.state != PrayerBackgroundTravelState.unsupported;
    final isEnabled = isSupported && (status?.preferenceEnabled ?? false);
    final canToggle = !_busy && status != null && isSupported;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
                    Colors.grey[800]!.withValues(alpha: 0.8),
                    Colors.grey[850]!.withValues(alpha: 0.9),
                  ]
                : [Colors.white, Colors.grey[50]!],
          ),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _busy
                  ? LinearProgressIndicator(
                      key: const ValueKey('busy'),
                      minHeight: 2.h,
                      color: context.primaryColor,
                    )
                  : SizedBox(height: 2.h, key: const ValueKey('idle')),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.primaryColor,
                                context.primaryColor.withValues(alpha: 0.72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.travel_explore_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.prayerTravelUpdates,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                l10n.prayerTravelUpdatesDescription,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  height: 1.3,
                                  color: colors.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          visual.color.withValues(alpha: 0.1),
                          visual.color.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: visual.color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: visual.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: visual.color.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                visual.icon,
                                color: Colors.white,
                                size: 11.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusLabel(l10n, status?.state),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: visual.color,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    l10n.backgroundTravelUpdates,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              excludeSemantics: true,
                              toggled: isEnabled,
                              enabled: canToggle,
                              label:
                                  '${l10n.prayerTravelUpdates}: '
                                  '${_statusLabel(l10n, status?.state)}',
                              child: Switch.adaptive(
                                value: isEnabled,
                                onChanged: canToggle ? _toggle : null,
                              ),
                            ),
                          ],
                        ),
                        if (needsRecovery) ...[
                          SizedBox(height: 8.h),
                          Divider(
                            height: 1,
                            color: visual.color.withValues(alpha: 0.2),
                          ),
                          SizedBox(height: 6.h),
                          _RecoveryPanel(
                            color: visual.color,
                            settingsLabel:
                                status?.state ==
                                    PrayerBackgroundTravelState.unavailable
                                ? l10n.travelTurnOnLocation
                                : l10n.openSettings,
                            retryLabel:
                                status?.state ==
                                    PrayerBackgroundTravelState
                                        .permissionRequired
                                ? l10n.travelAllowLocation
                                : l10n.retry,
                            retryIcon:
                                status?.state ==
                                    PrayerBackgroundTravelState
                                        .permissionRequired
                                ? Icons.location_on_outlined
                                : Icons.refresh_rounded,
                            busy: _busy,
                            showRetry:
                                status?.state !=
                                PrayerBackgroundTravelState.unavailable,
                            settingsFirst:
                                PlatformUtils.isAndroid &&
                                status?.state ==
                                    PrayerBackgroundTravelState.foregroundOnly,
                            onSettings: () =>
                                _openRecoverySettings(status!.state),
                            onRetry: _retry,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]!.withValues(alpha: 0.3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.locationMode ==
                                      PrayerLocationMode.automatic
                                  ? Icons.my_location_rounded
                                  : Icons.location_on_outlined,
                              color: colors.onSurfaceVariant,
                              size: 14.sp,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                l10n.prayerLocationMode,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                widget.locationMode ==
                                        PrayerLocationMode.automatic
                                    ? l10n.automatic
                                    : l10n.manual,
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _selectManualLocation,
                            icon: Icon(Icons.search_rounded, size: 14.sp),
                            label: Text(
                              l10n.searchManually,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: colors.onSurface
                                  .withValues(alpha: 0.12),
                              padding: EdgeInsets.symmetric(vertical: 9.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              elevation: 2,
                              shadowColor: context.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(
    AppLocalizations l10n,
    PrayerBackgroundTravelState? state,
  ) => switch (state) {
    PrayerBackgroundTravelState.enabled => l10n.travelUpdatesEnabled,
    PrayerBackgroundTravelState.foregroundOnly => l10n.travelForegroundOnly,
    PrayerBackgroundTravelState.permissionRequired =>
      l10n.travelPermissionRequired,
    PrayerBackgroundTravelState.unsupported => l10n.travelUpdatesUnsupported,
    PrayerBackgroundTravelState.unavailable => l10n.travelUpdatesUnavailable,
    PrayerBackgroundTravelState.disabled => l10n.travelUpdatesDisabled,
    null => l10n.loading,
  };

  bool _needsRecovery(PrayerBackgroundTravelState? state) =>
      state == PrayerBackgroundTravelState.foregroundOnly ||
      state == PrayerBackgroundTravelState.permissionRequired ||
      state == PrayerBackgroundTravelState.unavailable;

  _TravelStatusVisual _statusVisual(
    ThemeData theme,
    PrayerBackgroundTravelState? state,
  ) => switch (state) {
    PrayerBackgroundTravelState.enabled => _TravelStatusVisual(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF75D69C)
          : const Color(0xFF217A4B),
      icon: Icons.check_circle_rounded,
    ),
    PrayerBackgroundTravelState.foregroundOnly => _TravelStatusVisual(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFFFFC26E)
          : const Color(0xFF965100),
      icon: Icons.info_rounded,
    ),
    PrayerBackgroundTravelState.permissionRequired => _TravelStatusVisual(
      color: theme.colorScheme.error,
      icon: Icons.location_disabled_rounded,
    ),
    PrayerBackgroundTravelState.unavailable => _TravelStatusVisual(
      color: theme.colorScheme.error,
      icon: Icons.error_rounded,
    ),
    PrayerBackgroundTravelState.unsupported => _TravelStatusVisual(
      color: theme.colorScheme.onSurfaceVariant,
      icon: Icons.block_rounded,
    ),
    PrayerBackgroundTravelState.disabled => _TravelStatusVisual(
      color: theme.colorScheme.onSurfaceVariant,
      icon: Icons.pause_circle_rounded,
    ),
    null => _TravelStatusVisual(
      color: theme.colorScheme.onSurfaceVariant,
      icon: Icons.hourglass_top_rounded,
    ),
  };
}

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({
    required this.color,
    required this.settingsLabel,
    required this.retryLabel,
    required this.retryIcon,
    required this.busy,
    required this.showRetry,
    required this.settingsFirst,
    required this.onSettings,
    required this.onRetry,
  });

  final Color color;
  final String settingsLabel;
  final String retryLabel;
  final IconData retryIcon;
  final bool busy;
  final bool showRetry;
  final bool settingsFirst;
  final VoidCallback onSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final settingsButton = TextButton.icon(
      onPressed: busy ? null : onSettings,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(Icons.settings_outlined, size: 14.sp),
      label: Text(settingsLabel, style: TextStyle(fontSize: 10.sp)),
    );
    final retryButton = TextButton.icon(
      onPressed: busy ? null : onRetry,
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(retryIcon, size: 14.sp),
      label: Text(retryLabel, style: TextStyle(fontSize: 10.sp)),
    );

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.h,
        children: [
          if (showRetry && !settingsFirst) retryButton,
          settingsButton,
          if (showRetry && settingsFirst) retryButton,
        ],
      ),
    );
  }
}

class _TravelStatusVisual {
  const _TravelStatusVisual({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}
