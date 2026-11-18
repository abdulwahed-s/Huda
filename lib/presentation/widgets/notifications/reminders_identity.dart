import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:intl/intl.dart' as intl;

/// Reminders' identity: the day dial, the whole day as a half disc carved in
/// stone on the page. A half disc on a double base rule, 24 long hour lines
/// fanning from the center to a rim band (numerals every third hour, midnight
/// at both ends), a gilt hand from the center to now meeting two notches on
/// the rim, the part of the day already gone washed in. Each reminder
/// that fires today is an enamel medallion carrying its own icon, hung from
/// its hour on the rim; the next one is lit and gilt-ringed, and the ones the
/// hand has passed go quiet. Random Athkar's rhythm is a row of dots on an
/// inner arc. Time runs in reading direction. See `design/IDENTITIES.md`.

/// One reminder on the dial: where it fires today, in hours (0–24).
@immutable
class ReminderMark {
  const ReminderMark(this.id, this.hour, this.icon, {this.next = false});

  final String id;
  final double hour;

  /// The reminder's own icon, the same as its row's.
  final IconData icon;

  /// The next one to fire: a larger, ringed stud.
  final bool next;
}

/// The day dial. As it first appears the hand sweeps from midnight to
/// [now]; when a mark's hour changes its stud slides along the rim, and a
/// new mark rises (the signature motion). Reduce motion: end states.
class RemindersDial extends StatefulWidget {
  const RemindersDial({
    super.key,
    required this.marks,
    required this.now,
    required this.semanticLabel,
    this.rhythmMinutes,
  });

  final List<ReminderMark> marks;

  /// The current time of day, in hours.
  final double now;

  /// Random Athkar's interval, when it's on.
  final int? rhythmMinutes;
  final String semanticLabel;

  @override
  State<RemindersDial> createState() => _RemindersDialState();
}

class _Stud {
  _Stud(this.hour, this.presence, this.icon, {this.next = false});

  double hour;
  double presence;
  IconData icon;
  bool next;
}

