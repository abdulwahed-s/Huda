import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Petals of the rosette sun and of the repetition medallion.
const int athkarPetals = 8;

/// How high the sun stands at rest: half risen on the horizon.
const double athkarSunAtRest = 0.5;

/// Athkar's voice (see `design/IDENTITIES.md`): an 8-petal rosette sun
/// rising on a horizon, framed by a pointed horizon arch. Light and sky.
final FeatureIdentity athkarIdentity = FeatureIdentity(
  id: 'athkar',
  motif: 'An 8-petal rosette sun rising on a horizon, in a horizon arch',
  count: athkarPetals,
  rhythm: IdentityRhythm.single,
  material: IdentityMaterial.light,
  headerArt: (style) => AthkarHorizonPainter(style: style),
);

/// The horizon arch with the rosette sun: [rise] 0 is set below the
/// horizon, 0.5 half risen (at rest), 1 fully risen. Animate it by passing
/// the same value as a [repaint] listenable through [riseOf].
class AthkarHorizonPainter extends CustomPainter {
  AthkarHorizonPainter({
    required this.style,
    this.rise = athkarSunAtRest,
    this.riseOf,
    this.arch = true,
  }) : super(repaint: riseOf);

  final OrnamentStyle style;
  final double rise;

  /// Drives [rise] when set (the signature motion).
  final ValueListenable<double>? riseOf;

  /// Draws the arch around the sun; off for small marks.
  final bool arch;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final rise = riseOf?.value ?? this.rise;
    final s = style.stroke;

    // The arch: two outlines, the jambs running off the bottom.
    var inner = Rect.fromLTRB(s, s, w - s, h + 1);
    if (arch) {
      final archWidth = math.min(w, h * 1.1);
      final left = (w - archWidth) / 2;
      final outer = Rect.fromLTRB(
        left + s,
        h * 0.04,
        left + archWidth - s,
        h + 1,
      );
      inner = outer.deflate(archWidth * 0.06);
      style.draw(canvas, OrnamentGeometry.pointedArch(outer), closed: false);
      style.draw(canvas, OrnamentGeometry.pointedArch(inner), closed: false);
    }

    // The horizon, across the arch.
    final horizon = arch ? inner.top + inner.height * 0.62 : h * 0.62;
    final reach = arch ? inner.width / 2 : w * 0.46;
    final cx = w / 2;
    final line = Path()
      ..moveTo(cx - reach, horizon)
      ..lineTo(cx + reach, horizon);
    style.draw(canvas, line, closed: false);

    // Quiet ground under the horizon, so the arch below it isn't blank.
    if (arch) {
      final ground = style.copyWith(
        color: style.color.withValues(alpha: style.color.a * 0.45),
      );
      for (final (step, span) in [(0.32, 0.62), (0.62, 0.34)]) {
        final y = horizon + (inner.bottom - horizon) * step;
        if (y >= h - s) break;
        ground.draw(
          canvas,
          Path()
            ..moveTo(cx - reach * span, y)
            ..lineTo(cx + reach * span, y),
          closed: false,
        );
      }
    }

    // The sun, clipped by the horizon.
    final r = math.min(reach * 0.62, horizon * (arch ? 0.42 : 0.6));
    if (r <= 2) return;
    final center = Offset(cx, horizon + r * (1 - 2 * rise.clamp(0.0, 1.0)));
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, w, horizon - s / 2));
    paintAthkarSun(canvas, style, center, r);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AthkarHorizonPainter old) =>
      old.style != style ||
      old.rise != rise ||
      old.riseOf != riseOf ||
      old.arch != arch;
}

/// The rosette sun: a double disc, 8 petals, a center and 16 short rays.
void paintAthkarSun(Canvas canvas, OrnamentStyle style, Offset c, double r) {
  const turn = -math.pi / 2;
  style.draw(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
  style.draw(
    canvas,
    Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9)),
  );
  style.draw(
    canvas,
    OrnamentGeometry.petals(
      c,
      r * 0.78,
      count: athkarPetals,
      width: 0.42,
      rotation: turn,
    ),
  );
  style.draw(
    canvas,
    Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.14)),
  );
  // Short rays between the petals' tips, outside the disc.
  final rays = Path();
  for (var i = 0; i < athkarPetals * 2; i++) {
    final a = turn + i * math.pi / athkarPetals;
    final from = r * 1.12;
    final to = r * (i.isEven ? 1.34 : 1.24);
    rays
      ..moveTo(c.dx + math.cos(a) * from, c.dy + math.sin(a) * from)
      ..lineTo(c.dx + math.cos(a) * to, c.dy + math.sin(a) * to);
  }
  style.draw(canvas, rays, closed: false);
}

/// The rosette sun alone, filling its box with its rays.
class AthkarSunPainter extends CustomPainter {
  const AthkarSunPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 / 1.36;
    if (r <= 2) return;
    paintAthkarSun(canvas, style, size.center(Offset.zero), r);
  }

  @override
  bool shouldRepaint(AthkarSunPainter old) => old.style != style;
}

/// A sun that rises from below the horizon to [to] once, when it's first
/// shown: the signature motion. Under reduce motion it stands at [to].
class AthkarRisingSun extends StatefulWidget {
  const AthkarRisingSun({
    super.key,
    required this.builder,
    this.to = athkarSunAtRest,
    this.from = 0,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
  });

