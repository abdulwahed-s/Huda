import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

/// Onboarding's voice: the threshold arcade. A receding arcade of
/// multifoil (polylobed) arches, one per step, nested toward a doorway of
/// light, in luminous gilt on the chrome. Lit arches are the steps behind
/// you; the next one lights as you step forward. See
/// `design/IDENTITIES.md`.
final FeatureIdentity onboardingIdentity = FeatureIdentity(
  id: 'onboarding',
  motif: 'A receding arcade of multifoil arches, one per step',
  count: 9,
  rhythm: IdentityRhythm.sequence,
  material: IdentityMaterial.stone,
  headerArt: (style) => OnboardingArcadePainter(style: style, count: 7),
);

/// The lobes on each arch's crown (Córdoba's cusped arches).
const int _lobes = 7;

/// Draws the arcade: [count] arches, the outermost first, framed by a
/// rectangular alfiz. [lit] arches are drawn bright (a fraction lights the
/// next arch from both jambs up to its crown); the rest are quiet.
/// [reveal] draws the whole arcade in on first open (0 → 1, outer arch
/// first); [flood] fills the doorway with light when setup finishes.
class OnboardingArcadePainter extends CustomPainter {
  const OnboardingArcadePainter({
    required this.style,
    required this.count,
    this.lit = 1,
    this.reveal = 1,
    this.flood = 0,
  });

  final OrnamentStyle style;
  final int count;
  final double lit;
  final double reveal;
  final double flood;

  /// Each arch's crown in a box of [width] × [height] whose base is at the
  /// bottom: two jambs and seven lobes cut into a round head, drawn as two
  /// halves (left jamb up to the keystone, right jamb up to the keystone),
  /// so the light can climb both jambs at once.
  static (Path, Path) archHalves(Rect box) {
    final r = box.width / 2;
    final cx = box.center.dx;
    final spring = box.top + r;
    final left = Path()..moveTo(box.left, box.bottom);
    final right = Path()..moveTo(box.right, box.bottom);
    left.lineTo(box.left, spring);
    right.lineTo(box.right, spring);
    // Lobe points on the head, from the left spring over the top.
    final points = [
      for (var i = 0; i <= _lobes; i++)
        Offset(
          cx - r * math.cos(math.pi * i / _lobes),
          spring - r * math.sin(math.pi * i / _lobes),
        ),
    ];
    final chord = (points[1] - points[0]).distance;
    final lobe = Radius.circular(chord * 0.62);
    // The middle lobe is split at its top so both halves meet there.
    final mid = _lobes ~/ 2;
    for (var i = 0; i < mid; i++) {
      left.arcToPoint(points[i + 1], radius: lobe);
    }
    final keystone = Offset(cx, spring - r - chord * 0.18);
    left.arcToPoint(keystone, radius: lobe);
    for (var i = _lobes; i > _lobes - mid; i--) {
      right.arcToPoint(points[i - 1], radius: lobe, clockwise: false);
    }
    right.arcToPoint(keystone, radius: lobe, clockwise: false);
    return (left, right);
  }

  /// The [i]th arch's box: smaller and higher toward the doorway, as if
  /// seen down an arcade.
  static Rect archBox(Size size, int i, int count) {
    final outerW = math.min(size.width * 0.86, size.height * 0.64);
    final outerH = outerW / 0.64;
    final vanish = Offset(size.width / 2, size.height * 0.56);
    final last = math.max(1, count - 1);
    final k = math.pow(0.3, i / last).toDouble();
    final base = vanish.dy + (size.height - vanish.dy) * k;
    final w = outerW * k;
    final h = outerH * k;
    return Rect.fromLTWH(vanish.dx - w / 2, base - h, w, h);
  }

