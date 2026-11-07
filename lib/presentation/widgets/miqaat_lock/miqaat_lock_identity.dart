import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';

/// Miqaat Lock's voice: the bab, a carved wooden double door under a flat
/// lintel. Each leaf is carved in three panels with a lozenge boss; the
/// lintel carries one lozenge per time window (lit once that window's goal
/// is met today). The doors swing shut while a window locks the apps and
/// open when the goal is met. Rectilinear on purpose: no arch, so it never
/// echoes Athkar's pointed arch or onboarding's cusped arcade. See
/// `design/IDENTITIES.md`.
final FeatureIdentity miqaatLockIdentity = FeatureIdentity(
  id: 'miqaat-lock',
  motif: 'A carved double door that shuts for focus and opens when done',
  count: 5,
  rhythm: IdentityRhythm.single,
  material: IdentityMaterial.wood,
  headerArt: (style) =>
      MiqaatDoorPainter(line: style.color, stroke: style.stroke, closed: 1),
);

/// The door. [closed] runs from 0 (leaves swung wide, light through the
/// doorway) to 1 (shut, the bar across). [progress] fills the threshold
/// while a window is locked. [windows] lozenges sit on the lintel,
/// [windowsDone] of them lit.
class MiqaatDoorPainter extends CustomPainter {
  const MiqaatDoorPainter({
    required this.line,
    required this.closed,
    this.glow,
    this.wood,
    this.stroke = 1.5,
    this.progress = 0,
    this.barred = false,
    this.windows = 0,
    this.windowsDone = 0,
  });

  /// Carving and frame.
  final Color line;

  /// The light beyond the doorway.
  final Color? glow;

  /// The leaves' fill.
  final Color? wood;
  final double stroke;
  final double closed;
  final double progress;
  final bool barred;
  final int windows;
  final int windowsDone;

