import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Quran Audio's identity: the arabesque vine (islimi). A stem runs in a
/// gentle wave; from every crest a tendril springs into the hollow beside
/// it and curls into a spiral that ends in a leaf, so the scroll
/// alternates coil above, coil below. A recitation's vine has two ends;
/// the radio's runs off both edges. The vine grows in from its start (the
/// signature motion). Owner round 1 (2026-11-04) chose it over the first
/// run's waveform. See `design/IDENTITIES.md`.
final FeatureIdentity quranAudioIdentity = FeatureIdentity(
  id: 'quran-audio',
  motif: 'The arabesque vine: a waving stem whose tendrils curl into coils',
  count: 2,
  rhythm: IdentityRhythm.band,
  material: IdentityMaterial.brass,
  headerArt: (style) => ArabesqueVinePainter(style: style, coils: 2),
  emptyArt: (style) => ArabesqueVinePainter(style: style, coils: 2),
);

/// The radio's art: the vine running off both edges, as a broadcast has
/// no ends.
final FeatureIdentity quranRadioIdentity = FeatureIdentity(
  id: 'quran-audio',
  motif: 'The open vine: the scroll runs off both edges',
  count: 3,
  rhythm: IdentityRhythm.band,
  material: IdentityMaterial.brass,
  headerArt: (style) =>
      ArabesqueVinePainter(style: style, coils: 3, open: true),
  emptyArt: (style) => ArabesqueVinePainter(style: style, coils: 3, open: true),
);

/// Draws the vine across its box: [coils] half-waves of the stem (or as
/// many as keep each coil about as wide as the band is tall), a spiral
/// tendril in the hollow beside each crest with a leaf at its heart, and a
/// bud where the stem crosses its middle. [grow] (0–1), or [growth]
/// without rebuilding, draws it in from its start. [open] runs it off both
/// edges, faded there. Mirrors in RTL.
class ArabesqueVinePainter extends CustomPainter {
  ArabesqueVinePainter({
    required this.style,
    this.coils,
    this.open = false,
    this.grow = 1,
    this.growth,
    this.leadingSpace = 0,
    this.textDirection = TextDirection.ltr,
  }) : super(repaint: growth);

  final OrnamentStyle style;

  /// Half-waves across the box; null fits them to the box's shape.
  final int? coils;
  final bool open;
  final double grow;
  final Animation<double>? growth;

  /// The share of the box left empty at the start, where a landing
  /// header's title may reach into its art slot.
  final double leadingSpace;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (textDirection == TextDirection.rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final box = Rect.fromLTRB(
      size.width * leadingSpace,
      0,
      size.width,
      size.height,
    );
    final g = (growth?.value ?? grow).clamp(0.0, 1.0);
    if (g <= 0) return;
    canvas.save();
    // Growing from the start; once grown, nothing is clipped.
    final pad = style.stroke * 4;
    canvas.clipRect(
      Rect.fromLTRB(
        box.left - pad,
        0,
        box.left - pad + (box.width + pad * 2) * g,
        size.height,
      ),
    );
    _paintVine(canvas, box);
    canvas.restore();
  }

