import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Checklist's voice: the inlaid star. A seven-pointed star set like
/// marquetry, each point a kite of two inlaid halves around a heptagon
/// heart, gilt fillets between the pieces. The day's progress fills the
/// points in turn; the heart sets when every item is done. See
/// `design/IDENTITIES.md`.
final FeatureIdentity checklistIdentity = FeatureIdentity(
  id: 'checklist',
  motif: 'An inlaid seven-pointed star whose points fill as the day is done',
  count: 7,
  rhythm: IdentityRhythm.radial,
  material: IdentityMaterial.stone,
  headerArt: (style) => ChecklistStarPainter.outline(style: style),
);

/// The star's colors, from the scheme: the deep half of each point in
/// `primary`, the light half in a tint of it, gilt fillets and heart.
@immutable
class ChecklistInlay {
  const ChecklistInlay({
    required this.deep,
    required this.light,
    required this.fillet,
    required this.open,
    required this.heart,
    required this.glint,
  });

  factory ChecklistInlay.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ChecklistInlay(
      deep: scheme.primary,
      light: Color.alphaBlend(
        scheme.primary.withValues(alpha: dark ? 0.26 : 0.30),
        scheme.surface,
      ),
      fillet: tokens.ornament,
      open: tokens.ornament.withValues(alpha: dark ? 0.55 : 0.5),
      heart: tokens.ornament,
      glint: Colors.white.withValues(alpha: dark ? 0.55 : 0.7),
    );
  }

  final Color deep;
  final Color light;
  final Color fillet;
  final Color open;
  final Color heart;
  final Color glint;
}

/// The geometry of the inlaid star, shared by the large star and the
/// path's small ones.
class _Star {
  _Star(this.center, this.radius, {required this.clockwise});

  final Offset center;
  final double radius;
  final bool clockwise;

  static const points = 7;
  static const innerRatio = 0.56;
  static const heartRatio = 0.34;

  double get inner => radius * innerRatio;
  double get heart => radius * heartRatio;

  /// The axis of point [i], starting at the top, in reading direction.
  double angle(int i) =>
      -math.pi / 2 + (clockwise ? 1 : -1) * i * 2 * math.pi / points;

  Offset at(double angle, double r) =>
      center + Offset(math.cos(angle) * r, math.sin(angle) * r);

  Path outline() {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final a = angle(i);
      final tip = at(a, radius);
      final next = at(a + math.pi / points, inner);
      i == 0 ? path.moveTo(tip.dx, tip.dy) : path.lineTo(tip.dx, tip.dy);
      path.lineTo(next.dx, next.dy);
    }
    return path..close();
  }

  Path heartPath([double scale = 1]) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final p = at(angle(i), heart * scale);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// The two halves of point [i]'s kite: the one before its axis and the
  /// one after it.
  (Path, Path) halves(int i) {
    final a = angle(i);
    final tip = at(a, radius);
    final base = at(a, heart);
    final before = at(a - math.pi / points, inner);
    final after = at(a + math.pi / points, inner);
    return (
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(before.dx, before.dy)
        ..lineTo(base.dx, base.dy)
        ..close(),
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx, base.dy)
        ..lineTo(after.dx, after.dy)
        ..close(),
    );
  }

  /// Clips to the part of point [i] from its base out to [fill] (0 to 1)
  /// of its length.
  void clipPoint(Canvas canvas, int i, double fill) {
    final a = angle(i);
    canvas
      ..translate(center.dx, center.dy)
      ..rotate(a + math.pi / 2)
      ..clipRect(
        Rect.fromLTRB(
          -radius,
          -(heart + (radius - heart) * fill) - 0.5,
          radius,
          radius,
        ),
      )
      ..rotate(-(a + math.pi / 2))
      ..translate(-center.dx, -center.dy);
  }
}

/// Paints the inlaid star at [progress] (0 to 1 of the day's items): the
/// points fill in turn, each from its base to its tip; [heart] (0 to 1)
/// sets the heptagon at the center; [glint] (0 to 1) runs one band of
/// light across the star.
class ChecklistStarPainter extends CustomPainter {
  const ChecklistStarPainter({
    required this.inlay,
    required this.progress,
    this.heart = 0,
    this.glint = 0,
    this.textDirection = TextDirection.ltr,
    this.fillets = true,
  }) : _style = null;

