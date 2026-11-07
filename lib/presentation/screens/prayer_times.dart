import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';
import 'package:huda/core/services/desktop_prayer_settings_navigation.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';
import 'package:huda/presentation/widgets/prayer_times/mac_prayer_menu_card.dart';
import 'package:huda/presentation/widgets/prayer_times/linux_prayer_tray_card.dart';
import 'package:huda/presentation/widgets/prayer_times/windows_prayer_taskbar_card.dart';
import 'package:huda/presentation/widgets/prayer_times/persistent_prayer_countdown_control_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_alerts_ready_card.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_summary_card.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_share_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_iqamah_bottom_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_loading_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_location_sheet.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({
    super.key,
    this.openSettingsOnLoad = false,
    this.debugAccess,
    this.debugClock,
  });

  final bool openSettingsOnLoad;

  /// Notification access without the platform, for the device matrix.
  @visibleForTesting
  final NotificationAccessController Function(
    NotificationsCubit cubit,
    Future<void> Function() onAccessGained,
  )?
  debugAccess;

  /// A fixed "now" for the device matrix, so shots show a normal day.
  @visibleForTesting
  final DateTime Function()? debugClock;

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> with WidgetsBindingObserver {
  late PrayerTimesCubit _prayerTimesCubit;
  late final NotificationAccessController _access;

  bool _prepared = false;

  bool _setupShown = false;

  /// The user's own answer to "Where are you?" is running.
  bool _locating = false;
  bool _choosing = false;

  bool _pendingMenuSettings = false;
  late final bool Function() _openMenuSettingsAction;

  @override
  void initState() {
    super.initState();
    _openMenuSettingsAction = () {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
      if (_prayerTimesCubit.state is PrayerTimesLoaded) {
        showPrayerTimeAdjustmentSheet(context);
      } else {
        _pendingMenuSettings = true;
      }
      return true;
    };
    DesktopPrayerSettingsNavigation.register(_openMenuSettingsAction);
    _pendingMenuSettings = widget.openSettingsOnLoad;
    _prayerTimesCubit = context.read<PrayerTimesCubit>();
    PrayerAlerts.shared.onApplied =
        _prayerTimesCubit.refreshNotificationSchedule;
    final notifications = context.read<NotificationsCubit>();
    _access =
        (widget.debugAccess?.call(
                notifications,
                _prayerTimesCubit.refreshNotificationSchedule,
              ) ??
              NotificationAccessController(
                cubit: notifications,
                onAccessGained: _prayerTimesCubit.refreshNotificationSchedule,
              ))
          ..addListener(_onAccessChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePrayerTimes();
    });
  }

  void _onAccessChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _prayerTimesCubit.loadCachedPrayerTimes();
      final current = _prayerTimesCubit.state;
      if (current is PrayerTimesLoaded) {
        unawaited(_prayerTimesCubit.loadPrayerTimes());
      } else if (current is PrayerTimesNeedsPlace &&
          (current.problem == PrayerLocationProblem.denied ||
              (current.problem?.needsSettings ?? false))) {
        unawaited(_retryLocationIfAccessRestored());
      }
    }
  }

  /// Back from Settings with location allowed: the times load by
  /// themselves (the user already chose "Use my location").
  Future<void> _retryLocationIfAccessRestored() async {
    if (!await canLocateWithoutAsking() || !mounted) return;
    await _useLocation();
  }

  @override
  void dispose() {
    DesktopPrayerSettingsNavigation.unregister(_openMenuSettingsAction);
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
      return;
    }
    // A problem the user has seen stays until they act; nothing asks again.
    if (state is PrayerTimesLoading ||
        (state is PrayerTimesNeedsPlace && state.problem != null)) {
      return;
    }
    // Times first: with location already allowed this finds the place by
    // itself; otherwise it waits for "Where are you?" (no prompt).
    await _prayerTimesCubit.loadPrayerTimes();
  }

  Future<void> _useLocation() async {
    if (_locating || _choosing) return;
    setState(() => _locating = true);
    try {
      await _prayerTimesCubit.refreshLocationAndPrayerTimes();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseCity() async {
    if (_locating || _choosing) return;
    try {
      await pickPrayerCity(
        context,
        _prayerTimesCubit,
        onPicked: () {
          if (mounted) setState(() => _choosing = true);
        },
      );
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
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
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) => HudaScaffold(
        title: l10n.prayerTimes,
        body: HudaRevealScope(
          child: HudaStateSwitcher(
            stateKey: switch (state) {
              PrayerTimesLoaded() => 'loaded',
              _ when _isLoading(state) => 'loading',
              _ => 'setup',
            },
            child: _buildPrayerContent(context, state),
          ),
        ),
      ),
    );
  }

  bool _isLoading(PrayerTimesState state) =>
      !_prepared || (state is PrayerTimesLoading && !_setupShown);

  Widget _buildPrayerContent(BuildContext context, PrayerTimesState state) {
    if (state is PrayerTimesLoaded) {
      if (_pendingMenuSettings) {
        _pendingMenuSettings = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showPrayerTimeAdjustmentSheet(context);
        });
      }
      return _PrayerLoadedView(
        clock: widget.debugClock ?? DateTime.now,
        state: state,
        cubit: _prayerTimesCubit,
        access: _access,
      );
    }
    if (_isLoading(state)) return const PrayerTimesLoadingWidget();
    _setupShown = true;
    final cityOnly = !deviceLocationSupported;
    return _PrayerSetupView(
      cityOnly: cityOnly,
      step: PrayerPlaceStep(
        problem: prayerLocationProblemIn(state),
        canUseDeviceLocation: !cityOnly,
        canOpenSettings: !PlatformUtils.isLinux,
        locating:
            _locating || (state is PrayerTimesLoading && !_choosing),
        choosing: _choosing,
        onUseLocation: _useLocation,
        onChooseCity: _chooseCity,
        onOpenAppSettings: () async {
          await Geolocator.openAppSettings();
        },
        onOpenLocationSettings: () async {
          await Geolocator.openLocationSettings();
        },
      ),
    );
  }
}

