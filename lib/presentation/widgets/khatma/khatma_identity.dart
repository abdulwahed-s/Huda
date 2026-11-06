import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Khatma's identity: the road of thirty. The Quran as a journey of 30
/// juz, drawn as one trail that winds back and forth across the plate
/// (boustrophedon), a stretch per juz with a waymark between them, from a
/// trailhead to a ten-pointed star at the khatm. The walked road is gilt,
/// the road ahead an engraved dotted line, today's portion a soft band,
/// and a passed waymark becomes a small star. See `design/IDENTITIES.md`.
///
/// Distinct from Tasbih's ring of beads (circular, counted per tap),
/// Hadith's isnad chain (a straight chain of nodes), Onboarding's row of
/// arches and Quran's 12-lobed rosettes: a road that turns, measured in
/// juz, with 10-pointed stars.
abstract final class KhatmaJourney {
  static const juzCount = 30;
  static const totalPages = 604;

  /// The first page of each juz in the 604-page Madinah Mushaf.
  static const juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, //
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382, //
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  /// Where the reader is on the road (0–30, in juz) after reading the
  /// first [pagesRead] pages.
  static double position(int pagesRead) {
    final read = pagesRead.clamp(0, totalPages);
    if (read == 0) return 0;
    var juz = juzCount - 1;
    while (juz > 0 && juzStartPages[juz] > read) {
      juz--;
    }
    final start = juzStartPages[juz];
    final end = juz + 1 < juzCount ? juzStartPages[juz + 1] : totalPages + 1;
    return juz + (read - start + 1) / (end - start);
  }

  /// The juz completed after reading [pagesRead] pages.
  static int juzDone(int pagesRead) => position(pagesRead).floor();
}

/// The road on a chrome plate: [walked] and [todayEnd] are positions in
/// juz (see [KhatmaJourney.position]). Draws itself in from [from] when it
/// appears and walks on whenever [walked] grows: each waymark it passes
/// swells into its star, and reaching 30 lights the khatm star. Under
/// reduce motion it shows the end state.
class KhatmaTrail extends StatefulWidget {
  const KhatmaTrail({
    super.key,
    required this.walked,
    this.todayEnd,
    this.from = 0,
    this.flat = false,
    this.glint,
    this.semanticLabel,
  });

  final double walked;

  /// A light that runs once along the walked road (0 → 1), for the
  /// completion.
  final Animation<double>? glint;

  /// Ten juz a row wherever it fits: a shorter road (the setup).
  final bool flat;
  final double? todayEnd;

  /// Where the walk starts when the road first appears.
  final double from;
  final String? semanticLabel;

  @override
  State<KhatmaTrail> createState() => _KhatmaTrailState();
}

class _KhatmaTrailState extends State<KhatmaTrail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late double _from = widget.from;
  late double _to = widget.walked;

  /// Today's portion's end moves with the walk: from where the road starts
  /// drawing on open, from the old portion's end when one is marked done.
  late double? _endFrom = widget.todayEnd == null ? null : widget.from;
  late double? _endTo = widget.todayEnd;
  bool _started = false;

  double get _t => Curves.easeInOutCubic.transform(_controller.value);

  /// The road as last laid out, so the walk moves along the path itself
  /// (at an even speed, through the turns too) rather than juz by juz,
  /// where a turn would take no time at all.
  KhatmaTrailLayout? _layout;

  double _d(double t) => _layout?.distance(t) ?? t;

  /// Along the road from [from] to [to] (positions in juz), as a distance.
  double _along(double from, double to) => ui.lerpDouble(_d(from), _d(to), _t)!;

  double get _headDistance => _along(_from, _to);

  double? get _endDistance {
    final to = _endTo;
    return to == null ? null : _along(_endFrom ?? to, to);
  }

  /// The walk's current position in juz (for a walk that starts mid-way).
  double get _head => _layout?.position(_headDistance) ?? _along(_from, _to);

  double? get _end {
    final d = _endDistance;
    return d == null ? null : (_layout?.position(d) ?? d);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // The road draws in once, as the plate appears (signature motion).
    _walk(const Duration(milliseconds: 1100));
  }

  @override
  void didUpdateWidget(KhatmaTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walked != _to || widget.todayEnd != _endTo) {
      _endFrom = _end ?? widget.todayEnd;
      _endTo = widget.todayEnd;
      _from = _head;
      _to = widget.walked;
      _walk(const Duration(milliseconds: 900));
    }
  }

  void _walk(Duration duration) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce || (_from == _to && _endFrom == _endTo)) {
      _controller.value = 1;
      return;
    }
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final label = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: tokens.onChromeMuted,
      letterSpacing: 0,
    );
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Short windows (phone landscape) get a flatter road.
        final layout = KhatmaTrailLayout(
          constraints.maxWidth,
          flat: widget.flat,
          rowGap: MediaQuery.sizeOf(context).height < 480 ? 30 : 40,
        );
        _layout = layout;
        return SizedBox(
          height: layout.height,
          child: Ornament(
            semanticLabel: widget.semanticLabel,
            painter: _TrailFrame(
              animation: Listenable.merge([_controller, ?widget.glint]),
              glint: widget.glint,
              walkedDistance: () => _headDistance,
              layout: layout,
              endDistance: () => _endDistance,
              rtl: rtl,
              colors: _TrailColors(
                road: tokens.onChromeMuted.withValues(alpha: 0.55),
                walked: tokens.gilt,
                today: tokens.onChrome,
                traveler: tokens.onChrome,
              ),
              label: label,
              scaler: scaler,
            ),
          ),
        );
      },
    );
  }
}

