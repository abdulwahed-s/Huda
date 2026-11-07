import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Books' voice: the tooled binding. Leather covers with gilt tooling (a
/// lobed mandorla with pendants, arabesque bands or lobed corner pieces)
/// and the title stamped in gold; a shelf of bound books on the header
/// and as the state art (owner rounds 1–2). See `design/IDENTITIES.md`.
/// The library's header shows a shelf of such books (owner round 1).
final FeatureIdentity booksIdentity = FeatureIdentity(
  id: 'books',
  motif:
      'A tooled binding: leather covers with the title stamped in gold, a '
      'lobed mandorla with pendants, arabesque bands or corner pieces',
  count: 4,
  rhythm: IdentityRhythm.single,
  material: IdentityMaterial.leather,
  headerArt: (style) => BookShelfPainter(style: style),
  emptyArt: (style) => BookShelfPainter(style: style),
);

/// The shade of a book's leather: the theme's chrome, a step toward its
/// primary, a step toward the gilt (brown), or the deeper chrome. Picked
/// from the book's id so a book keeps its binding. Never a fixed hue.
Color bookLeather(BuildContext context, int seed) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final shades = [
    tokens.chrome,
    Color.lerp(tokens.chrome, scheme.primary, 0.3)!,
    Color.lerp(tokens.chrome, tokens.gilt, 0.24)!,
    Color.lerp(tokens.chromeEnd, scheme.primary, 0.14)!,
  ];
  return bookLeatherDeep(shades[seed.abs() % shades.length]);
}

/// Deepens a leather until the gilt title stamped on it keeps AA
/// contrast (relative luminance at most 0.04: about 4.5:1 or more against
/// the chrome's gilt), keeping its hue.
Color bookLeatherDeep(Color leather) {
  var color = leather;
  for (var i = 0; i < 12 && color.computeLuminance() > 0.04; i++) {
    color = Color.lerp(color, const Color(0xFF000000), 0.12)!;
  }
  return color;
}

/// Paper for bookplates and title pages: warm white, a little dimmer at
/// night so it doesn't glare, with ink drawn from the deep chrome.
({Color paper, Color ink, Color inkMuted}) bookPaper(BuildContext context) {
  final tokens = context.tokens;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final warm = Color.alphaBlend(
    tokens.gilt.withValues(alpha: 0.09),
    const Color(0xFFFFFFFF),
  );
  final paper = dark ? Color.lerp(warm, tokens.chromeEnd, 0.12)! : warm;
  final ink = Color.lerp(tokens.chrome, const Color(0xFF000000), 0.2)!;
  return (paper: paper, ink: ink, inkMuted: Color.lerp(ink, paper, 0.32)!);
}

/// The tooling's shapes: the almond (mandorla), its lobed edge and the
/// lobed corner pieces. Shared by the cover and the shelf.
abstract final class BookTooling {
  /// An almond: half width a, half height b, pointed ends on the long axis.
  static Path mandorla(Offset c, double a, double b) {
    final path = Path();
    const n = 48;
    for (var i = 0; i <= n; i++) {
      final p = almondPoint(c, a, b, i / n);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Offset almondPoint(Offset c, double a, double b, double t) {
    // t runs once around: down the right side, up the left.
    final y = math.cos(t * 2 * math.pi);
    final side = t < 0.5 ? 1.0 : -1.0;
    final w = a * (1 - y * y);
    return Offset(c.dx + side * w * 1.0, c.dy - b * y);
  }

  /// The almond with a scalloped edge of [lobes] lobes.
  static Path lobedMandorla(Offset c, double a, double b, {int lobes = 16}) {
    final points = [
      for (var i = 0; i <= lobes; i++) almondPoint(c, a, b, i / lobes),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final depth = (a + b) * 0.07;
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = (p0 + p1) / 2;
      final out = mid - c;
      final len = out.distance;
      final ctrl = len == 0 ? mid : mid + out / len * depth * 2;
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
    }
    return path..close();
  }

  /// A lobed quarter ellipse from one edge of a corner to the other.
  static Path quarterLobes(
    Offset corner,
    double rx,
    double ry,
    double dx,
    double dy, {
    int lobes = 4,
  }) {
    Offset at(double t) => Offset(
      corner.dx + dx * rx * math.cos(t * math.pi / 2),
      corner.dy + dy * ry * math.sin(t * math.pi / 2),
    );
    final path = Path();
    final start = at(0);
    path.moveTo(start.dx, start.dy);
    final depth = (rx + ry) * 0.09;
    for (var i = 1; i <= lobes; i++) {
      final p0 = at((i - 1) / lobes);
      final p1 = at(i / lobes);
      final mid = (p0 + p1) / 2;
      final out = mid - corner;
      final ctrl = mid + out / out.distance * depth * 2;
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
    }
    return path;
  }

  static Path quarterArc(
    Offset corner,
    double rx,
    double ry,
    double dx,
    double dy,
  ) {
    final path = Path();
    for (var i = 0; i <= 16; i++) {
      final t = i / 16 * math.pi / 2;
      final p = Offset(
        corner.dx + dx * rx * math.cos(t),
        corner.dy + dy * ry * math.sin(t),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }
}

/// The board's inside (the doublure) on the book page: plain leather, a
/// little lighter, shaded toward the spine on the reading end, with one
/// gilt fillet.
class BookDoublurePainter extends CustomPainter {
  const BookDoublurePainter({
    required this.style,
    required this.leather,
    this.rtl = false,
    this.radius = 6,
  });

  final OrnamentStyle style;
  final Color leather;
  final bool rtl;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    // The spine is on the reading end of the doublure (where the title
    // page begins): left in RTL, right in LTR.
    final r = Radius.circular(radius);
    final s = Radius.circular(radius / 3);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: rtl ? s : r,
        bottomLeft: rtl ? s : r,
        topRight: rtl ? r : s,
        bottomRight: rtl ? r : s,
      ),
      Paint()..color = leather,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: rtl ? Alignment.centerLeft : Alignment.centerRight,
          end: rtl ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0x40000000), Color(0x00000000)],
          stops: const [0, 0.14],
        ).createShader(rect),
    );
    final inset = size.shortestSide * 0.08;
    final frame = rect.deflate(inset);
    if (frame.width > 8 && frame.height > 8) {
      style.draw(canvas, Path()..addRect(frame));
    }
  }

  @override
  bool shouldRepaint(BookDoublurePainter old) =>
      old.style != style ||
      old.leather != leather ||
      old.rtl != rtl ||
      old.radius != radius;
}

