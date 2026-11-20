import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/services/get_current_location.dart';
import 'package:huda/core/services/prayer_location_monitor.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/services/location_service.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/notifications/permission_explainer_sheet.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showPrayerLocationSheet(
  BuildContext context, {
  @visibleForTesting PrayerLocationMonitor? monitor,
  @visibleForTesting bool? deviceLocation,
  @visibleForTesting bool? travelUpdates,
  @visibleForTesting LocationService? cityService,
}) {
  final cubit = context.read<PrayerTimesCubit>();
  return showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.prayerLocationTitle,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: PrayerLocationSheet(
        monitor:
            monitor ??
            (getIt.isRegistered<PrayerLocationMonitor>()
                ? getIt<PrayerLocationMonitor>()
                : null),
        deviceLocation: deviceLocation ?? deviceLocationSupported,
        travelUpdates:
            travelUpdates ?? PrayerLocationMonitor.supportsTravelUpdates,
        cityService: cityService,
      ),
    ),
  );
}

enum _Work {
  idle,

  locating,

  choosing,

  failed,

  retrying,

  updating,
}

class PrayerLocationSheet extends StatefulWidget {
  const PrayerLocationSheet({
    super.key,
    required this.monitor,
    required this.deviceLocation,
    required this.travelUpdates,
    this.cityService,
  });

  final PrayerLocationMonitor? monitor;

  final bool deviceLocation;

  final bool travelUpdates;

  final LocationService? cityService;

  @override
  State<PrayerLocationSheet> createState() => _PrayerLocationSheetState();
}