class _RemindersDialState extends State<RemindersDial>
    with TickerProviderStateMixin {
  /// The opening sweep: a short rest while the page fades in, then the
  /// hand runs from midnight to now (950 ms in all).
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  static const _sweepCurve = Interval(0.16, 1, curve: Curves.easeOutCubic);
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  /// Where each stud starts and ends in the current move.
  Map<String, _Stud> _from = {};
  Map<String, _Stud> _to = {};
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _to = {
      for (final m in widget.marks)
        m.id: _Stud(m.hour, 1, m.icon, next: m.next),
    };
    _from = _to;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final tokens = context.tokens;
    if (tokens.motion.of(context, tokens.motion.long) == Duration.zero) {
      _sweep.value = 1;
    } else {
      _sweep.forward();
    }
  }

  @override
  void didUpdateWidget(RemindersDial old) {
    super.didUpdateWidget(old);
    final next = {
      for (final m in widget.marks)
        m.id: _Stud(m.hour, 1, m.icon, next: m.next),
    };
    final changed =
        next.length != _to.length ||
        next.entries.any((e) {
          final was = _to[e.key];
          return was == null ||
              was.hour != e.value.hour ||
              was.next != e.value.next;
        });
    if (!changed) return;
    // Start from wherever the studs are now; gone ones sink in place.
    final now = _current();
    _from = {
      for (final id in {...now.keys, ...next.keys})
        id: now[id] ?? _Stud(next[id]!.hour, 0, next[id]!.icon),
    };
    _to = {
      for (final id in _from.keys)
        id: next[id] ?? _Stud(_from[id]!.hour, 0, _from[id]!.icon),
    };
    final tokens = context.tokens;
    if (tokens.motion.of(context, tokens.motion.long) == Duration.zero) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  Map<String, _Stud> _current() {
    final t = Curves.easeInOutCubic.transform(_move.value);
    return {
      for (final id in _to.keys)
        id: _Stud(
          _lerp(_from[id]?.hour ?? _to[id]!.hour, _to[id]!.hour, t),
          _lerp(_from[id]?.presence ?? 0, _to[id]!.presence, t),
          _to[id]!.icon,
          next: _to[id]!.next,
        ),
    };
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _sweep.dispose();
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final digits = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final numeralStyle = (theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0);
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: AspectRatio(
        aspectRatio: 2 / 1.08,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_sweep, _move]),
            builder: (context, _) => CustomPaint(
              painter: RemindersDialPainter(
                nowHour: widget.now * _sweepCurve.transform(_sweep.value),
                studs: [
                  for (final e in _current().entries)
                    if (e.value.presence > 0.01)
                      (
                        e.value.hour,
                        e.value.presence,
                        e.value.next,
                        e.value.icon,
                      ),
                ],
                rhythmMinutes: widget.rhythmMinutes,
                rtl: rtl,
                plate: Color.alphaBlend(
                  scheme.primary.withValues(alpha: dark ? 0.06 : 0.035),
                  scheme.surfaceContainerLow,
                ),
                line: scheme.outline,
                lineQuiet: scheme.outlineVariant,
                gilt: tokens.ornament,
                stud: scheme.primary,
                onStud: scheme.onPrimary,
                quiet: scheme.onSurfaceVariant,
                face: scheme.surface,
                wash: scheme.primary.withValues(alpha: dark ? 0.08 : 0.05),
                numerals: {
                  for (var h = 3; h <= 21; h += 3) h: digits.format(h),
                },
                numeralStyle: numeralStyle,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
                textDirection: Directionality.of(context),
                hairline: tokens.stroke.hairline,
                fine: tokens.stroke.fine,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the day dial. Hours map to a half turn: midnight at the
/// reading start, noon at the top, midnight again at the reading end.
class RemindersDialPainter extends CustomPainter {
  RemindersDialPainter({
    required this.nowHour,
    required this.studs,
    required this.rhythmMinutes,
    required this.rtl,
    required this.plate,
    required this.line,
    required this.lineQuiet,
    required this.gilt,
    required this.stud,
    required this.onStud,
    required this.quiet,
    required this.face,
    required this.wash,
    required this.numerals,
    required this.numeralStyle,
    required this.textScaler,
    required this.textDirection,
    required this.hairline,
    required this.fine,
  });

  final double nowHour;

  /// (hour, presence 0–1, next, icon).
  final List<(double, double, bool, IconData)> studs;
  final int? rhythmMinutes;
  final bool rtl;
  final Color plate;
  final Color line;
  final Color lineQuiet;
  final Color gilt;
  final Color stud;

  /// The icon on the lit (next) medallion.
  final Color onStud;

  /// Passed medallions' ring and icon: quiet, still readable (about 3:1).
  final Color quiet;

  /// The medallions' enamel.
  final Color face;

  /// The part of the day already gone.
  final Color wash;
  final Map<int, String> numerals;
  final TextStyle numeralStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final double hairline;
  final double fine;

  double _angle(double hour) {
    final t = (hour / 24).clamp(0.0, 1.0);
    return rtl ? math.pi * t : math.pi * (1 - t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height * 0.07;
    final r = math.min(size.width / 2 - 2, size.height - base - 2);
    if (r <= 0) return;
    final c = Offset(size.width / 2, size.height - base);
    Offset at(double hour, double radius) {
      final a = _angle(hour);
      return c + Offset(math.cos(a), -math.sin(a)) * radius;
    }

    final rimInner = r * 0.84;
    final foot = r * 0.15;

    // The plate.
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r, c.dy)
        ..arcTo(disc, math.pi, math.pi, false)
        ..close(),
      Paint()..color = plate,
    );

    // The part of the day already gone, washed in up to the hand.
    if (nowHour > 0) {
      final start = -_angle(0);
      final sweep = _angle(0) - _angle(nowHour);
      canvas.drawPath(
        Path()
          ..arcTo(
            Rect.fromCircle(center: c, radius: rimInner),
            start,
            sweep,
            true,
          )
          ..arcTo(
            Rect.fromCircle(center: c, radius: foot),
            start + sweep,
            -sweep,
            false,
          )
          ..close(),
        Paint()..color = wash,
      );
    }

    // The rim: a fine outer arc, a hairline inner arc holding the numerals.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      disc,
      math.pi,
      math.pi,
      false,
      stroke
        ..color = gilt
        ..strokeWidth = fine,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rimInner),
      math.pi,
      math.pi,
      false,
      stroke
        ..color = line.withValues(alpha: 0.7)
        ..strokeWidth = hairline,
    );

    // The double base rule (the east–west line).
    canvas.drawLine(
      Offset(c.dx - r, c.dy),
      Offset(c.dx + r, c.dy),
      stroke
        ..color = gilt
        ..strokeWidth = fine,
    );
    canvas.drawLine(
      Offset(c.dx - r * 0.96, c.dy + base * 0.5),
      Offset(c.dx + r * 0.96, c.dy + base * 0.5),
      stroke
        ..color = gilt.withValues(alpha: 0.5)
        ..strokeWidth = hairline,
    );

    // Hour lines: long lines from the center, every third stronger.
    for (var h = 0; h <= 24; h++) {
      final major = h % 3 == 0;
      canvas.drawLine(
        at(h.toDouble(), foot),
        at(h.toDouble(), rimInner),
        stroke
          ..color = major ? line : lineQuiet
          ..strokeWidth = major ? fine : hairline,
      );
    }

    // Numerals in the rim band.
    final band = (r + rimInner) / 2;
    for (final entry in numerals.entries) {
      final painter = TextPainter(
        text: TextSpan(text: entry.value, style: numeralStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final p = at(entry.key.toDouble(), band);
      // Too large for the band (big text on a small dial): leave it out.
      if (painter.height > (r - rimInner) * 1.25) continue;
      painter.paint(canvas, p - Offset(painter.width / 2, painter.height / 2));
    }

    // Random Athkar's rhythm: dots on an inner arc.
    final rhythm = rhythmMinutes;
    if (rhythm != null && rhythm > 0) {
      final step = math.max(rhythm, 20) / 60;
      final dot = Paint()..color = stud.withValues(alpha: 0.45);
      for (var h = step; h < 24; h += step) {
        canvas.drawCircle(at(h, r * 0.31), r * 0.011 + 0.6, dot);
      }
    }

    // Now, read on the rim: two short gilt notches at the band's edges,
    // leaving the numerals between them clear.
    final notch = (r - rimInner) * 0.28;
    for (final (from, to) in [(rimInner, rimInner + notch), (r - notch, r)]) {
      canvas.drawLine(
        at(nowHour, from),
        at(nowHour, to),
        stroke
          ..color = gilt
          ..strokeWidth = fine * 1.8,
      );
    }

    // Reminders: enamel medallions with their icons, each hung from its hour
    // on the rim. Close neighbours alternate between two rings so they never
    // touch; the ones the hand has passed go quiet.
    final m = r * 0.078 + 2.5;
    final ordered = [...studs]..sort((x, y) => x.$1.compareTo(y.$1));
    var lastHour = -24.0;
    var lastInner = true;
    for (final (hour, presence, next, icon) in ordered) {
      final inner = hour - lastHour < 2.6 && !lastInner;
      lastHour = hour;
      lastInner = inner;
      final ring = inner ? r * 0.49 : r * 0.70;
      // 0 ahead of the hand, 1 once it has passed (eased across ~15 min).
      final done = next ? 0.0 : ((nowHour - hour) * 4).clamp(0.0, 1.0);
      final tone = Color.lerp(stud, quiet, done)!;
      canvas.drawLine(
        at(hour, ring + m),
        at(hour, rimInner),
        stroke
          ..color = tone.withValues(alpha: (0.7 - 0.25 * done) * presence)
          ..strokeWidth = fine,
      );
      final p = at(hour, ring);
      final size = m * (0.7 + 0.3 * presence);
      if (next) {
        canvas.drawCircle(
          p,
          size + r * 0.024,
          stroke
            ..color = gilt.withValues(alpha: presence)
            ..strokeWidth = fine,
        );
      }
      canvas.drawCircle(
        p,
        size,
        Paint()
          ..color = (next ? stud : Color.lerp(face, plate, done)!).withValues(
            alpha: presence,
          ),
      );
      if (!next) {
        canvas.drawCircle(
          p,
          size,
          stroke
            ..color = tone.withValues(alpha: (0.9 - 0.2 * done) * presence)
            ..strokeWidth = fine,
        );
      }
      final glyph = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: size * 1.12,
            height: 1,
            color: (next ? onStud : tone).withValues(
              alpha: (1 - 0.15 * done) * presence,
            ),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glyph.paint(canvas, p - Offset(glyph.width / 2, glyph.height / 2));
    }

    // The hand: a gilt needle from the boss to now, on top of everything,
    // meeting the notches on the rim.
    final a = _angle(nowHour);
    final dir = Offset(math.cos(a), -math.sin(a));
    final normal = Offset(-dir.dy, dir.dx);
    final tip = c + dir * (rimInner - 1);
    final waist = r * 0.026;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + normal.dx * waist, c.dy + normal.dy * waist)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(c.dx - normal.dx * waist, c.dy - normal.dy * waist)
        ..close(),
      Paint()..color = gilt,
    );
    final boss = Rect.fromCircle(center: c, radius: r * 0.07);
    final half = Path()
      ..moveTo(c.dx - r * 0.07, c.dy)
      ..arcTo(boss, math.pi, math.pi, false)
      ..close();
    canvas.drawPath(half, Paint()..color = plate);
    canvas.drawPath(
      half,
      stroke
        ..color = gilt
        ..strokeWidth = fine,
    );
    canvas.drawCircle(c, r * 0.022, Paint()..color = gilt);
  }

  @override
  bool shouldRepaint(RemindersDialPainter old) =>
      old.nowHour != nowHour ||
      old.studs.length != studs.length ||
      !_sameStuds(old.studs, studs) ||
      old.rhythmMinutes != rhythmMinutes ||
      old.rtl != rtl ||
      old.plate != plate ||
      old.line != line ||
      old.gilt != gilt ||
      old.stud != stud ||
      old.quiet != quiet ||
      old.face != face ||
      old.wash != wash ||
      old.numeralStyle != numeralStyle ||
      old.textScaler != textScaler;

  static bool _sameStuds(
    List<(double, double, bool, IconData)> a,
    List<(double, double, bool, IconData)> b,
  ) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