/// How the road lies in a given width: juz per row, rows and spacing.
class KhatmaTrailLayout {
  KhatmaTrailLayout(this.width, {this.rowGap = 40, bool flat = false}) {
    final inner = width - 2 * margin;
    perRow = inner >= (flat ? 220 : 400)
        ? 10
        : inner >= 200
        ? 6
        : 5;
    rows = KhatmaJourney.juzCount ~/ perRow;
    stretch = inner / perRow;
  }

  final double width;
  final double rowGap;
  static const margin = 28.0;
  static const top = 22.0;
  static const bottom = 20.0;
  late final int perRow;
  late final int rows;
  late final double stretch;

  double get height => top + (rows - 1) * rowGap + bottom;
  double get bend => math.pi * rowGap / 2;

  /// Distance along the road to position [t] (in juz).
  double distance(double t) {
    if (t <= 0) return 0;
    final bends = ((t / perRow).ceil() - 1).clamp(0, rows - 1);
    return t * stretch + bends * bend;
  }

  /// The position (in juz) at [d] along the road: inside a turn it's the
  /// juz the turn follows.
  double position(double d) {
    final row = perRow * stretch;
    final unit = row + bend;
    final r = (d / unit).floor().clamp(0, rows - 1);
    final within = d - r * unit;
    final t = within <= row ? r * perRow + within / stretch : (r + 1) * perRow;
    return t.clamp(0, KhatmaJourney.juzCount).toDouble();
  }

  /// The road as one path (left to right on the first row in LTR).
  Path path(bool rtl) {
    double x(double v) => rtl ? width - v : v;
    final left = margin;
    final right = width - margin;
    final p = Path()..moveTo(x(left), top);
    for (var r = 0; r < rows; r++) {
      final y = top + r * rowGap;
      final forward = r.isEven;
      p.lineTo(x(forward ? right : left), y);
      if (r < rows - 1) {
        // A half turn down to the next row, on the outside.
        p.arcToPoint(
          Offset(x(forward ? right : left), y + rowGap),
          radius: Radius.circular(rowGap / 2),
          clockwise: forward != rtl,
        );
      }
    }
    return p;
  }
}

class _TrailColors {
  const _TrailColors({
    required this.road,
    required this.walked,
    required this.today,
    required this.traveler,
  });

  final Color road;
  final Color walked;
  final Color today;
  final Color traveler;
}

class _TrailFrame extends CustomPainter {
  _TrailFrame({
    required Listenable animation,
    this.glint,
    required this.walkedDistance,
    required this.layout,
    required this.endDistance,
    required this.rtl,
    required this.colors,
    required this.label,
    required this.scaler,
  }) : super(repaint: animation);

  final Animation<double>? glint;

  /// How far along the road the walker is, and where today's portion
  /// ends, as distances (so turns are walked too).
  final double Function() walkedDistance;
  final KhatmaTrailLayout layout;
  final double? Function() endDistance;
  final bool rtl;
  final _TrailColors colors;
  final TextStyle label;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final road = layout.path(rtl);
    final metric = road.computeMetrics().first;
    Offset at(double t) =>
        metric.getTangentForOffset(layout.distance(t))!.position;
    final walkedD = walkedDistance().clamp(0.0, metric.length);
    final walked = layout.position(walkedD);