class _PrayerLocationSheetState extends State<PrayerLocationSheet>
    with WidgetsBindingObserver {
  _Work _work = _Work.idle;
  PrayerLocationProblem? _problem;
  PrayerLocationMonitoringStatus? _travel;
  bool _travelBusy = false;

  PrayerTimesCubit get _cubit => context.read<PrayerTimesCubit>();
  bool get _busy =>
      _work == _Work.locating ||
      _work == _Work.choosing ||
      _work == _Work.retrying ||
      _work == _Work.updating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reloadTravel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _reloadTravel();
    if (_work == _Work.failed && (_problem?.needsSettings ?? false)) {
      canLocateWithoutAsking().then((ok) {
        if (ok && mounted && _work == _Work.failed) {
          _useDeviceLocation(_Work.updating);
        }
      });
    }
  }

  Future<void> _reloadTravel() async {
    final monitor = widget.monitor;
    if (monitor == null || !widget.travelUpdates) return;
    final status = await monitor.currentStatus(
      mode: PrayerLocationMode.automatic,
    );
    if (mounted) setState(() => _travel = status);
  }

  Future<void> _useDeviceLocation(_Work work) async {
    if (_busy) return;
    setState(() => _work = work);
    final problem = await _cubit.refreshLocationAndPrayerTimes();
    if (!mounted) return;
    setState(() {
      _problem = problem;
      _work = problem == null ? _Work.idle : _Work.failed;
    });
    if (problem == null) await _reloadTravel();
  }

  Future<void> _chooseCity() async {
    if (_busy) return;
    final previous = _work;
    setState(() => _work = _Work.choosing);
    final pick = await pickPrayerCity(
      context,
      _cubit,
      service: widget.cityService,
    );
    if (!mounted) return;
    setState(() {
      if (!pick.picked) {
        _work = previous == _Work.failed ? _Work.failed : _Work.idle;
        return;
      }
      _problem = pick.problem;
      _work = pick.problem == null ? _Work.idle : _Work.failed;
    });
  }

  Future<void> _fix() async {
    final problem = _problem;
    final canOpenSettings = !PlatformUtils.isLinux;
    if (problem == PrayerLocationProblem.blocked && canOpenSettings) {
      await Geolocator.openAppSettings();
    } else if (problem == PrayerLocationProblem.servicesOff &&
        canOpenSettings) {
      await Geolocator.openLocationSettings();
    } else {
      await _useDeviceLocation(_Work.retrying);
    }
  }

  void _selectMode(PrayerLocationMode mode, PrayerLocationMode current) {
    if (mode == current || _busy) return;
    HudaHaptics.selection(context);
    if (mode == PrayerLocationMode.automatic) {
      _useDeviceLocation(_Work.locating);
    } else {
      _chooseCity();
    }
  }


  Future<void> _setTravel(bool enabled) async {
    final monitor = widget.monitor;
    if (monitor == null) return;
    HudaHaptics.selection(context);
    if (enabled && !await _explainBackgroundLocation()) return;
    if (!mounted) return;
    setState(() => _travelBusy = true);
    try {
      await monitor.setEnabled(enabled);
      await _reloadTravel();
      if (enabled &&
          PlatformUtils.isAndroid &&
          _travel?.state == PrayerBackgroundTravelState.foregroundOnly) {
        await _showAndroidBackgroundHelp();
      }
    } finally {
      if (mounted) setState(() => _travelBusy = false);
    }
  }

  Future<bool> _explainBackgroundLocation() async {
    if (await Permission.locationAlways.isGranted) return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    return showPermissionExplainer(
      context,
      icon: Icons.travel_explore_rounded,
      title: l10n.travelExplainerTitle,
      message: l10n.travelExplainerMessage,
    );
  }

  Future<void> _fixTravel(PrayerBackgroundTravelState state) async {
    final monitor = widget.monitor;
    if (monitor == null) return;
    switch (state) {
      case PrayerBackgroundTravelState.unavailable:
        if (!await Geolocator.openLocationSettings()) {
          await monitor.openAppSettings();
        }
      case PrayerBackgroundTravelState.foregroundOnly
          when PlatformUtils.isAndroid:
        await _showAndroidBackgroundHelp();
      case PrayerBackgroundTravelState.permissionRequired:
        setState(() => _travelBusy = true);
        try {
          await monitor.setEnabled(true);
          await _reloadTravel();
        } finally {
          if (mounted) setState(() => _travelBusy = false);
        }
      default:
        await monitor.openAppSettings();
    }
  }

  Future<void> _showAndroidBackgroundHelp() async {
    final monitor = widget.monitor;
    if (monitor == null) return;
    final systemLabel = await monitor.backgroundPermissionOptionLabel();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
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
    if (open == true) await monitor.openAppSettings();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final state = context.watch<PrayerTimesCubit>().state;
    final mode = _cubit.locationMode;
    final automatic =
        widget.deviceLocation && mode == PrayerLocationMode.automatic;
    final place = state is PrayerTimesLoaded
        ? prayerPlaceName(l10n, state)
        : null;
    final problem = _problem;
    final fix =
        _work == _Work.failed && problem != null && widget.deviceLocation
        ? prayerLocationFixAction(
            l10n,
            problem,
            canOpenSettings: !PlatformUtils.isLinux,
            onUseLocation: _fix,
            onOpenAppSettings: _fix,
            onOpenLocationSettings: _fix,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlaceCard(place: place, automatic: automatic),
        if (widget.deviceLocation) ...[
          SizedBox(height: space.md),
          SegmentedButton<PrayerLocationMode>(
            key: const ValueKey('prayer-location-mode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: PrayerLocationMode.automatic,
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: Text(l10n.prayerLocationAutomatic),
              ),
              ButtonSegment(
                value: PrayerLocationMode.manual,
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(l10n.prayerLocationChosen),
              ),
            ],
            selected: {
              automatic
                  ? PrayerLocationMode.automatic
                  : PrayerLocationMode.manual,
            },
            onSelectionChanged: _busy
                ? null
                : (value) => _selectMode(value.first, mode),
          ),
        ],
        AnimatedSize(
          duration: tokens.motion.of(context, tokens.motion.medium),
          curve: tokens.motion.standard,
          alignment: Alignment.topCenter,
          child: _status(l10n),
        ),
        SizedBox(height: space.md),
        if (fix != null) ...[
          _ActionButton(
            key: const ValueKey('prayer-location-fix'),
            icon: fix.icon,
            label: fix.label,
            running: false,
            onPressed: fix.onPressed,
          ),
          if (!automatic)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _chooseCity,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(l10n.prayerLocationChangeCity),
              ),
            ),
        ] else if (automatic)
          _ActionButton(
            key: const ValueKey('prayer-location-update'),
            icon: Icons.my_location_rounded,
            label: _work == _Work.locating
                ? l10n.prayerLocationUpdating
                : l10n.prayerLocationUpdateNow,
            running: _work == _Work.locating,
            onPressed: _busy ? null : () => _useDeviceLocation(_Work.locating),
          )
        else
          _ActionButton(
            key: const ValueKey('prayer-location-change-city'),
            icon: Icons.search_rounded,
            label: place == null
                ? l10n.prayerChooseCity
                : l10n.prayerLocationChangeCity,
            running: _work == _Work.choosing,
            onPressed: _busy ? null : _chooseCity,
          ),
        if (automatic && widget.travelUpdates && widget.monitor != null) ...[
          SizedBox(height: space.md),
          _TravelCard(
            status: _travel,
            busy: _travelBusy,
            onChanged: _setTravel,
            onFix: _fixTravel,
          ),
        ],
      ],
    );
  }

  Widget _status(AppLocalizations l10n) {
    final space = context.tokens.space;
    final problem = _problem;
    final Widget? child = switch (_work) {
      _Work.updating => const PrayerStatusLine(status: HudaStatus.updating),
      _Work.retrying => const PrayerStatusLine(status: HudaStatus.retrying),
      _Work.failed when problem != null => PrayerStatusLine(
        key: ValueKey('prayer-location-problem-${problem.name}'),
        status: HudaStatus.failed,
        message: prayerLocationProblemText(l10n, problem),
      ),
      _ => null,
    };
    if (child == null) return const SizedBox(width: double.infinity);
    return Padding(
      key: ValueKey('prayer-location-status-${_work.name}'),
      padding: EdgeInsets.only(top: space.md),
      child: child,
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.automatic});

  final String? place;
  final bool automatic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final space = context.tokens.space;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(space.md),
        child: Row(
          children: [
            HudaIconMark(
              automatic ? Icons.near_me_rounded : Icons.location_on_rounded,
            ),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place ?? l10n.prayerWhereTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    automatic
                        ? l10n.prayerLocationAutomaticHint
                        : l10n.prayerLocationChosenHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.muted,
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
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.running,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool running;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onPressed,
    icon: running ? const HudaLampSpinner(size: 18) : Icon(icon, size: 20),
    label: Text(label, textAlign: TextAlign.center),
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
  );
}

