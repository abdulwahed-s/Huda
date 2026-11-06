import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// The Six Books (Kutub al-Sittah) by their sunnah.com slugs, in the order
/// they lead the collections. The identity's count: six, and the header
/// folio's chain has six narrators.
const hadithSixBooks = [
  'bukhari',
  'muslim',
  'abudawud',
  'tirmidhi',
  'nasai',
  'ibnmajah',
];

/// Hadith's voice: a manuscript folio, ruled with a jadwal, its isnad drawn
/// as a chain of ink nodes running down the margin into a seal. Paper and
/// ink. See `design/IDENTITIES.md` and `design/features/hadith/brief.md`.
final FeatureIdentity hadithIdentity = FeatureIdentity(
  id: 'hadith',
  motif:
      'A manuscript folio: a jadwal-ruled page, a rubric, and the isnad as '
      'a chain of ink nodes running into a seal',
  count: hadithSixBooks.length,
  rhythm: IdentityRhythm.sequence,
  material: IdentityMaterial.paper,
  headerArt: (style) => HadithFolioPainter(style: style),
);

/// A folio: a page with a wide outer margin, a jadwal (a double rule)
/// around the text block, a rubric line and lines of text, and the isnad
/// in the margin, [nodes] linked ink nodes running down into a seal.
///
/// [ink] draws it: the rules first, then the lines, then the chain node by
/// node (0 nothing, 1 complete). Pass an animation as [inkOf] to animate it
/// without rebuilding. [small] is the tile mark: no chain, fewer lines.
class HadithFolioPainter extends CustomPainter {
  HadithFolioPainter({
    required this.style,
    this.nodes = 6,
    this.small = false,
    double ink = 1,
    this.inkOf,
  }) : _ink = ink,
       super(repaint: inkOf);

  final OrnamentStyle style;
  final int nodes;
  final bool small;
  final double _ink;
  final ValueListenable<double>? inkOf;

  double get ink => inkOf?.value ?? _ink;

  /// The portion of [path] drawn by [t] (0–1), along its length.
  static Path _partial(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    if (t <= 0) return out;
    for (final PathMetric metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  static double _phase(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(ink.clamp(0.0, 1.0));
    if (t <= 0) return;
    final pad = style.stroke * 3;
    // A portrait page, as large as the box allows.
    const ratio = 0.74;
    var h = size.height - pad * 2;
    var w = h * ratio;
    if (w > size.width - pad * 2) {
      w = size.width - pad * 2;
      h = w / ratio;
    }
    if (w <= 0 || h <= 0) return;
    final page = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    final rules = _phase(t, 0, 0.45);
    final lines = _phase(t, 0.25, 0.6);
    final chain = _phase(t, 0.5, 1);

    // The page and the jadwal around the text block, the outer margin
    // (the chain's) on the end.
    style.draw(canvas, _partial(Path()..addRect(page), rules));
    final block = Rect.fromLTRB(
      page.left + w * 0.11,
      page.top + h * 0.1,
      page.right - w * (small ? 0.11 : 0.3),
      page.bottom - h * 0.1,
    );
    final gap = math.max(2.0, w * 0.025);
    final rule = style.copyWith(stroke: style.stroke * 0.8);
    rule.draw(canvas, _partial(Path()..addRect(block), rules));
    rule.draw(canvas, _partial(Path()..addRect(block.deflate(gap)), rules));

    // A rubric, then lines of text.
    final text = block.deflate(gap * 2.6);
    final count = small ? 3 : 7;
    final step = text.height / (count + 0.5);
    final linePaint = style.copyWith(stroke: style.stroke * 0.7);
    for (var i = 0; i < count; i++) {
      final reveal = _phase(lines, i / count, (i + 1.5) / count);
      if (reveal <= 0) break;
      final y = text.top + step * (i + 0.5);
      final rubric = i == 0;
      final inset = rubric ? text.width * 0.22 : 0.0;
      final end = i == count - 1 ? text.width * 0.45 : 0.0;
      final from = Offset(text.left + inset, y);
      final to = Offset(text.right - inset - end, y);
      final line = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(from.dx + (to.dx - from.dx) * reveal, y);
      (rubric ? style.copyWith(stroke: style.stroke * 1.6) : linePaint).draw(
        canvas,
        line,
        closed: false,
      );
    }
    if (small || nodes <= 0) return;

    // The isnad down the margin: nodes linked one by one, the last a seal.
    final x = (block.right + page.right) / 2;
    final top = block.top + gap;
    final sealR = math.min(w * 0.09, (page.right - block.right) * 0.42);
    final bottom = block.bottom - sealR;
    final r = math.max(1.5, sealR * 0.32);
    final span = (bottom - top) / nodes;
    for (var i = 0; i < nodes; i++) {
      final reveal = _phase(chain, i / (nodes + 1), (i + 1) / (nodes + 1));
      if (reveal <= 0) break;
      final c = Offset(x, top + span * i);
      style.draw(
        canvas,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      );
      final next = i == nodes - 1
          ? Offset(x, bottom - sealR)
          : Offset(x, top + span * (i + 1) - r);
      final link = Path()
        ..moveTo(x, c.dy + r)
        ..lineTo(x, c.dy + r + (next.dy - c.dy - r) * reveal);
      linePaint.draw(canvas, link, closed: false);
    }
    final seal = _phase(chain, nodes / (nodes + 1), 1);
    if (seal > 0) {
      final c = Offset(x, bottom);
      style.draw(
        canvas,
        _partial(
          Path()..addOval(Rect.fromCircle(center: c, radius: sealR)),
          seal,
        ),
      );
      canvas.drawCircle(c, sealR * 0.45 * seal, style.fill(0.9));
    }
  }

  @override
  bool shouldRepaint(HadithFolioPainter old) =>
      old.style != style ||
      old.nodes != nodes ||
      old.small != small ||
      old._ink != _ink ||
      old.inkOf != inkOf;
}

/// Plays the ink once: [builder] gets a listenable from 0 to 1 that draws
/// the folio's rules, lines and chain. Complete from the first frame under
/// reduce motion.
class HadithInk extends StatefulWidget {
  const HadithInk({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1100),
  });

  final Widget Function(BuildContext context, ValueListenable<double> ink)
  builder;
  final Duration duration;

  @override
  State<HadithInk> createState() => _HadithInkState();
}

class _HadithInkState extends State<HadithInk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
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
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// A collection's mark on its tile: a small folio.
class HadithFolioMark extends StatelessWidget {
  const HadithFolioMark({super.key, this.quiet = false});

