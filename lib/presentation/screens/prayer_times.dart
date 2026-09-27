import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';
import 'package:huda/presentation/widgets/prayer_times/persistent_prayer_countdown_control_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_alert_status_card.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_share_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_hero_card.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_loading_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_travel_settings_card.dart';
import 'package:permission_handler/permission_handler.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> with WidgetsBindingObserver {
  static const _alertsAnsweredKey = 'prayer_setup_alerts_answered';
  static const _reliabilityAnsweredKey = 'prayer_setup_reliability_answered';

  late PrayerTimesCubit _prayerTimesCubit;
  late final NotificationAccessController _access;

  bool _prepared = false;

  bool _setupShown = false;
  bool _setupBusy = false;

  bool _alertsDeclined = false;

  @override
  void initState() {
    super.initState();
    _prayerTimesCubit = context.read<PrayerTimesCubit>();
    _access = NotificationAccessController(
      cubit: context.read<NotificationsCubit>(),
      onAccessGained: _prayerTimesCubit.refreshNotificationSchedule,
    )..addListener(_onAccessChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePrayerTimes();
    });
  }

  void _onAccessChanged() {
    if (mounted) setState(() {});
  }

  bool _flag(String key) =>
      _prayerTimesCubit.cacheHelper.getData(key: key) == true;

  Future<void> _setFlag(String key) async {
    await _prayerTimesCubit.cacheHelper.saveData(key: key, value: true);
    if (mounted) setState(() {});
  }

  PrayerSetupAlerts get _alertsStatus {
    final access = _access.access;
    if (access?.notificationsEnabled ?? false) return PrayerSetupAlerts.granted;
    if (_flag(_alertsAnsweredKey)) return PrayerSetupAlerts.skipped;
    if (_alertsDeclined || (access?.notificationNeedsSettings ?? false)) {
      return PrayerSetupAlerts.declined;
    }
    return PrayerSetupAlerts.pending;
  }

  PrayerSetupReliability? get _reliabilityStatus {
    if (!PlatformUtils.isAndroid) return null;
    final access = _access.access;
    if (access?.batteryOptimizationExempted ?? false) {
      return PrayerSetupReliability.done;
    }
    if (_alertsStatus == PrayerSetupAlerts.skipped) {
      return PrayerSetupReliability.skipped;
    }
    if (_flag(_reliabilityAnsweredKey)) {
      return (access?.exactAlarmsAllowed ?? false)
          ? PrayerSetupReliability.done
          : PrayerSetupReliability.skipped;
    }
    return PrayerSetupReliability.pending;
  }

  bool get _alertStepsSettled {
    final alerts = _alertsStatus;
    final reliability = _reliabilityStatus;
    return (alerts == PrayerSetupAlerts.granted ||
            alerts == PrayerSetupAlerts.skipped) &&
        reliability != PrayerSetupReliability.pending;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _prayerTimesCubit.loadCachedPrayerTimes();
      final current = _prayerTimesCubit.state;
      if (current is PrayerTimesLoaded) {
        unawaited(_prayerTimesCubit.loadPrayerTimes());
      } else if (current is PrayerTimesLocationDenied ||
          current is PrayerTimesLocationPermanentlyDenied ||
          current is PrayerTimesLocationServiceDisabled) {
        unawaited(_retryLocationIfAccessRestored());
      }
    }
  }

  Future<void> _retryLocationIfAccessRestored() async {
    if (!_alertStepsSettled) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    await _prayerTimesCubit.refreshLocationAndPrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _access
      ..removeListener(_onAccessChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _preparePrayerTimes() async {
    if (!mounted) return;

    _prayerTimesCubit.loadCachedPrayerTimes();
    await _access.ready.timeout(const Duration(seconds: 3), onTimeout: () {});
    if (!mounted) return;
    setState(() => _prepared = true);

    final state = _prayerTimesCubit.state;
    if (state is PrayerTimesLoaded) {
      unawaited(_prayerTimesCubit.refreshNotificationSchedule());
      if (!state.provisional) unawaited(_askAlertsOnce());
      return;
    }
    if (state is PrayerTimesLoading ||
        state is PrayerTimesLocationDenied ||
        state is PrayerTimesLocationPermanentlyDenied ||
        state is PrayerTimesLocationServiceDisabled ||
        state is PrayerTimesError) {
      return;
    }

    if (!_alertStepsSettled) return;
    await _prayerTimesCubit.loadPrayerTimes();
  }

  Future<void> _askAlertsOnce() async {
    if (_flag(_alertsAnsweredKey) ||
        _alertsStatus != PrayerSetupAlerts.pending ||
        !(PlatformUtils.isAndroid || PlatformUtils.isIOS)) {
      return;
    }
    await _access.requestNotificationPrompt(context);
    await _setFlag(_alertsAnsweredKey);
  }

  Future<void> _runSetupAction(Future<void> Function() action) async {
    if (_setupBusy) return;
    setState(() => _setupBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _setupBusy = false);
    }
  }

  Future<void> _allowAlerts() => _runSetupAction(() async {
    final granted = await _access.requestNotificationPrompt(context);
    if (!mounted) return;
    if (granted) {
      await _setFlag(_alertsAnsweredKey);
    } else {
      setState(() => _alertsDeclined = true);
    }
  });

  Future<void> _allowReliability() => _runSetupAction(() async {
    await _access.requestBatteryOptimization(context);
    if (_access.access?.batteryOptimizationExempted ?? false) {
      await _setFlag(_reliabilityAnsweredKey);
    }
  });

  Future<void> _useExactAlarms() => _runSetupAction(() async {
    await _access.requestExactAlarms(context);
    if (_access.access?.exactAlarmsAllowed ?? false) {
      await _setFlag(_reliabilityAnsweredKey);
    }
  });

  Future<void> _searchManually() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ManualLocationSearchDialog(),
    );
    if (!mounted || result == null) return;

    final lat = result['lat'];
    final lon = result['lon'];
    if (lat is! num || lon is! num) return;

    await _prayerTimesCubit.setManualLocation(
      lat.toDouble(),
      lon.toDouble(),
      cityName: result['name'] as String?,
      countryCode: result['country_code'] as String?,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _prayerTimesCubit.setLocalizations(localizations);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          title: Text(
            AppLocalizations.of(context)!.prayerTimes,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                      builder: (context, state) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(switch (state) {
                            PrayerTimesLoaded() => 'loaded',
                            PrayerTimesInitial() ||
                            PrayerTimesLoading() => 'loading',
                            _ => 'setup',
                          }),
                          child: _buildStateContent(context, state),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, PrayerTimesState state) {
    if (state is PrayerTimesLoaded) {
      return _PrayerLoadedView(
        state: state,
        cubit: _prayerTimesCubit,
        access: _access,
      );
    }
    final locating = state is PrayerTimesLoading;
    if (!_prepared || (locating && !_setupShown)) {
      return const _PrayerStateCard(child: PrayerTimesLoadingWidget());
    }
    _setupShown = true;
    return PrayerSetupChecklist(
      state: state,
      alerts: _alertsStatus,
      alertsNeedSettings: _access.access?.notificationNeedsSettings ?? false,
      reliability: _reliabilityStatus,
      canOpenSettings: !PlatformUtils.isLinux,
      busy: _setupBusy || locating,
      onAllowAlerts: _allowAlerts,
      onOpenAlertSettings: () async {
        await openAppSettings();
      },
      onContinueWithoutAlerts: () => _setFlag(_alertsAnsweredKey),
      onAllowReliability: _allowReliability,
      onUseExactAlarms: _useExactAlarms,
      onSkipReliability: () => _setFlag(_reliabilityAnsweredKey),
      onUseLocation: _prayerTimesCubit.refreshLocationAndPrayerTimes,
      onSearchCity: _searchManually,
      onOpenAppSettings: () async {
        await Geolocator.openAppSettings();
      },
      onOpenLocationSettings: () async {
        await Geolocator.openLocationSettings();
      },
    );
  }
}

