import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// What a feature's ornament evokes. See `design/LANGUAGE.md`, "Voice".
enum IdentityMaterial { light, paper, stone, brass, leather, thread, night, wood }

/// How a feature's motif repeats.
enum IdentityRhythm { single, radial, sequence, field, band }

/// A feature's voice, as code: the motif, its meaningful count and
/// rhythm, the material it evokes, and the art the shared components draw
/// for it (landing header, empty states, share frames). Generalizes Home's
/// `EventVisualIdentity` (special events keep theirs).
///
/// Each feature defines one constant-like instance next to its screens and
/// records it in `design/IDENTITIES.md`. Identities use the theme's colors
/// (the [OrnamentStyle] passed in), never fixed hues.
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

  /// The feature id from `design/TRACKER.md`.
  final String id;

  /// One line naming the structural idea ("an 8-fold rosette rising").
  final String motif;

  /// The meaningful number (33 beads, 30 juz, 5 prayers).
  final int count;
  final IdentityRhythm rhythm;
  final IdentityMaterial material;

  /// Art for the landing header, on the chrome.
  final HeaderArtBuilder headerArt;

  /// Art for empty and error states, on the surface. Defaults to
  /// [headerArt].
  final HeaderArtBuilder? emptyArt;

  /// Read out when the art carries meaning; null keeps it decorative.
  final String? semanticLabel;

  HeaderArtBuilder get stateArt => emptyArt ?? headerArt;

  /// A neutral identity for shared specimens and screens without art yet:
  /// a plain khatam, so no feature inherits another's seed motif (the
  /// rosette is Athkar's).
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
