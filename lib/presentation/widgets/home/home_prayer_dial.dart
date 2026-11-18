import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:prayer_time_plus/prayer_time_plus.dart' show Prayer;

/// Why Home has no prayer times to show, in words, never a raw error.
(IconData, String) homePrayerUnavailable(
  AppLocalizations l10n,
  PrayerTimesState state,
) {
  final problem = prayerLocationProblemIn(state);
  return switch (problem) {
    null => (Icons.add_location_alt_outlined, l10n.prayerSetupRequired),
    PrayerLocationProblem.denied || PrayerLocationProblem.blocked => (
      Icons.location_off_outlined,
      prayerLocationProblemText(l10n, problem),
    ),
    PrayerLocationProblem.servicesOff => (
      Icons.location_disabled_outlined,
      prayerLocationProblemText(l10n, problem),
    ),
    _ => (Icons.error_outline, prayerLocationProblemText(l10n, problem)),
  };
}

enum HomeStation { passed, lit, ahead }

/// One of the day's moments on the dial.
typedef HomeDayMoment = ({
  Prayer prayer,
  String name,
  String time,
  DateTime instant,
  HomeStation status,
});

/// The day as the dial draws it: the six moments (Sunrise among them), and
/// now. The lit one is the next prayer, or the one whose time it is.
class HomePrayerDay {
  HomePrayerDay._(this.moments, this.now);

  static const _order = [
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  /// The day of [state] at Home's now, or null if a time is missing or
  /// out of order (high latitudes).
  static HomePrayerDay? of(BuildContext context, PrayerTimesLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final times = state.prayerTimes;
    final now = HomeClock.now().toUtc();
    final moment = PrayerMomentResolver.resolve(
      now: now,
      iqamah: state.iqamahSettings,
      transitions: [
        for (final entry in PrayerTimesCalculator.dailyAdjustedInstants(
          times,
          state.offsets,
        ).entries)
          PrayerTransition(prayer: entry.key, instant: entry.value),
      ],
    );
    final moments = <HomeDayMoment>[];
    for (final prayer in _order) {
      final instant = PrayerTimesCalculator.adjustedInstantFor(
        times,
        prayer,
        state.offsets,
      );
      final wall = PrayerTimesCalculator.adjustedTimeFor(
        times,
        prayer,
        state.offsets,
      );
      if (instant == null || wall == null) return null;
      if (moments.isNotEmpty && !instant.isAfter(moments.last.instant)) {
        return null;
      }
      moments.add((
        prayer: prayer,
        name: localizedPrayerName(l10n, prayer),
        time: DateFormat.jm(locale).format(wall),
        instant: instant.toUtc(),
        status: moment?.prayer == prayer
            ? HomeStation.lit
            : !instant.isAfter(now)
            ? HomeStation.passed
            : HomeStation.ahead,
      ));
    }
    // After Isha nothing is left today: tomorrow's Fajr is next, so Fajr's
    // lamp is the lit one (as the Prayer page counts down to it).
    if (moment == null && !moments.last.instant.isAfter(now)) {
      final fajr = moments.first;
      moments[0] = (
        prayer: fajr.prayer,
        name: fajr.name,
        time: fajr.time,
        instant: fajr.instant,
        status: HomeStation.lit,
      );
    }
    return HomePrayerDay._(moments, now);
  }

  final List<HomeDayMoment> moments;
  final DateTime now;

  HomeDayMoment get _sunrise => moments[1];
  HomeDayMoment get _maghrib => moments[4];

  /// Where [instant] sits on the dial: sunrise on the left of the horizon
  /// (π), noon at the top, sunset on the right (2π); Fajr and Isha below
  /// the horizon at either end.
  double angleOf(DateTime instant) {
    final day = _maghrib.instant.difference(_sunrise.instant).inSeconds;
    if (day <= 0) return math.pi;
    final t = instant.difference(_sunrise.instant).inSeconds / day;
    return (math.pi + math.pi * t).clamp(math.pi * 0.62, math.pi * 2.38);
  }

  double get start => angleOf(moments.first.instant);
  double get end => angleOf(moments.last.instant);

  /// Now on the dial, kept to the arc (before Fajr at its start, after Isha
  /// at its end).
  double get nowAngle => angleOf(now).clamp(start, end);

  /// Whether the sun is up (between sunrise and sunset).
  bool get daytime =>
      now.isAfter(_sunrise.instant) && now.isBefore(_maghrib.instant);
}

/// Path of Prayer's dial: the day as an arc over a horizon, like an
/// astrolabe's ring. The five prayers sit on it as lamps at their real
/// times (Sunrise a small mark on the horizon), the arc is walked in gilt
/// to now, where the sun rides (or the moon, at night). The next prayer,
/// its time and the time left are inside; the five times are in a row
/// under it ([HomePrayerTimesRow], placed by the page). A tap opens Prayer
/// Times. Without times it says why on the same ring; loading shows the
/// lamp spinner in it.
class HomePrayerDial extends StatelessWidget {
  const HomePrayerDial({
    super.key,
    required this.actions,
    this.maxHeight = double.infinity,
  });