  Iterable<Path> _part(Path path, double t) sync* {
    if (t <= 0) return;
    for (final PathMetric metric in path.computeMetrics()) {
      yield metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0 || size.isEmpty) return;
    final quiet = style.copyWith(
      color: style.color.withValues(alpha: style.color.a * 0.2),
      render: OrnamentRender.line,
    );
    final bright = style;

    // The doorway: the innermost arch filled with soft light that grows to
    // a flood when setup finishes.
    final inner = archBox(size, count - 1, count);
    final (dl, dr) = archHalves(inner);
    final doorGlow = 0.08 + 0.22 * (lit / count).clamp(0.0, 1.0) + 0.5 * flood;
    final doorPaint = Paint()
      ..color = style.color.withValues(alpha: doorGlow * reveal);
    for (final half in [dl, dr]) {
      canvas.drawPath(
        Path.from(half)
          ..lineTo(inner.center.dx, inner.bottom)
          ..close(),
        doorPaint,
      );
    }
    if (flood > 0) {
      final glow = inner.bottomCenter;
      final radius = size.height * (0.2 + 0.9 * flood);
      canvas.drawCircle(
        glow,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              style.color.withValues(alpha: 0.5 * flood),
              style.color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: glow, radius: radius)),
      );
    }

    for (var i = 0; i < count; i++) {
      // The arcade draws in from the outside: each arch over its own slice
      // of the reveal, overlapping the next.
      final window = 1 / (count + 1);
      final drawn = ((reveal - i * window) / (window * 2)).clamp(0.0, 1.0);
      if (drawn <= 0) continue;
      final box = archBox(size, i, count);
      final (left, right) = archHalves(box);
      final light = (lit - i).clamp(0.0, 1.0);
      for (final half in [left, right]) {
        for (final part in _part(half, drawn)) {
          quiet.draw(canvas, part, closed: false);
        }
        for (final part in _part(half, math.min(drawn, light))) {
          bright.draw(canvas, part, closed: false);
        }
      }
      if (i == 0) _alfiz(canvas, box, drawn, light > 0 ? bright : quiet);
    }
  }

  /// The rectangular frame around the outer arch's head.
  void _alfiz(Canvas canvas, Rect box, double drawn, OrnamentStyle s) {
    final pad = box.width * 0.08;
    final top = box.top - pad;
    final spring = box.top + box.width / 2 + pad * 0.6;
    final frame = Path()
      ..moveTo(box.left - pad, spring)
      ..lineTo(box.left - pad, top)
      ..lineTo(box.right + pad, top)
      ..lineTo(box.right + pad, spring);
    for (final part in _part(frame, drawn)) {
      s.copyWith(stroke: s.stroke * 0.7).draw(canvas, part, closed: false);
    }
  }

  @override
  bool shouldRepaint(OnboardingArcadePainter old) =>
      old.style != style ||
      old.count != count ||
      old.lit != lit ||
      old.reveal != reveal ||
      old.flood != flood;
}

/// The arcade on the chrome, moving with the wizard: it draws itself in
/// once when [entrance] (1.1 s), lights the next arch as [lit] grows and
/// puts it out as it shrinks (700 ms), and floods the doorway as [flood]
/// turns on (900 ms). Under reduce motion it shows the end state.
class OnboardingArcade extends StatefulWidget {
  const OnboardingArcade({
    super.key,
    required this.count,
    required this.lit,
    this.flood = false,
    this.entrance = false,
    this.semanticLabel,
    this.logo = false,
  });

  final int count;
  final int lit;
  final bool flood;
  final bool entrance;
  final String? semanticLabel;

  /// Huda's logo in gilt inside the doorway (the welcome).
  final bool logo;

  static const drawIn = Duration(milliseconds: 1100);
  static const step = Duration(milliseconds: 700);
  static const floodIn = Duration(milliseconds: 900);

  @override
  State<OnboardingArcade> createState() => _OnboardingArcadeState();
}

