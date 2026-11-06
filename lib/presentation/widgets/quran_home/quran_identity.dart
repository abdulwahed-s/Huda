import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Quran's voice: illumination (tazhib), the gold a copyist lays around the
/// text. A surah opens under a headpiece (an unwan: a ruled panel with the
/// name in a lobed cartouche and a star roundel in each margin), every ayah
/// ends in a 12-lobed gilt rosette, and the landing carries the star
/// medallion. Gold leaf on the scheme's tones. See `design/IDENTITIES.md`
/// and `design/features/quran/brief.md`.
final FeatureIdentity quranIdentity = FeatureIdentity(
  id: 'quran',
  motif:
      'Illumination: a surah headpiece (a ruled panel, a lobed cartouche, '
      'a star roundel in each margin), 12-lobed ayah-end rosettes and a '
      '12-point star medallion',
  count: 114,
  rhythm: IdentityRhythm.sequence,
  material: IdentityMaterial.light,
  headerArt: (style) => QuranMedallionPainter(style: style),
);

/// The rosette's lobes. Not 8 (the system's khatam, Athkar's petals), not
/// 6 (the button engraving).
const quranRosetteLobes = 12;

/// Geometry shared by the Quran painters.
abstract final class QuranGeometry {
  /// A scalloped circle: [lobes] round lobes with soft cusps between them,
  /// [depth] of the radius deep.
  static Path lobedCircle(
    Offset center,
    double radius, {
    int lobes = quranRosetteLobes,
    double depth = 0.12,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final a = rotation + i / steps * math.pi * 2;
      final lobe = (math.cos((a - rotation) * lobes / 2)).abs();
      final r = radius * (1 - depth + depth * math.sqrt(lobe));
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// A 12-point star in one interlaced line: the {12/5} star polygon,
  /// each point joined to the fifth one on, its tips on [radius]. Drawn
  /// with [partial], the line traces the star point by point.
  static Path star(
    Offset center,
    double radius, {
    int points = quranRosetteLobes,
    int step = 5,
    double rotation = -math.pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i <= points; i++) {
      final a = rotation + (i * step % points) / points * math.pi * 2;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// A circle drawn from its top, both halves the same way round, so
  /// [partial] closes it at the bottom.
  static Path ring(Offset center, double radius) {
    final box = Rect.fromCircle(center: center, radius: radius);
    return Path()
      ..addArc(box, -math.pi / 2, math.pi)
      ..addArc(box, math.pi / 2, math.pi);
  }

  /// A star roundel, the medallion small: a ring, the open 12-point star
  /// in a fine line and an open heart with a point in it, drawn in by [t]
  /// (the ring first, then the star). Used in the headpiece's margins.
  static void paintRoundel(
    Canvas canvas,
    Offset center,
    double radius,
    double t, {
    required Paint line,
    required Paint dot,
  }) {
    if (t <= 0 || radius <= 0) return;
    final ringT = phase(t, 0, 0.5);
    canvas.drawPath(partial(ring(center, radius), ringT), line);
    final starT = phase(t, 0.3, 1);
    if (starT <= 0) return;
    final fine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = line.strokeWidth * 0.55
      ..strokeJoin = StrokeJoin.round
      ..color = line.color;
    final heart = radius * 0.34;
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawPath(partial(star(center, radius * 0.86), starT), fine);
    // The heart is open: the star's lines stop at it.
    canvas.drawCircle(center, heart, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    canvas.drawCircle(center, heart * starT, fine);
    canvas.drawCircle(center, heart * 0.4 * starT, dot);
  }

  /// The portion of [path] drawn by [t] (0–1), along its length.
  static Path partial(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    if (t <= 0) return out;
    for (final PathMetric metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  /// Where [t] stands inside the phase [from]–[to], eased.
  static double phase(double t, double from, double to) =>
      Curves.easeOutCubic.transform(((t - from) / (to - from)).clamp(0, 1));
}

/// An ayah-end rosette: 12 gilt lobes around a ring. [lit] (0–1) fills it
/// with gold, for the ayah being recited.
class QuranRosettePainter extends CustomPainter {
  const QuranRosettePainter({
    required this.color,
    required this.fill,
    this.lit = 0,
    this.stroke = 1.2,
  });

  final Color color;

  /// The page under it, so the number stays clear when lit.
  final Color fill;
  final double lit;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke;
    if (r <= 0) return;
    final outer = QuranGeometry.lobedCircle(c, r);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(
      outer,
      Paint()..color = Color.lerp(fill, color, 0.14 + 0.86 * lit)!,
    );
    canvas.drawPath(outer, line);
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()..color = Color.lerp(fill, color, lit * 0.82)!,
    );
    canvas.drawCircle(c, r * 0.7, line..strokeWidth = stroke * 0.75);
  }

  @override
  bool shouldRepaint(QuranRosettePainter old) =>
      old.color != color ||
      old.fill != fill ||
      old.lit != lit ||
      old.stroke != stroke;
}

/// An ayah's number in its rosette. The rosette brightens to gold while
/// the ayah is recited ([lit]); nothing else moves while reading.
class QuranAyahRosette extends StatelessWidget {
  const QuranAyahRosette({
    super.key,
    required this.number,
    this.size = 34,
    this.lit = false,
    this.color,
    this.background,
    this.mushafDigits = false,
  });

  final int number;
  final double size;
  final bool lit;

  /// Arabic-Indic digits whatever the language, as a Mushaf numbers its
  /// ayat (the share card).
  final bool mushafDigits;

  /// The rosette's gold (defaults to the gilt ornament) and the page under
  /// it, for custom page colors.
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final gold = color ?? scheme.tertiary;
    final page = background ?? scheme.surface;
    final digits = mushafDigits
        ? String.fromCharCodes(
            '$number'.codeUnits.map((c) => c - 0x30 + 0x0660),
          )
        : quranNumber(context, number);
    final duration = tokens.motion.of(context, tokens.motion.medium);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: lit ? 1 : 0),
      duration: duration,
      curve: tokens.motion.standard,
      builder: (context, value, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: QuranRosettePainter(
            color: gold,
            fill: page,
            lit: value,
            stroke: size < 30 ? 1 : 1.3,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: FittedBox(
                child: Text(
                  digits,
                  textScaler: TextScaler.noScaling,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Color.lerp(gold, page, value),
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [number] in the locale's digits: Arabic-Indic in Arabic, Eastern
/// Arabic-Indic in Urdu, Western elsewhere.
String quranNumber(BuildContext context, int number) {
  final language = Localizations.localeOf(context).languageCode;
  final zero = switch (language) {
    'ar' => 0x0660,
    'ur' => 0x06F0,
    _ => null,
  };
  if (zero == null) return '$number';
  return String.fromCharCodes('$number'.codeUnits.map((c) => zero + c - 0x30));
}

/// The landing header's art and Quran's state art: an illuminated
/// medallion, the roundel a copyist paints at a surah's opening. A double
/// ring, a 12-point star drawn as one continuous line with its tips on the
/// inner ring, an open heart holding a 12-lobed rosette, and a gilt point
/// on the band between each pair of tips. [draw] (0–1) lets it draw in: the rings from
/// the top, the star point by point, the rosette, then the points.
class QuranMedallionPainter extends CustomPainter {
  QuranMedallionPainter({required this.style, double draw = 1, this.drawOf})
    : _draw = draw,
      super(repaint: drawOf);

  final OrnamentStyle style;
  final double _draw;
  final ValueListenable<double>? drawOf;

  double get draw => drawOf?.value ?? _draw;

  @override
  void paint(Canvas canvas, Size size) {
    final t = draw.clamp(0.0, 1.0);
    if (t <= 0) return;
    // The landing header lets its art run 8 below its edge: keep the
    // medallion whole above it.
    final room = Size(size.width, math.max(0, size.height - 10));
    final c = room.center(Offset.zero);
    final r = room.shortestSide / 2 - style.stroke * 4;
    if (r <= 4) return;
    final inner = r * 0.86;

    final ringT = QuranGeometry.phase(t, 0, 0.4);
    canvas.drawCircle(c, inner * ringT, style.fill(0.06));
    for (final radius in [r, inner]) {
      style.draw(
        canvas,
        QuranGeometry.partial(QuranGeometry.ring(c, radius), ringT),
        closed: false,
      );
    }

    // The star's lines stop at the open heart (the rosette's ground).
    final heart = r * 0.34;
    final starT = QuranGeometry.phase(t, 0.2, 0.75);
    if (starT > 0) {
      canvas.saveLayer(Offset.zero & size, Paint());
      style.draw(
        canvas,
        QuranGeometry.partial(QuranGeometry.star(c, inner), starT),
        closed: false,
      );
      canvas.drawCircle(c, heart, Paint()..blendMode = BlendMode.clear);
      canvas.restore();
    }

    final heartT = QuranGeometry.phase(t, 0.55, 0.9);
    if (heartT > 0) {
      final rosette = heart * 0.86 * heartT;
      canvas.drawPath(
        QuranGeometry.lobedCircle(c, rosette, depth: 0.2),
        style.fill(0.14),
      );
      style.draw(
        canvas,
        QuranGeometry.lobedCircle(c, rosette, depth: 0.2),
        closed: false,
      );
      canvas.drawCircle(c, rosette * 0.3, style.fill(0.9));
    }

    final pointsT = QuranGeometry.phase(t, 0.75, 1);
    if (pointsT > 0) {
      final band = (r + inner) / 2;
      for (var i = 0; i < quranRosetteLobes; i++) {
        final a = -math.pi / 2 + (i + 0.5) / quranRosetteLobes * math.pi * 2;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * band,
          math.max(style.stroke * 1.2, (r - inner) * 0.22) * pointsT,
          style.fill(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(QuranMedallionPainter old) =>
      old.style != style || old._draw != _draw || old.drawOf != drawOf;
}

/// A surah's headpiece (unwan): a ruled gilt panel, a lobed cartouche in
/// its middle for the surah's name, a rosette in each side compartment,
/// and a star roundel out in each margin on a short rule.
///
/// [draw] (0–1) is the signature motion: the panel's rules draw outward
/// from the middle, the cartouche closes, the rosettes come in, then the
/// rules run out to the margins and the roundels draw their stars. Pass an
/// animation as [drawOf].
class QuranHeadpiecePainter extends CustomPainter {
  QuranHeadpiecePainter({
    required this.color,
    required this.panel,
    this.stroke = 1.5,
    double draw = 1,
    this.drawOf,
  }) : _draw = draw,
       super(repaint: drawOf);

  /// The gold.
  final Color color;

  /// The cartouche's ground, under the name.
  final Color panel;
  final double stroke;
  final double _draw;
  final ValueListenable<double>? drawOf;

  double get draw => drawOf?.value ?? _draw;

  /// The cartouche's box inside a headpiece of [size], where the name goes.
  static Rect cartoucheRect(Size size) {
    final panel = _panelRect(size);
    final h = panel.height * 0.74;
    final w = math.min(
      panel.width * 0.64,
      math.max(h * 4.6, panel.width * 0.5),
    );
    return Rect.fromCenter(center: panel.center, width: w, height: h);
  }

  /// The margin each side of the panel, for its roundel.
  static double _marginWidth(Size size) =>
      math.min(size.height * 0.95, size.width * 0.11);

  static Rect _panelRect(Size size) {
    final p = _marginWidth(size);
    return Rect.fromLTRB(
      p,
      size.height * 0.12,
      size.width - p,
      size.height * 0.88,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = draw.clamp(0.0, 1.0);
    if (t <= 0 || size.width < 40) return;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;
    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.6
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: color.a * 0.7);
    final box = _panelRect(size);
    final inner = box.deflate(stroke * 3);

    // The rules, drawn from the top and bottom middle out to the ends.
    final rulesT = QuranGeometry.phase(t, 0, 0.45);
    if (rulesT > 0) {
      canvas.drawRect(
        inner,
        Paint()..color = color.withValues(alpha: color.a * 0.07 * rulesT),
      );
      for (final (rect, paint) in [(box, line), (inner, hair)]) {
        for (final half in _halves(rect)) {
          canvas.drawPath(QuranGeometry.partial(half, rulesT), paint);
        }
      }
    }

    // The cartouche closes around the name.
    final cartouche = cartoucheRect(size);
    final cartoucheT = QuranGeometry.phase(t, 0.25, 0.7);
    if (cartoucheT > 0) {
      final shape = CartouchePainter.shape(cartouche);
      canvas.drawPath(shape, Paint()..color = panel);
      canvas.drawPath(QuranGeometry.partial(shape, cartoucheT), line);
      canvas.drawPath(
        QuranGeometry.partial(
          CartouchePainter.shape(cartouche.deflate(stroke * 2.5)),
          cartoucheT,
        ),
        hair,
      );
    }

    // A rosette in each side compartment.
    final rosetteT = QuranGeometry.phase(t, 0.45, 0.8);
    if (rosetteT > 0) {
      final r = math.min(
        inner.height * 0.3,
        (cartouche.left - inner.left) * 0.3,
      );
      if (r > 3) {
        for (final x in [
          (inner.left + cartouche.left) / 2,
          (cartouche.right + inner.right) / 2,
        ]) {
          final c = Offset(x, inner.center.dy);
          canvas.drawPath(
            QuranGeometry.lobedCircle(c, r * rosetteT),
            Paint()..color = color.withValues(alpha: color.a * 0.18),
          );
          canvas.drawPath(QuranGeometry.lobedCircle(c, r * rosetteT), line);
          canvas.drawCircle(c, r * 0.3 * rosetteT, Paint()..color = color);
        }
      }
    }

    // A rule runs out of each end, and a star roundel draws in the margin.
    final marginT = QuranGeometry.phase(t, 0.6, 1);
    if (marginT > 0) {
      final margin = _marginWidth(size);
      final radius = math.min(margin * 0.4, box.height * 0.42);
      final mid = box.center.dy;
      for (final (edge, sign) in [(box.left, -1.0), (box.right, 1.0)]) {
        final center = Offset(edge + sign * (margin - radius - stroke), mid);
        final ruleT = QuranGeometry.phase(marginT, 0, 0.4);
        final reach = (center.dx + -sign * radius) - edge;
        canvas.drawLine(
          Offset(edge, mid),
          Offset(edge + reach * ruleT, mid),
          line,
        );
        QuranGeometry.paintRoundel(
          canvas,
          center,
          radius,
          QuranGeometry.phase(marginT, 0.25, 1),
          line: line,
          dot: Paint()..color = color,
        );
      }
    }
  }

  /// A rectangle's outline as two paths from the top middle, one each way
  /// around, meeting at the bottom middle.
  static List<Path> _halves(Rect r) => [
    Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.center.dx, r.bottom),
    Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.center.dx, r.bottom),
  ];

  @override
  bool shouldRepaint(QuranHeadpiecePainter old) =>
      old.color != color ||
      old.panel != panel ||
      old.stroke != stroke ||
      old._draw != _draw ||
      old.drawOf != drawOf;
}

/// Plays the illumination in once: 0 → 1 over [duration] when it first
/// builds, or at once under reduce motion. [builder] gets the animation to
/// pass as a painter's `drawOf`.
class QuranIlluminate extends StatefulWidget {
  const QuranIlluminate({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
  });

  final Widget Function(BuildContext context, ValueListenable<double> draw)
  builder;
  final Duration duration;

  /// Waits this long first, e.g. for the route to arrive.
  final Duration delay;

  @override
  State<QuranIlluminate> createState() => _QuranIlluminateState();
}

class _QuranIlluminateState extends State<QuranIlluminate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );

  // The delay is the start of one run, so nothing waits on a timer.
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.delay + widget.duration).inMicroseconds,
      1,
    ),
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
  Widget build(BuildContext context) => widget.builder(context, _draw);
}

/// A surah's mark in lists: its number in a rosette.
class QuranSurahMark extends StatelessWidget {
  const QuranSurahMark({super.key, required this.number, this.size = 44});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: QuranAyahRosette(number: number, size: size),
  );
}
