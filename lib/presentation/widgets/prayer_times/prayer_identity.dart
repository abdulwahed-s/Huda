import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hijri_date_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/data/models/countdown_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_sky.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart' hide TextDirection;

export 'package:huda/presentation/widgets/prayer_times/prayer_sky.dart';


class PrayerSkyBand extends StatelessWidget {
  const PrayerSkyBand({
    super.key,
    required this.child,
    this.padding,
    this.times,
    this.hour,
    this.skyRoom = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  final PrayerSkyTimes? times;
  final double? hour;

  final double skyRoom;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(tokens.radius.lg);
    final base =
        padding?.resolve(Directionality.of(context)) ??
        EdgeInsets.all(tokens.space.md);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: tokens.gilt.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: HudaNight(
          child: Stack(
            children: [
              Positioned.fill(
                child: PrayerSky(
                  times: times ?? PrayerSkyTimes.fallback,
                  hour: hour ?? prayerSkyHour(DateTime.now()),
                  veil: true,
                ),
              ),
              Padding(
                padding: base.copyWith(bottom: base.bottom + skyRoom),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerSkyCard extends StatelessWidget {
  const PrayerSkyCard({
    super.key,
    required this.state,
    required this.countdown,
    required this.now,
    required this.locationMode,
    required this.timeZoneId,
    required this.onOpenLocation,
    this.clock = DateTime.now,
  });

  final DateTime Function() clock;

  final PrayerTimesLoaded state;
  final NextPrayerCountdown? countdown;
  final DateTime now;
  final PrayerLocationMode locationMode;
  final String? timeZoneId;

  final VoidCallback onOpenLocation;

  DateTime _wallClock(DateTime instant) => timeZoneId == null
      ? instant.toLocal()
      : PrayerTimeZoneService.wallClockAtInstant(instant, timeZoneId!);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final times = PrayerSkyTimes.of(state, _wallClock);
    final hour = prayerSkyHour(_wallClock(now.toUtc()));
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = MediaQuery.sizeOf(context).height < 480;
        final beside = short && constraints.maxWidth >= 420;
        final words = _Words(
          clock: clock,
          compact: beside,
          countdown: countdown,
          wallClock: _wallClock,
          provisional: state.provisional,
        );
        return PrayerSkyBand(
          times: times,
          hour: hour,
          padding: EdgeInsets.fromLTRB(space.md, space.md, space.md, space.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlaceRow(
                place: prayerPlaceName(l10n, state),
                automatic: locationMode == PrayerLocationMode.automatic,
                updating: state.updating,
                onTap: onOpenLocation,
              ),
              SizedBox(height: space.sm),
              words,
              SizedBox(
                height: beside ? space.lg : (short ? space.xxl : space.giant),
              ),
              _DayLine(state: state),
            ],
          ),
        );
      },
    );
  }
}

const prayerSkyTextShadows = [
  Shadow(color: Color(0x73000000), blurRadius: 10),
  Shadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1)),
];

String prayerPlaceName(AppLocalizations l10n, PrayerTimesLoaded state) {
  if (state.placemarks.isEmpty) return l10n.unknown;
  final place = state.placemarks.first;
  final parts = <String?>[
    place.locality,
    place.country,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
  return parts.isEmpty ? l10n.unknown : parts.join(', ');
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.automatic,
    required this.updating,
    required this.onTap,
  });