class _OnboardingArcadeState extends State<OnboardingArcade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: OnboardingArcade.drawIn,
    value: widget.entrance ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reveal.value < 1 && !_reveal.isAnimating) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward();
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = OrnamentStyle.of(context, onChrome: true);
    final stepDuration = tokens.motion.of(context, OnboardingArcade.step);
    final floodDuration = tokens.motion.of(context, OnboardingArcade.floodIn);
    final arcade = TweenAnimationBuilder<double>(
      tween: Tween(end: widget.lit.toDouble()),
      duration: stepDuration,
      curve: tokens.motion.emphasized,
      builder: (context, lit, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: widget.flood ? 1 : 0),
        duration: floodDuration,
        curve: Curves.easeOutCubic,
        builder: (context, flood, _) => AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: OnboardingArcadePainter(
              style: style,
              count: widget.count,
              lit: lit,
              reveal: Curves.easeInOutCubic.transform(_reveal.value),
              flood: flood,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: widget.logo
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final door = OnboardingArcadePainter.archBox(
                    size,
                    widget.count - 1,
                    widget.count,
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      arcade,
                      Positioned.fromRect(
                        rect: Rect.fromCenter(
                          center: Offset(
                            door.center.dx,
                            door.bottom - door.height * 0.38,
                          ),
                          width: door.width * 1.6,
                          height: door.width * 0.62,
                        ),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _reveal,
                            curve: const Interval(0.6, 1),
                          ),
                          child: OnboardingLogo(color: tokens.gilt),
                        ),
                      ),
                    ],
                  );
                },
              )
            : arcade,
      ),
    );
  }
}

/// Huda's logo glyph tinted [color], fitted into its box (the asset's
/// padding cropped away).
class OnboardingLogo extends StatelessWidget {
  const OnboardingLogo({super.key, required this.color});

  final Color color;

