import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/checklist/checklist_identity.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_identity.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_identity.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_identity.dart';

/// Home's voice (see `design/IDENTITIES.md`): the hall of lamps. Every
/// tool hangs as a small chrome plate carrying its own feature's art, the
/// same art its landing header shows large, so a plate is a window onto
/// the page it opens. Home's own pieces are the plate and the
/// lamplighter: as Home opens the plates light one after another. Home's
/// header carries Huda's own logo ([HomeLogo]), not a drawing.
final FeatureIdentity homeIdentity = FeatureIdentity(
  id: 'home',
  motif: 'The hall of lamps: each tool a chrome plate lit with its own art',
  count: HomeFeatureId.values.length,
  rhythm: IdentityRhythm.field,
  material: IdentityMaterial.night,
  headerArt: (style) => HomePrayerArtPainter(style: style),
);

/// The pieces Quran Kit unfolds, each with its plate.
enum HomeQuranTool { quran, audio, radio, bookmarks }

/// A tool's art: its feature's identity art, or Home's drawing for the
/// tools whose pages carry none (Prayer, whose header is the sky itself;
/// Ramadan; Settings and Widgets, quiet by design).
HeaderArtBuilder homeToolArt(HomeFeatureId id) => switch (id) {
  HomeFeatureId.quran => homeQuranMedallion,
  // The Kit holds the Quran's tools as a rahla holds the Mushaf.
  HomeFeatureId.quranKit => (style) => HomeRahlaPainter(style: style),
  HomeFeatureId.hadith => hadithIdentity.headerArt,
  HomeFeatureId.athkar => athkarIdentity.headerArt,
  HomeFeatureId.hijriCalendar => calendarIdentity.headerArt,
  HomeFeatureId.miqaatLock => miqaatLockIdentity.headerArt,
  HomeFeatureId.books => booksIdentity.headerArt,
  HomeFeatureId.audios => audiobooksIdentity.headerArt,
  HomeFeatureId.hudaAI => hudaAiIdentity.headerArt,
  HomeFeatureId.checklist => checklistIdentity.headerArt,
  HomeFeatureId.qiblah => qiblahIdentity.headerArt,
  HomeFeatureId.zakat => zakatIdentity.headerArt,
  HomeFeatureId.tasbih => tasbihIdentity.headerArt,
  // Prayer's living sky, engraved: the sun on its day path over the hills.
  HomeFeatureId.prayerTimes => (style) => HomePrayerArtPainter(style: style),
  // Ramadan lives in the calendar: the month's moons, waxing to full and
  // waning, along an arc (the calendar's own tile is one moon).
  HomeFeatureId.ramadan => (style) => HomeMonthMoonsPainter(style: style),
  // Reminders: the day dial, small.
  HomeFeatureId.notifications => (style) => HomeDayDialPainter(style: style),
  HomeFeatureId.settings => (style) => HomeSettingsArtPainter(style: style),
  HomeFeatureId.widgetManagement => (style) => HomeWidgetsArtPainter(
    style: style,
  ),
};

/// The art of a Quran Kit piece.
HeaderArtBuilder homeQuranToolArt(HomeQuranTool tool) => switch (tool) {
  HomeQuranTool.quran => homeQuranMedallion,
  HomeQuranTool.audio => quranAudioIdentity.headerArt,
  HomeQuranTool.radio => quranRadioIdentity.headerArt,
  // A saved place: the ayah-end rosette.
  HomeQuranTool.bookmarks => (style) => QuranRosettePainter(
    color: style.color,
    fill: style.color.withValues(alpha: 0),
    stroke: style.stroke,
  ),
};

/// Quran's medallion for a plate. The landing header lets its art run 8
/// below its edge, so the medallion keeps 10 free at its foot; a plate has
/// no such edge, so it gets that room back and sits centered at full size.
CustomPainter homeQuranMedallion(OrnamentStyle style) =>
    _RoomPainter(quranIdentity.headerArt(style), foot: 10);

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.inner, {required this.foot});

  final CustomPainter inner;
  final double foot;

  @override
  void paint(Canvas canvas, Size size) =>
      inner.paint(canvas, Size(size.width, size.height + foot));

  @override
  bool shouldRepaint(_RoomPainter old) => inner.shouldRepaint(old.inner);
}

