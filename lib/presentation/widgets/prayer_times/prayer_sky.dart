import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';


@immutable
class PrayerSkyTimes {
  const PrayerSkyTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  static const fallback = PrayerSkyTimes(
    fajr: 5,
    sunrise: 6.4,
    dhuhr: 12.3,
    asr: 15.6,
    maghrib: 18.2,
    isha: 19.5,
  );

  final double fajr;
  final double sunrise;
  final double dhuhr;
  final double asr;
  final double maghrib;
  final double isha;

  factory PrayerSkyTimes.of(
    PrayerTimesLoaded state,
    DateTime Function(DateTime instant) wallClock,
  ) {
    double? hourOf(Prayer prayer) {
      final instant = PrayerTimesCalculator.adjustedInstantFor(
        state.prayerTimes,
        prayer,
        state.offsets,
      );
      return instant == null ? null : prayerSkyHour(wallClock(instant));
    }

    final values = [
      for (final prayer in const [
        Prayer.fajr,
        Prayer.sunrise,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ])
        hourOf(prayer),
    ];
    if (values.any((value) => value == null)) return fallback;
    for (var i = 1; i < values.length; i++) {
      if (values[i]! <= values[i - 1]!) return fallback;
    }
    return PrayerSkyTimes(
      fajr: values[0]!,
      sunrise: values[1]!,
      dhuhr: values[2]!,
      asr: values[3]!,
      maghrib: values[4]!,
      isha: values[5]!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerSkyTimes &&
      other.fajr == fajr &&
      other.sunrise == sunrise &&
      other.dhuhr == dhuhr &&
      other.asr == asr &&
      other.maghrib == maghrib &&
      other.isha == isha;

  @override
  int get hashCode => Object.hash(fajr, sunrise, dhuhr, asr, maghrib, isha);
}

double prayerSkyHour(DateTime time) =>
    time.hour + time.minute / 60 + time.second / 3600;

class PrayerSkyScope extends InheritedWidget {
  const PrayerSkyScope({
    super.key,
    required this.times,
    required this.hour,
    required super.child,
  });

  final PrayerSkyTimes times;
  final double hour;

  static PrayerSkyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrayerSkyScope>();

  @override
  bool updateShouldNotify(PrayerSkyScope old) =>
      old.times != times || old.hour != hour;
}

({Color top, Color bottom, double stars}) prayerSkyColors(
  HudaTokens t,
  Color red,
  PrayerSkyTimes d,
  double hour,
) {
  final nightTop = Color.lerp(t.chromeEnd, Colors.black, 0.4)!;
  final keys = <(double, Color, Color, double)>[
    (0, nightTop, t.chrome, 1),
    (d.fajr - 0.4, nightTop, Color.lerp(t.chrome, t.gilt, 0.08)!, 0.9),
    (
      d.fajr + 0.5,
      Color.lerp(t.chrome, Colors.black, 0.25)!,
      Color.lerp(t.chrome, t.gilt, 0.42)!,
      0.45,
    ),
    (d.sunrise, t.chrome, Color.lerp(t.gilt, red, 0.18)!, 0.1),
    (
      d.sunrise + 1.2,
      Color.lerp(t.chrome, t.onChrome, 0.06)!,
      Color.lerp(t.chrome, t.gilt, 0.5)!,
      0,
    ),
    (
      d.dhuhr,
      Color.lerp(t.chrome, t.onChrome, 0.14)!,
      Color.lerp(t.gilt, t.onChrome, 0.25)!,
      0,
    ),
    (d.asr, t.chrome, Color.lerp(t.chrome, t.gilt, 0.7)!, 0),
    (
      d.maghrib - 0.4,
      Color.lerp(t.chrome, red, 0.12)!,
      Color.lerp(t.gilt, red, 0.4)!,
      0,
    ),
    (
      d.maghrib + 0.3,
      Color.lerp(t.chrome, red, 0.08)!,
      Color.lerp(t.chrome, red, 0.45)!,
      0.2,
    ),
    (d.isha, nightTop, Color.lerp(t.chrome, t.gilt, 0.12)!, 0.8),
    (24, nightTop, t.chrome, 1),
  ];
  final h = hour.clamp(0.0, 24.0);
  for (var i = 0; i < keys.length - 1; i++) {
    final (a, at, ab, as_) = keys[i];
    final (b, bt, bb, bs) = keys[i + 1];
    if (h <= b && b > a) {
      final e = Curves.easeInOut.transform(((h - a) / (b - a)).clamp(0, 1));
      return (
        top: Color.lerp(at, bt, e)!,
        bottom: Color.lerp(ab, bb, e)!,
        stars: as_ + (bs - as_) * e,
      );
    }
  }
  return (top: nightTop, bottom: t.chrome, stars: 1);
}

double _ramp(double x, double a, double b) =>
    Curves.easeInOut.transform(((x - a) / (b - a)).clamp(0.0, 1.0));

class _Sky {
  _Sky({
    required this.tokens,
    required this.red,
    required this.times,
    required double hour,
    this.rtl = false,
  }) : hour = (hour % 24 + 24) % 24 {
    final colors = prayerSkyColors(tokens, red, times, this.hour);
    top = colors.top;
    bottom = colors.bottom;
    stars = colors.stars;
    warmLight = Color.lerp(tokens.gilt, red, 0.32)!;
    paleLight = Color.lerp(tokens.gilt, tokens.onChrome, 0.55)!;
    final h = this.hour;
    dawn =
        _ramp(h, times.fajr - 0.2, times.fajr + 0.5) *
        (1 - _ramp(h, times.sunrise, times.sunrise + 0.8));
    shafaq =
        _ramp(h, times.maghrib - 0.5, times.maghrib) *
        (1 - _ramp(h, times.maghrib + 0.2, times.isha));
    sunF = (h - times.sunrise) / (times.maghrib - times.sunrise);
    sunUp = math.sin(math.pi * sunF.clamp(-0.3, 1.3));
    sunShown = sunF > -0.3 && sunF < 1.3;
    sunLight = ((sunUp + 0.1) / 0.25).clamp(0.0, 1.0);
    low = (1 - sunUp).clamp(0.0, 1.0);
    final night = 24 - times.maghrib + times.sunrise;
    final hh = h < times.sunrise + 1 ? h + 24 : h;
    moonG = (hh - times.maghrib - 0.3) / night;
    moonUp = 0.78 * math.sin(math.pi * moonG.clamp(-0.2, 1.2));
    moonShown = moonG > -0.2 && moonG < 1.2;
    moonLight =
        ((moonUp + 0.06) / 0.16).clamp(0.0, 1.0) *
        (1 - sunLight) *
        (1 - 0.55 * dawn);
  }

  final HudaTokens tokens;
  final Color red;
  final PrayerSkyTimes times;
  final double hour;

  final bool rtl;
  late final Color top;
  late final Color bottom;
  late final double stars;
  late final Color warmLight;
  late final Color paleLight;
  late final double dawn;
  late final double shafaq;
  late final double sunF;
  late final double sunUp;
  late final bool sunShown;

  late final double sunLight;

  late final double low;
  late final double moonG;
  late final double moonUp;
  late final bool moonShown;
  late final double moonLight;

  double horizonOf(Size size) => size.height * 0.8;

  double x(Size size, double x) => size.width * (rtl ? 1 - x : x);

  Offset sunAt(Size size) => Offset(
    x(size, 0.12 + 0.72 * sunF.clamp(-0.3, 1.3)),
    horizonOf(size) - size.height * 0.03 - sunUp * size.height * 0.6,
  );

  Offset moonAt(Size size) => Offset(
    x(size, 0.42 + 0.5 * moonG.clamp(-0.2, 1.2)),
    horizonOf(size) - size.height * 0.03 - moonUp * size.height * 0.62,
  );

  double sunRadius(Size size) =>
      math.max(3.5, size.height * 0.045) * (1 + 0.9 * low);

  double moonRadius(Size size) => math.max(4.5, size.height * 0.06);

  bool same(_Sky other) =>
      other.tokens == tokens &&
      other.red == red &&
      other.times == times &&
      other.hour == hour &&
      other.rtl == rtl;
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.sky);

  final _Sky sky;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = sky.horizonOf(size);
    final rect = Offset.zero & size;
    final t = sky.tokens;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, Color.lerp(sky.top, sky.bottom, 0.5)!, sky.bottom],
          stops: const [0, 0.5, 0.8],
        ).createShader(rect),
    );
    if (sky.dawn > 0) {
      final band = Rect.fromLTRB(0, horizon - h * 0.16, w, horizon + 2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sky.paleLight.withValues(alpha: 0),
              sky.paleLight.withValues(alpha: 0.45 * sky.dawn),
              t.onChrome.withValues(alpha: 0.75 * sky.dawn),
            ],
            stops: const [0, 0.7, 1],
          ).createShader(band),
      );
      final east = Offset(sky.x(size, 0.12), horizon);
      canvas.drawCircle(
        east,
        w * 0.5,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sky.warmLight.withValues(alpha: 0.28 * sky.dawn),
              sky.warmLight.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: east, radius: w * 0.5)),
      );
    }
    if (sky.shafaq > 0) {
      final west = Offset(sky.x(size, 0.86), horizon);
      final glow = Color.lerp(sky.warmLight, sky.red, 0.35)!;
      canvas.drawCircle(
        west,
        w * 0.7,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.withValues(alpha: 0.45 * sky.shafaq),
              sky.warmLight.withValues(alpha: 0.12 * sky.shafaq),
              sky.warmLight.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: west, radius: w * 0.7)),
      );
    }
    final milky = ((sky.stars - 0.5) / 0.4).clamp(0.0, 1.0);
    if (milky > 0) {
      final band = Path()
        ..moveTo(sky.x(size, 0.05), 0)
        ..lineTo(sky.x(size, 0.32), 0)
        ..lineTo(sky.x(size, 0.95), horizon * 0.85)
        ..lineTo(sky.x(size, 0.62), horizon * 0.95)
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..color = t.onChrome.withValues(alpha: 0.05 * milky)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackPainter old) => !old.sky.same(sky);
}