  void _paintVine(Canvas canvas, Rect area) {
    var box = area;
    // A closed vine ends in a leaf at each end: keep room for them.
    final tip = open ? 0.0 : box.height * 0.22;
    box = Rect.fromLTRB(box.left + tip, box.top, box.right - tip, box.bottom);
    final n = coils ?? math.max(2, (box.width / (box.height * 1.5)).round());
    // A coil keeps its shape however wide the box is.
    final half = math.min(box.width / n, box.height * 1.6);
    final total = half * n;
    final left = box.left + (box.width - total) / 2;
    final cy = box.center.dy;
    final amp = math.min(box.height * 0.3, half * 0.34);
    final r = math.min(half * 0.32, amp * 0.92);
    final stroke = style.stroke;
    final from = open ? -1 : 0;
    final to = open ? n : n - 1;

    for (var i = from; i <= to; i++) {
      final x0 = left + i * half;
      final x1 = x0 + half;
      final xm = (x0 + x1) / 2;
      // Faded toward the edges when it runs on past them.
      final fade = open
          ? (math.min(xm - box.left, box.right - xm) / (half * 0.7)).clamp(
              0.0,
              1.0,
            )
          : 1.0;
      if (fade <= 0) continue;
      final color = style.color.withValues(alpha: style.color.a * fade);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      final leafFill = Paint()..color = color.withValues(alpha: color.a * 0.35);

      // The stem: up over even half-waves, down over odd ones (s is the
      // crest's side: -1 above the middle, 1 below).
      final s = i.isEven ? -1.0 : 1.0;
      final k = half * 0.36;
      final lift = amp * 1.33;
      final a = Offset(x0, cy);
      final b = Offset(x0 + k, cy + s * lift);
      final c = Offset(x1 - k, cy + s * lift);
      final d = Offset(x1, cy);
      final stem = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(b.dx, b.dy, c.dx, c.dy, d.dx, d.dy);

      // The tendril leaves the stem just past the crest and carries on
      // forward, then curls back into the hollow under (or over) the
      // crest, turning inward.
      final center = Offset(xm + half * 0.02, cy - s * amp * 0.3);
      const turns = 1.85 * math.pi;
      const steps = 48;
      final spiral = <Offset>[
        for (var j = 0; j <= steps; j++)
          () {
            final t = j / steps;
            final theta = t * turns;
            final rr = r * (1 - 0.78 * t);
            return center +
                Offset(math.cos(theta) * rr, -s * math.sin(theta) * rr);
          }(),
      ];
      final branch = _cubicPoint(a, b, c, d, 0.6);
      final along = _cubicPoint(a, b, c, d, 0.64) - branch;
      final start = spiral.first;
      final tendril = Path()
        ..moveTo(branch.dx, branch.dy)
        ..cubicTo(
          branch.dx + along.dx * 2.2,
          branch.dy + along.dy * 2.2,
          start.dx,
          start.dy + s * r * 0.9,
          start.dx,
          start.dy,
        );
      for (final p in spiral.skip(1)) {
        tendril.lineTo(p.dx, p.dy);
      }

      // A leaf at the spiral's heart, along its last turn.
      final end = spiral.last;
      final heart = _leaf(end, end - spiral[spiral.length - 6], r * 0.7);

      // A bud where the stem crosses the middle, on the crest's side.
      final bud = _leaf(d, Offset(half * 0.18, s * amp), r * 0.55);

      canvas
        ..drawPath(stem, line)
        ..drawPath(tendril, line);
      // The ends of a closed vine finish in a leaf along the stem.
      if (!open && i == 0) {
        final first = _leaf(a, a - b, tip * 1.1);
        canvas
          ..drawPath(first, leafFill)
          ..drawPath(first, line);
      }
      if (!open && i == to) {
        final last = _leaf(d, d - c, tip * 1.1);
        canvas
          ..drawPath(last, leafFill)
          ..drawPath(last, line);
      }
      canvas
        ..drawPath(heart, leafFill)
        ..drawPath(heart, line);
      if (i < to || open) {
        canvas
          ..drawPath(bud, leafFill)
          ..drawPath(bud, line);
      }
    }
  }

  /// A pointed leaf of [length] from [base] along [dir].
  static Path _leaf(Offset base, Offset dir, double length) {
    final u = dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
    final n = Offset(-u.dy, u.dx);
    final tip = base + u * length;
    final w = length * 0.42;
    final mid = base + u * (length * 0.42);
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + n.dx * w, mid.dy + n.dy * w, tip.dx, tip.dy)
      ..quadraticBezierTo(
        mid.dx - n.dx * w,
        mid.dy - n.dy * w,
        base.dx,
        base.dy,
      )
      ..close();
  }

  static Offset _cubicPoint(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  @override
  bool shouldRepaint(ArabesqueVinePainter old) =>
      old.style != style ||
      old.coils != coils ||
      old.open != open ||
      old.grow != grow ||
      old.growth != growth ||
      old.leadingSpace != leadingSpace ||
      old.textDirection != textDirection;
}

/// A single curl of the vine: a tendril coiling in to a leaf. Marks the
/// surah or station that's sounding; while [playing] (live state only) it
/// turns slowly, and rests when paused.
class QuranVoiceGlyph extends StatefulWidget {
  const QuranVoiceGlyph({
    super.key,
    required this.playing,
    this.size = 24,
    this.color,
  });

  final bool playing;
  final double size;
  final Color? color;

  @override
  State<QuranVoiceGlyph> createState() => _QuranVoiceGlyphState();
}

class _QuranVoiceGlyphState extends State<QuranVoiceGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(QuranVoiceGlyph old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.playing && !still) {
      if (!_turn.isAnimating) _turn.repeat();
    } else {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: RotationTransition(
          turns: _turn,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _CurlPainter(
              color: color,
              stroke: context.tokens.stroke.fine,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurlPainter extends CustomPainter {
  const _CurlPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke;
    const steps = 40;
    const turns = 1.6 * 2 * math.pi;
    final points = [
      for (var j = 0; j <= steps; j++)
        () {
          final t = j / steps;
          final theta = math.pi + t * turns;
          final rr = r * (1 - 0.78 * t);
          return c + Offset(math.cos(theta) * rr, math.sin(theta) * rr);
        }(),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final end = points.last;
    final leaf = ArabesqueVinePainter._leaf(
      end,
      end - points[points.length - 5],
      r * 0.6,
    );
    canvas.drawPath(leaf, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CurlPainter old) =>
      old.color != color || old.stroke != stroke;
}
