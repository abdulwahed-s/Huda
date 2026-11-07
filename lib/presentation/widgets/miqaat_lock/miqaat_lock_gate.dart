import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_platform.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_format.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_identity.dart';

/// Where the lock stands right now.
enum MiqaatGateStatus { needsAccess, off, noWindows, waiting, locked, done }

/// The lock's state, read from the cubit's state at [now].
class MiqaatGate {
  const MiqaatGate({
    required this.status,
    this.progress = 0,
    this.remainingSeconds = 0,
    this.goalMinutes = 0,
    this.next,
    this.windows = 0,
    this.windowsDone = 0,
  });

  factory MiqaatGate.of(MiqaatLockLoaded state, {DateTime? now}) {
    final settings = state.settings;
    final at = now ?? DateTime.now();
    final windows = settings.timeSlots.length;
    final done = settings.timeSlots
        .where((s) => state.completedTimeSlotIds.contains(s.id))
        .length;
    MiqaatGate gate(
      MiqaatGateStatus status, {
      double progress = 0,
      int remaining = 0,
    }) => MiqaatGate(
      status: status,
      progress: progress,
      remainingSeconds: remaining,
      goalMinutes: settings.goalDurationMinutes,
      next: miqaatNextWindow(settings.timeSlots, at),
      windows: windows,
      windowsDone: done,
    );

    if (!settings.isEnabled) {
      return gate(
        miqaatNeedsAccess(state.permissions)
            ? MiqaatGateStatus.needsAccess
            : MiqaatGateStatus.off,
      );
    }
    if (settings.timeSlots.isEmpty) return gate(MiqaatGateStatus.noWindows);
    final active = settings.timeSlots
        .where((slot) => slot.isActiveAt(at))
        .firstOrNull;
    if (active == null) return gate(MiqaatGateStatus.waiting);
    if (state.completedTimeSlotIds.contains(active.id)) {
      return gate(MiqaatGateStatus.done, progress: 1);
    }
    final session = state.activeSession;
    final mine = session != null && session.timeSlotId == active.id
        ? session
        : null;
    final goal = settings.goalDurationMinutes * 60;
    final spent = mine?.currentAccumulatedSeconds ?? 0;
    return gate(
      MiqaatGateStatus.locked,
      progress: goal <= 0 ? 1 : (spent / goal).clamp(0.0, 1.0),
      remaining: (goal - spent).clamp(0, goal),
    );
  }

  final MiqaatGateStatus status;
  final double progress;
  final int remainingSeconds;
  final int goalMinutes;
  final DateTime? next;
  final int windows;
  final int windowsDone;

  /// How far the doors are shut: wide when off or done, ajar while
  /// waiting, shut while locked.
  double get closed => switch (status) {
    MiqaatGateStatus.locked => 1,
    MiqaatGateStatus.waiting => 0.55,
    _ => 0,
  };
}

/// Whether this platform's access is still missing.
bool miqaatNeedsAccess(MiqaatLockPermissions permissions) =>
    switch (MiqaatLockPlatform.current) {
      MiqaatLockPlatform.android => !permissions.isAndroidReady,
      MiqaatLockPlatform.ios => !permissions.isIOSReady,
      MiqaatLockPlatform.other => false,
    };

/// The lock's signature card on the night chrome: the carved door, what
/// the lock is doing now, and the one switch that turns it on. [large]
/// stacks a big door above the words (a pane of its own).
class MiqaatLockGate extends StatelessWidget {
  const MiqaatLockGate({
    super.key,
    required this.gate,
    required this.enabled,
    required this.onToggle,
    this.large = false,
  });

  final MiqaatGate gate;
  final bool enabled;
  final ValueChanged<bool>? onToggle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.tokens.radius.lg);
    return ClipRRect(
      borderRadius: radius,
      child: HudaNight(
        child: _GateBody(
          gate: gate,
          enabled: enabled,
          onToggle: onToggle,
          large: large,
        ),
      ),
    );
  }
}

class _GateBody extends StatelessWidget {
  const _GateBody({
    required this.gate,
    required this.enabled,
    required this.onToggle,
    required this.large,
  });

  final MiqaatGate gate;
  final bool enabled;
  final ValueChanged<bool>? onToggle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final text = Theme.of(context).textTheme;
    final signature = tokens.motion.of(
      context,
      const Duration(milliseconds: 900),
    );