  final String place;
  final bool automatic;
  final bool updating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.prayerLocationRowSemantics(place);
    return Row(
      children: [
        Flexible(
          child: Tooltip(
            message: l10n.prayerLocationTitle,
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                key: const ValueKey('prayer-open-location'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(tokens.radius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(end: tokens.space.xxs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          automatic
                              ? Icons.near_me_rounded
                              : Icons.location_on_rounded,
                          size: 18,
                          color: tokens.gilt,
                        ),
                        SizedBox(width: tokens.space.xs),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: tokens.onChrome,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: tokens.onChromeMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: tokens.motion.of(context, tokens.motion.medium),
          child: updating
              ? Semantics(
                  key: const ValueKey('prayer-place-updating'),
                  liveRegion: true,
                  label: l10n.prayerLocationUpdating,
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: tokens.space.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HudaLampSpinner(size: 14, color: tokens.gilt),
                        SizedBox(width: tokens.space.xxs),
                        Text(
                          l10n.prayerLocationUpdating,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tokens.onChromeMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({
    required this.clock,
    this.compact = false,
    required this.countdown,
    required this.wallClock,
    required this.provisional,
  });

  final NextPrayerCountdown? countdown;
  final DateTime Function(DateTime instant) wallClock;
  final bool provisional;

  final bool compact;

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final countdown = this.countdown;
    final ready = countdown?.prayer != null && countdown?.instant != null;
    final elapsed = ready && countdown!.isPastPrayer;
    final name = ready ? localizedPrayerName(l10n, countdown!.prayer!) : '…';
    final time = ready
        ? DateFormat.jm(locale).format(wallClock(countdown!.instant!))
        : null;
    final startedAgo = elapsed
        ? l10n.prayerHeroStartedAgo(countdown.secondsPassed ~/ 60)
        : null;
    final left = ready && !elapsed ? countdown!.duration.inSeconds : null;
    final counter = left == null
        ? null
        : PrayerCountdownFormatter.formatDuration(Duration(seconds: left));

    final eyebrow = Text(
      (elapsed ? l10n.prayerHeroStarted : l10n.nextPrayer).toUpperCase(),
      style: context.type.eyebrow.copyWith(
        color: tokens.gilt,
        shadows: prayerSkyTextShadows,
      ),
    );
    final title = Text(
      name,
      maxLines: 2,
      style:
          (compact
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.displaySmall)
              ?.copyWith(
                color: tokens.onChrome,
                shadows: prayerSkyTextShadows,
                height: 1.1,
              ),
    );
    final detail = Wrap(
      spacing: tokens.space.sm,
      runSpacing: tokens.space.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (time != null)
          Text(
            time,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.onChrome,
              shadows: prayerSkyTextShadows,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (elapsed) _Chip(label: l10n.prayerTimelineNow, lit: true),
        if (startedAgo != null)
          Text(
            startedAgo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.onChromeMuted,
              shadows: prayerSkyTextShadows,
            ),
          ),
        if (provisional)
          _Chip(
            label: l10n.prayerTimesProvisional,
            icon: Icons.hourglass_top_rounded,
          ),
      ],
    );
    final remaining = !ready
        ? Text(
            '--:--',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: tokens.onChromeMuted,
              shadows: prayerSkyTextShadows,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : counter == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: PrayerCountdown(
                  target: countdown!.instant!,
                  clock: clock,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: tokens.onChrome,
                    shadows: prayerSkyTextShadows,
                  ),
                ),
              ),
              Text(
                l10n.prayerHeroRemaining,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.onChromeMuted,
                  shadows: prayerSkyTextShadows,
                ),
              ),
            ],
          );

    return Semantics(
      container: true,
      liveRegion: false,
      label: ready
          ? [
              elapsed ? l10n.prayerHeroStarted : l10n.nextPrayer,
              name,
              ?time,
              ?startedAgo,
              if (counter != null) '$counter ${l10n.prayerHeroRemaining}',
              if (provisional) l10n.prayerTimesProvisional,
            ].join(', ')
          : l10n.prayerCountdownLoadingText,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                eyebrow,
                Wrap(
                  spacing: tokens.space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [title, detail],
                ),
                if (left != null)
                  Wrap(
                    spacing: tokens.space.xs,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: PrayerCountdown(
                          target: countdown!.instant!,
                          clock: clock,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: tokens.onChrome,
                            shadows: prayerSkyTextShadows,
                          ),
                        ),
                      ),
                      Text(
                        l10n.prayerHeroRemaining,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.onChromeMuted,
                          shadows: prayerSkyTextShadows,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }
          final words = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              eyebrow,
              title,
              SizedBox(height: tokens.space.xxs),
              detail,
            ],
          );
          if (remaining == null) return words;
          final scale = MediaQuery.textScalerOf(context).scale(1);
          if (constraints.maxWidth < 250 * scale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                words,
                SizedBox(height: tokens.space.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: remaining,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: words),
              SizedBox(width: tokens.space.sm),
              remaining,
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.lit = false});

  final String label;
  final IconData? icon;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final icon = this.icon;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.space.xs,
        tokens.space.xxs / 2,
        tokens.space.xs,
        tokens.space.xxs / 2,
      ),
      decoration: BoxDecoration(
        color: lit ? tokens.gilt : tokens.onChrome.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: lit
            ? null
            : Border.all(color: tokens.onChrome.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tokens.onChrome),
            SizedBox(width: tokens.space.xxs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: lit ? tokens.chrome : tokens.onChrome,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLine extends StatelessWidget {
  const _DayLine({required this.state});

  final PrayerTimesLoaded state;

  @override
  Widget build(BuildContext context) {
    final times = state.prayerTimes;
    final day = times.fajr ?? times.dhuhr;
    if (day == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final hijri = hijriDateFromDateTime(day);
    return Text(
      '${DateFormat.MMMEd(locale).format(day)} · '
      '${hijri.day} ${hijriMonthName(l10n, hijri.month)} ${hijri.year}',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.tokens.onChromeMuted),
    );
  }
}

class PrayerCountdown extends StatefulWidget {
  const PrayerCountdown({
    super.key,
    required this.target,
    this.clock = DateTime.now,
    this.style,
  });

  final DateTime target;
  final DateTime Function() clock;
  final TextStyle? style;

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown> {
  Timer? _timer;
  late int _seconds = _left();
  bool _active = true;

  int _left() {
    final ms = widget.target
        .toUtc()
        .difference(widget.clock().toUtc())
        .inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_active || _seconds <= 0) return;
    final ms = widget.target
        .toUtc()
        .difference(widget.clock().toUtc())
        .inMilliseconds;
    final wait = ms % 1000 + 1;
    _timer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      final next = _left();
      if (next != _seconds) setState(() => _seconds = next);
      _schedule();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active != _active || _timer == null) {
      _active = active;
      if (active) _seconds = _left();
      _schedule();
    }
  }

  @override
  void didUpdateWidget(covariant PrayerCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _seconds = _left();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = PrayerCountdownFormatter.formatDuration(
      Duration(seconds: _seconds),
    );
    final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final motion = context.tokens.motion;
    final duration = motion.of(context, const Duration(milliseconds: 420));
    final chars = text.characters.toList();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < chars.length; i++)
            ClipRect(
              child: AnimatedSwitcher(
                key: ValueKey(chars.length - i),
                duration: duration,
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey('${chars[i]}$i');
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0, incoming ? -1 : 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: Text(
                  chars[i],
                  key: ValueKey('${chars[i]}$i'),
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