// The lamplighter -------------------------------------------------------------

/// Home's signature motion: as Home opens, its plates light one after
/// another in reading order, each from an engraved outline to its luminous
/// gilt with a soft glow that swells once (about 1.1 s, once per Home).
/// Plates read their own moment from their index; plates built later
/// (scrolled in) are already lit. Reduce motion: lit from the first frame.
class HomeLamplighter extends StatefulWidget {
  const HomeLamplighter({super.key, required this.child});

  final Widget child;

  static const duration = Duration(milliseconds: 1100);

  /// Each plate's own light, from the lamplighter above it (lit when there
  /// is none).
  static Animation<double> lightOf(BuildContext context, int index) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_LamplighterScope>();
    if (scope == null) return kAlwaysCompleteAnimation;
    final start = math.min(index * 0.055, 0.72);
    return CurvedAnimation(
      parent: scope.animation,
      curve: Interval(start, math.min(1, start + 0.28), curve: Curves.easeOut),
    );
  }

  @override
  State<HomeLamplighter> createState() => _HomeLamplighterState();
}

class _HomeLamplighterState extends State<HomeLamplighter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HomeLamplighter.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    // After the first frame, so the page is there when the lamps light.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _LamplighterScope(animation: _controller, child: widget.child);
}

class _LamplighterScope extends InheritedWidget {
  const _LamplighterScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_LamplighterScope old) => old.animation != animation;
}

// The plate -------------------------------------------------------------------

/// A tool's plate: a small deep tablet with a faint gilt rim carrying the
/// tool's [art]. It lights when the lamplighter reaches [index]: the
/// engraved outline gives way to the luminous art while a glow swells once
/// and settles.
class HomePlate extends StatelessWidget {
  const HomePlate({
    super.key,
    required this.art,
    this.index = 0,
    this.size,
    this.highlighted = false,
    this.round = false,
  });

  final HeaderArtBuilder art;
  final int index;

  /// A round medallion (the focused styles' tools): a domed face under a
  /// double gilt ring.
  final bool round;

  /// Square side; fills the width it's given when null.
  final double? size;

  /// A brighter rim (an unfolded Quran Kit or View More).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final light = HomeLamplighter.lightOf(context, index);
    final radius = BorderRadius.circular(tokens.radius.md);
    final lit = OrnamentStyle.of(context, onChrome: true);
    final unlit = OrnamentStyle(
      color: tokens.gilt.withValues(alpha: 0.32),
      render: OrnamentRender.line,
      stroke: tokens.stroke.hairline,
    );
    // The glow swells as the plate lights, then settles to a faint warmth.
    final glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.35), weight: 45),
    ]).animate(light);

    final face = round
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.25, -0.4),
              radius: 1,
              colors: [
                Color.lerp(tokens.chromeEnd, tokens.gilt, 0.14)!,
                tokens.chrome,
              ],
            ),
          )
        : BoxDecoration(gradient: tokens.chromeGradient, borderRadius: radius);
    final inner = Stack(
      fit: StackFit.expand,
      children: [
        // A medallion's inner ring, a little in from its rim.
        if (round)
          Padding(
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.gilt.withValues(alpha: 0.22),
                  width: tokens.stroke.hairline,
                ),
              ),
            ),
          ),
        FadeTransition(
          opacity: glow,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  tokens.gilt.withValues(alpha: 0.26),
                  tokens.gilt.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: round ? 0.56 : 0.68,
          heightFactor: round ? 0.56 : 0.68,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: ReverseAnimation(light),
                child: Ornament(painter: art(unlit)),
              ),
              FadeTransition(
                opacity: light,
                child: Ornament(painter: art(lit)),
              ),
            ],
          ),
        ),
      ],
    );
    final plate = DecoratedBox(
      decoration: face,
      child: round
          ? ClipOval(child: inner)
          : ClipRRect(borderRadius: radius, child: inner),
    );
    final rimColor = tokens.gilt.withValues(
      alpha: highlighted ? 0.8 : (round ? 0.5 : 0.18),
    );
    final rimmed = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : radius,
        border: Border.all(
          color: rimColor,
          width: highlighted ? tokens.stroke.fine : tokens.stroke.hairline,
        ),
      ),
      child: plate,
    );
    final square = AspectRatio(aspectRatio: 1, child: rimmed);
    final size = this.size;
    return ExcludeSemantics(
      child: size == null
          ? square
          : SizedBox.square(dimension: size, child: square),
    );
  }
}

