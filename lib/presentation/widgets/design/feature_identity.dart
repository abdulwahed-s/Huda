import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

enum IdentityMaterial { light, paper, stone, brass, leather, thread, night, wood }

enum IdentityRhythm { single, radial, sequence, field, band }

@immutable
class FeatureIdentity {
  const FeatureIdentity({
    required this.id,
    required this.motif,
    required this.count,
    required this.rhythm,
    required this.material,
    required this.headerArt,
    this.emptyArt,
    this.semanticLabel,
  });

  final String id;

  final String motif;

  final int count;
  final IdentityRhythm rhythm;
  final IdentityMaterial material;

  final HeaderArtBuilder headerArt;

  final HeaderArtBuilder? emptyArt;

  final String? semanticLabel;

  HeaderArtBuilder get stateArt => emptyArt ?? headerArt;

  static final FeatureIdentity neutral = FeatureIdentity(
    id: 'neutral',
    motif: 'A plain khatam (two squares)',
    count: 8,
    rhythm: IdentityRhythm.single,
    material: IdentityMaterial.light,
    headerArt: (style) => _KhatamPainter(style: style),
  );
}

class _KhatamPainter extends CustomPainter {
  const _KhatamPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - style.stroke * 3;
    if (r <= 0) return;
    style.draw(canvas, OrnamentGeometry.khatam(c, r));
    style.draw(canvas, OrnamentGeometry.khatam(c, r * 0.62));
  }

  @override
  bool shouldRepaint(_KhatamPainter old) => old.style != style;
}