class _PrayerLoadedView extends StatefulWidget {
  const _PrayerLoadedView({
    required this.clock,
    required this.state,
    required this.cubit,
    required this.access,
  });

  final PrayerTimesLoaded state;
  final PrayerTimesCubit cubit;
  final NotificationAccessController access;
  final DateTime Function() clock;

  @override
  State<_PrayerLoadedView> createState() => _PrayerLoadedViewState();
}

class _PrayerLoadedViewState extends State<_PrayerLoadedView> {
  StreamSubscription<NextPrayerCountdown>? _countdownSubscription;
  NextPrayerCountdown? _countdown;
  late DateTime _now = widget.clock();

  @override
  void initState() {
    super.initState();
    _countdownSubscription = widget.cubit.getNextPrayerCountdown().listen((
      countdown,
    ) {
      if (!mounted) return;
      // The countdown ticks by itself (`PrayerCountdown`); the page only
      // changes when the prayer does, or with the minute (the sun, the
      // rows, "started N min ago").
      final now = widget.clock();
      final previous = _countdown;
      final changed =
          previous == null ||
          previous.prayer != countdown.prayer ||
          previous.isPastPrayer != countdown.isPastPrayer ||
          previous.instant != countdown.instant ||
          previous.secondsPassed ~/ 60 != countdown.secondsPassed ~/ 60 ||
          now.minute != _now.minute ||
          now.hour != _now.hour;
      if (!changed) return;
      setState(() {
        _countdown = countdown;
        _now = now;
      });
    });
  }

  @override
  void dispose() {
    _countdownSubscription?.cancel();
    super.dispose();
  }

  void _openAlerts([String? prayer]) => showPrayerAlertSheet(
    context,
    prayer: prayer,
    nextPrayer: _countdown?.prayer?.name,
  );