  // The glyph's box inside the 1024 square asset.
  static const _glyphWidth = 830 / 1024;
  static const _glyphHeight = 448 / 1024;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = math.min(
        constraints.maxHeight,
        constraints.maxWidth * _glyphHeight / _glyphWidth,
      );
      final side = height / _glyphHeight;
      return Center(
        child: SizedBox(
          width: side * _glyphWidth,
          height: height,
          child: OverflowBox(
            maxWidth: side,
            maxHeight: side,
            child: Image.asset(
              BrandedShareFrame.logoAsset,
              width: side,
              height: side,
              color: color,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    },
  );
}

/// Draws [paths] up to [t] of their length (each path from its start).
void _drawPartial(
  Canvas canvas,
  OrnamentStyle style,
  Iterable<Path> paths,
  double t,
) {
  if (t <= 0) return;
  for (final path in paths) {
    for (final metric in path.computeMetrics()) {
      style.draw(
        canvas,
        metric.extractPath(0, metric.length * t.clamp(0.0, 1.0)),
        closed: false,
      );
    }
  }
}

/// A step's emblem: what the step sets up, drawn as gilt line work in a
/// square [r] (a minaret calling the adhan, a gnomon's shadow for Asr, a
/// globe and pin for the location…). [masks] are filled with the ground
/// first, so a shape in front hides the lines behind it.
({List<Path> lines, List<Path> masks}) onboardingEmblem(
  OnboardingStep step,
  Rect r,
) {
  Offset p(double x, double y) =>
      Offset(r.left + x * r.width, r.top + y * r.height);
  final s = r.width;
  final lines = <Path>[];
  final masks = <Path>[];
  Path circle(double x, double y, double radius) =>
      Path()..addOval(Rect.fromCircle(center: p(x, y), radius: radius * s));
  Path line(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  Path rays(
    double x,
    double y,
    double from,
    double to,
    double a0,
    double a1,
    int count,
  ) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final a = a0 + (a1 - a0) * (count == 1 ? 0.5 : i / (count - 1));
      final c = p(x, y);
      path
        ..moveTo(c.dx + math.cos(a) * from * s, c.dy + math.sin(a) * from * s)
        ..lineTo(c.dx + math.cos(a) * to * s, c.dy + math.sin(a) * to * s);
    }
    return path;
  }

  Path sparkle(double x, double y, double size) {
    final c = p(x, y);
    final k = size * s;
    return Path()
      ..moveTo(c.dx, c.dy - k)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + k, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + k)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - k, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - k);
  }

  Path pin(double x, double tipY, double headY, double radius) {
    final tip = p(x, tipY);
    final rad = radius * s;
    final head = p(x, headY);
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        tip.dx - rad * 0.35,
        tip.dy - (tip.dy - head.dy) * 0.35,
        head.dx - rad,
        head.dy + rad * 0.7,
        head.dx - rad,
        head.dy,
      )
      ..arcToPoint(Offset(head.dx + rad, head.dy), radius: Radius.circular(rad))
      ..cubicTo(
        head.dx + rad,
        head.dy + rad * 0.7,
        tip.dx + rad * 0.35,
        tip.dy - (tip.dy - head.dy) * 0.35,
        tip.dx,
        tip.dy,
      )
      ..close();
  }

  Path crescent(double x, double y, double radius) => Path.combine(
    PathOperation.difference,
    circle(x, y, radius),
    circle(x + radius * 0.55, y - radius * 0.25, radius * 0.85),
  );

  switch (step) {
    case OnboardingStep.appearance:
      // Light and dark in one disc: the terminator between them, stars on
      // the night side (no sun: the rising sun is Athkar's).
      lines
        ..add(circle(0.5, 0.5, 0.26))
        ..add(
          Path()
            ..moveTo(p(0.5, 0.24).dx, p(0.5, 0.24).dy)
            ..arcToPoint(p(0.5, 0.76), radius: Radius.circular(0.34 * s)),
        )
        ..add(sparkle(0.82, 0.26, 0.06))
        ..add(sparkle(0.86, 0.72, 0.035));
    case OnboardingStep.focus:
      // Three doorways to choose from, the middle one taller.
      Path door(double x, double w, double h) {
        const base = 0.82;
        final half = w / 2;
        final spring = base - h + half;
        return Path()
          ..moveTo(p(x - half, base).dx, p(x - half, base).dy)
          ..lineTo(p(x - half, spring).dx, p(x - half, spring).dy)
          ..arcToPoint(p(x + half, spring), radius: Radius.circular(half * s))
          ..lineTo(p(x + half, base).dx, p(x + half, base).dy);
      }
      lines
        ..add(door(0.2, 0.2, 0.44))
        ..add(door(0.5, 0.26, 0.6))
        ..add(door(0.8, 0.2, 0.44))
        ..add(line([p(0.04, 0.82), p(0.96, 0.82)]));
    case OnboardingStep.permissions:
      // A location pin beside a bell: the two things Huda asks for.
      final bell = Path()
        ..moveTo(p(0.52, 0.7).dx, p(0.52, 0.7).dy)
        ..quadraticBezierTo(
          p(0.58, 0.64).dx,
          p(0.58, 0.64).dy,
          p(0.58, 0.48).dx,
          p(0.58, 0.48).dy,
        )
        ..cubicTo(
          p(0.58, 0.3).dx,
          p(0.58, 0.3).dy,
          p(0.86, 0.3).dx,
          p(0.86, 0.3).dy,
          p(0.86, 0.48).dx,
          p(0.86, 0.48).dy,
        )
        ..quadraticBezierTo(
          p(0.86, 0.64).dx,
          p(0.86, 0.64).dy,
          p(0.92, 0.7).dx,
          p(0.92, 0.7).dy,
        )
        ..close();
      lines
        ..add(pin(0.3, 0.8, 0.38, 0.17))
        ..add(circle(0.3, 0.38, 0.06))
        ..add(bell)
        ..add(line([p(0.72, 0.33), p(0.72, 0.27)]))
        ..add(
          Path()..addArc(
            Rect.fromCircle(center: p(0.72, 0.72), radius: 0.05 * s),
            0,
            math.pi,
          ),
        );
    case OnboardingStep.location:
      // A globe with a pin standing on it.
      lines
        ..add(circle(0.5, 0.6, 0.3))
        ..add(
          Path()..addOval(
            Rect.fromCenter(
              center: p(0.5, 0.6),
              width: 0.28 * s,
              height: 0.6 * s,
            ),
          ),
        )
        ..add(line([p(0.2, 0.6), p(0.8, 0.6)]))
        ..add(
          Path()..addArc(
            Rect.fromCenter(
              center: p(0.5, 0.6),
              width: 0.54 * s,
              height: 0.3 * s,
            ),
            math.pi * 1.08,
            math.pi * 0.84,
          ),
        );
      final head = pin(0.5, 0.52, 0.2, 0.13);
      masks.add(head);
      lines
        ..add(head)
        ..add(circle(0.5, 0.2, 0.045));
    case OnboardingStep.asr:
      // A gnomon on the ground, the light's line over its tip, and its
      // shadow: Asr is told by the length of a shadow.
      lines
        ..add(line([p(0.06, 0.78), p(0.94, 0.78)]))
        ..add(line([p(0.32, 0.78), p(0.32, 0.4)]))
        ..add(line([p(0.32, 0.78), p(0.88, 0.78)]))
        ..add(line([p(0.7, 0.74), p(0.7, 0.82)]))
        ..add(line([p(0.32, 0.4), p(0.88, 0.78)]));
    case OnboardingStep.alerts:
      // A minaret calling the adhan: the shaft, the balcony, the dome and
      // its crescent, and the call spreading out on both sides.
      final dome = Path()
        ..moveTo(p(0.44, 0.31).dx, p(0.44, 0.31).dy)
        ..quadraticBezierTo(
          p(0.44, 0.22).dx,
          p(0.44, 0.22).dy,
          p(0.5, 0.18).dx,
          p(0.5, 0.18).dy,
        )
        ..quadraticBezierTo(
          p(0.56, 0.22).dx,
          p(0.56, 0.22).dy,
          p(0.56, 0.31).dx,
          p(0.56, 0.31).dy,
        );
      lines
        ..add(
          line([p(0.42, 0.88), p(0.42, 0.46), p(0.58, 0.46), p(0.58, 0.88)]),
        )
        ..add(line([p(0.36, 0.46), p(0.64, 0.46)]))
        ..add(line([p(0.38, 0.46), p(0.42, 0.52)]))
        ..add(line([p(0.62, 0.46), p(0.58, 0.52)]))
        ..add(
          line([p(0.45, 0.46), p(0.45, 0.31), p(0.55, 0.31), p(0.55, 0.46)]),
        )
        ..add(line([p(0.43, 0.31), p(0.57, 0.31)]))
        ..add(dome)
        ..add(line([p(0.5, 0.18), p(0.5, 0.12)]))
        ..add(crescent(0.5, 0.09, 0.03))
        ..add(line([p(0.47, 0.88), p(0.47, 0.74)]))
        ..add(
          Path()
            ..moveTo(p(0.47, 0.74).dx, p(0.47, 0.74).dy)
            ..arcToPoint(p(0.53, 0.74), radius: Radius.circular(0.03 * s))
            ..lineTo(p(0.53, 0.88).dx, p(0.53, 0.88).dy),
        )
        ..add(line([p(0.22, 0.88), p(0.78, 0.88)]));
      for (final radius in const [0.16, 0.24, 0.32]) {
        final box = Rect.fromCircle(center: p(0.5, 0.38), radius: radius * s);
        lines
          ..add(Path()..addArc(box, math.pi * 0.86, math.pi * 0.2))
          ..add(Path()..addArc(box, -math.pi * 0.06, math.pi * 0.2));
      }
    case OnboardingStep.reliability:
      // A shield that holds: alerts that always arrive.
      lines
        ..add(
          Path()
            ..moveTo(p(0.5, 0.14).dx, p(0.5, 0.14).dy)
            ..lineTo(p(0.8, 0.25).dx, p(0.8, 0.25).dy)
            ..lineTo(p(0.8, 0.5).dx, p(0.8, 0.5).dy)
            ..cubicTo(
              p(0.8, 0.7).dx,
              p(0.8, 0.7).dy,
              p(0.64, 0.82).dx,
              p(0.64, 0.82).dy,
              p(0.5, 0.88).dx,
              p(0.5, 0.88).dy,
            )
            ..cubicTo(
              p(0.36, 0.82).dx,
              p(0.36, 0.82).dy,
              p(0.2, 0.7).dx,
              p(0.2, 0.7).dy,
              p(0.2, 0.5).dx,
              p(0.2, 0.5).dy,
            )
            ..lineTo(p(0.2, 0.25).dx, p(0.2, 0.25).dy)
            ..close(),
        )
        ..add(line([p(0.37, 0.51), p(0.47, 0.61), p(0.65, 0.41)]));
    case OnboardingStep.mushaf:
      // An open Mushaf on its folding stand (rahle).
      Path page(double sign) {
        double x(double v) => 0.5 + sign * v;
        return Path()
          ..moveTo(p(x(0), 0.3).dx, p(x(0), 0.3).dy)
          ..quadraticBezierTo(
            p(x(0.16), 0.22).dx,
            p(x(0.16), 0.22).dy,
            p(x(0.36), 0.27).dx,
            p(x(0.36), 0.27).dy,
          )
          ..lineTo(p(x(0.36), 0.58).dx, p(x(0.36), 0.58).dy)
          ..quadraticBezierTo(
            p(x(0.16), 0.53).dx,
            p(x(0.16), 0.53).dy,
            p(x(0), 0.62).dx,
            p(x(0), 0.62).dy,
          );
      }
      Path textLine(double sign, double y) {
        double x(double v) => 0.5 + sign * v;
        return Path()
          ..moveTo(p(x(0.06), y).dx, p(x(0.06), y).dy)
          ..quadraticBezierTo(
            p(x(0.17), y - 0.04).dx,
            p(x(0.17), y - 0.04).dy,
            p(x(0.3), y - 0.01).dx,
            p(x(0.3), y - 0.01).dy,
          );
      }
      lines
        ..add(page(-1))
        ..add(page(1))
        ..add(line([p(0.5, 0.3), p(0.5, 0.62)]));
      for (final y in const [0.36, 0.44, 0.52]) {
        lines
          ..add(textLine(-1, y))
          ..add(textLine(1, y));
      }
      lines
        ..add(line([p(0.28, 0.9), p(0.72, 0.62)]))
        ..add(line([p(0.72, 0.9), p(0.28, 0.62)]));
    case OnboardingStep.reminders:
      // A reminder's hour: a clock face under the crescent and a star.
      lines
        ..add(circle(0.42, 0.6, 0.24))
        ..add(line([p(0.42, 0.6), p(0.42, 0.44)]))
        ..add(line([p(0.42, 0.6), p(0.54, 0.66)]))
        ..add(rays(0.42, 0.6, 0.19, 0.23, -math.pi / 2, math.pi * 4 / 3, 12))
        ..add(crescent(0.76, 0.26, 0.1))
        ..add(sparkle(0.9, 0.44, 0.04));
    case OnboardingStep.privacy:
      // A padlock: crash reports only with your consent.
      lines
        ..add(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromPoints(p(0.28, 0.46), p(0.72, 0.84)),
              Radius.circular(0.06 * s),
            ),
          ),
        )
        ..add(
          Path()
            ..moveTo(p(0.36, 0.46).dx, p(0.36, 0.46).dy)
            ..lineTo(p(0.36, 0.34).dx, p(0.36, 0.34).dy)
            ..arcToPoint(p(0.64, 0.34), radius: Radius.circular(0.14 * s))
            ..lineTo(p(0.64, 0.46).dx, p(0.64, 0.46).dy),
        )
        ..add(circle(0.5, 0.6, 0.04))
        ..add(line([p(0.5, 0.64), p(0.5, 0.72)]));
    case OnboardingStep.welcome:
    case OnboardingStep.summary:
      break;
  }
  return (lines: lines, masks: masks);
}

