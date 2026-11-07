import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/ramadan/ramadan_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';
import 'package:huda/presentation/widgets/ramadan/qadhaa_tracker_widget.dart';
import 'package:huda/presentation/widgets/ramadan/ramadan_header_widget.dart';
import 'package:huda/presentation/widgets/ramadan/ramadan_loading_widget.dart';

/// Ramadan: the plate (the night's moon, the day or the days until it,
/// today's fast) and the 30 nights to mark fasted or missed. One column
/// on phones; the nights beside the plate from 840 and on open folds; the
/// plate above a tabletop fold.
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key, this.debugClock});

  /// The device matrix's fixed "now".
  final DateTime Function()? debugClock;

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  bool _retrying = false;
  RamadanError? _failure;

  @override
  void initState() {
    super.initState();
    context.read<RamadanCubit>().loadRamadanData();
  }

  void _retry() {
    setState(() => _retrying = true);
    context.read<RamadanCubit>().loadRamadanData();
  }

  Widget _scroll(List<Widget> children, {double maxWidth = 720}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final space = context.tokens.space;
        final width = constraints.maxWidth;
        final side = math.max(space.gutter(width), (width - maxWidth) / 2);
        return ListView(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(side, space.sm, side, space.xxl),
          ),
          children: children,
        );
      },
    );
  }

  Widget _plate(RamadanState state) => HudaStateSwitcher(
    stateKey: state is RamadanLoaded,
    child: state is RamadanLoaded
        ? HudaReveal(
            child: RamadanPlate(
              isRamadan: state.isRamadan,
              currentDay: state.currentDay,
              daysUntilRamadan: state.daysUntilRamadan,
              hijriYear: state.hijriYear,
              fajrTime: state.fajrTime,
              maghribTime: state.maghribTime,
              clock: widget.debugClock,
            ),
          )
        : const RamadanPlateSkeleton(),
  );

  Widget _nights(RamadanState state) => HudaStateSwitcher(
    stateKey: state is RamadanLoaded,
    child: state is RamadanLoaded
        ? HudaReveal(
            index: 1,
            child: state.ramadanDays.isEmpty
                ? const SizedBox.shrink()
                : RamadanNightsCard(
                    ramadanDays: state.ramadanDays,
                    fastedCount: state.fastedCount,
                    missedCount: state.missedCount,
                    currentDay: state.currentDay,
                    isRamadan: state.isRamadan,
                    hijriYear: state.hijriYear,
                    clock: widget.debugClock,
                    onSetStatus: (day, status) =>
                        context.read<RamadanCubit>().setDayStatus(day, status),
                    nightsOpen: state.nightsOpen,
                    onNightsOpen: context.read<RamadanCubit>().setNightsOpen,
                  ),
          )
        : const RamadanNightsSkeleton(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);

    return HudaRevealScope(
      child: BlocConsumer<RamadanCubit, RamadanState>(
        listener: (context, state) {
          if (state is! RamadanLoading && _retrying) {
            setState(() => _retrying = false);
          }
        },
        builder: (context, state) {
          if (state is RamadanError) _failure = state;
          if (state is RamadanLoaded) _failure = null;
          final failure = _failure;
          // After Retry, the failure stays with "Retrying…" until it ends.
          if (failure != null && (state is RamadanError || _retrying)) {
            return HudaScaffold(
              title: l10n.ramadan,
              body: HudaErrorState(
                identity: calendarIdentity,
                title: l10n.setupLocationFailedTitle,
                message: l10n.ramadanLocationError,
                onRetry: _retry,
                retrying: _retrying,
              ),
            );
          }

          // Short windows put the nights beside the plate from 600 wide.
          final short = context.windowClass.isCompactHeight && width >= 600;
          final twoPaneMinWidth = short ? 600.0 : 840.0;
          if (AdaptivePanes.showsTwoPanes(
            width,
            fold,
            twoPaneMinWidth: twoPaneMinWidth,
          )) {
            return HudaScaffold(
              title: l10n.ramadan,
              body: AdaptivePanes(
                twoPaneMinWidth: twoPaneMinWidth,
                primaryFraction: 0.42,
                maxPrimaryWidth: 520,
                primary: _scroll([_plate(state)]),
                secondary: _scroll([_nights(state)], maxWidth: 760),
              ),
            );
          }
          if (TabletopSplit.applies(context)) {
            return TabletopSplit(
              top: HudaScaffold(
                title: l10n.ramadan,
                body: _scroll([_plate(state)]),
              ),
              bottom: Scaffold(
                backgroundColor: Colors.transparent,
                body: _scroll([_nights(state)]),
              ),
            );
          }
          return HudaScaffold(
            title: l10n.ramadan,
            body: _scroll([
              _plate(state),
              SizedBox(height: space.lg),
              _nights(state),
            ]),
          );
        },
      ),
    );
  }
}