/// The style for tooling on a leather board: luminous gilt.
OrnamentStyle bookTooling(BuildContext context, {bool quiet = false}) {
  final tokens = context.tokens;
  return OrnamentStyle(
    color: quiet ? tokens.gilt.withValues(alpha: 0.55) : tokens.gilt,
    render: OrnamentRender.luminous,
    stroke: quiet ? tokens.stroke.hairline : tokens.stroke.fine,
  );
}

/// Lays its child out at least `width / aspect` tall, so a book keeps its
/// proportions, and lets it grow when its text needs more (large text).
/// Reports that height to intrinsic queries, so grid rows stay even.
class BookAspect extends SingleChildRenderObjectWidget {
  const BookAspect({super.key, required this.aspect, super.child});

  /// Width over height.
  final double aspect;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderBookAspect(aspect);

  @override
  void updateRenderObject(BuildContext context, RenderBookAspect renderObject) {
    renderObject.aspect = aspect;
  }
}

class RenderBookAspect extends RenderProxyBox {
  RenderBookAspect(this._aspect);

  double _aspect;
  set aspect(double value) {
    if (value == _aspect) return;
    _aspect = value;
    markNeedsLayout();
  }

  double _min(double width) => width.isFinite ? width / _aspect : 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_min(width), super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_min(width), super.computeMaxIntrinsicHeight(width));

  /// The height: the book's proportions, or the content's own minimum
  /// when it needs more (large text), within the constraints.
  double _height(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final content = child?.getMinIntrinsicHeight(width) ?? 0;
    return constraints.constrainHeight(math.max(_min(width), content));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      Size(constraints.maxWidth, _height(constraints));

  @override
  void performLayout() {
    final height = _height(constraints);
    final width = constraints.maxWidth;
    child?.layout(
      BoxConstraints.tightFor(width: width, height: height),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(width, height));
  }
}

/// A library cover as a book seen from the front: the leather face, the
/// spine on the reading start with three raised bands, the page block
/// showing along the fore-edge, one gilt fillet, and one of three tooled
/// ornaments picked by the book ([variant]): the lobed mandorla with its
/// pendants, arabesque bands at head and tail, or the four corner pieces.
/// The title is stamped on top by the widget.
class BookCoverPainter extends CustomPainter {
  const BookCoverPainter({
    required this.style,
    required this.leather,
    required this.pages,
    required this.variant,
    this.rtl = false,
    this.radius = 6,
  });

  final OrnamentStyle style;
  final Color leather;

  /// The paper of the page block along the fore-edge.
  final Color pages;
  final int variant;
  final bool rtl;
  final double radius;

  /// The spine's share of the cover's width.
  static const double spine = 0.1;

  /// The page block's width at the fore-edge.
  static const double pageBlock = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final spineW = w * spine;
    double x(double ltr) => rtl ? w - ltr : ltr;
    Rect span(double from, double to) =>
        Rect.fromLTRB(math.min(x(from), x(to)), 0, math.max(x(from), x(to)), h);