  /// The empty star in an ornament style (state art).
  const ChecklistStarPainter.outline({required OrnamentStyle style})
    : _style = style,
      inlay = null,
      progress = 0,
      heart = 0,
      glint = 0,
      textDirection = TextDirection.ltr,
      fillets = true;

  final ChecklistInlay? inlay;
  final OrnamentStyle? _style;
  final double progress;
  final double heart;
  final double glint;
  final TextDirection textDirection;

  /// Draws the gilt fillets and open outlines. Small stars (the path) set
  /// without them, as solid two-tone pieces, so they don't blur to gilt.
  final bool fillets;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - (fillets ? 2 : 0.5);
    if (r <= 0) return;
    final star = _Star(
      size.center(Offset.zero),
      r,
      clockwise: textDirection == TextDirection.ltr,
    );
    final style = _style;
    if (style != null) {
      style.draw(canvas, star.outline());
      style.draw(canvas, star.heartPath());
      for (var i = 0; i < _Star.points; i++) {
        final (before, _) = star.halves(i);
        style.draw(canvas, before);
      }
      return;
    }
    final inlay = this.inlay!;
    final fine = math.max(1.1, r / 48);
    final fillet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fine
      ..strokeJoin = StrokeJoin.round
      ..color = inlay.fillet;
    final open = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fine
      ..strokeJoin = StrokeJoin.round
      ..color = inlay.open;

    // The ground: the star's body is one quiet inlaid piece, and the
    // shoulders between the points are set from the start, so the star
    // reads whole while its points are still open.
    canvas.drawPath(
      star.outline(),
      Paint()
        ..color = fillets
            ? inlay.fillet.withValues(alpha: 0.07)
            : inlay.light.withValues(alpha: inlay.light.a * 0.45),
    );
    final shoulder = Paint()
      ..color = fillets
          ? inlay.fillet.withValues(alpha: 0.16)
          : inlay.light.withValues(alpha: inlay.light.a * 0.8);
    for (var i = 0; i < _Star.points; i++) {
      final a = star.angle(i);
      final b = star.angle(i + 1);
      final p = Path()
        ..moveTo(star.at(a, star.heart).dx, star.at(a, star.heart).dy)
        ..lineTo(
          star.at(a + (b - a) / 2, star.inner).dx,
          star.at(a + (b - a) / 2, star.inner).dy,
        )
        ..lineTo(star.at(b, star.heart).dx, star.at(b, star.heart).dy)
        ..close();
      canvas.drawPath(p, shoulder);
      if (fillets) canvas.drawPath(p, open);
    }

    final filled = progress.clamp(0.0, 1.0) * _Star.points;
    for (var i = 0; i < _Star.points; i++) {
      final fill = (filled - i).clamp(0.0, 1.0);
      final (before, after) = star.halves(i);
      if (fill > 0) {
        canvas.save();
        star.clipPoint(canvas, i, fill);
        canvas
          ..drawPath(before, Paint()..color = inlay.deep)
          ..drawPath(after, Paint()..color = inlay.light);
        canvas.restore();
      }
      // The fillets: gilt where the piece is set, engraved where it's open.
      if (fillets) {
        canvas
          ..drawPath(before, fill >= 1 ? fillet : open)
          ..drawPath(after, fill >= 1 ? fillet : open);
      }
    }