class _Seq {
  _Seq(int seed) : _s = seed & 0x7fffffff;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}

class _LifePainter extends CustomPainter {
  _LifePainter(this.sky, this.phase) : super(repaint: phase);

  final _Sky sky;
  final ValueNotifier<double> phase;

  static double meteorStart(int k) => 2.0 + (k * 2.7) % 3.5;
  static const meteorPeriod = 8.0;
  static const meteorLength = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = sky.horizonOf(size);
    final t = sky.tokens;
    final time = phase.value;
    final day = sky.sunLight * (1 - sky.stars);

    if (sky.sunShown && sky.sunLight > 0.02) {
      final sun = sky.sunAt(size);
      final r = sky.sunRadius(size);
      final core = Color.lerp(sky.paleLight, sky.warmLight, sky.low * 0.8)!;
      if (day > 0.2) {
        final reach = r * 11;
        final rays = Path();
        const count = 12;
        final turn = time * 0.025;
        for (var i = 0; i < count; i++) {
          final a = turn + i * 2 * math.pi / count;
          final width = 0.06 + 0.03 * math.sin(time * 0.5 + i);
          rays
            ..moveTo(sun.dx, sun.dy)
            ..lineTo(
              sun.dx + math.cos(a - width) * reach,
              sun.dy + math.sin(a - width) * reach,
            )
            ..lineTo(
              sun.dx + math.cos(a + width) * reach,
              sun.dy + math.sin(a + width) * reach,
            )
            ..close();
        }
        canvas.drawPath(
          rays,
          Paint()
            ..shader = RadialGradient(
              colors: [
                core.withValues(alpha: 0.10 * day),
                core.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: sun, radius: reach)),
        );
      }
      final breath = 2.6 + 0.35 * math.sin(time * 0.8);
      canvas.drawCircle(
        sun,
        r * breath,
        Paint()
          ..shader = RadialGradient(
            colors: [
              core.withValues(alpha: 0.16 * sky.sunLight),
              core.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: r * breath)),
      );
    }