class _PrayerLoadedView extends StatefulWidget {
  const _PrayerLoadedView({
    required this.state,
    required this.cubit,
    required this.access,
  });

  final PrayerTimesLoaded state;
  final PrayerTimesCubit cubit;
  final NotificationAccessController access;

  @override
  State<_PrayerLoadedView> createState() => _PrayerLoadedViewState();
}

class _PrayerLoadedViewState extends State<_PrayerLoadedView> {
  StreamSubscription<NextPrayerCountdown>? _countdownSubscription;
  NextPrayerCountdown? _countdown;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _countdownSubscription = widget.cubit.getNextPrayerCountdown().listen((
      countdown,
    ) {
      if (!mounted) return;
      setState(() {
        _countdown = countdown;
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _countdownSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openWorkflowSettings(Set<PrayerWorkflowIssue> issues) async {
    try {
      if (issues.contains(PrayerWorkflowIssue.location) &&
          !await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = widget.cubit;
    final access = widget.access;
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final items = buildPrayerAttentionItems(
      l10n: l10n,
      state: state,
      access: access.access,
      callbacks: PrayerAttentionCallbacks(
        retryWorkflow: cubit.retryPrayerUpdates,
        openWorkflowSettings: _openWorkflowSettings,
        requestBatteryOptimization: () =>
            access.requestBatteryOptimization(context),
        requestExactAlarms: () => access.requestExactAlarms(context),
      ),
    );
    final alertStatus = buildPrayerAlertStatus(
      l10n: l10n,
      state: state,
      access: access.access,
      isIOS: PlatformUtils.isIOS,
      formatDate: (value) =>
          materialL10n.formatMediumDate(value.isUtc ? value.toLocal() : value),
      onEnableNotifications: () => access.requestNotifications(context),
      onRetry: cubit.retryNotificationSchedule,
    );
    final canShare = !state.provisional && cubit.verifiedExportSnapshot != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: PrayerAttentionStrip(
            items: items,
            onChooseCountry: cubit.chooseCountry,
            onDismissCountry: cubit.dismissCountryQuestion,
          ),
        ),
        PrayerHeroCard(
          state: state,
          countdown: _countdown?.prayer == null ? null : _countdown,
          now: _now,
          locationMode: cubit.locationMode,
          timeZoneId: cubit.prayerTimeZoneId,
          onRefreshLocation: cubit.refreshLocationAndPrayerTimes,
        ),
        PrayerTimelineCard(
          state: state,
          now: _now,
          onAdjust: () => showPrayerTimeAdjustmentSheet(context),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: alertStatus == null
              ? const SizedBox(width: double.infinity)
              : PrayerAlertStatusCard(status: alertStatus),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 10),
          child: Text(
            l10n.prayerMoreOptions,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: PrayerPalette.of(context).muted,
            ),
          ),
        ),
        if (canShare)
          _OptionTile(
            icon: Icons.ios_share_rounded,
            title: l10n.prayerCalendarShare,
            onTap: () => showPrayerCalendarShareSheet(context),
          ),
        PrayerTravelSettingsCard(locationMode: cubit.locationMode),
        if (PlatformUtils.isAndroid)
          const PersistentPrayerCountdownControlWidget(),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 4, 12, 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: palette.primary, size: 20),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: palette.muted),
        ),
      ),
    );
  }
}

class _PrayerStateCard extends StatelessWidget {
  const _PrayerStateCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: PrayerPalette.of(context).cardDecoration(),
      child: child,
    );
  }
}
