import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/home/special_event/event_visual_identity.dart';

/// The colors an event scene is painted in: the person's chrome and gilt,
/// tinted toward night or golden hour by the event's family (never a hue
/// of its own).
@immutable
class HomeEventPalette {
  const HomeEventPalette({
    required this.chrome,
    required this.chromeEnd,
    required this.gilt,
    required this.light,
  });

  factory HomeEventPalette.of(BuildContext context) {
    final tokens = context.tokens;
    return HomeEventPalette(
      chrome: tokens.chrome,
      chromeEnd: tokens.chromeEnd,
      gilt: tokens.gilt,
      light: tokens.onChrome,
    );
  }

  final Color chrome;
  final Color chromeEnd;
  final Color gilt;

  /// The moon's and the lamps' brightest light.
  final Color light;

  /// Silhouettes against the sky: the chrome, much darker.
  Color get dark => Color.lerp(chrome, Colors.black, 0.5)!;

  @override
  bool operator ==(Object other) =>
      other is HomeEventPalette &&
      other.chrome == chrome &&
      other.chromeEnd == chromeEnd &&
      other.gilt == gilt &&
      other.light == light;

  @override
  int get hashCode => Object.hash(chrome, chromeEnd, gilt, light);
}

/// Where a scene's picture is composed: at the end of a banner (its words
/// at the start) or centered in a band with no words over it.
enum HomeEventStage { end, center }

/// An event's scene. The sky fills the box; the land, sea and wall run
/// across it (fading out toward the words at the start); the picture
/// itself is composed inside a stage ([stageRect]) whose proportions stay
/// between about 4:5 and 5:3 whatever the box, so nothing is cut or
/// squeezed. Mirrored in right-to-left.
///
/// Ramadan: the crescent and three lanterns hanging. The last ten nights:
/// ten lanterns on a garland, the odd nights brighter, the twenty-seventh
/// brightest. Eid al-Fitr: a mosque under fireworks. Eid al-Adha: the
/// Kaaba before the colonnade, light behind it. Arafah: the Mount of Mercy
/// with its pillar and pilgrims, the sun low behind it. The first ten of
/// Dhul Hijjah: ten lamps rising to the tenth. Ashura: the sea parted, a
/// path to the dawn. Tashreeq: three lamps on the ground at dusk. The
/// white days: three full moons over still water. Monday and Thursday:
/// the week as seven arches, two lit. Others: the crescent and a star.
///
/// [reveal] (0–1) brings it in: the sky first, then its light, then the
/// lamps one by one.
class HomeEventScenePainter extends CustomPainter {
  HomeEventScenePainter({
    required this.eventKey,
    required this.palette,
    required this.rtl,
    this.stage = HomeEventStage.end,
    this.reveal,
  }) : identity = EventVisualIdentity.resolve(eventKey),
       super(repaint: reveal);

  final String eventKey;
  final EventVisualIdentity identity;
  final HomeEventPalette palette;
  final bool rtl;
  final HomeEventStage stage;
  final Animation<double>? reveal;

  /// The stage's width at the end of a banner [width] wide: about two
  /// fifths of it, up to 180 on compact banners and 300 on wide ones.
  static double endStageWidth(double width) =>
      math.min(width * 0.4, width >= 600 ? 300.0 : 180.0);

  /// The rect the picture is composed in (unmirrored: the end is right).
  static Rect stageRect(Size size, HomeEventStage stage) {
    if (stage == HomeEventStage.center) {
      final w = math.min(size.height * 1.6, size.width * 0.8);
      final h = math.min(size.height, w / 0.8);
      return Rect.fromLTWH((size.width - w) / 2, size.height - h, w, h);
    }
    // Never wider than the banner's own share, nor than about 5:3 on a
    // short banner.
    final w = math.min(endStageWidth(size.width), size.height * 1.7);
    final h = math.min(size.height, w / 0.8);
    return Rect.fromLTWH(size.width - w, size.height - h, w, h);
  }

  double get _t => reveal?.value ?? 1;

  /// A phase of the reveal: 0 before [from], 1 after [to].
  double _phase(double from, double to) =>
      Curves.easeOutCubic.transform(((_t - from) / (to - from)).clamp(0, 1));

  late Rect _s;
  late Size _size;