  final HomeActions actions;

  /// The most height the dial may take (a pane's).
  final double maxHeight;

  /// The dial's height for a [width].
  static double heightFor(double width) => width * 0.78;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Larger where its pane has the room for it.
        final cap = constraints.maxWidth >= 640 && maxHeight >= 640
            ? 560.0
            : 460.0;
        final width = math.min(
          math.min(constraints.maxWidth, cap),
          maxHeight / 0.78,
        );
        final rtl = Directionality.of(context) == TextDirection.rtl;
        Widget dial({
          required HomePrayerDay? day,
          required Object stateKey,
          required String label,
          required Widget inside,
        }) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('home-prayer-hero'),
            behavior: HitTestBehavior.opaque,
            onTap: actions.openPrayerTimes,
            child: Center(
              child: SizedBox(
                width: width,
                height: heightFor(width),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: HomeDialReveal(
                          builder: (context, reveal) => CustomPaint(
                            painter: _DialPainter(
                              day: day,
                              palette: _DialPalette.of(context),
                              rtl: rtl,
                              reveal: reveal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: HudaStateSwitcher(
                        stateKey: stateKey,
                        child: inside,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
          builder: (context, state) {
            final day = state is PrayerTimesLoaded
                ? HomePrayerDay.of(context, state)
                : null;
            if (state is PrayerTimesLoaded) {
              // Today's next prayer, or after Isha the cubit's (tomorrow's
              // Fajr), never a stand-in title.
              return HomeNextPrayerBuilder(
                state: state,
                builder: (context, next) => dial(
                  day: day,
                  stateKey: state.runtimeType,
                  label: [
                    prayerPlaceName(l10n, state),
                    if (next != null) ...[
                      next.started ? l10n.prayerHeroStarted : l10n.nextPrayer,
                      next.name,
                      next.tomorrow
                          ? l10n.remindersNextTomorrow(next.time)
                          : next.time,
                    ],
                  ].join(', '),
                  inside: _Inside(next: next, width: width),
                ),
              );
            }
            final String label;
            final Widget inside;
            if (state is PrayerTimesInitial || state is PrayerTimesLoading) {
              label = l10n.loading;
              inside = _Waiting(width: width);
            } else {
              final (_, message) = homePrayerUnavailable(l10n, state);
              label = '${l10n.prayerTimes}. $message';
              inside = _Problem(message: message, width: width);
            }
            return dial(
              day: day,
              stateKey: state.runtimeType,
              label: label,
              inside: inside,
            );
          },
        );
      },
    );
  }
}

/// Walks the dial's arc to now once, as Home opens (0.9 s). Settled under
/// reduce motion.
class HomeDialReveal extends StatefulWidget {
  const HomeDialReveal({super.key, required this.builder});

  final Widget Function(BuildContext context, Animation<double> reveal) builder;

  @override
  State<HomeDialReveal> createState() => _HomeDialRevealState();
}

class _HomeDialRevealState extends State<HomeDialReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _curve);
}

@immutable
class _DialPalette {
  const _DialPalette({
    required this.gilt,
    required this.light,
    required this.ground,
  });

  factory _DialPalette.of(BuildContext context) {
    final tokens = context.tokens;
    return _DialPalette(
      gilt: tokens.gilt,
      light: tokens.onChrome,
      ground: tokens.chrome,
    );
  }

  final Color gilt;
  final Color light;
  final Color ground;

  @override
  bool operator ==(Object other) =>
      other is _DialPalette &&
      other.gilt == gilt &&
      other.light == light &&
      other.ground == ground;