/// Huda's logo (the app's own mark, `assets/images/huda.png`) in gilt,
/// lit from above like the lamps, with a faint glow of its own shape so it
/// sits in the night rather than on it. [height] is the glyph's; the
/// asset's padding is cropped away. In [ink] (on the page) it's the
/// engraved color, without the glow.
class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key, required this.height, this.ink = false});

  static const asset = 'assets/images/huda.png';

  /// The glyph's width over its height.
  static const aspect = _glyphWidth / _glyphHeight;

  // The glyph's box inside the 1024 square asset.
  static const _glyphWidth = 830 / 1024;
  static const _glyphHeight = 448 / 1024;

  final double height;
  final bool ink;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = ink ? tokens.ornament : tokens.gilt;
    final side = height / _glyphHeight;
    final light = Color.lerp(color, Colors.white, ink ? 0.15 : 0.45)!;
    Widget glyph() => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, color, Color.lerp(color, Colors.black, 0.12)!],
        stops: const [0.3, 0.55, 0.72],
      ).createShader(bounds),
      child: Image.asset(
        asset,
        width: side,
        height: side,
        filterQuality: FilterQuality.medium,
      ),
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          key: const ValueKey('home-logo'),
          width: side * _glyphWidth,
          height: height,
          child: OverflowBox(
            maxWidth: side,
            maxHeight: side,
            child: Stack(
              children: [
                if (!ink)
                  // The glow: the glyph itself, blurred and faint.
                  Opacity(
                    opacity: 0.5,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: height / 10,
                        sigmaY: height / 10,
                      ),
                      child: glyph(),
                    ),
                  ),
                glyph(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Painters --------------------------------------------------------------------

/// Reminders' day dial, small enough for a plate: a half disc on a double
/// base rule, twelve hour lines fanning from the center (every third
/// stronger), the rim, and a gilt hand to now. Runs in reading direction.
class HomeDayDialPainter extends CustomPainter {
  HomeDayDialPainter({
    required this.style,
    double? dayFraction,
    this.rtl = false,
  }) : dayFraction = dayFraction ?? _today();

  final OrnamentStyle style;
  final double dayFraction;
  final bool rtl;

  static double _today() {
    final now = DateTime.now();
    return (now.hour + now.minute / 60) / 24;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = math.min(w / 2, size.height * 0.78) - style.stroke * 2;
    if (r <= 0) return;
    final c = Offset(w / 2, size.height / 2 + r * 0.42);
    final line = style.line;
    final quiet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.stroke * 0.8
      ..strokeCap = StrokeCap.round
      ..color = style.color.withValues(alpha: style.color.a * 0.55);
    // The base, doubled.
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), line);
    canvas.drawLine(c + Offset(-r, r * 0.09), c + Offset(r, r * 0.09), quiet);
    // The rim.
    final rim = Rect.fromCircle(center: c, radius: r);
    style.draw(canvas, Path()..addArc(rim, math.pi, math.pi), closed: false);
    // Hour lines, every two hours (every third of them stronger).
    for (var i = 1; i < 12; i++) {
      final a = math.pi + math.pi * i / 12;
      final dir = Offset(math.cos(a), math.sin(a));
      final strong = i % 3 == 0;
      canvas.drawLine(
        c + dir * r * (strong ? 0.34 : 0.5),
        c + dir * r * 0.9,
        strong ? line : quiet,
      );
    }
    // The hand to now, from the reading start.
    final t = rtl ? 1 - dayFraction : dayFraction;
    final a = math.pi + math.pi * t;
    final tip = c + Offset(math.cos(a), math.sin(a)) * r * 0.96;
    style.draw(
      canvas,
      Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(tip.dx, tip.dy),
      closed: false,
    );
    canvas.drawCircle(c, style.stroke * 2.2, style.fill());
  }

  @override
  bool shouldRepaint(HomeDayDialPainter old) =>
      old.style != style || old.dayFraction != dayFraction || old.rtl != rtl;
}