    if (sky.moonShown && sky.moonLight > 0.02) {
      final m = sky.moonAt(size);
      final rr = sky.moonRadius(size) * (3.6 + 0.4 * math.sin(time * 0.6));
      canvas.drawCircle(
        m,
        rr,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sky.paleLight.withValues(alpha: 0.1 * sky.moonLight),
              sky.paleLight.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: m, radius: rr)),
      );
    }

    if (sky.stars > 0.02) {
      final rnd = _Seq(11);
      final count = (w * h / 520).clamp(24, 420).toInt();
      for (var i = 0; i < count; i++) {
        final p = Offset(
          rnd.next() * w,
          math.pow(rnd.next(), 1.4) * horizon * 0.95,
        );
        final kind = rnd.next();
        final fade = (1 - p.dy / horizon).clamp(0.0, 1.0);
        final base = sky.stars * fade * (0.35 + 0.65 * rnd.next());
        final pace = 0.4 + rnd.next() * 1.2;
        final offset = rnd.next() * math.pi * 2;
        final flare = math
            .pow(math.max(0, math.sin(time * 0.23 * pace + offset * 3)), 40)
            .toDouble();
        final a =
            (base * (0.7 + 0.3 * math.sin(time * pace + offset)) + flare * base)
                .clamp(0.0, 1.0);
        if (kind > 0.975 || flare > 0.3 && kind > 0.85) {
          final big = kind > 0.975 ? 1.0 : flare;
          canvas.drawCircle(
            p,
            4 * big + 3 * flare,
            Paint()..color = sky.paleLight.withValues(alpha: 0.18 * a),
          );
          final length =
              (4 + 1.5 * math.sin(time * pace * 0.7 + offset)) * big +
              5 * flare;
          final spark = Paint()
            ..strokeWidth = 0.7
            ..color = t.onChrome.withValues(alpha: 0.75 * a);
          canvas.drawLine(p - Offset(length, 0), p + Offset(length, 0), spark);
          canvas.drawLine(p - Offset(0, length), p + Offset(0, length), spark);
          canvas.drawCircle(
            p,
            1.4,
            Paint()..color = t.onChrome.withValues(alpha: a),
          );
        } else {
          canvas.drawCircle(
            p,
            kind > 0.82 ? 0.95 : 0.55,
            Paint()
              ..color = t.onChrome.withValues(
                alpha: (kind > 0.82 ? 0.8 : 0.5) * a,
              ),
          );
        }
      }
    }

    final dark = ((sky.stars - 0.3) / 0.4).clamp(0.0, 1.0);
    if (dark > 0) {
      final k = (time / meteorPeriod).floor();
      final local = time - k * meteorPeriod;
      final start = meteorStart(k);
      if (k > 0 && local >= start && local <= start + meteorLength) {
        final rnd = _Seq(97 + k * 31);
        final p = (local - start) / meteorLength;
        final travel = Curves.easeOutQuad.transform(p);
        final from = Offset(
          sky.x(size, 0.05 + rnd.next() * 0.4),
          horizon * (0.05 + rnd.next() * 0.3),
        );
        rnd.next();
        final dir = sky.rtl ? -1.0 : 1.0;
        final v = Offset(dir * 0.82, 0.57);
        final length = w * (0.38 + rnd.next() * 0.14);
        final head = from + v * length * travel;
        final tail = head - v * length * 0.5 * math.min(1, p * 2.5);
        final a = dark * math.sin(math.pi * p);
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              colors: [
                t.onChrome.withValues(alpha: 0),
                t.onChrome.withValues(alpha: 0.9 * a),
              ],
            ).createShader(Rect.fromPoints(tail, head)),
        );
        canvas.drawCircle(
          head,
          3.5,
          Paint()..color = sky.paleLight.withValues(alpha: 0.35 * a),
        );
        canvas.drawCircle(
          head,
          1.4,
          Paint()..color = t.onChrome.withValues(alpha: a),
        );
      }
    }

    final lit = math.max(sky.sunShown ? sky.low * sky.sunLight : 0.0, sky.dawn);
    final night = sky.stars > 0.6;
    final cloud = night
        ? Color.lerp(sky.top, Colors.black, 0.25)!
        : Color.lerp(
            Color.lerp(t.onChrome, sky.top, 0.35)!,
            sky.warmLight,
            lit,
          )!;
    final alpha = night ? 0.32 : 0.16 + 0.24 * lit;
    for (final (cx, cy, cw, ch, speed) in const [
      (0.22, 0.66, 0.34, 0.03, 1.6),
      (0.62, 0.74, 0.26, 0.026, 1.1),
      (0.78, 0.82, 0.3, 0.024, 2.0),
    ]) {
      final span = w * (1 + cw);
      final x = (w * cx + time * speed) % span - w * cw / 2;
      final c = Offset(x, horizon * cy);
      for (final (dx, dy, k) in const [
        (0.0, 0.0, 1.0),
        (-0.3, 0.6, 0.7),
        (0.32, 0.5, 0.6),
      ]) {
        final center = c + Offset(dx * w * cw * 0.5, dy * h * ch);
        final rx = w * cw * k / 2;
        final ry = h * ch * k * 0.9;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(rx / ry, 1);
        canvas.drawCircle(
          Offset.zero,
          ry,
          Paint()
            ..shader = RadialGradient(
              colors: [
                cloud.withValues(alpha: alpha),
                cloud.withValues(alpha: alpha * 0.4),
                cloud.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: ry)),
        );
        canvas.restore();
      }
    }

    final golden = math.max(
      sky.sunShown
          ? ((sky.low - 0.5) / 0.3).clamp(0.0, 1.0) * sky.sunLight
          : 0.0,
      ((sky.dawn - 0.4) / 0.4).clamp(0.0, 1.0),
    );
    if (golden > 0) {
      const period = 20.0, cross = 11.0;
      final k = (time / period).floor();
      final local = time - k * period - 3;
      if (k > 0 && local > 0 && local < cross) {
        final p = local / cross;
        final ink = Color.lerp(
          sky.bottom,
          Colors.black,
          0.65,
        )!.withValues(alpha: 0.75 * golden * math.sin(math.pi * p));
        final lead = Offset(
          sky.x(size, -0.05 + 1.1 * p),
          horizon * (0.5 + 0.06 * math.sin(p * math.pi * 2)),
        );
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = ink;
        for (final (i, (bx, by)) in const [
          (0.0, 0.0),
          (-14.0, 6.0),
          (-26.0, -3.0),
          (-9.0, -9.0),
        ].indexed) {
          final c = lead + Offset((sky.rtl ? -bx : bx), by);
          final flap = 2.5 * math.sin(time * 9 + i * 1.3);
          final wing = 4.5;
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - wing, c.dy - flap)
              ..quadraticBezierTo(c.dx - wing / 2, c.dy - 1, c.dx, c.dy + 1)
              ..quadraticBezierTo(
                c.dx + wing / 2,
                c.dy - 1,
                c.dx + wing,
                c.dy - flap,
              ),
            stroke,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LifePainter old) => !old.sky.same(sky);
}

