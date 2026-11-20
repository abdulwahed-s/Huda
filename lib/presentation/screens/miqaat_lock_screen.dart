import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_platform.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_gate.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_identity.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_sections.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_sheets.dart';

class MiqaatLockScreen extends StatefulWidget {
  const MiqaatLockScreen({super.key});

  @override
  State<MiqaatLockScreen> createState() => _MiqaatLockScreenState();
}

class _MiqaatLockScreenState extends State<MiqaatLockScreen>
    with WidgetsBindingObserver {
  late final MiqaatLockCubit _cubit = context.read<MiqaatLockCubit>();
  bool _retrying = false;
  ({int apps, int categories})? _iosCount;

  bool get _ios => MiqaatLockPlatform.current == MiqaatLockPlatform.ios;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.loadSettings();
    _cubit.refreshPermissions();
    _readIOSCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cubit.refreshPermissions();
  }

  Future<void> _readIOSCount() async {
    if (!_ios) return;
    final count = await _cubit.iosSelectionCount();
    if (mounted) setState(() => _iosCount = count);
  }

  void _retry() {
    setState(() => _retrying = true);
    _cubit.loadSettings();
  }

  void _toggle(bool on) {
    HudaHaptics.selection(context);
    _cubit.toggleEnabled(on);
  }

  Future<void> _addApps(MiqaatLockLoaded state) async {
    final l10n = AppLocalizations.of(context)!;
    if (_ios) {
      try {
        final chosen = await _cubit.chooseIOSApps();
        if (!mounted) return;
        if (chosen) {
          showHudaToast(context, message: l10n.iosAppsSelectedSuccessfully);
        }
        await _readIOSCount();
      } on PlatformException catch (e) {
        if (!mounted) return;
        showHudaToast(
          context,
          kind: HudaToastKind.failed,
          message: l10n.iosAppSelectionError(e.message ?? ''),
        );
      }
      return;
    }
    final apps = await showMiqaatAppsSheet(
      context,
      cubit: _cubit,
      current: state.settings.lockedApps,
    );
    if (apps != null) _cubit.setLockedApps(apps);
  }

  void _removeApp(MiqaatLockLoaded state, LockedApp app) {
    final l10n = AppLocalizations.of(context)!;
    final before = state.settings.lockedApps;
    HudaHaptics.light(context);
    _cubit.removeLockedApp(app.packageId);
    showHudaToast(
      context,
      message: l10n.miqaatRemoved(app.appName),
      actionLabel: l10n.undo,
      onAction: () => _cubit.setLockedApps(before),
    );
  }

  Future<void> _editWindow([TimeSlot? slot]) async {
    final result = await showMiqaatWindowSheet(context, existing: slot);
    if (result == null) return;
    slot == null ? _cubit.addTimeSlot(result) : _cubit.updateTimeSlot(result);
  }

  void _removeWindow(TimeSlot slot) {
    final l10n = AppLocalizations.of(context)!;
    HudaHaptics.light(context);
    _cubit.removeTimeSlot(slot.id);
    showHudaToast(
      context,
      message: l10n.miqaatWindowRemoved,
      actionLabel: l10n.undo,
      onAction: () => _cubit.addTimeSlot(slot),
    );
  }

  void _goal(int minutes) {
    HudaHaptics.selection(context);
    _cubit.setGoalDuration(minutes);
  }

  Future<void> _customGoal(int current) async {
    final minutes = await showMiqaatGoalSheet(context, current: current);
    if (minutes != null) _cubit.setGoalDuration(minutes);
  }

  Future<void> _accessibility() async {
    final agreed = await showMiqaatAccessibilitySheet(context);
    if (agreed == true) _cubit.openAccessibilitySettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<MiqaatLockCubit>().state;
    final loaded = state is MiqaatLockLoaded ? state : null;
    final size = MediaQuery.sizeOf(context);
    final short = size.height < 480;
    const twoPaneMin = 700.0;
    final fold = FoldInfo.of(context);
    final wide =
        !short &&
        AdaptivePanes.showsTwoPanes(
          size.width,
          fold,
          twoPaneMinWidth: twoPaneMin,
        );

    Widget frame(Widget child) =>
        BlocListener<MiqaatLockCubit, MiqaatLockState>(
          listener: (context, state) {
            if (_retrying && state is! MiqaatLockLoading) {
              setState(() => _retrying = false);
            }
          },
          child: HudaRevealScope(child: child),
        );

    if (loaded != null && !wide && TabletopSplit.applies(context)) {
      return frame(
        TabletopSplit(
          top: HudaScaffold(
            title: l10n.miqaatLock,
            body: _pane((context) => _gate(loaded)),
          ),
          bottom: Scaffold(
            backgroundColor: Colors.transparent,
            body: _pane((context) => _setup(loaded, goal: true)),
          ),
        ),
      );
    }

    final failed =
        state is MiqaatLockError || (_retrying && state is! MiqaatLockLoaded);
    final Widget body = switch (state) {
      _ when failed => HudaErrorState(
        identity: miqaatLockIdentity,
        message: l10n.unexpectedError,
        onRetry: _retry,
        retrying: _retrying,
      ),
      MiqaatLockLoaded() when wide => _capped(
        fold,
        size.width,
        AdaptivePanes(
          twoPaneMinWidth: twoPaneMin,
          primary: _pane(
            (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HudaReveal(child: _gate(state, large: true)),
                SizedBox(height: context.tokens.space.xl),
                HudaReveal(index: 1, child: _goalSection(state)),
              ],
            ),
          ),
          secondary: _pane(
            (context) => _setup(state, goal: false, revealFrom: 2),
            key: const PageStorageKey('miqaat-setup'),
          ),
        ),
      ),
      MiqaatLockLoaded() => _pane(
        (context) => ReadableWidth(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HudaReveal(child: _gate(state)),
              SizedBox(height: context.tokens.space.xl),
              _setup(state, goal: true, revealFrom: 1),
            ],
          ),
        ),
      ),
      _ => _pane(
        (context) => const ReadableWidth(maxWidth: 720, child: _Skeleton()),
      ),
    };

    return frame(
      HudaScaffold(
        title: l10n.miqaatLock,
        body: HudaStateSwitcher(
          stateKey: failed
              ? 'error'
              : state is MiqaatLockLoaded
              ? 'loaded'
              : 'loading',
          child: body,
        ),
      ),
    );
  }

  Widget _capped(FoldInfo fold, double width, Widget panes) {
    if (width <= 1200 || fold.posture != FoldPosture.none) return panes;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: panes,
      ),
    );
  }

  Widget _pane(WidgetBuilder content, {Key? key}) => Builder(
    builder: (context) {
      final space = context.tokens.space;
      final gutter = space.gutter(MediaQuery.sizeOf(context).width);
      return SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          key: key,
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
          ),
          child: content(context),
        ),
      );
    },
  );

  Widget _gate(MiqaatLockLoaded state, {bool large = false}) => MiqaatLockGate(
    gate: MiqaatGate.of(state),
    enabled: state.settings.isEnabled,
    large: large,
    onToggle: state.settings.isEnabled || !miqaatNeedsAccess(state.permissions)
        ? _toggle
        : null,
  );

  Widget _goalSection(MiqaatLockLoaded state) => MiqaatGoalSection(
    minutes: state.settings.goalDurationMinutes,
    onSelect: _goal,
    onCustom: () => _customGoal(state.settings.goalDurationMinutes),
  );

  Widget _setup(
    MiqaatLockLoaded state, {
    required bool goal,
    int revealFrom = 0,
  }) => Builder(
    builder: (context) {
      final gap = context.tokens.space.xl;
      var i = revealFrom;
      final needs = miqaatNeedsAccess(state.permissions);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needs) ...[
            HudaReveal(
              index: i++,
              child: MiqaatAccessCard(
                permissions: state.permissions,
                onAccessibility: _accessibility,
                onOverlay: _cubit.requestOverlayPermission,
                onScreenTime: _cubit.requestScreenTimeAuthorization,
                onCheck: _cubit.refreshPermissions,
              ),
            ),
            SizedBox(height: gap),
          ],
          HudaReveal(
            index: i++,
            child: MiqaatAppsSection(
              apps: state.settings.lockedApps,
              iosCount: _ios ? (_iosCount ?? (apps: 0, categories: 0)) : null,
              onAdd: () => _addApps(state),
              onRemove: (app) => _removeApp(state, app),
            ),
          ),
          SizedBox(height: gap),
          HudaReveal(
            index: i++,
            child: MiqaatWindowsSection(
              slots: state.settings.timeSlots,
              completed: state.completedTimeSlotIds,
              onAdd: _editWindow,
              onEdit: _editWindow,
              onRemove: _removeWindow,
            ),
          ),
          if (goal) ...[
            SizedBox(height: gap),
            HudaReveal(index: i++, child: _goalSection(state)),
          ],
        ],
      );
    },
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HudaSkeletonBlock(height: 176),
          SizedBox(height: space.xl),
          const HudaSkeletonLines(lines: 1),
          SizedBox(height: space.sm),
          const HudaSkeletonBlock(height: 160),
          SizedBox(height: space.xl),
          const HudaSkeletonLines(lines: 1),
          SizedBox(height: space.sm),
          const HudaSkeletonBlock(height: 120),
        ],
      ),
    );
  }
}