  @override
  int get hashCode => Object.hash(gilt, light, ground);
}

/// The dial's geometry for a box: the ring's center and radius.
({Offset center, double radius}) _ring(Size size) {
  final r = size.width * 0.42;
  return (center: Offset(size.width / 2, r + size.width * 0.05), radius: r);
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.day,
    required this.palette,
    required this.rtl,
    required this.reveal,
  }) : super(repaint: reveal);

  final HomePrayerDay? day;
  final _DialPalette palette;
  final bool rtl;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = palette;
    final (:center, :radius) = _ring(size);
    final t = reveal.value;
    canvas.save();
    // The day runs in reading direction.
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    Offset at(double angle, [double r = 0]) =>
        center + Offset(math.cos(angle), math.sin(angle)) * (radius + r);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const track = 3.5;

    final day = this.day;
    // The span the day's ring covers: Fajr to Isha (or, with no times, a
    // resting arc over the horizon).
    final start = day?.start ?? math.pi * 0.85;
    final end = day?.end ?? math.pi * 2.15;

    // The bezel: a fine outer line and the hours, only along the day, so
    // nothing runs behind the times under the dial. Its ends fade.
    const fade = 0.12;
    for (var i = 0; i < 24; i++) {
      final a0 = start - fade + (end - start + fade * 2) * i / 24;
      final a1 = start - fade + (end - start + fade * 2) * (i + 1) / 24;
      final edge = math.min(i, 23 - i);
      final alpha = edge >= 2 ? 0.28 : 0.28 * (edge + 1) / 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 15),
        a0,
        a1 - a0 + 0.002,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = p.gilt.withValues(alpha: alpha),
      );
    }
    if (day != null) {
      final first = day.moments.first.instant;
      final last = day.moments.last.instant;
      final tick = Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = p.gilt.withValues(alpha: 0.45);
      for (
        var h = first.add(const Duration(hours: 1));
        h.isBefore(last);
        h = h.add(const Duration(hours: 1))
      ) {
        final a = day.angleOf(h);
        canvas.drawLine(at(a, 9), at(a, 13), tick);
      }
    }

    // The horizon, at either side of the ring only: the words inside keep
    // a clear field.
    final horizon = center.dy;
    for (final side in [-1.0, 1.0]) {
      final outer = center.dx + side * (radius + 26);
      final inner = center.dx + side * radius * 0.62;
      final segment = Rect.fromPoints(
        Offset(math.min(inner, outer), horizon - 1),
        Offset(math.max(inner, outer), horizon + 1),
      );
      canvas.drawLine(
        Offset(inner, horizon),
        Offset(outer, horizon),
        Paint()
          ..strokeWidth = 1
          ..shader = LinearGradient(
            colors: side < 0
                ? [
                    p.gilt.withValues(alpha: 0),
                    p.gilt.withValues(alpha: 0.55),
                    p.gilt.withValues(alpha: 0),
                  ]
                : [
                    p.gilt.withValues(alpha: 0),
                    p.gilt.withValues(alpha: 0.55),
                    p.gilt.withValues(alpha: 0),
                  ],
            stops: const [0, 0.55, 1],
          ).createShader(segment),
      );
    }

    // The day's track: one soft line from Fajr to Isha.
    canvas.drawArc(
      rect,
      start,
      end - start,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = track
        ..strokeCap = StrokeCap.round
        ..color = p.light.withValues(alpha: 0.14),
    );
    if (day == null) {
      canvas.restore();
      return;
    }

    // The progress: walked in gilt to now (drawn in as Home opens),
    // brightening toward the sun, with a soft glow under it.
    final now = start + (day.nowAngle - start) * t;
    if (now > start) {
      canvas.drawArc(
        rect,
        start,
        now - start,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = track * 3
          ..strokeCap = StrokeCap.round
          ..color = p.gilt.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawArc(
        rect,
        start,
        now - start,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = track
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            center: Alignment(
              (center.dx / size.width) * 2 - 1,
              (center.dy / size.height) * 2 - 1,
            ),
            startAngle: 0,
            endAngle: math.pi * 2,
            transform: GradientRotation(start),
            colors: [p.gilt.withValues(alpha: 0.55), p.gilt, p.gilt],
            stops: [0, ((now - start) / (math.pi * 2)).clamp(0.01, 1.0), 1],
          ).createShader(Offset.zero & size),
      );
    }

    // The moments: sunrise a small half sun on the horizon; the prayers as
    // beads on the track. A bead lights as the progress reaches it.
    for (final moment in day.moments) {
      final a = day.angleOf(moment.instant);
      final c = at(a);
      if (moment.prayer == Prayer.sunrise) {
        final sunrise = Paint()..color = p.gilt.withValues(alpha: 0.85);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: 5),
          math.pi,
          math.pi,
          true,
          sunrise,
        );
        final rays = Paint()
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = p.gilt.withValues(alpha: 0.7);
        for (final ray in const [-0.75, -0.5, -0.25]) {
          final d = Offset(
            math.cos(math.pi * 2 * ray),
            math.sin(math.pi * 2 * ray),
          );
          canvas.drawLine(c + d * 7.5, c + d * 10.5, rays);
        }
        continue;
      }
      final reached = a <= now + 0.001;
      final status = moment.status == HomeStation.passed && !reached
          ? HomeStation.ahead
          : moment.status;
      switch (status) {
        case HomeStation.passed:
          // A gilt bead with a dark rim, so it reads on the gilt line.
          canvas.drawCircle(c, 6.5, Paint()..color = p.ground);
          canvas.drawCircle(c, 4.5, Paint()..color = p.gilt);
        case HomeStation.lit:
          // The next prayer: a halo, a clean gilt ring, a lit heart.
          final halo = Curves.easeOut.transform(
            ((t - 0.6) / 0.4).clamp(0.0, 1.0),
          );
          canvas.drawCircle(
            c,
            20,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  p.gilt.withValues(alpha: 0.42 * halo),
                  p.gilt.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromCircle(center: c, radius: 20)),
          );
          canvas.drawCircle(c, 9, Paint()..color = p.ground);
          canvas.drawCircle(
            c,
            9,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = p.gilt,
          );
          canvas.drawCircle(
            c,
            4,
            Paint()..color = Color.lerp(p.gilt, p.light, 0.35)!,
          );
        case HomeStation.ahead:
          canvas.drawCircle(c, 6, Paint()..color = p.ground);
          canvas.drawCircle(
            c,
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = p.light.withValues(alpha: 0.6),
          );
      }
    }

    // Now: a small crisp sun with fine rays by day; the crescent by night.
    final sun = at(now);
    if (day.daytime) {
      canvas.drawCircle(
        sun,
        24,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.gilt.withValues(alpha: 0.32),
              p.gilt.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: 24)),
      );
      final rays = Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = p.gilt.withValues(alpha: 0.85);
      for (var i = 0; i < 8; i++) {
        final d = Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4));
        canvas.drawLine(sun + d * 11, sun + d * 15, rays);
      }
      canvas.drawCircle(sun, 8, Paint()..color = p.ground);
      canvas.drawCircle(
        sun,
        7,
        Paint()..color = Color.lerp(p.light, p.gilt, 0.3)!,
      );
    } else {
      canvas.drawCircle(
        sun,
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.light.withValues(alpha: 0.26),
              p.light.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: 22)),
      );
      canvas.drawCircle(sun, 10, Paint()..color = p.ground);
      final moon = Path()..addOval(Rect.fromCircle(center: sun, radius: 8.5));
      final bite = Path()
        ..addOval(
          Rect.fromCircle(center: sun + const Offset(4, -3), radius: 7.5),
        );
      canvas.drawPath(
        Path.combine(PathOperation.difference, moon, bite),
        Paint()..color = p.light,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.day?.now != day?.now ||
      old.day?.moments != day?.moments ||
      old.palette != palette ||
      old.rtl != rtl ||
      old.reveal != reveal;
}