    // Today's portion: a soft band under the road.
    final endD = endDistance();
    if (endD != null && endD > walkedD) {
      canvas.drawPath(
        metric.extractPath(walkedD, math.min(endD, metric.length)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = colors.today.withValues(alpha: 0.16),
      );
    }

    // The road ahead: an engraved dotted line.
    final dots = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = colors.road;
    // Dots fixed on the road (every 7), so they don't crawl with the walker.
    for (var d = (walkedD / 7).floor() * 7 + 7.0; d < metric.length; d += 7) {
      canvas.drawPath(
        metric.extractPath(d, math.min(d + 2.5, metric.length)),
        dots,
      );
    }

    // The completion's light, running once along the walked road.
    final g = glint?.value ?? 0;
    if (g > 0 && g < 1 && walkedD > 0) {
      final d = g * walkedD;
      final fade = math.sin(math.pi * g);
      canvas
        ..drawPath(
          metric.extractPath(math.max(0, d - 48), d),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = colors.today.withValues(alpha: 0.22 * fade),
        )
        ..drawCircle(
          metric.getTangentForOffset(d)!.position,
          5,
          Paint()..color = colors.today.withValues(alpha: 0.9 * fade),
        );
    }

    // The walked road: luminous gilt.
    if (walkedD > 0) {
      OrnamentStyle(
        color: colors.walked,
        render: OrnamentRender.luminous,
        stroke: 2.5,
      ).draw(canvas, metric.extractPath(0, walkedD), closed: false);
    }

    // The trailhead.
    canvas.drawCircle(
      at(0),
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = walked > 0 ? colors.walked : colors.road,
    );

    // Waymarks between the juz: hollow lozenges ahead; passed, small
    // ten-pointed stars that swell as the walk reaches them.
    for (var k = 1; k < KhatmaJourney.juzCount; k++) {
      final c = at(k.toDouble());
      // Measured along the road, so a waymark at a turn swells as the
      // walker passes it, not after the turn.
      final passed =
          (walkedD - layout.distance(k.toDouble())) / (layout.stretch / 2);
      if (passed <= 0) {
        canvas.drawPath(
          _lozenge(c, 4.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = colors.road,
        );
      } else {
        final b = passed.clamp(0.0, 1.0);
        final swell = 1 + 0.9 * math.sin(math.pi * b);
        final star = OrnamentGeometry.star(
          c,
          5 * swell,
          points: 10,
          innerRatio: 0.5,
        );
        canvas.drawPath(star, Paint()..color = colors.walked);
        if (b < 1) {
          canvas.drawCircle(
            c,
            9 * swell,
            Paint()
              ..color = colors.walked.withValues(
                alpha: 0.2 * math.sin(math.pi * b),
              ),
          );
        }
      }
      // Juz numbers where the road turns.
      if (k % layout.perRow == 0) _label(canvas, '$k', c);
    }

    // The khatm: a ten-pointed star at the end of the road, drawn as one
    // interlaced line ({10/3}) in a ring; it lights once the walk arrives,
    // the ring swelling once.
    final goal = at(30);
    final arrive = ((walked - 29.5) / 0.5).clamp(0.0, 1.0);
    final swell = math.sin(math.pi * arrive);
    final lit = arrive > 0;
    final color = lit ? colors.walked : colors.road;
    if (lit) {
      canvas.drawCircle(
        goal,
        14 + 6 * swell,
        Paint()..color = colors.walked.withValues(alpha: 0.12 + 0.1 * swell),
      );
    }
    final star = Path();
    for (var i = 0; i <= 10; i++) {
      final a = -math.pi / 2 + (i * 3 % 10) * math.pi / 5;
      final p = goal + Offset(math.cos(a), math.sin(a)) * 10;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas
      ..drawCircle(
        goal,
        13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      )
      ..drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lit ? 1.5 : 1.2
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    if (lit) {
      canvas.drawCircle(
        goal,
        3,
        Paint()..color = colors.walked.withValues(alpha: arrive),
      );
    }

    // The traveler: where the reader is now.
    if (walked < 30) {
      final c = metric.getTangentForOffset(walkedD)!.position;
      canvas
        ..drawCircle(
          c,
          9,
          Paint()..color = colors.walked.withValues(alpha: 0.25),
        )
        ..drawCircle(c, 5.5, Paint()..color = colors.traveler)
        ..drawCircle(
          c,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = colors.walked,
        );
    }
  }

  Path _lozenge(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r * 0.75, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r * 0.75, c.dy)
    ..close();

  void _label(Canvas canvas, String text, Offset mark) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: label),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    painter.paint(canvas, mark - Offset(painter.width / 2, painter.height + 7));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_TrailFrame old) =>
      old.layout.width != layout.width ||
      old.layout.rowGap != layout.rowGap ||
      old.rtl != rtl ||
      old.colors.walked != colors.walked ||
      old.label != label;
}

