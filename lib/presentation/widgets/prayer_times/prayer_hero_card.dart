import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart' hide TextDirection;

class PrayerHeroCard extends StatelessWidget {
  const PrayerHeroCard({
    super.key,
    required this.state,
    required this.countdown,
    required this.now,
    required this.locationMode,
    required this.timeZoneId,
    required this.onRefreshLocation,
  });

  final PrayerTimesLoaded state;
  final NextPrayerCountdown? countdown;
  final DateTime now;
  final PrayerLocationMode locationMode;

  final String? timeZoneId;
  final Future<void> Function() onRefreshLocation;

  static const _white = Colors.white;

  DateTime _wallClock(DateTime instant) => timeZoneId == null
      ? instant.toLocal()
      : PrayerTimeZoneService.wallClockAtInstant(instant, timeZoneId!);

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = _white.withValues(alpha: 0.74);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [palette.heroStart, palette.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.heroEnd.withValues(
              alpha: palette.isDark ? 0.5 : 0.3,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -46,
            end: -46,
            child: SizedBox.square(
              dimension: 200,
              child: CustomPaint(
                painter: PrayerStarPainter(
                  color: _white.withValues(alpha: 0.09),
                  strokeWidth: 1.6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _GlassChip(
                          icon: Icons.location_on_rounded,
                          label:
                              '${_locationName(l10n)} · '
                              '${locationMode == PrayerLocationMode.automatic ? l10n.automatic : l10n.manual}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _white.withValues(alpha: 0.14),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onRefreshLocation,
                        tooltip: l10n.refreshLocation,
                        color: _white,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.my_location_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Countdown(
                  state: state,
                  countdown: countdown,
                  wallClock: _wallClock,
                  muted: muted,
                ),
                if (state.provisional) ...[
                  const SizedBox(height: 18),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _GlassChip(
                      icon: Icons.hourglass_top_rounded,
                      label: l10n.prayerTimesProvisional,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _locationName(AppLocalizations l10n) {
    if (state.placemarks.isEmpty) return l10n.unknown;
    final place = state.placemarks.first;
    final parts = <String?>[
      place.locality,
      place.country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? l10n.unknown : parts.join(', ');
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.state,
    required this.countdown,
    required this.wallClock,
    required this.muted,
  });

  final PrayerTimesLoaded state;
  final NextPrayerCountdown? countdown;
  final DateTime Function(DateTime instant) wallClock;
  final Color muted;

  static const _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final countdown = this.countdown;
    final ready = countdown?.prayer != null && countdown?.instant != null;
    final elapsed = ready && countdown!.isPastPrayer;
    final counter = !ready
        ? '--:--'
        : PrayerCountdownFormatter.formatDuration(countdown!.duration);
    final startedAgo = elapsed
        ? l10n.prayerHeroStartedAgo(countdown.secondsPassed ~/ 60)
        : null;
    final name = ready ? localizedPrayerName(l10n, countdown!.prayer!) : '…';
    final time = ready
        ? DateFormat.jm(locale).format(wallClock(countdown!.instant!))
        : null;

    return Semantics(
      container: true,
      label: ready
          ? '${elapsed ? l10n.prayerHeroStarted : l10n.nextPrayer}: '
                '$name, $time${startedAgo == null ? '' : ', $startedAgo'}'
          : l10n.prayerCountdownLoadingText,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (elapsed)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          l10n.prayerTimelineNow,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        l10n.prayerHeroStarted,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    l10n.nextPrayer,
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: _white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                if (time != null)
                  Text(
                    time,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (startedAgo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      startedAgo,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 112,
            child: CustomPaint(
              painter: _RingPainter(
                progress: elapsed
                    ? 1
                    : ready
                    ? _progress(countdown!)
                    : 0,
                showDot: !elapsed,
                track: _white.withValues(alpha: 0.16),
                fill: _white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: elapsed
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mosque_rounded,
                            color: _white,
                            size: 26,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.prayerTimelineNow,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              counter,
                              textDirection: TextDirection.ltr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _white,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          if (ready)
                            Text(
                              l10n.prayerHeroRemaining,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _progress(NextPrayerCountdown countdown) {
    if (countdown.isPastPrayer) {
      return (countdown.secondsPassed /
              PrayerMomentResolver.gracePeriod.inSeconds)
          .clamp(0.0, 1.0);
    }
    final target = countdown.instant!.toUtc();
    final today = PrayerTimesCalculator.dailyAdjustedInstants(
      state.prayerTimes,
      state.offsets,
    ).values;
    DateTime? previous;
    for (final instant in [
      ...today,
      for (final t in today) t.subtract(const Duration(days: 1)),
    ]) {
      if (instant.isBefore(target) &&
          (previous == null || instant.isAfter(previous))) {
        previous = instant;
      }
    }
    if (previous == null) return 0;
    final total = target.difference(previous).inSeconds;
    if (total <= 0) return 0;
    return (1 - countdown.duration.inSeconds / total).clamp(0.0, 1.0);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    this.showDot = true,
  });

  final double progress;
  final Color track;
  final Color fill;

  final bool showDot;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
    if (!showDot) return;
    final angle = -math.pi / 2 + sweep;
    canvas.drawCircle(
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      stroke * 0.95,
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill ||
      oldDelegate.showDot != showDot;
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