/// Quran Kit's plate: a rahla, the folding wooden stand a Mushaf is read
/// on, holding an open Mushaf. Two carved boards cross in an X at their
/// hinge, their upper arms a cradle for the open pages, their legs pierced
/// with a pointed-arch cutout. The Kit holds the Quran's tools as the
/// stand holds the Quran, so its plate is the stand, not the Quran's own
/// medallion (owner, 2026-11-13: the two plates looked the same).
class HomeRahlaPainter extends CustomPainter {
  const HomeRahlaPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height);
    if (m < 12) return;
    canvas.save();
    canvas.translate((size.width - m) / 2, (size.height - m) / 2);
    Offset p(double x, double y) => Offset(x * m, y * m);
    final thin = style.copyWith(stroke: math.max(0.8, style.stroke * 0.85));

    // The boards: each from just under a page, through the hinge, to a
    // foot. They cross where they meet the middle.
    const topX = 0.29, topY = 0.47, footX = 0.33, footY = 0.95;
    final hinge = p(0.5, topY + (footY - topY) * topX / (topX + footX));
    for (final side in [-1.0, 1.0]) {
      final top = p(0.5 + side * topX, topY);
      final foot = p(0.5 - side * footX, footY);
      final along = foot - top;
      final length = along.distance;
      final angle = math.atan2(along.dy, along.dx);
      final half = m * 0.045;
      canvas.save();
      canvas.translate(top.dx, top.dy);
      canvas.rotate(angle);
      final board = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -half, length, half * 2),
        Radius.circular(half * 0.6),
      );
      canvas.drawRRect(board, style.fill(0.1));
      style.draw(canvas, Path()..addRRect(board));
      // The leg's cutout: a slim pointed arch along the board, below the
      // hinge.
      final from = length * 0.68;
      final to = length * 0.9;
      final w = half * 0.42;
      thin.draw(
        canvas,
        Path()
          ..moveTo(to, -w)
          ..lineTo(from + w * 1.6, -w)
          ..quadraticBezierTo(from, -w, from, 0)
          ..quadraticBezierTo(from, w, from + w * 1.6, w)
          ..lineTo(to, w)
          ..close(),
      );
      canvas.restore();
    }
    // The hinge pin.
    canvas.drawCircle(hinge, m * 0.032, style.fill());

    // The open Mushaf in the cradle: two pages rising from the gutter,
    // their outer edges lifted, with lines of text.
    final gutterLow = p(0.5, 0.5);
    final gutterHigh = p(0.5, 0.26);
    for (final side in [-1.0, 1.0]) {
      final outerLow = p(0.5 + side * 0.42, 0.33);
      final outerHigh = p(0.5 + side * 0.4, 0.1);
      final page = Path()
        ..moveTo(gutterLow.dx, gutterLow.dy)
        ..quadraticBezierTo(
          0.5 * m + side * 0.2 * m,
          0.47 * m,
          outerLow.dx,
          outerLow.dy,
        )
        ..lineTo(outerHigh.dx, outerHigh.dy)
        ..quadraticBezierTo(
          0.5 * m + side * 0.2 * m,
          0.22 * m,
          gutterHigh.dx,
          gutterHigh.dy,
        )
        ..close();
      canvas.drawPath(page, style.fill(0.12));
      style.draw(canvas, page);
      // Three lines of text, following the page's curve.
      for (var i = 0; i < 3; i++) {
        final t = 0.3 + i * 0.2;
        final y0 = 0.26 + (0.5 - 0.26) * t;
        final y1 = 0.1 + (0.33 - 0.1) * t;
        final start = p(0.5 + side * 0.07, y0 - 0.02);
        final end = p(0.5 + side * 0.34, y1 + 0.005);
        thin.draw(
          canvas,
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              0.5 * m + side * 0.2 * m,
              (y0 + y1) / 2 * m + 0.03 * m,
              end.dx,
              end.dy,
            ),
          closed: false,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HomeRahlaPainter old) => old.style != style;
}