/// The khatm medallion: the road's ten-pointed star at full size. A
/// double ring, ten waymark lozenges between the rings, the interlaced
/// {10/3} star, and a small star at the heart. [progress] (0–1) draws it
/// in: the rings sweep, the star traces itself, the heart and the
/// lozenges come in, and a soft glow swells once at the end.
class KhatmMedallionPainter extends CustomPainter {
  const KhatmMedallionPainter({
    required this.color,
    this.progress = 1,
    super.repaint,
  });

  final Color color;
  final double progress;

  static double _span(double p, double a, double b) =>
      ((p - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    final style = OrnamentStyle(
      color: color,
      render: OrnamentRender.luminous,
      stroke: r > 40 ? 2 : 1.5,
    );

    // The glow behind: steady once drawn, swelling once as it finishes.
    final settle = _span(p, 0.6, 1);
    final swell = math.sin(math.pi * _span(p, 0.7, 1));
    if (settle > 0) {
      canvas.drawCircle(
        c,
        r * (0.9 + 0.12 * swell),
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.10 * settle + 0.14 * swell),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r * 1.05)),
      );
    }

    // The rings sweep from the top.
    final ring = _span(p, 0, 0.45);
    if (ring > 0) {
      for (final rr in [r, r * 0.84]) {
        style.draw(
          canvas,
          Path()..addArc(
            Rect.fromCircle(center: c, radius: rr),
            -math.pi / 2,
            2 * math.pi * ring,
          ),
          closed: false,
        );
      }
    }

    // The interlaced star traces itself.
    final trace = _span(p, 0.25, 0.8);
    if (trace > 0) {
      final star = Path();
      for (var i = 0; i <= 10; i++) {
        final a = -math.pi / 2 + (i * 3 % 10) * math.pi / 5;
        final q = c + Offset(math.cos(a), math.sin(a)) * r * 0.72;
        i == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
      }
      final metric = star.computeMetrics().first;
      style.draw(
        canvas,
        metric.extractPath(0, metric.length * trace),
        closed: false,
      );
    }

    // The heart and the waymarks between the rings.
    final heart = _span(p, 0.5, 0.9);
    if (heart > 0) {
      canvas.drawPath(
        OrnamentGeometry.star(c, r * 0.2 * heart, points: 10, innerRatio: 0.5),
        Paint()..color = color,
      );
    }
    final marks = _span(p, 0.6, 1);
    if (marks > 0) {
      final fill = Paint()..color = color.withValues(alpha: marks);
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + (i + 0.5) * math.pi / 5;
        final m = c + Offset(math.cos(a), math.sin(a)) * r * 0.92;
        final h = r * 0.06 * marks;
        canvas.save();
        canvas.translate(m.dx, m.dy);
        canvas.rotate(a + math.pi / 2);
        canvas.drawPath(
          Path()
            ..moveTo(0, -h)
            ..lineTo(h * 0.7, 0)
            ..lineTo(0, h)
            ..lineTo(-h * 0.7, 0)
            ..close(),
          fill,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(KhatmMedallionPainter old) =>
      old.progress != progress || old.color != color;
}

/// The chrome plate the road lies on: the deep band with a faint girih
/// field, warm text. The page's one strong surface.
class KhatmaPlate extends StatelessWidget {
  const KhatmaPlate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: tokens.chromeGradient,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Stack(
          children: [
            Positioned.fill(
              child: Ornament(
                painter: StarFieldPainter(
                  style: OrnamentStyle(
                    color: tokens.gilt.withValues(alpha: 0.10),
                    render: OrnamentRender.line,
                  ),
                  module: 44,
                  fade: AlignmentDirectional.bottomStart,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.space.md),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: tokens.onChrome),
                child: IconTheme.merge(
                  data: IconThemeData(color: tokens.onChrome),
                  child: Theme(
                    data: theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        bodyColor: tokens.onChrome,
                        displayColor: tokens.onChrome,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