    // The heart: open until the day is done, then it sets from the center.
    if (fillets) {
      canvas.drawPath(star.heartPath(), heart >= 1 ? fillet : open);
    }
    if (heart > 0 && !fillets) {
      canvas.drawPath(star.heartPath(), Paint()..color = inlay.deep);
    } else if (heart > 0) {
      final scale = Curves.easeOutBack.transform(heart.clamp(0.0, 1.0));
      canvas.drawPath(star.heartPath(scale), Paint()..color = inlay.heart);
      final seal = _Star(
        star.center,
        star.heart * 0.62 * scale,
        clockwise: star.clockwise,
      );
      canvas.drawPath(
        seal.outline(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fine
          ..color = inlay.deep.withValues(alpha: 0.85),
      );
    }

    // One glint across the set star, in reading direction.
    if (glint > 0 && glint < 1) {
      final rect = Rect.fromCircle(center: star.center, radius: r);
      final t = Curves.easeInOut.transform(glint);
      final x = rect.left - r + t * (rect.width + 2 * r);
      final band = r * 0.5;
      final ltr = textDirection == TextDirection.ltr;
      final from = ltr ? x - band : rect.right - (x - rect.left) + band;
      final to = ltr ? x + band : rect.right - (x - rect.left) - band;
      canvas.save();
      canvas.clipPath(star.outline());
      canvas.drawRect(
        rect,
        Paint()
          ..shader =
              LinearGradient(
                colors: [
                  inlay.glint.withValues(alpha: 0),
                  inlay.glint,
                  inlay.glint.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromLTRB(
                  math.min(from, to),
                  rect.top,
                  math.max(from, to),
                  rect.bottom,
                ),
              ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ChecklistStarPainter old) =>
      old.progress != progress ||
      old.heart != heart ||
      old.glint != glint ||
      old.textDirection != textDirection ||
      old._style?.color != _style?.color ||
      old.inlay?.deep != inlay?.deep ||
      old.inlay?.fillet != inlay?.fillet;
}

/// The streak as a straight row of small inlaid stars on one gilt fillet,
/// ending at today's: [past] stars set for the days already in the run,
/// then today's, set as far as [today] (0 to 1). Longer runs fade in from
/// the leading edge.
class ChecklistPathPainter extends CustomPainter {
  const ChecklistPathPainter({
    required this.inlay,
    required this.past,
    required this.today,
    required this.slots,
    this.textDirection = TextDirection.ltr,
  });

  final ChecklistInlay inlay;
  final int past;
  final double today;

  /// How many stars fit; the row shows the last [slots] days of the run.
  final int slots;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (slots <= 0) return;
    final pitch = size.width / slots;
    final r = math.min(size.height / 2, pitch / 2) - 1.5;
    if (r <= 0) return;
    final ltr = textDirection == TextDirection.ltr;
    double x(int slot) =>
        ltr ? pitch * (slot + 0.5) : size.width - pitch * (slot + 0.5);
    final y = size.height / 2;
    final shown = math.min(past, slots - 1);
    final first = slots - 1 - shown;

    // The fillet the stars sit on, from the first star of the run.
    final line = Paint()
      ..strokeWidth = 1
      ..color = inlay.open.withValues(alpha: inlay.open.a * 0.7);
    for (var slot = first; slot < slots - 1; slot++) {
      final dir = ltr ? 1 : -1;
      canvas.drawLine(
        Offset(x(slot) + dir * (r + 3), y),
        Offset(x(slot + 1) - dir * (r + 3), y),
        line,
      );
    }

    for (var slot = first; slot < slots; slot++) {
      final isToday = slot == slots - 1;
      // The oldest shown star fades when the run is longer than the row.
      final faded = !isToday && slot == first && past > shown;
      final star = ChecklistStarPainter(
        inlay: faded
            ? ChecklistInlay(
                deep: inlay.deep.withValues(alpha: 0.4),
                light: inlay.light.withValues(alpha: 0.4),
                fillet: inlay.fillet.withValues(alpha: 0.4),
                open: inlay.open,
                heart: inlay.heart,
                glint: inlay.glint,
              )
            : inlay,
        progress: isToday ? today : 1,
        heart: isToday ? (today >= 1 ? 1 : 0) : 1,
        textDirection: textDirection,
        fillets: false,
      );
      canvas.save();
      canvas.translate(x(slot) - r - 2, y - r - 2);
      star.paint(canvas, Size.square(2 * r + 4));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ChecklistPathPainter old) =>
      old.past != past ||
      old.today != today ||
      old.slots != slots ||
      old.inlay.deep != inlay.deep ||
      old.textDirection != textDirection;
}

/// The celebration when the day completes, around the star: a soft pool
/// of gilt light swells behind it and fades ([behind]); in front, seven
/// inlaid lozenges fly out from the points' tips, turning as they go,
/// with seven gilt motes from the shoulders a beat later, all fading as
/// they land ([behind] false). [t] runs 0 to 1 once.
class ChecklistBurstPainter extends CustomPainter {
  const ChecklistBurstPainter({
    required this.inlay,
    required this.t,
    required this.behind,
    this.textDirection = TextDirection.ltr,
  });

  final ChecklistInlay inlay;
  final double t;
  final bool behind;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final star = _Star(
      center,
      r,
      clockwise: textDirection == TextDirection.ltr,
    );
    if (behind) {
      // Swells over the first third, then fades slowly.
      final swell = t < 0.3
          ? Curves.easeOut.transform(t / 0.3)
          : 1 - Curves.easeIn.transform((t - 0.3) / 0.7);
      final radius = r * (1.05 + 0.35 * Curves.easeOut.transform(t));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              inlay.fillet.withValues(alpha: 0.32 * swell),
              inlay.fillet.withValues(alpha: 0.12 * swell),
              inlay.fillet.withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      return;
    }

    void lozenge(Offset at, double angle, double length, Color color) {
      final w = length * 0.45;
      canvas.save();
      canvas
        ..translate(at.dx, at.dy)
        ..rotate(angle);
      final path = Path()
        ..moveTo(0, -length / 2)
        ..lineTo(w / 2, 0)
        ..lineTo(0, length / 2)
        ..lineTo(-w / 2, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }

    // The tips' lozenges: out from the point, turning a quarter, fading.
    final out = Curves.easeOutCubic.transform(t);
    final fade = math.pow(1 - t, 1.4).toDouble();
    for (var i = 0; i < _Star.points; i++) {
      final a = star.angle(i);
      final at = star.at(a, r * (1.02 + 0.42 * out));
      final turn = (star.clockwise ? 1 : -1) * out * math.pi / 2;
      lozenge(
        at,
        a + math.pi / 2 + turn,
        r * 0.2 * (1 - 0.35 * t),
        (i.isEven ? inlay.deep : inlay.fillet).withValues(alpha: fade),
      );
    }
    // The shoulders' motes follow a beat later.
    final late = ((t - 0.12) / 0.88).clamp(0.0, 1.0);
    if (late <= 0) return;
    final lateOut = Curves.easeOutCubic.transform(late);
    final lateFade = math.pow(1 - late, 1.2).toDouble();
    for (var i = 0; i < _Star.points; i++) {
      final a = star.angle(i) + (star.clockwise ? 1 : -1) * math.pi / 7;
      final at = star.at(a, r * (0.62 + 0.62 * lateOut));
      canvas.drawCircle(
        at,
        r * 0.035 * (1 - 0.4 * late) + 0.8,
        Paint()..color = inlay.fillet.withValues(alpha: lateFade),
      );
    }
  }

  @override
  bool shouldRepaint(ChecklistBurstPainter old) =>
      old.t != t ||
      old.behind != behind ||
      old.inlay.deep != inlay.deep ||
      old.textDirection != textDirection;
}

/// The inlaid frame inside the day card: a stringing of small lozenges,
/// alternating deep and gilt, between two gilt fillets, running round all
/// four sides; at each corner a square block holding a twisted knot (two
/// interlaced loops, over and under), where the bands meet like the
/// corner pieces of a marquetry panel.
class ChecklistInlayFramePainter extends CustomPainter {
  const ChecklistInlayFramePainter({
    required this.inlay,
    this.inset = 6,
    this.band = 10,
    this.radius = 10,
  });

  final ChecklistInlay inlay;

  /// From the card's edge to the frame's outer fillet.
  final double inset;

  /// The band's width between its fillets.
  final double band;

  /// The outer corner's rounding.
  final double radius;

  /// How far the content must stay from the card's edge.
  static double clearance({double inset = 6, double band = 10}) =>
      inset + band + 1;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = (Offset.zero & size).deflate(inset);
    if (outer.width < band * 6 || outer.height < band * 6) return;
    final inner = outer.deflate(band);
    final fillet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = inlay.fillet.withValues(alpha: 0.7);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(outer, Radius.circular(radius)), fillet)
      ..drawRect(inner, fillet);

    final deep = Paint()..color = inlay.deep.withValues(alpha: 0.78);
    final gilt = Paint()..color = inlay.fillet.withValues(alpha: 0.72);
    // The corner blocks are a little larger than the band.
    final block = band + 6;

    // One run of lozenges between two corner blocks, along [from] → [to].
    void run(Offset from, Offset to) {
      final length = (to - from).distance;
      final dir = (to - from) / length;
      final normal = Offset(-dir.dy, dir.dx);
      final pitch = band * 1.5;
      final count = (length / pitch).floor();
      if (count <= 0) return;
      final start = (length - count * pitch) / 2;
      for (var i = 0; i < count; i++) {
        final c = from + dir * (start + pitch * (i + 0.5));
        final half = pitch / 2 - 1;
        final w = band / 2 - 2;
        final path = Path()
          ..moveTo((c - dir * half).dx, (c - dir * half).dy)
          ..lineTo((c + normal * w).dx, (c + normal * w).dy)
          ..lineTo((c + dir * half).dx, (c + dir * half).dy)
          ..lineTo((c - normal * w).dx, (c - normal * w).dy)
          ..close();
        canvas.drawPath(path, i.isEven ? deep : gilt);
      }
    }

    final mid = outer.deflate(band / 2);
    final gap = block / 2 + 2;
    run(
      Offset(mid.left + gap, mid.top),
      Offset(mid.right - gap, mid.top),
    );
    run(
      Offset(mid.right, mid.top + gap),
      Offset(mid.right, mid.bottom - gap),
    );
    run(
      Offset(mid.right - gap, mid.bottom),
      Offset(mid.left + gap, mid.bottom),
    );
    run(
      Offset(mid.left, mid.bottom - gap),
      Offset(mid.left, mid.top + gap),
    );

    for (final corner in [
      mid.topLeft,
      mid.topRight,
      mid.bottomRight,
      mid.bottomLeft,
    ]) {
      _knot(canvas, corner, block);
    }
  }

  /// A square block with a twisted knot: two loops crossing at right
  /// angles, each passing over the other once and under once.
  void _knot(Canvas canvas, Offset c, double size) {
    final rect = Rect.fromCenter(center: c, width: size, height: size);
    final surface = Paint()..color = inlay.light;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = inlay.fillet;
    canvas
      ..drawRect(rect, surface)
      ..drawRect(rect, edge);

    final long = size * 0.78;
    final short = size * 0.36;
    final strand = size * 0.13;
    final a = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: long, height: short),
      Radius.circular(short / 2),
    );
    final b = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: short, height: long),
      Radius.circular(short / 2),
    );
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strand
      ..color = inlay.deep;
    final gap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strand + 2
      ..color = inlay.light;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = inlay.fillet;

    // Loop A, then loop B over it, then A over B at two opposite
    // crossings: the over-and-under that makes the twist.
    canvas
      ..drawRRect(a, band)
      ..drawRRect(a, line)
      ..drawRRect(b, gap)
      ..drawRRect(b, band)
      ..drawRRect(b, line);
    for (final sign in [-1.0, 1.0]) {
      // Re-lay loop A across loop B at the top-left and bottom-right
      // crossings.
      final clip = Rect.fromCenter(
        center: c + Offset(sign * short / 2, sign * short / 2) * 0.9,
        width: strand * 2.6,
        height: strand * 2.6,
      );
      canvas.save();
      canvas.clipRect(clip);
      canvas
        ..drawRRect(a, gap)
        ..drawRRect(a, band)
        ..drawRRect(a, line);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ChecklistInlayFramePainter old) =>
      old.inlay.deep != inlay.deep ||
      old.inlay.fillet != inlay.fillet ||
      old.inset != inset ||
      old.band != band;
}