/// Ramadan's plate: the month's moons along an arc, from the young
/// crescent through the full moon to the last crescent.
class HomeMonthMoonsPainter extends CustomPainter {
  const HomeMonthMoonsPainter({required this.style});

  final OrnamentStyle style;

  static const _phases = [0.22, 0.5, 0.78];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final d = w / 3.1;
    if (d < 4) return;
    final moon = OrnamentStyle(
      color: style.color,
      render: style.render,
      stroke: math.max(0.8, style.stroke * 0.8),
    );
    for (var i = 0; i < _phases.length; i++) {
      // A gentle arc: the full moon highest, in the middle.
      final x = w * (0.17 + i * 0.33);
      final lift = i == 1 ? 1.0 : 0.0;
      final y = size.height * 0.6 - lift * size.height * 0.16;
      canvas.save();
      canvas.translate(x - d / 2, y - d / 2);
      CalendarMoonPainter.styled(
        phase: _phases[i],
        style: moon,
      ).paint(canvas, Size.square(d));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(HomeMonthMoonsPainter old) => old.style != style;
}

/// Prayer's plate: Prayer's living sky, engraved. The sun's day path as a
/// dotted arc from horizon to horizon with a small lamp for each of the
/// five prayers, the sun on it in the afternoon, over the sky's three
/// ridges of hills (the front one strongest).
class HomePrayerArtPainter extends CustomPainter {
  const HomePrayerArtPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final m = math.min(w, h);
    if (m < 12) return;
    final horizon = h * 0.64;
    final center = Offset(w / 2, horizon);
    final rx = w * 0.4;
    final ry = h * 0.48;
    Offset on(double t) {
      final a = math.pi + math.pi * t;
      return center + Offset(math.cos(a) * rx, math.sin(a) * ry);
    }

    // The day path: dots, quieter than the rest.
    final dot = style.fill(0.55);
    for (var i = 0; i <= 18; i++) {
      canvas.drawCircle(on(i / 18), math.max(0.6, style.stroke * 0.55), dot);
    }
    // A lamp per prayer; the sun stands at the fourth (Asr).
    const lamps = [0.08, 0.3, 0.52, 0.74, 0.94];
    const sunAt = 3;
    final lamp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, style.stroke * 0.9)
      ..color = style.color;
    for (var i = 0; i < lamps.length; i++) {
      if (i == sunAt) continue;
      final p = on(lamps[i]);
      canvas.drawCircle(p, math.max(1.6, m * 0.035), style.fill(0.25));
      canvas.drawCircle(p, math.max(1.6, m * 0.035), lamp);
    }
    final sun = on(lamps[sunAt]);
    final r = m * 0.1;
    canvas.drawCircle(sun, r * 1.75, style.fill(0.12));
    style.draw(
      canvas,
      Path()..addOval(Rect.fromCircle(center: sun, radius: r * 1.75)),
    );
    canvas.drawCircle(sun, r, style.fill());
    // Three ridges, back to front.
    for (var i = 0; i < 3; i++) {
      final y = horizon + h * (0.06 + i * 0.1);
      final a = h * (0.045 - i * 0.008);
      final shift = i.isEven ? 0.0 : w * 0.18;
      final ridge = Path()..moveTo(w * 0.02, y);
      ridge
        ..quadraticBezierTo(w * 0.22 + shift, y - a * 2, w * 0.45, y)
        ..quadraticBezierTo(
          w * 0.7 - shift * 0.5,
          y + a * 1.6,
          w * 0.98,
          y - a,
        );
      final ridgeStyle = i == 2
          ? style
          : style.copyWith(
              color: style.color.withValues(
                alpha: style.color.a * (0.45 + i * 0.2),
              ),
            );
      ridgeStyle.draw(canvas, ridge, closed: false);
    }
  }

  @override
  bool shouldRepaint(HomePrayerArtPainter old) => old.style != style;
}