/// A step's threshold: one cusped doorway in its alfiz frame, with an
/// inner arch behind it, and the step's emblem standing inside. [t] draws
/// it in (the doorway from both jambs up to the crown, then the emblem).
class OnboardingDoorwayPainter extends CustomPainter {
  const OnboardingDoorwayPainter({
    required this.step,
    required this.style,
    required this.ground,
    this.t = 1,
  });

  final OnboardingStep step;
  final OrnamentStyle style;

  /// The chrome behind, for the emblem's masks.
  final Color ground;
  final double t;

  /// The doorway's box in [size]: the arch's width over its height is
  /// 0.64, with room above for the alfiz.
  static Rect doorBox(Size size) {
    final w = math.min(size.width * 0.84, size.height * 0.6);
    final h = w / 0.64;
    final top = (size.height - h) / 2 + w * 0.05;
    return Rect.fromLTWH((size.width - w) / 2, top, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final box = doorBox(size);
    final w = box.width;
    // The doorway stands from the first frame (it doesn't redraw on every
    // step, which read as a flash); its emblem draws itself in.
    const arch = 1.0;
    final emblemT = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final quiet = style.copyWith(
      color: style.color.withValues(alpha: style.color.a * 0.28),
      render: OrnamentRender.line,
    );

    // The light inside the doorway.
    final (gl, gr) = OnboardingArcadePainter.archHalves(box);
    canvas.drawPath(
      Path.combine(
        PathOperation.union,
        Path.from(gl)
          ..lineTo(box.center.dx, box.bottom)
          ..close(),
        Path.from(gr)
          ..lineTo(box.center.dx, box.bottom)
          ..close(),
      ),
      Paint()..color = style.color.withValues(alpha: 0.07 * arch),
    );

    // The inner arch, quiet, a step deeper.
    final inner = Rect.fromLTRB(
      box.left + w * 0.09,
      box.top + w * 0.1,
      box.right - w * 0.09,
      box.bottom,
    );
    final (il, ir) = OnboardingArcadePainter.archHalves(inner);
    _drawPartial(canvas, quiet, [il, ir], arch);

    // The doorway and its alfiz.
    _drawPartial(canvas, style, [gl, gr], arch);
    final pad = w * 0.08;
    final spring = box.top + w / 2 + pad * 0.6;
    final frameLeft = Path()
      ..moveTo(box.left - pad, spring)
      ..lineTo(box.left - pad, box.top - pad)
      ..lineTo(box.center.dx, box.top - pad);
    final frameRight = Path()
      ..moveTo(box.right + pad, spring)
      ..lineTo(box.right + pad, box.top - pad)
      ..lineTo(box.center.dx, box.top - pad);
    _drawPartial(canvas, style.copyWith(stroke: style.stroke * 0.7), [
      frameLeft,
      frameRight,
    ], arch);
    // The threshold stone.
    _drawPartial(canvas, quiet, [
      Path()
        ..moveTo(box.left - pad * 1.6, box.bottom)
        ..lineTo(box.right + pad * 1.6, box.bottom),
    ], arch);

    // The emblem, standing in the doorway.
    if (emblemT <= 0) return;
    final side = w * 0.84;
    final emblemBox = Rect.fromCenter(
      center: Offset(box.center.dx, box.bottom - side * 0.5),
      width: side,
      height: side,
    );
    final emblem = onboardingEmblem(step, emblemBox);
    final emblemStyle = style.copyWith(stroke: style.stroke * 0.9);
    for (final mask in emblem.masks) {
      canvas.drawPath(mask, Paint()..color = ground.withValues(alpha: emblemT));
    }
    _drawPartial(canvas, emblemStyle, emblem.lines, emblemT);
  }

  @override
  bool shouldRepaint(OnboardingDoorwayPainter old) =>
      old.step != step ||
      old.style != style ||
      old.ground != ground ||
      old.t != t;
}

/// The doorway for [step]; its emblem draws itself in when it first shows
/// (at once under reduce motion).
class OnboardingDoorway extends StatefulWidget {
  const OnboardingDoorway({super.key, required this.step});