    final (eyebrow, title) = switch (gate.status) {
      MiqaatGateStatus.needsAccess => (
        l10n.miqaatStatusOff,
        l10n.miqaatGateNeedsAccess,
      ),
      MiqaatGateStatus.off => (l10n.miqaatStatusOff, l10n.miqaatGateOff),
      MiqaatGateStatus.noWindows => (
        l10n.miqaatStatusWaiting,
        l10n.miqaatGateNoWindows,
      ),
      MiqaatGateStatus.waiting => (
        l10n.miqaatStatusWaiting,
        gate.next == null
            ? l10n.miqaatGateNoWindows
            : l10n.miqaatGateWaiting(miqaatWhen(context, gate.next!)),
      ),
      MiqaatGateStatus.locked => (
        l10n.miqaatStatusLocked,
        l10n.miqaatGateLocked(
          l10n.miqaatMinutesShort((gate.remainingSeconds / 60).ceil()),
        ),
      ),
      MiqaatGateStatus.done => (l10n.miqaatStatusOpen, l10n.miqaatGateDone),
    };

    final door = TweenAnimationBuilder<double>(
      tween: Tween(end: gate.closed),
      duration: signature,
      curve: tokens.motion.emphasized,
      builder: (context, closed, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: gate.progress),
        duration: signature,
        curve: tokens.motion.standard,
        builder: (context, progress, _) => RepaintBoundary(
          child: CustomPaint(
            painter: MiqaatDoorPainter(
              line: tokens.gilt,
              glow: tokens.gilt.withValues(alpha: 0.45),
              wood: tokens.onChrome.withValues(alpha: 0.06),
              stroke: tokens.stroke.fine,
              closed: closed,
              progress: gate.status == MiqaatGateStatus.locked ? progress : 0,
              barred: gate.status == MiqaatGateStatus.locked,
              windows: gate.windows,
              windowsDone: gate.windowsDone,
            ),
          ),
        ),
      ),
    );

    final resize = tokens.motion.of(context, tokens.motion.medium);
    final words = Column(
      crossAxisAlignment: large
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaEyebrow(eyebrow, color: tokens.gilt),
        SizedBox(height: space.xs),
        Text(
          title,
          textAlign: large ? TextAlign.center : TextAlign.start,
          style: (large ? text.titleLarge : text.titleMedium)?.copyWith(
            color: tokens.onChrome,
          ),
        ),
        if (gate.status == MiqaatGateStatus.locked) ...[
          SizedBox(height: space.xs),
          Text(
            l10n.miqaatProgress(
              ((gate.goalMinutes * 60 - gate.remainingSeconds) / 60).floor(),
              gate.goalMinutes,
            ),
            style: text.bodySmall?.copyWith(color: tokens.onChromeMuted),
          ),
        ],
      ],
    );

    // The words cross-fade as the doors move, so they never run ahead.
    final fadeWords = AnimatedSwitcher(
      duration: tokens.motion.of(context, tokens.motion.long),
      layoutBuilder: (current, previous) => Stack(
        alignment: large
            ? Alignment.topCenter
            : AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(gate.status), child: words),
    );
    final status = Semantics(
      liveRegion: true,
      container: true,
      child: large
          ? Column(
              children: [
                SizedBox(
                  height: 220,
                  width: 220 * MiqaatDoorPainter.aspect,
                  child: door,
                ),
                SizedBox(height: space.lg),
                fadeWords,
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96 / MiqaatDoorPainter.aspect,
                  child: door,
                ),
                SizedBox(width: space.lg),
                Expanded(child: fadeWords),
              ],
            ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(space.lg, space.lg, space.lg, space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A zero-length AnimatedSize throws under reduce motion.
          if (resize == Duration.zero)
            status
          else
            AnimatedSize(
              duration: resize,
              curve: tokens.motion.standard,
              alignment: Alignment.topCenter,
              child: status,
            ),
          SizedBox(height: space.md),
          Divider(height: 1, color: tokens.onChrome.withValues(alpha: 0.14)),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: space.md),
                    child: Text(
                      l10n.enableMiqaatLock,
                      style: text.titleSmall?.copyWith(color: tokens.onChrome),
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('miqaat-master'),
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