  double get _u => math.min(_s.width, _s.height);
  double _x(double f) => _s.left + f * _s.width;
  double _y(double f) => _s.top + f * _s.height;
  Offset _at(double fx, double fy) => Offset(_x(fx), _y(fy));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _size = size;
    _s = stageRect(size, stage);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    switch (identity.family) {
      case EventVisualFamily.sacredSeason || EventVisualFamily.voluntaryFasting:
        _night(
          canvas,
          deep:
              identity.motif == EventStructuralMotif.mondayThursdayWeekCalendar
              ? 0.35
              : 0.55,
        );
      case EventVisualFamily.celebration:
        _festive(canvas);
      case EventVisualFamily.pilgrimage:
        _golden(canvas);
      case EventVisualFamily.remembrance:
        _golden(canvas, dusk: true);
      case EventVisualFamily.reflection:
        _dawn(canvas);
      case EventVisualFamily.authoredFallback:
        _night(canvas, deep: 0.3);
    }
    switch (identity.motif) {
      case EventStructuralMotif.ramadanCrescentDates:
        _ramadan(canvas);
      case EventStructuralMotif.lastTenPrayerMatTenNights:
        _lastTen(canvas);
      case EventStructuralMotif.eidFitrZakatGrain:
        _eidFitr(canvas);
      case EventStructuralMotif.eidAdhaRamOffering:
        _eidAdha(canvas);
      case EventStructuralMotif.arafahMountainMarker:
        _arafah(canvas);
      case EventStructuralMotif.dhulHijjahTenDayCalendar:
        _tenRising(canvas);
      case EventStructuralMotif.ashuraPartedSeaTenthDay:
        _partedSea(canvas);
      case EventStructuralMotif.tashreeqThreeDayRemembrance:
        _tashreeq(canvas);
      case EventStructuralMotif.whiteDaysThreeFullMoons:
        _moons(canvas, const [
          (0.2, 0.42, 0.1),
          (0.5, 0.28, 0.13),
          (0.8, 0.42, 0.1),
        ]);
        _water(canvas, top: 0.72);
      case EventStructuralMotif.mondayThursdayWeekCalendar:
        _crescent(canvas, _at(0.7, 0.26), 0.13 * _u);
        _week(canvas, ground: 0.88);
      case EventStructuralMotif.whiteDaysWeeklyConfluence:
        _moons(canvas, const [
          (0.2, 0.3, 0.075),
          (0.5, 0.2, 0.095),
          (0.8, 0.3, 0.075),
        ]);
        _week(canvas, ground: 0.9);
      case EventStructuralMotif.authoredCalendarCrescent:
        _crescent(canvas, _at(0.5, 0.46), 0.2 * _u);
        _burst(canvas, _at(0.82, 0.3), 0.05 * _u, _phase(0.3, 0.7));
    }
    canvas.restore();
  }

  // Skies ---------------------------------------------------------------------

  void _gradient(Canvas canvas, List<Color> colors) {
    final rect = Offset.zero & _size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  void _glow(Canvas canvas, Offset c, double r, Color color, double alpha) {
    if (alpha <= 0 || r <= 0) return;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _night(Canvas canvas, {double deep = 0.55}) {
    final p = palette;
    _gradient(canvas, [
      Color.lerp(p.chrome, Colors.black, deep)!,
      p.chrome,
      p.chromeEnd,
    ]);
    _stars(canvas, 42);
  }

  void _festive(Canvas canvas) {
    final p = palette;
    _gradient(canvas, [
      Color.lerp(p.chrome, Colors.black, 0.45)!,
      p.chrome,
      Color.lerp(p.chromeEnd, p.gilt, 0.22)!,
    ]);
    _stars(canvas, 22);
  }

  void _golden(Canvas canvas, {bool dusk = false}) {
    final p = palette;
    _gradient(canvas, [
      Color.lerp(p.chrome, Colors.black, dusk ? 0.4 : 0.2)!,
      Color.lerp(p.chromeEnd, p.gilt, dusk ? 0.2 : 0.28)!,
      Color.lerp(p.chromeEnd, p.gilt, dusk ? 0.4 : 0.55)!,
    ]);
    if (dusk) _stars(canvas, 14);
  }

  void _dawn(Canvas canvas) {
    final p = palette;
    _gradient(canvas, [
      Color.lerp(p.chrome, Colors.black, 0.35)!,
      p.chromeEnd,
      Color.lerp(p.chromeEnd, p.light, 0.3)!,
    ]);
    _stars(canvas, 10);
  }

  /// Stars in the upper sky, gathering toward the stage (fewer over the
  /// words); they come in with the reveal, each at its own moment.
  void _stars(Canvas canvas, int count) {
    final random = math.Random(eventKey.hashCode);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final fx = random.nextDouble();
      final x = stage == HomeEventStage.end
          ? math.pow(fx, 0.5) * _size.width
          : fx * _size.width;
      final y = random.nextDouble() * _size.height * 0.66;
      final r = 0.5 + random.nextDouble() * 1.1;
      final a =
          (0.25 + random.nextDouble() * 0.55) *
          _phase(0.1 + random.nextDouble() * 0.4, 0.8);
      if (a <= 0) continue;
      paint.color = palette.light.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  /// A fill for the land, sea or wall that runs across the box: solid
  /// under the stage, fading out toward the words at the start.
  Paint _across(Color color) {
    if (stage == HomeEventStage.center) return Paint()..color = color;
    final w = _size.width;
    final solid = (_s.left / w).clamp(0.0, 1.0);
    final clear = ((_s.left - _s.width * 0.9) / w).clamp(0.0, solid);
    return Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
          color,
          color,
        ],
        stops: [0, clear, solid, 1],
      ).createShader(Offset.zero & _size);
  }

  /// A gilt line across the box at [y], fading toward the start.
  void _horizon(Canvas canvas, double y, {double alpha = 0.6}) {
    canvas.drawRect(
      Rect.fromLTWH(0, y - 0.5, _size.width, 1),
      _across(palette.gilt.withValues(alpha: alpha)),
    );
  }

  // Lights --------------------------------------------------------------------

  void _crescent(Canvas canvas, Offset c, double r) {
    final t = _phase(0.15, 0.6);
    if (t <= 0) return;
    _glow(canvas, c, r * 2.6, palette.gilt, 0.28 * t);
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()
      ..addOval(
        Rect.fromCircle(
          center: c + Offset(r * 0.42, -r * 0.22),
          radius: r * 0.86,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, moon, bite),
      Paint()
        ..color = Color.lerp(
          palette.gilt,
          palette.light,
          0.45,
        )!.withValues(alpha: t),
    );
  }

  void _sun(Canvas canvas, Offset c, double r) {
    final t = _phase(0.1, 0.6);
    _glow(canvas, c, r * 4, palette.gilt, 0.45 * t);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Color.lerp(
          palette.gilt,
          palette.light,
          0.55,
        )!.withValues(alpha: t),
    );
  }

  /// A lantern (fanous) [w] wide whose cap is at [cap]: a ring and a dome,
  /// a faceted body glowing from within, a base and a drop. About 2.3 [w]
  /// tall. With [from], a cord runs up to it.
  void _lantern(
    Canvas canvas,
    Offset cap,
    double w,
    double lit, {
    Offset? from,
  }) {
    final p = palette;
    final line = Paint()
      ..color = p.gilt
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.045)
      ..strokeJoin = StrokeJoin.round;
    if (from != null) {
      canvas.drawLine(
        from,
        cap,
        Paint()
          ..color = p.gilt.withValues(alpha: 0.55)
          ..strokeWidth = 1,
      );
    }
    final h = w * 1.5;
    final y0 = cap.dy + w * 0.32;
    final cx = cap.dx;
    canvas.drawCircle(cap + Offset(0, w * 0.05), w * 0.07, line);
    final dome = Path()
      ..moveTo(cx - w * 0.32, y0)
      ..quadraticBezierTo(cx, cap.dy - w * 0.04, cx + w * 0.32, y0)
      ..close();
    canvas.drawPath(dome, Paint()..color = p.gilt.withValues(alpha: 0.85));
    final body = Path()
      ..moveTo(cx - w * 0.3, y0)
      ..lineTo(cx + w * 0.3, y0)
      ..lineTo(cx + w * 0.5, y0 + h * 0.36)
      ..lineTo(cx + w * 0.3, y0 + h)
      ..lineTo(cx - w * 0.3, y0 + h)
      ..lineTo(cx - w * 0.5, y0 + h * 0.36)
      ..close();
    final center = Offset(cx, y0 + h * 0.45);
    _glow(canvas, center, w * 1.6, p.gilt, 0.4 * lit);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(p.gilt, p.light, 0.6)!.withValues(alpha: 0.95 * lit),
            p.gilt.withValues(alpha: 0.3 * lit),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.6)),
    );
    canvas.drawPath(body, line);
    canvas.drawLine(
      Offset(cx - w * 0.5, y0 + h * 0.36),
      Offset(cx + w * 0.5, y0 + h * 0.36),
      line,
    );
    final facet = Paint()
      ..color = p.gilt.withValues(alpha: 0.6)
      ..strokeWidth = line.strokeWidth;
    for (final f in const [-0.15, 0.15]) {
      canvas.drawLine(
        Offset(cx + w * f * 1.2, y0),
        Offset(cx + w * f, y0 + h),
        facet,
      );
    }
    final base = Rect.fromCenter(
      center: Offset(cx, y0 + h + w * 0.09),
      width: w * 0.66,
      height: w * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(w * 0.05)),
      Paint()..color = p.gilt.withValues(alpha: 0.85),
    );
    canvas.drawLine(
      Offset(cx, base.bottom),
      Offset(cx, base.bottom + w * 0.2),
      line,
    );
    canvas.drawCircle(
      Offset(cx, base.bottom + w * 0.26),
      w * 0.06,
      Paint()..color = p.gilt,
    );
  }

  /// A starburst: an eight-pointed star with rays around it.
  void _burst(Canvas canvas, Offset c, double r, double t) {
    if (t <= 0) return;
    final p = palette;
    _glow(canvas, c, r * 2.4, p.gilt, 0.3 * t);
    final rays = Paint()
      ..color = p.gilt.withValues(alpha: 0.55 * t)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final d = Offset(math.cos(a), math.sin(a));
      final long = i.isEven ? 2.0 : 1.6;
      canvas.drawLine(
        c + d * r * 1.25,
        c + d * r * (1.25 + (long - 1.25) * t),
        rays,
      );
    }
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final d = i.isEven ? r : r * 0.48;
      final pt = c + Offset(math.cos(a), math.sin(a)) * d * t;
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      star..close(),
      Paint()..color = Color.lerp(p.gilt, p.light, 0.35)!.withValues(alpha: t),
    );
  }

  // Scenes --------------------------------------------------------------------

  /// The crescent with three lanterns hanging from the top edge.
  void _ramadan(Canvas canvas) {
    final u = _u;
    _crescent(canvas, _at(0.6, 0.34), 0.2 * u);
    const lanterns = [(0.16, 0.26, 1.0), (0.84, 0.5, 0.85), (0.34, 0.64, 0.7)];
    for (var i = 0; i < lanterns.length; i++) {
      final (fx, fy, scale) = lanterns[i];
      final cap = _at(fx, fy);
      _lantern(
        canvas,
        cap,
        0.15 * u * scale,
        _phase(0.35 + i * 0.12, 0.75 + i * 0.08),
        from: Offset(cap.dx, 0),
      );
    }
  }

  /// Ten lanterns on a garland, the odd nights brighter, the 27th
  /// brightest; a slim crescent above.
  void _lastTen(Canvas canvas) {
    final u = _u;
    final left = _at(0.07, 0.1);
    final right = _at(0.93, 0.1);
    final sag = _s.height * 0.28;
    canvas.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(
          (left.dx + right.dx) / 2,
          left.dy + sag * 2,
          right.dx,
          right.dy,
        ),
      Paint()
        ..color = palette.gilt.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _crescent(canvas, _at(0.5, 0.16), 0.075 * u);
    for (var i = 0; i < 10; i++) {
      final f = (i + 0.5) / 10;
      final x = left.dx + (right.dx - left.dx) * f;
      final y = left.dy + sag * 4 * f * (1 - f);
      final night = 21 + i;
      final odd = night.isOdd;
      final best = night == 27;
      final lit =
          _phase(0.3 + i * 0.05, 0.6 + i * 0.04) *
          (best ? 1 : (odd ? 0.8 : 0.45));
      final drop = _s.height * (odd ? 0.08 : 0.045);
      _lantern(
        canvas,
        Offset(x, y + drop),
        u * (best ? 0.1 : 0.072),
        lit,
        from: Offset(x, y),
      );
    }
  }

  /// A mosque on its wall under fireworks: the dome on its drum with the
  /// crescent finial, two minarets, lit windows.
  void _eidFitr(Canvas canvas) {
    final p = palette;
    final u = _u;
    final ground = _y(0.94);
    final cx = _x(0.5);
    _glow(
      canvas,
      Offset(cx, ground - 0.36 * u),
      0.62 * u,
      p.gilt,
      0.32 * _phase(0.2, 0.7),
    );
    // The wall, across.
    final wallTop = ground - 0.07 * u;
    canvas.drawRect(
      Rect.fromLTRB(0, wallTop, _size.width, _size.height),
      _across(Color.lerp(p.dark, Colors.black, 0.1)!),
    );
    _horizon(canvas, wallTop, alpha: 0.45);
    final dark = p.dark;
    final mosque = Path()
      ..addRect(
        Rect.fromLTRB(
          cx - 0.3 * u,
          ground - 0.2 * u,
          cx + 0.3 * u,
          _size.height,
        ),
      )
      ..addRect(
        Rect.fromLTRB(
          cx - 0.13 * u,
          ground - 0.27 * u,
          cx + 0.13 * u,
          ground - 0.19 * u,
        ),
      );
    final dome = Path()
      ..moveTo(cx - 0.15 * u, ground - 0.27 * u)
      ..cubicTo(
        cx - 0.21 * u,
        ground - 0.4 * u,
        cx - 0.05 * u,
        ground - 0.48 * u,
        cx,
        ground - 0.56 * u,
      )
      ..cubicTo(
        cx + 0.05 * u,
        ground - 0.48 * u,
        cx + 0.21 * u,
        ground - 0.4 * u,
        cx + 0.15 * u,
        ground - 0.27 * u,
      )
      ..close();
    Path minaret(double x) {
      final w = 0.055 * u;
      return Path()
        ..addRect(
          Rect.fromLTRB(x - w / 2, ground - 0.58 * u, x + w / 2, _size.height),
        )
        ..addRect(
          Rect.fromLTRB(
            x - w * 0.85,
            ground - 0.47 * u,
            x + w * 0.85,
            ground - 0.445 * u,
          ),
        )
        ..moveTo(x - w * 0.6, ground - 0.58 * u)
        ..lineTo(x, ground - 0.68 * u)
        ..lineTo(x + w * 0.6, ground - 0.58 * u)
        ..close();
    }

    final left = minaret(cx - 0.34 * u);
    final right = minaret(cx + 0.34 * u);
    for (final shape in [mosque, dome, left, right]) {
      canvas.drawPath(shape, Paint()..color = dark);
    }
    final edge = Paint()
      ..color = p.gilt.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(dome, edge);
    canvas.drawPath(left, edge..color = p.gilt.withValues(alpha: 0.4));
    canvas.drawPath(right, edge);
    // The finial and its crescent.
    final apex = Offset(cx, ground - 0.56 * u);
    canvas.drawLine(
      apex,
      apex - Offset(0, 0.05 * u),
      Paint()
        ..color = p.gilt
        ..strokeWidth = 1,
    );
    _crescent(canvas, apex - Offset(0, 0.075 * u), 0.024 * u);
    // Lit windows.
    final glow = _phase(0.35, 0.8);
    for (final k in const [-1, 0, 1]) {
      final x = cx + k * 0.16 * u;
      final w = 0.07 * u;
      final bottom = ground - 0.03 * u;
      final top = bottom - 0.11 * u;
      canvas.drawPath(
        Path()
          ..moveTo(x - w / 2, bottom)
          ..lineTo(x - w / 2, top + w * 0.5)
          ..quadraticBezierTo(x - w / 2, top, x, top - w * 0.15)
          ..quadraticBezierTo(x + w / 2, top, x + w / 2, top + w * 0.5)
          ..lineTo(x + w / 2, bottom)
          ..close(),
        Paint()
          ..color = Color.lerp(
            p.gilt,
            p.light,
            0.3,
          )!.withValues(alpha: 0.85 * glow),
      );
    }
    const bursts = [(0.18, 0.22, 0.07), (0.78, 0.2, 0.075), (0.5, 0.12, 0.045)];
    for (var i = 0; i < bursts.length; i++) {
      final (fx, fy, r) = bursts[i];
      _burst(canvas, _at(fx, fy), r * u, _phase(0.3 + i * 0.12, 0.7 + i * 0.1));
    }
  }

  /// The Kaaba before the colonnade of the Haram, light rising behind it.
  void _eidAdha(Canvas canvas) {
    final p = palette;
    final u = _u;
    final ground = _y(0.94);
    // The colonnade, across: a low wall pierced by small arches.
    final top = ground - 0.15 * u;
    final colonnade = Path()
      ..addRect(Rect.fromLTRB(0, top, _size.width, _size.height));
    final bay = 0.1 * u;
    final arches = Path();
    for (var x = _size.width - bay * 0.6; x > -bay; x -= bay) {
      final w = bay * 0.62;
      final bottom = ground - 0.01 * u;
      arches
        ..moveTo(x - w / 2, bottom)
        ..lineTo(x - w / 2, top + 0.06 * u)
        ..quadraticBezierTo(x - w / 2, top + 0.02 * u, x, top + 0.015 * u)
        ..quadraticBezierTo(
          x + w / 2,
          top + 0.02 * u,
          x + w / 2,
          top + 0.06 * u,
        )
        ..lineTo(x + w / 2, bottom)
        ..close();
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, colonnade, arches),
      _across(Color.lerp(p.chrome, Colors.black, 0.3)!),
    );
    canvas.drawPath(
      arches,
      _across(p.gilt.withValues(alpha: 0.25 * _phase(0.3, 0.8))),
    );
    _horizon(canvas, top, alpha: 0.5);
    // Light behind the Kaaba.
    final s = 0.42 * u;
    final depth = s * 0.28;
    final front = Rect.fromLTWH(_x(0.5) - (s + depth) / 2, ground - s, s, s);
    _glow(
      canvas,
      front.center - Offset(0, s * 0.25),
      s * 1.7,
      p.gilt,
      0.55 * _phase(0.2, 0.7),
    );
    final dark = Color.lerp(p.chrome, Colors.black, 0.82)!;
    final side = Path()
      ..moveTo(front.right, front.top)
      ..lineTo(front.right + depth, front.top - depth * 0.45)
      ..lineTo(front.right + depth, front.bottom - depth * 0.45)
      ..lineTo(front.right, front.bottom)
      ..close();
    final roof = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + depth, front.top - depth * 0.45)
      ..lineTo(front.right + depth, front.top - depth * 0.45)
      ..lineTo(front.right, front.top)
      ..close();
    canvas.drawRect(front, Paint()..color = dark);
    canvas.drawPath(
      side,
      Paint()..color = Color.lerp(dark, Colors.black, 0.35)!,
    );
    canvas.drawPath(roof, Paint()..color = Color.lerp(dark, p.chrome, 0.3)!);
    // The gilt band, a quarter down, on both faces; the door.
    final band = s * 0.08;
    final y = front.top + s * 0.22;
    final gold = Paint()..color = p.gilt;
    canvas.drawRect(Rect.fromLTWH(front.left, y, s, band), gold);
    canvas.drawPath(
      Path()
        ..moveTo(front.right, y)
        ..lineTo(front.right + depth, y - depth * 0.45)
        ..lineTo(front.right + depth, y - depth * 0.45 + band)
        ..lineTo(front.right, y + band)
        ..close(),
      Paint()..color = Color.lerp(p.gilt, Colors.black, 0.25)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          front.right - s * 0.32,
          front.top + s * 0.5,
          s * 0.17,
          s * 0.36,
        ),
        Radius.circular(s * 0.02),
      ),
      gold,
    );
    _burst(canvas, _at(0.14, 0.24), 0.07 * u, _phase(0.35, 0.75));
    _burst(canvas, _at(0.82, 0.22), 0.075 * u, _phase(0.45, 0.85));
  }

  /// The Mount of Mercy at golden hour: far ridges across, the sun low
  /// behind the mount, its pillar on the summit, pilgrims in white on its
  /// slopes and a path winding up.
  void _arafah(Canvas canvas) {
    final p = palette;
    final u = _u;
    final w = _size.width;
    _sun(canvas, _at(0.74, 0.5), 0.15 * u);
    // Far ridges, across the box: soft hills, no edges.
    void ridge(double base, double rise, double phase, Color color) {
      final path = Path()..moveTo(0, _size.height);
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final x = w * i / steps;
        final y =
            _y(base) -
            rise * u * (0.5 + 0.5 * math.sin(i / steps * math.pi * 3 + phase));
        i == 0 ? path.lineTo(x, y) : path.lineTo(x, y);
      }
      path
        ..lineTo(w, _size.height)
        ..close();
      canvas.drawPath(path, _across(color));
    }

    ridge(0.8, 0.1, 0.6, Color.lerp(p.chromeEnd, p.gilt, 0.18)!);
    ridge(0.9, 0.07, 2.2, Color.lerp(p.chrome, p.chromeEnd, 0.35)!);
    // The mount, inside the stage.
    final peak = _at(0.52, 0.5);
    final mount = Path()
      ..moveTo(_x(0.08), _y(0.97))
      ..cubicTo(_x(0.26), _y(0.8), _x(0.4), _y(0.52), peak.dx, peak.dy)
      ..cubicTo(_x(0.64), _y(0.52), _x(0.78), _y(0.8), _x(0.94), _y(0.97))
      ..lineTo(_x(0.94), _size.height)
      ..lineTo(_x(0.08), _size.height)
      ..close();
    canvas.drawPath(mount, Paint()..color = p.dark);
    // The sun's light on its far flank.
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..cubicTo(_x(0.64), _y(0.52), _x(0.78), _y(0.8), _x(0.94), _y(0.97)),
      Paint()
        ..color = p.gilt.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // The path winding up, dotted in gilt.
    final trail = Path()
      ..moveTo(_x(0.3), _size.height)
      ..cubicTo(
        _x(0.5),
        _y(0.86),
        _x(0.34),
        _y(0.7),
        peak.dx,
        peak.dy + 0.02 * u,
      );
    final dots = Paint()..color = p.gilt.withValues(alpha: 0.6);
    for (final metric in trail.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 5) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 0.8, dots);
      }
    }
    // Pilgrims in white on the lower slopes.
    final random = math.Random(9);
    final pilgrim = Paint()
      ..color = p.light.withValues(alpha: 0.7 * _phase(0.4, 0.9));
    for (var i = 0; i < 40; i++) {
      final at = Offset(
        _x(0.12 + random.nextDouble() * 0.8),
        _y(0.74 + random.nextDouble() * 0.24),
      );
      if (mount.contains(at)) {
        canvas.drawCircle(at, 0.7 + random.nextDouble() * 0.5, pilgrim);
      }
    }
    // The plain in front, grounding the mount's foot.
    canvas.drawRect(
      Rect.fromLTRB(0, _y(0.95), _size.width, _size.height),
      _across(Color.lerp(p.dark, Colors.black, 0.25)!),
    );
    _horizon(canvas, _y(0.95), alpha: 0.35);
    // The pillar on the summit, catching the light.
    final pillar = Rect.fromLTWH(
      peak.dx - 0.018 * u,
      peak.dy - 0.15 * u,
      0.036 * u,
      0.15 * u,
    );
    _glow(canvas, pillar.center, 0.16 * u, p.light, 0.35 * _phase(0.4, 0.9));
    canvas.drawRect(
      pillar,
      Paint()..color = Color.lerp(p.light, p.gilt, 0.25)!,
    );
  }

  /// Ten lamps rising along an arc to the tenth day, a burst; the dawn on
  /// the horizon.
  void _tenRising(Canvas canvas) {
    final p = palette;
    final u = _u;
    final horizon = _y(0.88);
    _glow(
      canvas,
      Offset(_x(0.9), horizon),
      0.6 * u,
      p.gilt,
      0.4 * _phase(0, 0.5),
    );
    _horizon(canvas, horizon, alpha: 0.5);
    Offset lamp(int i) {
      final f = i / 9;
      return _at(0.1 + 0.7 * f, 0.78 - 0.56 * math.pow(f, 1.2));
    }

    final arc = Path()..moveTo(lamp(0).dx, lamp(0).dy);
    for (var i = 1; i < 10; i++) {
      arc.lineTo(lamp(i).dx, lamp(i).dy);
    }
    canvas.drawPath(
      arc,
      Paint()
        ..color = p.gilt.withValues(alpha: 0.25 * _phase(0.2, 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 10; i++) {
      final t = _phase(0.3 + i * 0.05, 0.55 + i * 0.045);
      if (i == 9) {
        _burst(canvas, lamp(i), 0.065 * u, t);
        continue;
      }
      final r = u * (0.016 + 0.003 * i);
      _glow(canvas, lamp(i), r * 3.2, p.gilt, 0.45 * t);
      canvas.drawCircle(
        lamp(i),
        r,
        Paint()..color = Color.lerp(p.gilt, p.light, 0.4)!.withValues(alpha: t),
      );
    }
  }

  /// The sea parted: two walls of water with curling crests, a dry path
  /// between them running to the dawn.
  void _partedSea(Canvas canvas) {
    final p = palette;
    final w = _size.width;
    final horizon = _y(0.5);
    _sun(canvas, _at(0.5, 0.47), 0.07 * _u);
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, _size.height),
      _across(Color.lerp(p.chromeEnd, Colors.black, 0.25)!),
    );
    _horizon(canvas, horizon, alpha: 0.35);
    final mid = _x(0.5);
    final path = Path()
      ..moveTo(mid - _s.width * 0.012, horizon)
      ..lineTo(mid + _s.width * 0.012, horizon)
      ..lineTo(mid + _s.width * 0.12, _size.height)
      ..lineTo(mid - _s.width * 0.12, _size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(p.gilt, p.light, 0.4)!,
            Color.lerp(p.gilt, p.chromeEnd, 0.45)!,
          ],
        ).createShader(Rect.fromLTRB(0, horizon, w, _size.height)),
    );
    void wall(double side) {
      double x(double f) => _x(0.5 + side * f);
      final bottom = _size.height;
      final shape = Path()
        ..moveTo(x(0.44), bottom)
        ..lineTo(x(0.44), _y(0.6))
        ..quadraticBezierTo(x(0.38), _y(0.2), x(0.16), _y(0.16))
        ..quadraticBezierTo(x(0.07), _y(0.15), x(0.06), _y(0.26))
        ..quadraticBezierTo(x(0.1), _y(0.24), x(0.09), _y(0.34))
        ..quadraticBezierTo(x(0.07), _y(0.7), x(0.13), bottom)
        ..close();
      canvas.drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(p.chromeEnd, p.light, 0.18)!,
              Color.lerp(p.chrome, Colors.black, 0.3)!,
            ],
          ).createShader(Rect.fromLTRB(0, _y(0.15), w, bottom)),
      );
      canvas.save();
      canvas.clipPath(shape);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var i = 0; i < 6; i++) {
        final dy = _s.height * (0.06 + i * 0.11);
        line.color = p.gilt.withValues(alpha: 0.55 - i * 0.07);
        canvas.drawPath(
          Path()
            ..moveTo(x(0.46), _y(0.6) + dy)
            ..quadraticBezierTo(x(0.38), _y(0.2) + dy, x(0.14), _y(0.18) + dy),
          line,
        );
      }
      canvas.restore();
      canvas.drawPath(
        Path()
          ..moveTo(x(0.44), _y(0.6))
          ..quadraticBezierTo(x(0.38), _y(0.2), x(0.16), _y(0.16))
          ..quadraticBezierTo(x(0.07), _y(0.15), x(0.06), _y(0.26))
          ..quadraticBezierTo(x(0.1), _y(0.24), x(0.09), _y(0.34)),
        Paint()
          ..color = p.gilt.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
      final random = math.Random(side > 0 ? 7 : 11);
      final spray = Paint()
        ..color = p.light.withValues(alpha: 0.5 * _phase(0.4, 0.9));
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(
            x(0.08 + random.nextDouble() * 0.16),
            _y(0.08 + random.nextDouble() * 0.08),
          ),
          0.6 + random.nextDouble() * 1,
          spray,
        );
      }
    }

    wall(-1);
    wall(1);
  }

  /// Three lamps standing on the ground at dusk, the three days; a slim
  /// crescent.
  void _tashreeq(Canvas canvas) {
    final p = palette;
    final u = _u;
    final ground = _y(0.86);
    canvas.drawRect(
      Rect.fromLTRB(0, ground, _size.width, _size.height),
      _across(p.dark),
    );
    _horizon(canvas, ground);
    _crescent(canvas, _at(0.82, 0.18), 0.075 * u);
    const lamps = [(0.24, 0.13), (0.5, 0.155), (0.76, 0.13)];
    for (var i = 0; i < lamps.length; i++) {
      final (fx, size) = lamps[i];
      final w = size * u;
      _lantern(
        canvas,
        Offset(_x(fx), ground - w * 2.3),
        w,
        _phase(0.3 + i * 0.15, 0.7 + i * 0.1),
      );
    }
  }

  /// Three full moons along an arc, the middle one brightest: the 13th,
  /// 14th and 15th.
  void _moons(Canvas canvas, List<(double, double, double)> at) {
    final p = palette;
    for (var i = 0; i < at.length; i++) {
      final (fx, fy, size) = at[i];
      final c = _at(fx, fy);
      final r = size * _u;
      final t = _phase(0.2 + i * 0.15, 0.6 + i * 0.12);
      if (t <= 0) continue;
      _glow(canvas, c, r * 2.8, p.light, (i == 1 ? 0.3 : 0.2) * t);
      canvas.drawCircle(
        c,
        r,
        Paint()..color = Color.lerp(p.light, p.gilt, 0.3)!.withValues(alpha: t),
      );
      canvas.drawCircle(
        c + Offset(-r * 0.3, -r * 0.15),
        r * 0.22,
        Paint()..color = p.gilt.withValues(alpha: 0.18 * t),
      );
      canvas.drawCircle(
        c + Offset(r * 0.25, r * 0.3),
        r * 0.15,
        Paint()..color = p.gilt.withValues(alpha: 0.14 * t),
      );
    }
  }

  /// Still water across the foot, the moons' light on it.
  void _water(Canvas canvas, {required double top}) {
    final p = palette;
    final y0 = _y(top);
    canvas.drawRect(
      Rect.fromLTRB(0, y0, _size.width, _size.height),
      _across(Color.lerp(p.chrome, Colors.black, 0.35)!),
    );
    _horizon(canvas, y0, alpha: 0.35);
    final line = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final fx in const [0.2, 0.5, 0.8]) {
      final x = _x(fx);
      for (var j = 0; j < 4; j++) {
        final y = y0 + _s.height * (0.05 + j * 0.05);
        final half = _u * (0.08 - j * 0.015);
        line.color = p.gilt.withValues(alpha: (0.5 - j * 0.1) * _phase(0.5, 1));
        canvas.drawLine(Offset(x - half, y), Offset(x + half, y), line);
      }
    }
  }

  /// The week as seven pointed arches on the ground, Monday and Thursday
  /// lit (the week from Sunday).
  void _week(Canvas canvas, {required double ground}) {
    final p = palette;
    final y = _y(ground);
    canvas.drawRect(
      Rect.fromLTRB(0, y, _size.width, _size.height),
      _across(p.dark),
    );
    _horizon(canvas, y, alpha: 0.5);
    final bay = _s.width * 0.84 / 7;
    final w = math.min(bay * 0.66, _u * 0.11);
    final h = w * 1.55;
    for (var i = 0; i < 7; i++) {
      final x = _x(0.08) + bay * (i + 0.5);
      final arch = Path()
        ..moveTo(x - w / 2, y)
        ..lineTo(x - w / 2, y - h * 0.6)
        ..quadraticBezierTo(x - w / 2, y - h * 0.92, x, y - h)
        ..quadraticBezierTo(x + w / 2, y - h * 0.92, x + w / 2, y - h * 0.6)
        ..lineTo(x + w / 2, y)
        ..close();
      final lit = i == 1 || i == 4;
      if (lit) {
        final t = _phase(0.4 + (i == 4 ? 0.15 : 0), 0.85);
        _glow(canvas, Offset(x, y - h / 2), w * 1.8, p.gilt, 0.55 * t);
        canvas.drawPath(
          arch,
          Paint()
            ..color = Color.lerp(
              p.gilt,
              p.light,
              0.4,
            )!.withValues(alpha: 0.35 + 0.65 * t),
        );
      } else {
        canvas.drawPath(arch, Paint()..color = p.dark);
        canvas.drawPath(
          arch,
          Paint()
            ..color = p.gilt.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HomeEventScenePainter old) =>
      old.eventKey != eventKey ||
      old.palette != palette ||
      old.rtl != rtl ||
      old.stage != stage ||
      old.reveal != reveal;
}