/// Inside the ring: the next prayer above the horizon, the time left
/// below it.
class _Inside extends StatelessWidget {
  const _Inside({required this.next, required this.width});

  /// Null only for the moment before the cubit answers (after Isha):
  /// nothing inside then, never a stand-in title.
  final HomeNextPrayer? next;
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (:center, :radius) = _ring(
      Size(width, HomePrayerDial.heightFor(width)),
    );
    final next = this.next;
    if (next == null) {
      return const SizedBox(key: ValueKey('home-dial-inside'));
    }
    // The words follow the ring's size.
    final nameStyle = width >= 420
        ? theme.textTheme.displayLarge
        : width >= 340
        ? theme.textTheme.displayMedium
        : width >= 290
        ? theme.textTheme.displaySmall
        : theme.textTheme.headlineMedium;
    final eyebrow = width >= 290;
    // Above the horizon, centered in the upper half of the ring.
    final upper = Positioned(
      left: center.dx - radius * 0.78,
      width: radius * 1.56,
      bottom: HomePrayerDial.heightFor(width) - center.dy + 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow)
            Text(
              (next.started ? l10n.prayerHeroStarted : l10n.nextPrayer)
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: context.type.eyebrow.copyWith(color: tokens.gilt),
            ),
          Text(
            next.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: nameStyle?.copyWith(color: tokens.onChrome, height: 1.1),
          ),
          Text(
            // After Isha: "Tomorrow at 3:10 AM", never read as a time
            // already past today.
            next.tomorrow ? l10n.remindersNextTomorrow(next.time) : next.time,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.gilt,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    // Below the horizon: the time left (or, just after it began, how long
    // ago, as the Prayer page says it).
    final lower = next.started
        ? Positioned(
            left: center.dx - radius * 0.7,
            width: radius * 1.4,
            top: center.dy + 14,
            child: Text(
              l10n.prayerHeroStartedAgo(next.minutesSince),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.onChromeMuted,
              ),
            ),
          )
        : Positioned(
            left: center.dx - radius * 0.6,
            width: radius * 1.2,
            top: center.dy + 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Up to "13:23:45" to tomorrow's Fajr: it scales down to
                // its room rather than overflow (one scale, no retry).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: PrayerCountdown(
                      target: next.instant,
                      clock: HomeClock.now,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.onChrome,
                      ),
                    ),
                  ),
                ),
                Text(
                  l10n.prayerHeroRemaining,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.onChromeMuted,
                  ),
                ),
              ],
            ),
          );
    return MediaQuery.withClampedTextScaling(
      // Inside a ring the words can't grow without bound; the row under
      // the dial carries the times at any size.
      maxScaleFactor: 1.3,
      child: Stack(
        key: const ValueKey('home-dial-inside'),
        clipBehavior: Clip.none,
        children: [upper, lower],
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final (:center, radius: _) = _ring(
      Size(width, HomePrayerDial.heightFor(width)),
    );
    return Stack(
      key: const ValueKey('home-prayer-dial-loading'),
      children: [
        Positioned(
          left: center.dx - 18,
          top: center.dy - 56,
          child: HudaLampSpinner(size: 36, color: context.tokens.gilt),
        ),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.width});

  final String message;
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (:center, :radius) = _ring(
      Size(width, HomePrayerDial.heightFor(width)),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Stack(
        key: const ValueKey('home-prayer-sky-unavailable'),
        children: [
          Positioned(
            left: center.dx - radius * 0.8,
            width: radius * 1.6,
            bottom: HomePrayerDial.heightFor(width) - center.dy + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.prayerTimes.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: context.type.eyebrow.copyWith(color: tokens.gilt),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.onChrome,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: center.dx - radius * 0.6,
            width: radius * 1.2,
            top: center.dy + 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    l10n.prayerTimes,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.gilt,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.gilt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The five prayers' times in a row under the dial, in the day's order:
/// the next one in gilt with a bar under it, those passed quieter. Two
/// rows when five don't fit.
class HomePrayerTimesRow extends StatelessWidget {
  const HomePrayerTimesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is! PrayerTimesLoaded) return const SizedBox.shrink();
        final day = HomePrayerDay.of(context, state);
        if (day == null) return const SizedBox.shrink();
        final tokens = context.tokens;
        final theme = Theme.of(context);
        final prayers = [
          for (final moment in day.moments)
            if (moment.prayer != Prayer.sunrise) moment,
        ];
        final l10n = AppLocalizations.of(context)!;
        Widget cell(HomeDayMoment moment) {
          final lit = moment.status == HomeStation.lit;
          final passed = moment.status == HomeStation.passed;
          final color = lit
              ? tokens.gilt
              : passed
              ? tokens.onChromeMuted.withValues(alpha: 0.7)
              : tokens.onChrome;
          // The next prayer sits in a soft gilt capsule; those passed step
          // back.
          return Semantics(
            key: ValueKey('home-day-time-${moment.prayer.name}'),
            label: lit
                ? '${moment.name}, ${moment.time}, ${l10n.nextPrayer}'
                : '${moment.name}, ${moment.time}',
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: tokens.motion.of(context, tokens.motion.medium),
              curve: tokens.motion.standard,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tokens.gilt.withValues(alpha: lit ? 0.14 : 0),
                borderRadius: BorderRadius.circular(tokens.radius.md),
                border: Border.all(
                  color: tokens.gilt.withValues(alpha: lit ? 0.45 : 0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: lit ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // At large text a long time ("12:58 PM") scales down to
                  // its cell rather than clip (one scale, no retry).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      moment.time,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: lit ? FontWeight.w700 : FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final across = constraints.maxWidth >= 5 * 62 * scale ? 5 : 3;
            final rows = <Widget>[];
            for (var i = 0; i < prayers.length; i += across) {
              if (i > 0) rows.add(SizedBox(height: tokens.space.sm));
              rows.add(
                Row(
                  children: [
                    for (var j = i; j < i + across; j++)
                      Expanded(
                        child: j < prayers.length
                            ? cell(prayers[j])
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              );
            }
            return Column(
              key: const ValueKey('home-day-path'),
              mainAxisSize: MainAxisSize.min,
              children: rows,
            );
          },
        );
      },
    );
  }
}
