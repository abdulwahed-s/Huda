import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

abstract final class KhatmaJourney {
  static const juzCount = 30;
  static const totalPages = 604;

  static const juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

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

  static int juzDone(int pagesRead) => position(pagesRead).floor();
}

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

  final Animation<double>? glint;

  final bool flat;
  final double? todayEnd;

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

  late double? _endFrom = widget.todayEnd == null ? null : widget.from;
  late double? _endTo = widget.todayEnd;
  bool _started = false;

  double get _t => Curves.easeInOutCubic.transform(_controller.value);

  KhatmaTrailLayout? _layout;

  double _d(double t) => _layout?.distance(t) ?? t;

  double _along(double from, double to) => ui.lerpDouble(_d(from), _d(to), _t)!;

  double get _headDistance => _along(_from, _to);

  double? get _endDistance {
    final to = _endTo;
    return to == null ? null : _along(_endFrom ?? to, to);
  }

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

  double distance(double t) {
    if (t <= 0) return 0;
    final bends = ((t / perRow).ceil() - 1).clamp(0, rows - 1);
    return t * stretch + bends * bend;
  }

  double position(double d) {
    final row = perRow * stretch;
    final unit = row + bend;
    final r = (d / unit).floor().clamp(0, rows - 1);
    final within = d - r * unit;
    final t = within <= row ? r * perRow + within / stretch : (r + 1) * perRow;
    return t.clamp(0, KhatmaJourney.juzCount).toDouble();
  }

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

    final dots = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = colors.road;
    for (var d = (walkedD / 7).floor() * 7 + 7.0; d < metric.length; d += 7) {
      canvas.drawPath(
        metric.extractPath(d, math.min(d + 2.5, metric.length)),
        dots,
      );
    }

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

    if (walkedD > 0) {
      OrnamentStyle(
        color: colors.walked,
        render: OrnamentRender.luminous,
        stroke: 2.5,
      ).draw(canvas, metric.extractPath(0, walkedD), closed: false);
    }

    canvas.drawCircle(
      at(0),
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = walked > 0 ? colors.walked : colors.road,
    );

    for (var k = 1; k < KhatmaJourney.juzCount; k++) {
      final c = at(k.toDouble());
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
      if (k % layout.perRow == 0) _label(canvas, '$k', c);
    }

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
