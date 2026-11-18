import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Huda AI's voice: noor, a gathering of light. Motes of light placed on
/// the golden angle (a sunflower's phyllotaxis), each a small core in a
/// soft halo, larger and brighter toward the heart. Never joined by lines,
/// never counted: light, not beads or stars. See `design/IDENTITIES.md`.
///
/// 13 motes in the full gathering, 5 in the mark that signs an answer, 3
/// of falling size as a divider.
final FeatureIdentity hudaAiIdentity = FeatureIdentity(
  id: 'huda-ai',
  motif: 'Noor: motes of light gathered on the golden angle',
  count: 13,
  rhythm: IdentityRhythm.field,
  material: IdentityMaterial.light,
  headerArt: (style) => HudaAiNoorPainter(style: style),
);

/// The golden angle, in radians.
const double _golden = 2.399963229728653;

/// Paints [count] motes of light in a golden-angle spiral filling the box.
///
/// [gather] (0–1) is how far the light is drawing in, and [phase] (0–1,
/// looping) where the breath is: a wave runs inward through the motes,
/// pulling each toward the heart in turn, the spiral winds slowly and the
/// heart brightens. [settle] (0–1) brings the motes in from wider places
/// as the art first appears.
///
/// [breathe] (0–1) is the idle breath of the welcome (owner round 1): each
/// mote's halo swells and fades, out of step with the others, like
/// candlelight. Nothing moves, so every frame is the still mark used on
/// share images and Home; drawing inward ([gather]) stays the sign that an
/// answer is coming.
class HudaAiNoorPainter extends CustomPainter {
  const HudaAiNoorPainter({
    required this.style,
    this.count = 13,
    this.gather = 0,
    this.phase = 0,
    this.settle = 1,
    this.breathe = 0,
  });

  final OrnamentStyle style;
  final int count;
  final double gather;
  final double phase;
  final double settle;
  final double breathe;

  /// Idle breaths per loop of [phase] (4.8 s each).
  static const int idleBreaths = 2;

  /// Breaths per loop of [phase]; the spiral turns once per loop.
  static const int breaths = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || count <= 0) return;
    final center = size.center(Offset.zero);
    final extent = size.shortestSide / 2;
    // The outer motes' halos stay inside the box.
    final reach = extent * 0.78;
    final core = math.max(1.2, extent * (count > 5 ? 0.075 : 0.16));
    final breath = math.sin(2 * math.pi * breaths * phase);
    final heart = gather * (0.5 + 0.5 * breath);
    final turn = gather * phase * 2 * math.pi;
    for (var i = count - 1; i >= 0; i--) {
      final depth = count == 1 ? 0.0 : i / (count - 1);
      // Each mote arrives in turn, the heart first.
      final arrive = Curves.easeOutCubic.transform(
        ((settle - depth * 0.35) / 0.65).clamp(0.0, 1.0),
      );
      if (arrive <= 0) continue;
      // The wave of the breath runs from the rim toward the heart.
      final wave =
          0.5 + 0.5 * math.sin(2 * math.pi * (breaths * phase - depth));
      final pull = 1 - gather * 0.32 * wave;
      final radius =
          reach *
          math.sqrt((i + 0.6) / count) *
          pull *
          (1 + (1 - arrive) * 0.8);
      final angle = -math.pi / 2 + i * _golden + turn - (1 - arrive) * 0.7;
      final at = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final glow = (1 - depth * 0.6) * arrive;
      final lift = i == 0 ? heart * 0.45 : gather * wave * 0.25;
      final r = core * (1.25 - depth * 0.6) * (1 + lift);
      // Candlelight: each mote on its own beat (the golden ratio keeps
      // neighbours apart).
      final candle =
          breathe *
          math.sin(2 * math.pi * (idleBreaths * phase + i * 0.618034));
      final alpha =
          ((glow * (0.55 + 0.45 * (1 - depth)) + lift * 0.3) *
                  (1 + 0.26 * candle))
              .clamp(0.0, 1.0);
      _mote(canvas, at, r, alpha, halo: 1 + 0.55 * candle);
    }
  }

  void _mote(
    Canvas canvas,
    Offset at,
    double r,
    double alpha, {
    double halo = 1,
  }) {
    final color = style.color;
    final reach = r * 3.4 * halo;
    canvas.drawCircle(
      at,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha * 0.34),
            color.withValues(alpha: alpha * 0.10),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: at, radius: reach)),
    );
    canvas.drawCircle(at, r, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(HudaAiNoorPainter old) =>
      old.style.color != style.color ||
      old.count != count ||
      old.gather != gather ||
      old.phase != phase ||
      old.settle != settle ||
      old.breathe != breathe;
}