  /// A collection that isn't available yet.
  final bool quiet;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 44,
    child: Ornament(
      painter: HadithFolioPainter(
        style: OrnamentStyle.of(context, quiet: quiet),
        small: true,
      ),
    ),
  );
}

/// The isnad as a line of linked nodes at an even step, from the first
/// narrator to the last, filled node: the source, the Prophet ﷺ. It runs
/// from the start of [textDirection] (beside the hadith's seal) to its
/// end. Decorative.
class HadithChainPainter extends CustomPainter {
  const HadithChainPainter({
    required this.style,
    required this.nodes,
    this.textDirection = TextDirection.ltr,
  });

  final OrnamentStyle style;
  final int nodes;
  final TextDirection textDirection;

  static const double step = 26;
  static const double _r = 3.5;
  static const double _end = _r * 2.2;

  /// The width the chain of [nodes] narrators takes at its step.
  static double widthFor(int nodes) => nodes <= 0 ? 0 : nodes * step + _end * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes <= 0) return;
    final y = size.height / 2;
    final r = math.min(_r, size.height / 4);
    final gap = math.min(step, (size.width - _end * 2) / nodes);
    if (gap <= r * 2.5) return;
    final rtl = textDirection == TextDirection.rtl;
    double x(double fromStart) => rtl ? size.width - fromStart : fromStart;
    final link = style.copyWith(stroke: style.stroke * 0.7);
    for (var i = 0; i < nodes; i++) {
      final c = Offset(x(r + gap * i), y);
      style.draw(
        canvas,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      );
      final last = i == nodes - 1;
      final from = r * 2 + gap * i;
      final to = last ? r + gap * nodes - _end + r : r + gap * (i + 1) - r;
      link.draw(
        canvas,
        Path()
          ..moveTo(x(from), y)
          ..lineTo(x(to), y),
        closed: false,
      );
    }
    final source = Offset(x(r + gap * nodes + _end - r), y);
    canvas.drawCircle(source, r * 1.1, style.fill());
    style.draw(
      canvas,
      Path()..addOval(Rect.fromCircle(center: source, radius: _end)),
    );
  }

  @override
  bool shouldRepaint(HadithChainPainter old) =>
      old.style != style ||
      old.nodes != nodes ||
      old.textDirection != textDirection;
}

/// How many narrators a chain names: runs marked as narrators, counting
/// neighbors (one name split by formatting) once.
int hadithNarratorCount(Iterable<bool> narratorRuns) {
  var count = 0;
  var previous = false;
  for (final narrator in narratorRuns) {
    if (narrator && !previous) count++;
    previous = narrator;
  }
  return count;
}

/// A round ink seal: a ring, a beaded ring inside it, and [child] in the
/// middle. Hadith numbers sit in small ones; the share card's carries the
/// collection.
class HadithSeal extends StatelessWidget {
  const HadithSeal({
    super.key,
    required this.size,
    required this.child,
    this.color,
  });

  final double size;
  final Widget child;

  /// The ink; defaults to the theme's primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SealPainter(color: ink, stroke: context.tokens.stroke.fine),
        child: Center(child: child),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: color.a * 0.85);
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * 0.8, line..strokeWidth = stroke * 0.6);
    // A milled edge between the rings, like a stamp's: fine radial ticks
    // (not beads, which are Tasbih's).
    final ticks = math.max(24, (r * 1.6).round());
    final tick = Paint()
      ..strokeWidth = stroke * 0.6
      ..color = color.withValues(alpha: color.a * 0.55);
    for (var i = 0; i < ticks; i++) {
      final a = i * 2 * math.pi / ticks;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r * 0.84), c + d * (r * 0.95), tick);
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.color != color || old.stroke != stroke;
}