    // The page block peeks out at the fore-edge, under the board.
    final block = span(w - pageBlock - 1, w);
    final blockRect = Rect.fromLTRB(block.left, 2, block.right, h - 2);
    canvas.drawRect(blockRect, Paint()..color = pages);
    final pageLine = Paint()
      ..color = Color.lerp(pages, const Color(0xFF000000), 0.18)!
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      final px = blockRect.left + blockRect.width * i / 3;
      canvas.drawLine(Offset(px, 3), Offset(px, h - 3), pageLine);
    }

    // The board, rounded at the fore-edge.
    final board = span(0, w - pageBlock);
    final r = Radius.circular(radius);
    final s = Radius.circular(radius / 3);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        board,
        topLeft: rtl ? r : s,
        bottomLeft: rtl ? r : s,
        topRight: rtl ? s : r,
        bottomRight: rtl ? s : r,
      ),
      Paint()..color = leather,
    );
    // Light falls across the face; the spine curves away from it.
    canvas.drawRect(
      board,
      Paint()
        ..shader = LinearGradient(
          begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
          end: rtl ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [
            Color(0x47000000),
            Color(0x14000000),
            Color(0x00000000),
            Color(0x12FFFFFF),
          ],
          stops: [0, spine, spine + 0.02, 1],
        ).createShader(board),
    );
    // The hinge between spine and face.
    final hinge = x(spineW);
    canvas.drawLine(
      Offset(hinge, 0),
      Offset(hinge, h),
      Paint()
        ..color = const Color(0x52000000)
        ..strokeWidth = 1.2,
    );
    // Raised bands across the spine.
    final band = style.copyWith(stroke: style.stroke * 0.9);
    for (final at in [0.16, 0.5, 0.84]) {
      final y = h * at;
      for (final dy in [-1.6, 1.6]) {
        band.draw(
          canvas,
          Path()
            ..moveTo(x(spineW * 0.18), y + dy)
            ..lineTo(x(spineW * 0.82), y + dy),
          closed: false,
        );
      }
    }

    // The face: one gilt fillet.
    final faceLeft = spineW + w * 0.06;
    final faceRight = w - pageBlock - w * 0.07;
    final inset = h * 0.045;
    final frame = Rect.fromLTRB(
      math.min(x(faceLeft), x(faceRight)),
      inset,
      math.max(x(faceLeft), x(faceRight)),
      h - inset,
    );
    if (frame.width < 24 || frame.height < 24) return;
    style.draw(canvas, Path()..addRect(frame));

    switch (variant % 3) {
      case 0:
        // The mandorla with its pendants in the head of the face.
        final b = frame.height * 0.13;
        final a = math.min(b * 0.52, frame.width * 0.26);
        final c = Offset(frame.center.dx, frame.top + frame.height * 0.24);
        style.draw(canvas, BookTooling.lobedMandorla(c, a, b));
        style.draw(canvas, BookTooling.mandorla(c, a * 0.62, b * 0.7));
        final p = b * 0.42;
        for (final dir in [-1.0, 1.0]) {
          final tip = Offset(c.dx, c.dy + dir * b);
          final end = tip + Offset(0, dir * p * 0.4);
          style.draw(
            canvas,
            Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(end.dx, end.dy),
            closed: false,
          );
          style.draw(
            canvas,
            BookTooling.lobedMandorla(
              Offset(end.dx, end.dy + dir * p * 0.5),
              p * 0.32,
              p * 0.5,
              lobes: 6,
            ),
          );
        }
      case 1:
        // Arabesque bands at the head and the tail of the face.
        final bandH = frame.height * 0.07;
        for (final top in [
          frame.top + frame.height * 0.06,
          frame.bottom - frame.height * 0.06 - bandH,
        ]) {
          canvas.save();
          final rect = Rect.fromLTWH(
            frame.left + frame.width * 0.08,
            top,
            frame.width * 0.84,
            bandH,
          );
          canvas.translate(rect.left, rect.top);
          ArabesqueBorderPainter(
            style: style,
            module: rect.height * 2.2,
          ).paint(canvas, rect.size);
          canvas.restore();
        }
      default:
        // The four corner pieces and a small knot at the head.
        final cw = frame.width * 0.24;
        final ch = cw * 1.05;
        for (final (corner, dx, dy) in [
          (frame.topLeft, 1.0, 1.0),
          (frame.topRight, -1.0, 1.0),
          (frame.bottomLeft, 1.0, -1.0),
          (frame.bottomRight, -1.0, -1.0),
        ]) {
          style.draw(
            canvas,
            BookTooling.quarterLobes(corner, cw, ch, dx, dy),
            closed: false,
          );
        }
        final c = Offset(frame.center.dx, frame.top + frame.height * 0.2);
        style.draw(
          canvas,
          BookTooling.lobedMandorla(
            c,
            frame.width * 0.07,
            frame.width * 0.12,
            lobes: 8,
          ),
        );
    }
  }

  @override
  bool shouldRepaint(BookCoverPainter old) =>
      old.style != style ||
      old.leather != leather ||
      old.pages != pages ||
      old.variant != variant ||
      old.rtl != rtl ||
      old.radius != radius;
}