  final OnboardingStep step;

  static const drawIn = Duration(milliseconds: 700);

  @override
  State<OnboardingDoorway> createState() => _OnboardingDoorwayState();
}

class _OnboardingDoorwayState extends State<OnboardingDoorway>
    with SingleTickerProviderStateMixin {
  /// The page turn the doorway arrives with: the emblem waits for it to
  /// settle, so it draws on a still page (drawing mid-slide was lost).
  static const _settle = Duration(milliseconds: 400);

  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: _settle + OnboardingDoorway.drawIn,
  );

  /// The emblem's own progress: nothing while the page turns, then the
  /// stroke draws in.
  late final Animation<double> _draw = CurvedAnimation(
    parent: _t,
    curve: Interval(
      _settle.inMilliseconds /
          (_settle + OnboardingDoorway.drawIn).inMilliseconds,
      1,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t.value == 0 && !_t.isAnimating) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _t.value = 1;
      } else {
        _t.forward();
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = OrnamentStyle.of(context, onChrome: true);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: OnboardingDoorwayPainter(
            step: widget.step,
            style: style,
            ground: tokens.chrome,
            t: _draw.value,
          ),
        ),
      ),
    );
  }
}

/// The wizard's progress: one small cusped arch per step in a row, lit
/// up to where you stand; the next one lights from its base as you step
/// forward. Painted, so it shrinks to the room it gets.
class OnboardingProgressPainter extends CustomPainter {
  const OnboardingProgressPainter({
    required this.count,
    required this.lit,
    required this.gilt,
    required this.quiet,
    required this.rtl,
  });