  /// Builds the art from the rise listenable.
  final Widget Function(BuildContext context, ValueListenable<double> rise)
  builder;
  final double from;
  final double to;
  final Duration duration;

  /// Waits this long before rising (until the art has scrolled into view).
  final Duration delay;

  @override
  State<AthkarRisingSun> createState() => _AthkarRisingSunState();
}

class _AthkarRisingSunState extends State<AthkarRisingSun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _rise = _controller.drive(
    Tween(
      begin: widget.from,
      end: widget.to,
    ).chain(CurveTween(curve: Curves.easeOutCubic)),
  );
  final _value = ValueNotifier<double>(0);
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _value.value = widget.from;
    _rise.addListener(() => _value.value = _rise.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _wait ??= Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(AthkarRisingSun oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.to != widget.to) _value.value = widget.to;
  }

  @override
  void dispose() {
    _wait?.cancel();
    _controller.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

/// The repetition medallion: 8 petals around the count that light in
/// proportion as the dhikr is said ([progress] 0–1), clockwise from the
/// top (counter-clockwise in RTL). When [progress] reaches 1 the center
/// is lit and the petals bloom once.
class AthkarMedallionPainter extends CustomPainter {
  const AthkarMedallionPainter({
    required this.progress,
    required this.petal,
    required this.outline,
    required this.disc,
    required this.clockwise,
    this.bloom = 0,
  });

  final double progress;
  final Color petal;
  final Color outline;
  final Color disc;
  final bool clockwise;

  /// 0–1–0 over the completion bloom.
  final double bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final inner = r * 0.6;
    final outer = r * (0.98 + bloom * 0.06);
    final lit = progress * athkarPetals;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = outline;
    for (var i = 0; i < athkarPetals; i++) {
      final step = (clockwise ? 1 : -1) * i * 2 * math.pi / athkarPetals;
      final path = _petal(c, -math.pi / 2 + step, inner * 0.92, outer);
      final fill = (lit - i).clamp(0.0, 1.0);
      if (fill > 0) {
        canvas.drawPath(
          path,
          Paint()..color = petal.withValues(alpha: petal.a * fill),
        );
      }
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(c, inner, Paint()..color = disc);
    canvas.drawCircle(c, inner, line);
  }

  /// An almond petal from [from] to [to] along angle [a].
  Path _petal(Offset c, double a, double from, double to) {
    final dir = Offset(math.cos(a), math.sin(a));
    final side = Offset(-dir.dy, dir.dx);
    final base = c + dir * from;
    final tip = c + dir * to;
    final mid = c + dir * ((from + to) / 2);
    final bulge = side * ((to - from) * 0.42);
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + bulge.dx, mid.dy + bulge.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(
        mid.dx - bulge.dx,
        mid.dy - bulge.dy,
        base.dx,
        base.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(AthkarMedallionPainter old) =>
      old.progress != progress ||
      old.petal != petal ||
      old.outline != outline ||
      old.disc != disc ||
      old.clockwise != clockwise ||
      old.bloom != bloom;
}

/// A dhikr's repetition medallion: the petals light as it's said and the
/// numeral counts down what's left; done, the center lights with a check
/// and the petals bloom once. Decorative: the card says the count.
class AthkarMedallion extends StatelessWidget {
  const AthkarMedallion({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 56,
    this.label,
  });

  final int remaining;
  final int total;
  final double size;

  /// Shown in the center instead of the count left (the chapter's
  /// medallion shows "1/6").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const motion = HudaMotion();
    final done = remaining <= 0;
    final progress = total <= 0 ? 1.0 : (1 - remaining / total).clamp(0.0, 1.0);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final numeral = size >= 96
        ? theme.textTheme.headlineMedium
        : size >= 48
        ? theme.textTheme.titleMedium
        : theme.textTheme.labelMedium;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: motion.of(context, motion.medium),
          curve: motion.standard,
          builder: (context, value, _) => TweenAnimationBuilder<double>(
            // The bloom plays once when the dhikr is done.
            tween: Tween(end: done ? 1 : 0),
            duration: motion.of(context, motion.long),
            builder: (context, bloom, _) => CustomPaint(
              painter: AthkarMedallionPainter(
                progress: value,
                petal: tokens.ornament,
                outline: tokens.ornament.withValues(alpha: 0.55),
                disc: Color.lerp(
                  scheme.surfaceContainerLow,
                  tokens.lit,
                  bloom,
                )!,
                clockwise: !rtl,
                bloom: math.sin(bloom * math.pi),
              ),
              child: Center(
                child: done
                    ? Icon(
                        Icons.check_rounded,
                        size: size * 0.36,
                        color: Color.lerp(
                          scheme.onSurface,
                          tokens.onChrome,
                          bloom,
                        ),
                      )
                    // The numeral stays inside the center disc (100 too).
                    : SizedBox.square(
                        dimension: size * 0.46,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: label != null
                                ? Text(
                                    label!,
                                    textDirection: TextDirection.ltr,
                                    style: numeral?.copyWith(
                                      color: scheme.onSurface,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  )
                                : HudaNumberRoll(
                                    value: remaining,
                                    style: numeral?.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                          ),
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