  // The page's moment, for every sky on it (the hero, a problem's lamp).
  @override
  Widget build(BuildContext context) {
    final zone = widget.cubit.prayerTimeZoneId;
    DateTime wall(DateTime instant) => zone == null
        ? instant.toLocal()
        : PrayerTimeZoneService.wallClockAtInstant(instant, zone);
    return PrayerSkyScope(
      times: PrayerSkyTimes.of(widget.state, wall),
      hour: prayerSkyHour(wall(_now.toUtc())),
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final state = widget.state;
    final cubit = widget.cubit;
    final access = widget.access;
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final items = buildPrayerAttentionItems(
      l10n: l10n,
      state: state,
      callbacks: PrayerAttentionCallbacks(
        retryWorkflow: cubit.retryPrayerUpdates,
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
      // The ready card asks for it, with the explanation; don't repeat it.
      notificationsAskedElsewhere: PrayerAlertsReadyCard.showing(
        cubit.cacheHelper,
        buildPrayerReadinessItems(
          l10n: l10n,
          inputs: PrayerReadinessInputs(access: access.access),
          actions: _noReadinessActions,
        ),
        PrayerReadinessKind.notifications,
      ),
      onRetry: cubit.retryNotificationSchedule,
      onAllowExactAlarms: () => access.requestExactAlarms(context),
    );
    final canShare = !state.provisional && cubit.verifiedExportSnapshot != null;
    final space = context.tokens.space;

    // Errors lead the page; information (verification, the widget, the
    // country question) waits under the sky, so the times come first.
    final errorFirst = items.any(
      (item) => item.tone == PrayerAttentionTone.error,
    );
    final attention = AnimatedSize(
      duration: context.tokens.motion.of(context, context.tokens.motion.medium),
      curve: context.tokens.motion.standard,
      alignment: Alignment.topCenter,
      child: PrayerAttentionStrip(
        items: items,
        onChooseCountry: cubit.chooseCountry,
        onDismissCountry: cubit.dismissCountryQuestion,
      ),
    );
    final sky = PrayerSkyCard(
      state: state,
      countdown: _countdown?.prayer == null ? null : _countdown,
      now: _now,
      locationMode: cubit.locationMode,
      timeZoneId: cubit.prayerTimeZoneId,
      clock: widget.clock,
      onOpenLocation: () => showPrayerLocationSheet(context),
    );
    final times = ListenableBuilder(
      listenable: PrayerAlerts.shared,
      builder: (context, _) => PrayerTimelineCard(
        state: state,
        now: _now,
        alerts: PrayerAlerts.shared.settings,
        alertsBlocked: access.access?.needsNotification ?? false,
        onOpenAlerts: _openAlerts,
      ),
    );
    final ready = state.provisional
        ? null
        : PrayerAlertsReadyCard(access: access, cache: cubit.cacheHelper);
    final alerts = PrayerAlertSummaryCard(
      status: alertStatus,
      onOpen: ([prayer]) => _openAlerts(prayer),
    );
    // How the times are calculated: a card like the alerts' (owner round
    // 2), not an app bar icon.
    final settings = PrayerTimeSettingsCard(
      cubit: cubit,
      onOpen: () => showPrayerTimeAdjustmentSheet(context),
    );
    final more = <Widget>[
      HudaSection(
        title: l10n.prayerMoreOptions,
        children: [
          HudaSettingsRow(
            key: const ValueKey('prayer-iqamah'),
            icon: Icons.timer_outlined,
            title: l10n.prayerIqamahTitle,
            subtitle: iqamahSummary(cubit.iqamahSettings, l10n),
            trailing: const _Chevron(),
            onTap: () => showPrayerIqamahSheet(context),
          ),
          if (canShare)
            HudaSettingsRow(
              key: const ValueKey('prayer-share-calendar'),
              icon: Icons.ios_share_rounded,
              title: l10n.prayerCalendarShare,
              trailing: const _Chevron(),
              onTap: () => showPrayerCalendarShareSheet(context),
            ),
        ],
      ),
      if (PlatformUtils.isMacOS ||
          PlatformUtils.isLinux ||
          PlatformUtils.isWindows ||
          PlatformUtils.isAndroid) ...[
        HudaSectionHeader(l10n.prayerAlertOnThisDevice),
        if (PlatformUtils.isMacOS) const MacPrayerMenuCard(),
        if (PlatformUtils.isLinux) const LinuxPrayerTrayCard(),
        if (PlatformUtils.isWindows) const WindowsPrayerTaskbarCard(),
        if (PlatformUtils.isAndroid)
          const PersistentPrayerCountdownControlWidget(),
      ],
    ];

    Widget column(List<Widget?> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.nonNulls.indexed) ...[
          if (i > 0 && child is! PrayerAttentionStrip)
            SizedBox(height: space.md),
          HudaReveal(index: i, child: child),
        ],
      ],
    );
    Widget scroll(Widget child, {double maxWidth = ReadableWidth.measure}) =>
        Builder(
          builder: (context) {
            final gutter = space.gutter(MediaQuery.sizeOf(context).width);
            return SingleChildScrollView(
              padding: context.scrollPadding(
                EdgeInsets.fromLTRB(gutter, space.xs, gutter, space.xxl),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            );
          },
        );

    final sideItems = <Widget?>[alerts, settings, ...more];
    final day = errorFirst ? [attention, sky] : [sky, attention];
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);

    // Tabletop: the sky above the band, everything else below it.
    if (TabletopSplit.applies(context)) {
      return TabletopSplit(
        top: Padding(
          padding: EdgeInsets.all(space.gutter(width)),
          child: Center(child: sky),
        ),
        bottom: scroll(column([attention, times, ready, ...sideItems])),
      );
    }

    // Wide: the day beside the alerts and options.
    if (AdaptivePanes.showsTwoPanes(width, fold)) {
      return AdaptivePanes(
        primaryFraction: 0.62,
        minPrimaryWidth: 420,
        maxPrimaryWidth: 1100,
        primary: scroll(column([...day, times, ready]), maxWidth: 960),
        secondary: scroll(column(sideItems), maxWidth: 520),
      );
    }

    // Medium: one column for the day, then two for the rest.
    if (width >= 600) {
      return scroll(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            column([...day, times]),
            SizedBox(height: space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column([ready, alerts, settings])),
                SizedBox(width: space.md),
                Expanded(child: column(more)),
              ],
            ),
          ],
        ),
        maxWidth: 840,
      );
    }

    // Phones: how the times are calculated right under them.
    return scroll(
      column([...day, times, settings, ready, alerts, ...more]),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// Setup: an empty sky (no times yet) over the steps; side by side on wide
/// windows.
class _PrayerSetupView extends StatelessWidget {
  const _PrayerSetupView({required this.step, required this.cityOnly});

  final PrayerPlaceStep step;
  final bool cityOnly;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = space.gutter(width);
    final padding = context.scrollPadding(
      EdgeInsets.fromLTRB(gutter, space.xs, gutter, space.xxl),
    );

    // Tabletop: the empty sky above the band, the steps below it.
    if (TabletopSplit.applies(context)) {
      return TabletopSplit(
        top: Padding(
          padding: EdgeInsets.all(gutter),
          child: Center(child: PrayerSetupHeader(cityOnly: cityOnly)),
        ),
        bottom: SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: step,
            ),
          ),
        ),
      );
    }

    // Wide: one composition, the sky beside the steps, centered and
    // capped, so a large window isn't two small islands.
    // A vertical fold: the sky on one side, the steps on the other, split
    // at the fold (nothing on a half-open band).
    final fold = FoldInfo.of(context);
    if (fold.splitsHorizontally && AdaptivePanes.showsTwoPanes(width, fold)) {
      return AdaptivePanes(
        primary: SingleChildScrollView(
          padding: padding,
          child: PrayerSetupHeader(skyHeight: 140, cityOnly: cityOnly),
        ),
        secondary: SingleChildScrollView(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: step,
            ),
          ),
        ),
      );
    }

    final short = MediaQuery.sizeOf(context).height < 480;
    if (width >= 840 || (short && width >= 600)) {
      return LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            // Centered in the window when it fits, scrolling when not.
            constraints: BoxConstraints(
              minHeight: math.max(0, viewport.maxHeight - padding.vertical),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: PrayerSetupHeader(
                        skyHeight: short ? 56 : 140,
                        cityOnly: cityOnly,
                      ),
                    ),
                    SizedBox(width: space.xl),
                    Expanded(flex: 6, child: step),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrayerSetupHeader(cityOnly: cityOnly),
              SizedBox(height: space.md),
              step,
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _noAction() async {}

/// Only used to ask whether a readiness step is showing.
const _noReadinessActions = PrayerReadinessActions(
  requestNotifications: _noAction,
  openNotificationSettings: _noAction,
  openPrayerChannelSettings: _noAction,
  requestExactAlarms: _noAction,
  requestBatteryOptimization: _noAction,
  requestAlarms: _noAction,
  openAppleSettings: _noAction,
  openMacNotificationSettings: _noAction,
  openMacLoginSettings: _noAction,
  startWithWindows: _noAction,
  openWindowsStartupSettings: _noAction,
  startLinuxAtLogin: _noAction,
);