/// Three motes of falling size, side by side: the divider between a share
/// card's or a counsel's sections.
class HudaAiMoteDividerPainter extends CustomPainter {
  const HudaAiMoteDividerPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.height / 7;
    final gap = r * 4.2;
    final painter = HudaAiNoorPainter(style: style);
    painter._mote(canvas, c, r, 0.95);
    painter._mote(canvas, c - Offset(gap, 0), r * 0.55, 0.6);
    painter._mote(canvas, c + Offset(gap, 0), r * 0.55, 0.6);
  }

  @override
  bool shouldRepaint(HudaAiMoteDividerPainter old) =>
      old.style.color != style.color;
}

/// The divider as a widget, centered.
class HudaAiMoteDivider extends StatelessWidget {
  const HudaAiMoteDivider({super.key, this.color, this.height = 14});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => Center(
    child: Ornament(
      size: Size(height * 4, height),
      painter: HudaAiMoteDividerPainter(
        style: OrnamentStyle.of(
          context,
        ).copyWith(color: color ?? context.tokens.ornament),
      ),
    ),
  );
}

/// The gathering of light as a widget.
///
/// [gathering] makes it breathe and draw in while an answer is coming (a
/// live wait, so it loops; it stops when [gathering] turns off, when the
/// route is covered, and under reduce motion). [entrance] lets the motes
/// drift in and settle once as it first appears (900 ms).
class HudaAiNoor extends StatefulWidget {
  const HudaAiNoor({
    super.key,
    required this.size,
    this.count = 13,
    this.gathering = false,
    this.entrance = false,
    this.breathing = false,
    this.color,
  });

  final double size;
  final int count;
  final bool gathering;
  final bool entrance;

  /// Breathes in place while it shows (the welcome only, owner round 1).
  final bool breathing;
  final Color? color;

  /// One loop of the breath: [HudaAiNoorPainter.breaths] breaths and a
  /// full slow turn.
  static const Duration loop = Duration(milliseconds: 9600);

  static const Duration entranceDuration = Duration(milliseconds: 900);

  @override
  State<HudaAiNoor> createState() => _HudaAiNoorState();
}

class _HudaAiNoorState extends State<HudaAiNoor> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: HudaAiNoor.loop,
  );
  late final AnimationController _amount = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: widget.gathering ? 1 : 0,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: HudaAiNoor.entranceDuration,
    value: widget.entrance ? 0 : 1,
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _loop.stop();
      _settle.value = 1;
      _amount.value = 0;
    } else {
      if (_settle.value < 1 && !_settle.isAnimating) _settle.forward();
      _sync();
    }
  }

  @override
  void didUpdateWidget(HudaAiNoor old) {
    super.didUpdateWidget(old);
    if (old.gathering != widget.gathering ||
        old.breathing != widget.breathing) {
      _sync();
    }
  }

  void _sync() {
    if (_still) return;
    if (widget.gathering || widget.breathing) {
      if (!_loop.isAnimating) _loop.repeat();
    }
    if (widget.gathering) {
      _amount.forward();
    } else {
      _amount.reverse().whenComplete(() {
        if (mounted && !widget.gathering && !widget.breathing) _loop.stop();
      });
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _amount.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.tokens.ornament;
    final style = OrnamentStyle.of(context).copyWith(color: color);
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _amount, _settle]),
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: HudaAiNoorPainter(
              style: style,
              count: widget.count,
              gather: Curves.easeInOut.transform(_amount.value),
              phase: _loop.value,
              settle: _settle.value,
              // The breath comes in with the motes and gives way to the
              // gathering.
              breathe: widget.breathing && !_still
                  ? _settle.value * (1 - _amount.value)
                  : 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Huda AI's small mark: five motes, signing each answer. It gathers while
/// its answer is still being written.
class HudaAiMark extends StatelessWidget {
  const HudaAiMark({super.key, this.size = 28, this.gathering = false});

  final double size;
  final bool gathering;

  @override
  Widget build(BuildContext context) =>
      HudaAiNoor(size: size, count: 5, gathering: gathering);
}