  final int count;
  final double lit;
  final Color gilt;
  final Color quiet;
  final bool rtl;

  /// The widest one arch gets, and the gap after it.
  static const double archWidth = 11;
  static const double gap = 6;

  static double widthFor(int count) =>
      count * archWidth + math.max(0, count - 1) * gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0 || size.isEmpty) return;
    final scale = math.min(1.0, size.width / widthFor(count));
    final w = archWidth * scale;
    final g = gap * scale;
    final h = math.min(size.height, w * 1.5);
    final total = widthFor(count) * scale;
    final top = (size.height - h) / 2;
    var x = (size.width - total) / 2;
    for (var i = 0; i < count; i++) {
      final index = rtl ? count - 1 - i : i;
      final f = (lit - index).clamp(0.0, 1.0);
      final current = index == lit.ceil() - 1;
      final box = Rect.fromLTWH(x, top, w, h);
      final (l, r) = OnboardingArcadePainter.archHalves(box);
      final arch = Path.from(l)
        ..addPath(r, Offset.zero)
        ..moveTo(box.left, box.bottom)
        ..lineTo(box.right, box.bottom);
      final filled = Path.combine(
        PathOperation.union,
        Path.from(l)
          ..lineTo(box.center.dx, box.bottom)
          ..close(),
        Path.from(r)
          ..lineTo(box.center.dx, box.bottom)
          ..close(),
      );
      if (f > 0) {
        // Lit from the base up as f grows.
        canvas.save();
        canvas.clipRect(
          Rect.fromLTRB(
            box.left - 2,
            box.bottom - (box.height + 2) * f,
            box.right + 2,
            box.bottom + 2,
          ),
        );
        canvas.drawPath(
          filled,
          Paint()..color = gilt.withValues(alpha: current ? 0.95 : 0.55),
        );
        canvas.restore();
      }
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..color = Color.lerp(quiet, gilt, f)!,
      );
      x += w + g;
    }
  }

  @override
  bool shouldRepaint(OnboardingProgressPainter old) =>
      old.count != count ||
      old.lit != lit ||
      old.gilt != gilt ||
      old.quiet != quiet ||
      old.rtl != rtl;
}

/// The progress row, lighting the next arch as [lit] grows (700 ms) and
/// putting it out as it shrinks.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.count,
    required this.lit,
    this.semanticLabel,
  });

  final int count;
  final int lit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: lit.toDouble()),
        duration: tokens.motion.of(context, OnboardingArcade.step),
        curve: tokens.motion.emphasized,
        builder: (context, value, _) => CustomPaint(
          size: Size(OnboardingProgressPainter.widthFor(count), 18),
          painter: OnboardingProgressPainter(
            count: count,
            lit: value,
            gilt: tokens.gilt,
            quiet: tokens.onChromeMuted.withValues(alpha: 0.55),
            rtl: rtl,
          ),
        ),
      ),
    );
  }
}