/// The library's header: a shelf of bound books in gilt line, standing
/// spines of different heights and widths, each with raised bands, one
/// tooled with a small mandorla, the last one leaning on its neighbour.
/// [draw] (0–1) shelves it as the library opens: the shelf rule runs out,
/// the books are set down on it one after another, and the last one tips
/// over onto its neighbour. Without it the shelf is full.
class BookShelfPainter extends CustomPainter {
  const BookShelfPainter({required this.style, this.draw})
    : super(repaint: draw);

  final OrnamentStyle style;
  final Animation<double>? draw;

  // Width and height of each spine as a share of the art (width, height).
  static const _books = [
    (0.1, 0.78),
    (0.085, 0.66),
    (0.13, 0.9),
    (0.095, 0.72),
    (0.11, 0.84),
    (0.075, 0.62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pad = style.stroke * 6;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final t = (draw?.value ?? 1).clamp(0.0, 1.0);
    // A piece's own progress, eased, in its share of the run.
    double at(double start, double length) =>
        Curves.easeOutCubic.transform(((t - start) / length).clamp(0.0, 1.0));
    canvas.save();
    canvas.translate(pad, pad);
    final shelf = h * 0.96;
    // The shelf, a double rule, running out from its start.
    final run = at(0, 0.3);
    if (run > 0) {
      style.draw(
        canvas,
        Path()
          ..moveTo(0, shelf)
          ..lineTo(w * run, shelf)
          ..moveTo(w * 0.04, shelf + h * 0.035)
          ..lineTo(w * (0.04 + 0.92 * run), shelf + h * 0.035),
        closed: false,
      );
    }
    // Keep clear of the trailing edge, where the leaning book ends.
    var left = 0.0;
    final gap = w * 0.01;
    for (final (i, (bw, bh)) in _books.indexed) {
      final rect = Rect.fromLTWH(left, shelf - h * bh, w * bw, h * bh);
      // Set down in turn: each lowers the last stretch onto the shelf as
      // it appears.
      final placed = at(0.14 + i * 0.08, 0.3);
      if (placed > 0) {
        canvas.save();
        canvas.translate(0, -(1 - placed) * h * 0.1);
        _spine(canvas, rect, tooled: i == 2, style: _faded(placed));
        canvas.restore();
      }
      left = rect.right + gap;
    }
    // The last book leans on its neighbour: it stands, then tips over.
    final stood = at(0.62, 0.14);
    if (stood > 0) {
      final lean = Rect.fromLTWH(0, -h * 0.7, w * 0.1, h * 0.7);
      canvas.save();
      canvas.translate(left + w * 0.03, shelf);
      canvas.rotate(0.32 * at(0.72, 0.28));
      _spine(canvas, lean, tooled: false, style: _faded(stood));
      canvas.restore();
    }
    canvas.restore();
  }

  OrnamentStyle _faded(double opacity) => opacity >= 1
      ? style
      : style.copyWith(
          color: style.color.withValues(alpha: style.color.a * opacity),
        );

  void _spine(
    Canvas canvas,
    Rect rect, {
    required bool tooled,
    required OrnamentStyle style,
  }) {
    style.draw(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.12)),
      ),
    );
    for (final at in [0.12, 0.88]) {
      final y = rect.top + rect.height * at;
      style.draw(
        canvas,
        Path()
          ..moveTo(rect.left + rect.width * 0.15, y - 1.5)
          ..lineTo(rect.right - rect.width * 0.15, y - 1.5)
          ..moveTo(rect.left + rect.width * 0.15, y + 1.5)
          ..lineTo(rect.right - rect.width * 0.15, y + 1.5),
        closed: false,
      );
    }
    final c = rect.center;
    if (tooled) {
      style.draw(
        canvas,
        BookTooling.lobedMandorla(
          c,
          rect.width * 0.24,
          rect.height * 0.16,
          lobes: 10,
        ),
      );
    } else {
      // A title label between the bands.
      style.draw(
        canvas,
        Path()..addRect(
          Rect.fromCenter(
            center: Offset(c.dx, rect.top + rect.height * 0.32),
            width: rect.width * 0.5,
            height: rect.height * 0.14,
          ),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(BookShelfPainter old) =>
      old.style != style || old.draw != draw;
}