  /// The door's proportions (width over height).
  static const aspect = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    var w = size.width;
    var h = size.height;
    if (w / h > aspect) {
      w = h * aspect;
    } else {
      h = w / aspect;
    }
    if (w <= 8) return;
    final origin = Offset((size.width - w) / 2, (size.height - h) / 2);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final pen = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final faint = Paint()
      ..color = line.withValues(alpha: line.a * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.7;

    // Frame: two jambs and a lintel band.
    final lintel = h * 0.17;
    final jamb = w * 0.07;
    final outer = Rect.fromLTWH(0, 0, w, h);
    final opening = Rect.fromLTRB(jamb, lintel, w - jamb, h - stroke);

    // The light through the doorway, where the leaves don't cover it.
    final glow = this.glow;
    if (glow != null) {
      canvas.drawRect(
        opening,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              glow.withValues(alpha: glow.a * (1 - closed)),
              glow.withValues(alpha: 0),
            ],
          ).createShader(opening),
      );
    }

    canvas.drawRect(outer, pen);
    canvas.drawRect(Rect.fromLTRB(0, 0, w, lintel), pen);
    canvas.drawLine(Offset(jamb, lintel), Offset(jamb, h), faint);
    canvas.drawLine(Offset(w - jamb, lintel), Offset(w - jamb, h), faint);

    // The lintel's lozenges, one per window.
    if (windows > 0) {
      final n = windows;
      final cell = (w - jamb * 2) / n;
      final ry = lintel * 0.28;
      final rx = math.min(cell * 0.32, ry * 1.4);
      for (var i = 0; i < n; i++) {
        final c = Offset(jamb + cell * (i + 0.5), lintel / 2);
        final path = _lozenge(c, rx, ry);
        if (i < windowsDone) {
          canvas.drawPath(path, Paint()..color = line);
        }
        canvas.drawPath(path, pen);
      }
    } else {
      // A plain carved rule.
      canvas.drawLine(
        Offset(jamb, lintel / 2),
        Offset(w - jamb, lintel / 2),
        faint,
      );
    }

    // The leaves, hinged at the jambs: an open leaf is foreshortened.
    final half = opening.width / 2;
    final leaf = half * (0.16 + 0.84 * closed);
    final skew = (1 - closed) * opening.height * 0.06;
    _leaf(canvas, opening, leaf, skew, pen, faint, start: true);
    _leaf(canvas, opening, leaf, skew, pen, faint, start: false);

    // The bar across the shut doors, with its ring.
    if (barred && closed > 0.95) {
      final y = opening.top + opening.height * 0.52;
      final bar = Rect.fromCenter(
        center: Offset(opening.center.dx, y),
        width: opening.width * 0.46,
        height: stroke * 3.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(stroke)),
        Paint()..color = line,
      );
      canvas.drawCircle(
        Offset(opening.center.dx, y + stroke * 5),
        stroke * 3.4,
        pen,
      );
    }

    // The threshold: walked while the window is locked.
    final sill = h - stroke;
    if (progress > 0) {
      final p = Paint()
        ..color = line
        ..strokeWidth = stroke * 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(opening.left, sill),
        Offset(opening.left + opening.width * progress.clamp(0, 1), sill),
        p,
      );
    }
    canvas.restore();
  }

  void _leaf(
    Canvas canvas,
    Rect opening,
    double width,
    double skew,
    Paint pen,
    Paint faint, {
    required bool start,
  }) {
    final hinge = start ? opening.left : opening.right;
    final edge = start ? hinge + width : hinge - width;
    // The free edge looks shorter as the leaf swings in.
    final top = opening.top + skew;
    final bottom = opening.bottom - skew;
    final path = Path()
      ..moveTo(hinge, opening.top)
      ..lineTo(edge, top)
      ..lineTo(edge, bottom)
      ..lineTo(hinge, opening.bottom)
      ..close();
    final wood = this.wood;
    if (wood != null) canvas.drawPath(path, Paint()..color = wood);
    canvas.drawPath(path, pen);
    if (width < 6) return;

    // Three carved panels, tall in the middle, each with a lozenge boss.
    final inset = width * 0.16;
    final rows = [0.0, 0.26, 0.74, 1.0];
    for (var r = 0; r < 3; r++) {
      final t0 = rows[r];
      final t1 = rows[r + 1];
      Offset at(double x, double t) {
        final topY = opening.top + (top - opening.top) * x;
        final bottomY = opening.bottom + (bottom - opening.bottom) * x;
        final y = topY + (bottomY - topY) * t;
        return Offset(hinge + (edge - hinge) * x, y);
      }

      final gap = 0.05;
      final xa = inset / width;
      final xb = 1 - xa;
      final ta = t0 + gap;
      final tb = t1 - gap;
      final panel = Path()
        ..moveTo(at(xa, ta).dx, at(xa, ta).dy)
        ..lineTo(at(xb, ta).dx, at(xb, ta).dy)
        ..lineTo(at(xb, tb).dx, at(xb, tb).dy)
        ..lineTo(at(xa, tb).dx, at(xa, tb).dy)
        ..close();
      canvas.drawPath(panel, faint);
      final c = at(0.5, (ta + tb) / 2);
      final rx = width * 0.16;
      final ry = math.min(rx * 1.5, (tb - ta) * opening.height * 0.3);
      canvas.drawPath(_lozenge(c, rx, ry), faint);
    }
  }

  static Path _lozenge(Offset c, double rx, double ry) => Path()
    ..moveTo(c.dx, c.dy - ry)
    ..lineTo(c.dx + rx, c.dy)
    ..lineTo(c.dx, c.dy + ry)
    ..lineTo(c.dx - rx, c.dy)
    ..close();

  @override
  bool shouldRepaint(MiqaatDoorPainter old) =>
      old.line != line ||
      old.glow != glow ||
      old.wood != wood ||
      old.stroke != stroke ||
      old.closed != closed ||
      old.progress != progress ||
      old.barred != barred ||
      old.windows != windows ||
      old.windowsDone != windowsDone;
}