class _TravelCard extends StatelessWidget {
  const _TravelCard({
    required this.status,
    required this.busy,
    required this.onChanged,
    required this.onFix,
  });

  final PrayerLocationMonitoringStatus? status;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final Future<void> Function(PrayerBackgroundTravelState state) onFix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final space = context.tokens.space;
    final status = this.status;
    final on = status?.preferenceEnabled ?? false;
    final state = status?.state;
    final ({String text, String action})? missing = switch (state) {
      PrayerBackgroundTravelState.foregroundOnly => (
        text: l10n.prayerLocationTravelForegroundOnly,
        action: l10n.travelAllowAllTheTime,
      ),
      PrayerBackgroundTravelState.permissionRequired => (
        text: l10n.prayerLocationTravelNeedsPermission,
        action: l10n.travelAllowLocation,
      ),
      PrayerBackgroundTravelState.unavailable => (
        text: l10n.prayerProblemServicesOff,
        action: l10n.travelTurnOnLocation,
      ),
      _ => null,
    };
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: SwitchListTile(
              key: const ValueKey('prayer-location-travel'),
              secondary: const HudaIconMark(Icons.travel_explore_rounded),
              title: Text(l10n.prayerLocationTravel),
              subtitle: Text(
                l10n.prayerLocationTravelHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.muted,
                ),
              ),
              value: on,
              onChanged: busy || status == null ? null : onChanged,
            ),
          ),
          if (on && missing != null)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.md,
                0,
                space.sm,
                space.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrayerSetupWarningNote(
                    title: l10n.travelPermissionRequired,
                    text: missing.text,
                    icon: Icons.info_outline_rounded,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      key: const ValueKey('prayer-location-travel-fix'),
                      onPressed: busy ? null : () => onFix(state!),
                      child: Text(missing.action),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