class _FrontPainter extends CustomPainter {
  _FrontPainter(this.sky);

  final _Sky sky;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = sky.horizonOf(size);
    final t = sky.tokens;
    if (sky.moonShown && sky.moonLight > 0.01) {
      final m = sky.moonAt(size);
      final rr = sky.moonRadius(size);
      final a = sky.moonLight;
      canvas.drawCircle(
        m,
        rr * 4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sky.paleLight.withValues(alpha: 0.18 * a),
              sky.paleLight.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: m, radius: rr * 4)),
      );
      canvas.drawCircle(
        m,
        rr,
        Paint()..color = t.onChrome.withValues(alpha: 0.08 * a),
      );
      final lit = sky.rtl ? -1.0 : 1.0;
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: m, radius: rr)),
          Path()..addOval(
            Rect.fromCircle(
              center: m + Offset(lit * rr * 0.42, -rr * 0.28),
              radius: rr * 0.92,
            ),
          ),
        ),
        Paint()..color = t.onChrome.withValues(alpha: 0.95 * a),
      );
    }
    if (sky.dawn > 0.05) {
      final venus = Offset(sky.x(size, 0.22), horizon * 0.62);
      canvas.drawCircle(
        venus,
        6,
        Paint()..color = sky.paleLight.withValues(alpha: 0.25 * sky.dawn),
      );
      canvas.drawCircle(
        venus,
        1.8,
        Paint()..color = t.onChrome.withValues(alpha: sky.dawn),
      );
    }
    if (sky.sunShown) {
      final sun = sky.sunAt(size);
      final radius = sky.sunRadius(size);
      final core = Color.lerp(sky.paleLight, sky.warmLight, sky.low * 0.8)!;
      final glow = sky.sunLight;
      if (sky.low > 0.4 && glow > 0) {
        final haze = Rect.fromCenter(
          center: Offset(sun.dx, horizon),
          width: w * 1.1,
          height: h * 0.22,
        );
        canvas.drawOval(
          haze,
          Paint()
            ..shader = RadialGradient(
              colors: [
                core.withValues(alpha: 0.4 * sky.low * glow),
                core.withValues(alpha: 0),
              ],
            ).createShader(haze),
        );
      }
      for (final (k, a) in const [(7.0, 0.10), (3.4, 0.22), (1.8, 0.35)]) {
        canvas.drawCircle(
          sun,
          radius * k,
          Paint()
            ..shader = RadialGradient(
              colors: [
                core.withValues(alpha: a * glow),
                core.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: sun, radius: radius * k)),
        );
      }
      canvas.drawCircle(sun, radius, Paint()..color = core);
      canvas.drawCircle(
        sun,
        radius * 0.7,
        Paint()..color = Color.lerp(core, t.onChrome, 0.45)!,
      );
    }
    for (final (i, (rise, amp, freq, phase, dark)) in const [
      (0.0, 0.025, 2.2, 0.4, 0.22),
      (0.045, 0.03, 3.1, 1.7, 0.38),
      (0.1, 0.035, 1.6, 2.9, 0.55),
    ].indexed) {
      final ridge = Path()..moveTo(0, h);
      for (var x = 0; x <= 48; x++) {
        final u = x / 48;
        final y =
            horizon +
            h * rise -
            h *
                amp *
                (math.sin(u * math.pi * freq + phase) +
                    0.6 * math.sin(u * math.pi * freq * 2.3 + phase * 1.7));
        ridge.lineTo(w * u, y);
      }
      ridge
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        ridge,
        Paint()..color = Color.lerp(sky.bottom, Colors.black, dark)!,
      );
      final rim = math.max(
        sky.sunShown
            ? ((sky.low - 0.6) / 0.3).clamp(0.0, 1.0) * sky.sunLight
            : 0.0,
        ((sky.dawn - 0.3) / 0.4).clamp(0.0, 1.0),
      );
      if (i == 0 && rim > 0) {
        canvas.drawPath(
          ridge,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = sky.warmLight.withValues(alpha: 0.35 * rim),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrontPainter old) => !old.sky.same(sky);
}