/// Settings' plate: a gear of eight teeth around a ring (Settings has no
/// motif by design; this is its plain mark, engraved like the rest).
class HomeSettingsArtPainter extends CustomPainter {
  const HomeSettingsArtPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height);
    if (m < 12) return;
    final c = size.center(Offset.zero);
    final tip = m * 0.46;
    final root = m * 0.35;
    const teeth = 8;
    const step = math.pi * 2 / teeth;
    Offset at(double radius, double angle) =>
        c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    final gear = Path();
    for (var i = 0; i < teeth; i++) {
      final a = -math.pi / 2 + i * step;
      final p1 = at(root, a - 0.3);
      if (i == 0) gear.moveTo(p1.dx, p1.dy);
      final p2 = at(tip, a - 0.17);
      final p3 = at(tip, a + 0.17);
      final p4 = at(root, a + 0.3);
      gear
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..arcTo(
          Rect.fromCircle(center: c, radius: root),
          a + 0.3,
          step - 0.6,
          false,
        );
    }
    gear.close();
    canvas.drawPath(gear, style.fill(0.1));
    style.draw(canvas, gear);
    style.draw(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: m * 0.17)),
    );
    canvas.drawCircle(c, m * 0.06, style.fill());
  }

  @override
  bool shouldRepaint(HomeSettingsArtPainter old) => old.style != style;
}

/// Widgets' plate: a home screen's widgets. A wide one with the sun's day
/// path (the prayer widget), and two small ones: lines of a verse and a
/// clock.
class HomeWidgetsArtPainter extends CustomPainter {
  const HomeWidgetsArtPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height) * 0.92;
    if (m < 12) return;
    final origin = size.center(Offset.zero) - Offset(m / 2, m / 2);
    final gap = m * 0.12;
    final small = (m - gap) / 2;
    final radius = Radius.circular(m * 0.1);
    final wide = Rect.fromLTWH(origin.dx, origin.dy, m, small);
    final left = Rect.fromLTWH(
      origin.dx,
      origin.dy + small + gap,
      small,
      small,
    );
    final right = Rect.fromLTWH(
      origin.dx + small + gap,
      origin.dy + small + gap,
      small,
      small,
    );
    for (final rect in [wide, left, right]) {
      final box = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(box, style.fill(0.1));
      style.draw(canvas, Path()..addRRect(box));
    }
    final thin = style.copyWith(stroke: math.max(0.8, style.stroke * 0.85));
    // The prayer widget: the day path and the sun on it.
    final arc = Rect.fromLTRB(
      wide.left + wide.width * 0.2,
      wide.top + wide.height * 0.28,
      wide.right - wide.width * 0.2,
      wide.bottom + wide.height * 0.42,
    );
    thin.draw(
      canvas,
      Path()..addArc(arc, math.pi * 1.04, math.pi * 0.92),
      closed: false,
    );
    final a = math.pi * 1.68;
    final sun =
        arc.center +
        Offset(math.cos(a) * arc.width / 2, math.sin(a) * arc.height / 2);
    canvas.drawCircle(sun, m * 0.055, style.fill());
    // The verse: three lines, the last short.
    for (var i = 0; i < 3; i++) {
      final y = left.top + left.height * (0.32 + i * 0.18);
      final end = left.right - left.width * (i == 2 ? 0.45 : 0.22);
      thin.draw(
        canvas,
        Path()
          ..moveTo(left.left + left.width * 0.22, y)
          ..lineTo(end, y),
        closed: false,
      );
    }
    // The clock.
    final c = right.center;
    final r = right.width * 0.3;
    thin.draw(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    thin.draw(
      canvas,
      Path()
        ..moveTo(c.dx, c.dy - r * 0.62)
        ..lineTo(c.dx, c.dy)
        ..lineTo(c.dx + r * 0.48, c.dy + r * 0.2),
      closed: false,
    );
  }

  @override
  bool shouldRepaint(HomeWidgetsArtPainter old) => old.style != style;
}