class PrayerSky extends StatefulWidget {
  const PrayerSky({
    super.key,
    required this.times,
    required this.hour,
    this.animate = true,
    this.veil = false,
  });

  final PrayerSkyTimes times;
  final double hour;

  final bool animate;

  final bool veil;

  @visibleForTesting
  static void debugForgetHandoff() {
    _PrayerSkyState._handoffHour = null;
    _PrayerSkyState._handoffAt = null;
  }

  static const opening = Duration(milliseconds: 1400);
  static const replay = 2.0;

  @override
  State<PrayerSky> createState() => _PrayerSkyState();
}

class _PrayerSkyState extends State<PrayerSky>
    with SingleTickerProviderStateMixin {
  static double? _handoffHour;
  static DateTime? _handoffAt;

  late final Ticker _ticker = createTicker(_tick);
  final _phase = ValueNotifier<double>(0);
  double _reveal = 0;
  late double _shown = widget.hour;
  Duration _last = Duration.zero;
  Duration _lastFrame = Duration.zero;

  static const _frame = Duration(milliseconds: 42);

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastFrame).inMicroseconds / 1e6;
    _lastFrame = elapsed;
    var changed = false;
    if (_reveal < 1) {
      _reveal = (elapsed.inMicroseconds / PrayerSky.opening.inMicroseconds)
          .clamp(0.0, 1.0);
      changed = true;
    }
    final gap = widget.hour - _shown;
    if (gap.abs() > 1e-4) {
      _shown = gap.abs() > 12
          ? widget.hour
          : _shown + gap * math.min(1, dt * 2.4);
      changed = true;
    }
    if (changed) setState(() {});
    if (elapsed - _last >= _frame) {
      _last = elapsed;
      _phase.value = elapsed.inMicroseconds / 1e6;
    }
  }

  void _sync() {
    final still =
        !widget.animate ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled;
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _reveal = 1;
      _shown = widget.hour;
    }
    if (still) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _lastFrame = Duration.zero;
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void initState() {
    super.initState();
    final at = _handoffAt;
    final from = _handoffHour;
    var gap = from == null ? 24.0 : (widget.hour - from).abs() % 24;
    gap = math.min(gap, 24 - gap);
    if (widget.animate &&
        at != null &&
        gap < 3 &&
        DateTime.now().difference(at) < const Duration(seconds: 3)) {
      _reveal = 1;
      _shown = _handoffHour ?? widget.hour;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PrayerSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ticker.isActive) _shown = widget.hour;
  }

  @override
  void dispose() {
    if (widget.animate) {
      final eased = Curves.easeInOutCubic.transform(_reveal);
      _handoffHour = _shown - PrayerSky.replay * (1 - eased);
      _handoffAt = DateTime.now();
    }
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeInOutCubic.transform(_reveal);
    final sky = _Sky(
      tokens: context.tokens,
      red: Theme.of(context).colorScheme.error,
      times: widget.times,
      hour: _shown - PrayerSky.replay * (1 - eased),
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _BackPainter(sky))),
          RepaintBoundary(
            child: CustomPaint(painter: _LifePainter(sky, _phase)),
          ),
          RepaintBoundary(child: CustomPaint(painter: _FrontPainter(sky))),
          if (widget.veil)
            const RepaintBoundary(child: CustomPaint(painter: _VeilPainter())),
        ],
      ),
    );
  }
}

class PrayerSkyDisc extends StatelessWidget {
  const PrayerSkyDisc({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scope = PrayerSkyScope.maybeOf(context);
    final times = scope?.times ?? PrayerSkyTimes.fallback;
    final hour = scope?.hour ?? prayerSkyHour(DateTime.now());
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: PrayerSky(times: times, hour: hour, animate: false),
      ),
    );
  }
}

Offset prayerSkyDiscSun(BuildContext context, double size) {
  final scope = PrayerSkyScope.maybeOf(context);
  final sky = _Sky(
    tokens: context.tokens,
    red: Theme.of(context).colorScheme.error,
    times: scope?.times ?? PrayerSkyTimes.fallback,
    hour: scope?.hour ?? prayerSkyHour(DateTime.now()),
    rtl: Directionality.of(context) == TextDirection.rtl,
  );
  final s = Size.square(size);
  return sky.sunLight >= sky.moonLight ? sky.sunAt(s) : sky.moonAt(s);
}

class _VeilPainter extends CustomPainter {
  const _VeilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x47000000),
            Color(0x14000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x5C000000),
          ],
          stops: [0, 0.32, 0.5, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _VeilPainter old) => false;
}
