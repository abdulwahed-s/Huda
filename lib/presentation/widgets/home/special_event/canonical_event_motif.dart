import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/special_event/event_visual_identity.dart';

enum EventVisualHost {
  classic,
  prayer,
  quran,
  dialog,
}

class CanonicalEventMotif extends StatelessWidget {
  const CanonicalEventMotif({
    super.key,
    required this.eventKey,
    required this.host,
    required this.accent,
    required this.secondary,
    required this.progress,
    this.textDirection,
    this.strokeWidth = 1.5,
    this.highContrast = false,
  });

  final String eventKey;
  final EventVisualHost host;
  final Color accent;
  final Color secondary;
  final Animation<double> progress;
  final TextDirection? textDirection;
  final double strokeWidth;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final direction =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;
    final contrast =
        highContrast || (MediaQuery.maybeOf(context)?.highContrast ?? false);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: CanonicalEventMotifPainter(
              eventKey: eventKey,
              host: host,
              accent: accent,
              secondary: secondary,
              progress: progress,
              textDirection: direction,
              strokeWidth: strokeWidth,
              highContrast: contrast,
            ),
          ),
        ),
      ),
    );
  }
}

class CanonicalEventMotifPainter extends CustomPainter {
  CanonicalEventMotifPainter({
    required this.eventKey,
    required this.host,
    required this.accent,
    required this.secondary,
    required this.progress,
    required this.textDirection,
    this.strokeWidth = 1.5,
    this.highContrast = false,
  }) : super(repaint: progress);

  final String eventKey;
  final EventVisualHost host;
  final Color accent;
  final Color secondary;
  final Animation<double> progress;
  final TextDirection textDirection;
  final double strokeWidth;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    final value = progress.value.clamp(0.0, 1.0).toDouble();
    if (value <= 0) return;

    final identity = EventVisualIdentity.resolve(eventKey);
    final geometry = _MotifGeometry(
      rect: _stageFor(size),
      textDirection: textDirection,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawHostScaffold(canvas, geometry, value);
    switch (identity.motif) {
      case EventStructuralMotif.ramadanCrescentDates:
        _drawRamadanCrescentDates(canvas, geometry, value);
      case EventStructuralMotif.lastTenPrayerMatTenNights:
        _drawLastTenPrayerMatTenNights(canvas, geometry, value);
      case EventStructuralMotif.eidFitrZakatGrain:
        _drawEidFitrZakatGrain(canvas, geometry, value);
      case EventStructuralMotif.eidAdhaRamOffering:
        _drawEidAdhaRamOffering(canvas, geometry, value);
      case EventStructuralMotif.arafahMountainMarker:
        _drawArafahMountainMarker(canvas, geometry, value);
      case EventStructuralMotif.dhulHijjahTenDayCalendar:
        _drawDhulHijjahTenDayCalendar(canvas, geometry, value);
      case EventStructuralMotif.ashuraPartedSeaTenthDay:
        _drawAshuraPartedSeaTenthDay(canvas, geometry, value);
      case EventStructuralMotif.tashreeqThreeDayRemembrance:
        _drawTashreeqThreeDayRemembrance(canvas, geometry, value);
      case EventStructuralMotif.whiteDaysThreeFullMoons:
        _drawWhiteDaysThreeFullMoons(canvas, geometry, value);
      case EventStructuralMotif.mondayThursdayWeekCalendar:
        _drawMondayThursdayWeekCalendar(canvas, geometry, value);
      case EventStructuralMotif.whiteDaysWeeklyConfluence:
        _drawWhiteDaysWeeklyConfluence(canvas, geometry, value);
      case EventStructuralMotif.authoredCalendarCrescent:
        _drawAuthoredCalendarCrescent(canvas, geometry, value);
    }
    canvas.restore();
  }

  Rect _stageFor(Size size) {
    final shortest = math.min(size.width, size.height);
    return switch (host) {
      EventVisualHost.classic => Rect.fromLTWH(
          size.width * 0.06,
          size.height * 0.10,
          size.width * 0.88,
          size.height * 0.80,
        ),
      EventVisualHost.prayer => Rect.fromLTWH(
          size.width * 0.04,
          size.height * 0.16,
          size.width * 0.92,
          size.height * 0.68,
        ),
      EventVisualHost.quran => Rect.fromLTWH(
          size.width * 0.07,
          size.height * 0.10,
          size.width * 0.86,
          size.height * 0.80,
        ),
      EventVisualHost.dialog => Rect.fromCenter(
          center: size.center(Offset.zero),
          width: math.min(size.width * 0.88, shortest * 1.35),
          height: shortest * 0.84,
        ),
    };
  }

  double get _strongAlpha => highContrast ? 0.98 : 0.82;
  double get _softAlpha => highContrast ? 0.62 : 0.34;

  Paint _stroke(
    Color color,
    double alpha, {
    double width = 1,
    StrokeCap cap = StrokeCap.round,
  }) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * width * (highContrast ? 1.22 : 1)
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

  Paint _fill(Color color, double alpha) => Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

  double _phase(double value, double begin, double end) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return Curves.easeOutCubic.transform((value - begin) / (end - begin));
  }

  double _stagger(
    double value,
    int index,
    int count, {
    double begin = 0.08,
    double end = 0.84,
  }) {
    final slot = (end - begin) / math.max(1, count);
    final start = begin + slot * index * 0.72;
    return _phase(value, start, math.min(1, start + slot * 2.2));
  }

  void _drawHostScaffold(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    final reveal = _phase(value, 0, 0.42);
    final paint = _stroke(secondary, _softAlpha * reveal, width: 0.72);
    switch (host) {
      case EventVisualHost.classic:
        _drawLineProgress(
            canvas, g.p(0.02, 0.50), g.p(0.24, 0.50), paint, reveal);
        _drawLineProgress(
            canvas, g.p(0.76, 0.50), g.p(0.98, 0.50), paint, reveal);
        _drawCorner(canvas, g, 0.08, 0.18, reveal, paint);
        _drawCorner(canvas, g, 0.92, 0.82, reveal, paint);
      case EventVisualHost.prayer:
        _drawLineFromCenter(canvas, g, 0.50, paint, reveal);
        _drawLineFromCenter(
          canvas,
          g,
          0.66,
          _stroke(secondary, _softAlpha * 0.55 * reveal, width: 0.55),
          reveal,
        );
      case EventVisualHost.quran:
        _drawLineProgress(
          canvas,
          g.p(0.08, 0.18),
          g.p(0.92, 0.18),
          paint,
          reveal,
        );
        _drawRegistrationMark(
            canvas, g.p(0.08, 0.18), g.unit * 0.045, paint, reveal);
        _drawRegistrationMark(
            canvas, g.p(0.92, 0.18), g.unit * 0.045, paint, reveal);
      case EventVisualHost.dialog:
        final rect = Rect.fromCenter(
          center: g.p(0.5, 0.5),
          width: g.unit * 0.92,
          height: g.unit * 0.92,
        );
        canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * reveal, false, paint);
    }
  }

  void _drawRamadanCrescentDates(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawFilledCrescent(
      canvas,
      g.m(0.28, 0.43),
      g.unit * 0.19,
      _phase(value, 0.02, 0.70),
      color: secondary,
    );
    _drawDateBowl(
      canvas,
      g.m(0.66, 0.57),
      g.unit * 0.48,
      _phase(value, 0.18, 0.94),
    );
  }

  void _drawLastTenPrayerMatTenNights(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawPrayerMat(
      canvas,
      g.m(0.23, 0.55),
      g.unit * 0.38,
      g.unit * 0.53,
      _phase(value, 0.02, 0.68),
    );
    for (var i = 0; i < 10; i++) {
      final row = i ~/ 5;
      final column = i % 5;
      _drawStar(
        canvas,
        g.m(0.47 + column * 0.095, 0.34 + row * 0.28),
        g.unit * 0.035,
        _stagger(value, i, 10, begin: 0.18, end: 0.92),
        i.isEven ? accent : secondary,
      );
    }
  }

  void _drawEidFitrZakatGrain(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawFitrFoodGift(
      canvas,
      g.m(0.50, 0.53),
      g.unit * 0.86,
      _phase(value, 0.02, 0.96),
    );
  }

  void _drawEidAdhaRamOffering(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawRamProfile(
      canvas,
      g.m(0.50, 0.53),
      g.unit * 0.90,
      _phase(value, 0.02, 0.94),
    );
  }

  void _drawArafahMountainMarker(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawSun(
      canvas,
      g.m(0.73, 0.27),
      g.unit * 0.10,
      _phase(value, 0.02, 0.58),
    );
    final ridge = Path()
      ..moveToPoint(g.m(0.08, 0.78))
      ..quadraticBezierToPoint(g.m(0.24, 0.67), g.m(0.37, 0.55))
      ..quadraticBezierToPoint(g.m(0.46, 0.47), g.m(0.53, 0.29))
      ..quadraticBezierToPoint(g.m(0.63, 0.51), g.m(0.72, 0.59))
      ..quadraticBezierToPoint(g.m(0.84, 0.69), g.m(0.92, 0.78));
    _drawPathProgress(
      canvas,
      ridge,
      _stroke(accent, _strongAlpha, width: 1.45),
      _phase(value, 0.16, 0.78),
    );
    final foothill = Path()
      ..moveToPoint(g.m(0.16, 0.78))
      ..quadraticBezierToPoint(g.m(0.35, 0.69), g.m(0.47, 0.73))
      ..quadraticBezierToPoint(g.m(0.65, 0.80), g.m(0.84, 0.72));
    _drawPathProgress(
      canvas,
      foothill,
      _stroke(secondary, _softAlpha + 0.15, width: 0.85),
      _phase(value, 0.42, 1),
    );
    final waypointReveal = _phase(value, 0.54, 1);
    _drawWaypoint(
      canvas,
      g.m(0.27, 0.66),
      g.unit * 0.055,
      waypointReveal,
    );
    _drawWaypoint(
      canvas,
      g.m(0.64, 0.55),
      g.unit * 0.048,
      waypointReveal,
    );
  }

  void _drawDhulHijjahTenDayCalendar(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    final width = math.min(g.unit * 1.18, g.motifRect.width * 0.86);
    _drawTenDayCalendar(
      canvas,
      Rect.fromCenter(
        center: g.m(0.50, 0.53),
        width: width,
        height: g.unit * 0.67,
      ),
      value,
    );
  }

  void _drawAshuraPartedSeaTenthDay(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawPartedSea(
      canvas,
      g.m(0.50, 0.54),
      g.unit * 1.04,
      _phase(value, 0.02, 0.96),
    );
  }

  void _drawTashreeqThreeDayRemembrance(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    _drawServingBowlAndCup(
      canvas,
      g.m(0.50, 0.57),
      g.unit * 0.92,
      _phase(value, 0.02, 0.94),
    );
    for (var i = 0; i < 3; i++) {
      _drawSun(
        canvas,
        g.m(0.40 + i * 0.10, 0.20),
        g.unit * 0.035,
        _stagger(value, i, 3, begin: 0.38, end: 1),
        compactRays: true,
      );
    }
  }

  void _drawWhiteDaysThreeFullMoons(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    for (var i = 0; i < 3; i++) {
      final reveal = _stagger(value, i, 3, begin: 0.05, end: 0.72);
      final center = g.m(0.30 + i * 0.20, 0.52);
      _drawFullMoon(canvas, center, g.unit * 0.105, reveal, i == 1);
    }
  }

  void _drawMondayThursdayWeekCalendar(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    final width = math.min(g.unit * 1.28, g.motifRect.width * 0.88);
    _drawWeekCalendar(
      canvas,
      Rect.fromCenter(
        center: g.m(0.50, 0.54),
        width: width,
        height: g.unit * 0.62,
      ),
      _phase(value, 0.02, 0.96),
      const {0, 3},
    );
  }

  void _drawWhiteDaysWeeklyConfluence(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    for (var i = 0; i < 3; i++) {
      final reveal = _stagger(value, i, 3, begin: 0.02, end: 0.50);
      _drawFullMoon(
        canvas,
        g.m(0.40 + i * 0.10, 0.27),
        g.unit * 0.058,
        reveal,
        i == 1,
      );
    }
    final width = math.min(g.unit * 1.18, g.motifRect.width * 0.84);
    _drawWeekCalendar(
      canvas,
      Rect.fromCenter(
        center: g.m(0.50, 0.67),
        width: width,
        height: g.unit * 0.40,
      ),
      _phase(value, 0.28, 1),
      const {0, 3},
      compact: true,
    );
  }

  void _drawAuthoredCalendarCrescent(
    Canvas canvas,
    _MotifGeometry g,
    double value,
  ) {
    final width = math.min(g.unit * 0.96, g.motifRect.width * 0.72);
    _drawWeekCalendar(
      canvas,
      Rect.fromCenter(
        center: g.m(0.50, 0.54),
        width: width,
        height: g.unit * 0.66,
      ),
      _phase(value, 0.02, 0.88),
      const {},
      interior: (canvas, center, radius, reveal) => _drawFilledCrescent(
        canvas,
        center,
        radius,
        reveal,
        color: secondary,
      ),
    );
  }

  void _drawFilledCrescent(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal, {
    required Color color,
  }) {
    if (reveal <= 0) return;
    final crescent = _filledCrescentPath(center, radius);
    final fillReveal = _phase(reveal, 0.32, 1);
    canvas.drawPath(
      crescent,
      _fill(color, _strongAlpha * 0.72 * fillReveal),
    );
    _drawPathProgress(
      canvas,
      crescent,
      _stroke(color, _strongAlpha, width: 1.15),
      reveal,
    );
  }

  void _drawDateBowl(
    Canvas canvas,
    Offset center,
    double width,
    double reveal,
  ) {
    final height = width * 0.55;
    final left = center.dx - width * 0.50;
    final right = center.dx + width * 0.50;
    final rimY = center.dy - height * 0.02;
    final bottomY = center.dy + height * 0.42;
    final bowl = Path()
      ..moveTo(left, rimY)
      ..quadraticBezierTo(
        center.dx - width * 0.33,
        bottomY,
        center.dx,
        bottomY,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.33,
        bottomY,
        right,
        rimY,
      )
      ..close();
    final fillReveal = _phase(reveal, 0.34, 1);
    canvas.drawPath(
      bowl,
      _fill(accent, _softAlpha * 0.72 * fillReveal),
    );
    _drawPathProgress(
      canvas,
      bowl,
      _stroke(accent, _strongAlpha, width: 1.25),
      reveal,
    );
    _drawLineProgress(
      canvas,
      Offset(left, rimY),
      Offset(right, rimY),
      _stroke(secondary, _strongAlpha, width: 1.05),
      _phase(reveal, 0.18, 0.70),
    );

    final dateReveal = _phase(reveal, 0.38, 1);
    for (var i = 0; i < 3; i++) {
      final dateCenter = Offset(
        center.dx + (i - 1) * width * 0.20,
        rimY - height * (i == 1 ? 0.22 : 0.15),
      );
      final rect = Rect.fromCenter(
        center: dateCenter,
        width: width * 0.18 * dateReveal,
        height: height * 0.28 * dateReveal,
      );
      canvas.drawOval(
        rect,
        _fill(i == 1 ? secondary : accent, _strongAlpha * dateReveal),
      );
      _drawLineProgress(
        canvas,
        Offset(dateCenter.dx, rect.top + rect.height * 0.24),
        Offset(dateCenter.dx, rect.bottom - rect.height * 0.24),
        _stroke(
          i == 1 ? accent : secondary,
          _strongAlpha * dateReveal,
          width: 0.52,
        ),
        dateReveal,
      );
    }
  }

  void _drawPrayerMat(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double reveal,
  ) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(width * 0.055)),
      );
    canvas.drawPath(
      outline,
      _fill(accent, _softAlpha * 0.24 * _phase(reveal, 0.38, 1)),
    );
    _drawPathProgress(
      canvas,
      outline,
      _stroke(accent, _strongAlpha, width: 1.12),
      reveal,
    );

    final arch = Path()
      ..moveTo(rect.left + width * 0.20, rect.bottom - height * 0.16)
      ..lineTo(rect.left + width * 0.20, rect.top + height * 0.43)
      ..quadraticBezierTo(
        center.dx,
        rect.top + height * 0.09,
        rect.right - width * 0.20,
        rect.top + height * 0.43,
      )
      ..lineTo(rect.right - width * 0.20, rect.bottom - height * 0.16);
    _drawPathProgress(
      canvas,
      arch,
      _stroke(secondary, _strongAlpha, width: 0.90),
      _phase(reveal, 0.18, 0.88),
    );

    final fringeReveal = _phase(reveal, 0.52, 1);
    for (var i = 0; i < 4; i++) {
      final x = rect.left + width * (0.20 + i * 0.20);
      _drawLineProgress(
        canvas,
        Offset(x, rect.bottom),
        Offset(x, rect.bottom + height * 0.10),
        _stroke(accent, _strongAlpha, width: 0.60),
        fringeReveal,
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal,
    Color color,
  ) {
    if (reveal <= 0) return;
    final star = _starPath(center, radius);
    final fillReveal = _phase(reveal, 0.36, 1);
    canvas.drawPath(
      star,
      _fill(color, _strongAlpha * 0.74 * fillReveal),
    );
    _drawPathProgress(
      canvas,
      star,
      _stroke(color, _strongAlpha, width: 0.64),
      reveal,
    );
  }

  void _drawFitrFoodGift(
    Canvas canvas,
    Offset center,
    double size,
    double reveal,
  ) {
    final left = center.dx - size * 0.36;
    final right = center.dx + size * 0.15;
    final top = center.dy - size * 0.03;
    final bottom = center.dy + size * 0.28;
    final parcel = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right - size * 0.055, bottom)
      ..lineTo(left + size * 0.055, bottom)
      ..close();
    canvas.drawPath(
      parcel,
      _fill(accent, _softAlpha * 0.62 * _phase(reveal, 0.30, 1)),
    );
    _drawPathProgress(
      canvas,
      parcel,
      _stroke(accent, _strongAlpha, width: 1.20),
      reveal,
    );
    final leftFlap = Path()
      ..moveTo(left, top)
      ..lineTo(left + size * 0.10, top - size * 0.13)
      ..lineTo(center.dx - size * 0.09, top)
      ..close();
    final rightFlap = Path()
      ..moveTo(center.dx - size * 0.09, top)
      ..lineTo(center.dx + size * 0.03, top - size * 0.13)
      ..lineTo(right, top)
      ..close();
    _drawPathProgress(
      canvas,
      leftFlap,
      _stroke(secondary, _strongAlpha, width: 0.92),
      _phase(reveal, 0.10, 0.74),
    );
    _drawPathProgress(
      canvas,
      rightFlap,
      _stroke(secondary, _strongAlpha, width: 0.92),
      _phase(reveal, 0.18, 0.80),
    );

    final stalkReveal = _phase(reveal, 0.28, 0.92);
    final stalkBase = Offset(center.dx + size * 0.20, bottom);
    final stalkTop = Offset(center.dx + size * 0.29, center.dy - size * 0.32);
    _drawLineProgress(
      canvas,
      stalkBase,
      stalkTop,
      _stroke(secondary, _strongAlpha, width: 1.02),
      stalkReveal,
    );
    for (var i = 0; i < 4; i++) {
      final t = 0.22 + i * 0.18;
      final node = Offset.lerp(stalkBase, stalkTop, t)!;
      final direction = i.isEven ? -1.0 : 1.0;
      final grain = Path()
        ..moveToPoint(node)
        ..quadraticBezierToPoint(
          node + Offset(direction * size * 0.09, -size * 0.025),
          node + Offset(direction * size * 0.11, -size * 0.095),
        )
        ..quadraticBezierToPoint(
          node + Offset(direction * size * 0.025, -size * 0.075),
          node,
        );
      _drawPathProgress(
        canvas,
        grain,
        _stroke(accent, _strongAlpha, width: 0.72),
        _phase(stalkReveal, i * 0.08, 0.72 + i * 0.06),
      );
    }
    _drawStar(
      canvas,
      Offset(center.dx - size * 0.28, center.dy - size * 0.27),
      size * 0.055,
      _phase(reveal, 0.64, 1),
      secondary,
    );
  }

  void _drawRamProfile(
    Canvas canvas,
    Offset center,
    double size,
    double reveal,
  ) {
    final hornCenter = center + Offset(-size * 0.18, -size * 0.08);
    _drawPathProgress(
      canvas,
      _spiralPath(hornCenter, size * 0.29),
      _stroke(secondary, _strongAlpha, width: 1.90),
      _phase(reveal, 0.02, 0.74),
    );

    final head = Path()
      ..moveToPoint(center + Offset(-size * 0.10, -size * 0.24))
      ..quadraticBezierToPoint(
        center + Offset(size * 0.15, -size * 0.22),
        center + Offset(size * 0.30, -size * 0.07),
      )
      ..quadraticBezierToPoint(
        center + Offset(size * 0.46, size * 0.02),
        center + Offset(size * 0.29, size * 0.16),
      )
      ..quadraticBezierToPoint(
        center + Offset(size * 0.07, size * 0.25),
        center + Offset(-size * 0.09, size * 0.12),
      )
      ..quadraticBezierToPoint(
        center + Offset(-size * 0.19, -size * 0.03),
        center + Offset(-size * 0.10, -size * 0.24),
      )
      ..close();
    canvas.drawPath(
      head,
      _fill(accent, _strongAlpha * 0.82 * _phase(reveal, 0.26, 1)),
    );
    _drawPathProgress(
      canvas,
      head,
      _stroke(accent, _strongAlpha, width: 1.55),
      _phase(reveal, 0.12, 0.88),
    );

    final ear = Path()
      ..moveToPoint(center + Offset(size * 0.02, -size * 0.19))
      ..quadraticBezierToPoint(
        center + Offset(size * 0.19, -size * 0.35),
        center + Offset(size * 0.25, -size * 0.20),
      )
      ..quadraticBezierToPoint(
        center + Offset(size * 0.13, -size * 0.14),
        center + Offset(size * 0.02, -size * 0.19),
      );
    _drawPathProgress(
      canvas,
      ear,
      _stroke(secondary, _strongAlpha, width: 1.00),
      _phase(reveal, 0.34, 0.88),
    );
    final detailReveal = _phase(reveal, 0.60, 1);
    canvas.drawCircle(
      center + Offset(size * 0.12, -size * 0.06),
      size * 0.028 * detailReveal,
      _fill(secondary, _strongAlpha * detailReveal),
    );
    canvas.drawCircle(
      center + Offset(size * 0.37, size * 0.035),
      size * 0.022 * detailReveal,
      _fill(secondary, _strongAlpha * detailReveal),
    );
    _drawLineProgress(
      canvas,
      center + Offset(size * 0.29, size * 0.10),
      center + Offset(size * 0.41, size * 0.075),
      _stroke(secondary, _strongAlpha, width: 0.72),
      detailReveal,
    );
    _drawLineProgress(
      canvas,
      center + Offset(-size * 0.05, size * 0.16),
      center + Offset(-size * 0.10, size * 0.33),
      _stroke(accent, _strongAlpha, width: 1.05),
      detailReveal,
    );
  }

  void _drawSun(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal, {
    bool compactRays = false,
  }) {
    if (reveal <= 0) return;
    final fillReveal = _phase(reveal, 0.24, 1);
    canvas.drawCircle(
      center,
      radius * 0.72,
      _fill(secondary, _strongAlpha * 0.72 * fillReveal),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * reveal,
      false,
      _stroke(accent, _strongAlpha, width: 1.02),
    );
    final count = compactRays ? 4 : 8;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / count;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final rayReveal = _stagger(reveal, i, count, begin: 0.26, end: 1);
      _drawLineProgress(
        canvas,
        center + direction * radius * 1.32,
        center + direction * radius * (compactRays ? 1.66 : 1.82),
        _stroke(accent, _strongAlpha, width: 0.66),
        rayReveal,
      );
    }
  }

  void _drawWaypoint(
    Canvas canvas,
    Offset feet,
    double size,
    double reveal,
  ) {
    if (reveal <= 0) return;
    final head = feet - Offset(0, size * 2.45);
    canvas.drawCircle(
      head,
      size * 0.42 * reveal,
      _fill(secondary, _strongAlpha * reveal),
    );
    _drawLineProgress(
      canvas,
      head + Offset(0, size * 0.55),
      feet - Offset(0, size * 0.55),
      _stroke(accent, _strongAlpha, width: 0.72),
      reveal,
    );
    _drawLineProgress(
      canvas,
      feet - Offset(0, size * 0.55),
      feet + Offset(-size * 0.55, 0),
      _stroke(accent, _strongAlpha, width: 0.64),
      reveal,
    );
    _drawLineProgress(
      canvas,
      feet - Offset(0, size * 0.55),
      feet + Offset(size * 0.55, 0),
      _stroke(accent, _strongAlpha, width: 0.64),
      reveal,
    );
  }

  void _drawTenDayCalendar(
    Canvas canvas,
    Rect rect,
    double value,
  ) {
    final frameReveal = _phase(value, 0.02, 0.60);
    final frame = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.07)),
      );
    canvas.drawPath(
      frame,
      _fill(accent, _softAlpha * 0.18 * _phase(value, 0.28, 1)),
    );
    _drawPathProgress(
      canvas,
      frame,
      _stroke(accent, _strongAlpha, width: 1.12),
      frameReveal,
    );
    final headerY = rect.top + rect.height * 0.27;
    _drawLineProgress(
      canvas,
      Offset(rect.left, headerY),
      Offset(rect.right, headerY),
      _stroke(secondary, _strongAlpha, width: 0.86),
      _phase(value, 0.12, 0.58),
    );
    _drawCalendarBindings(canvas, rect, value);

    final gridLeft = rect.left + rect.width * 0.10;
    final gridTop = headerY + rect.height * 0.14;
    final columnGap = rect.width * 0.18;
    final rowGap = rect.height * 0.26;
    final markerRadius = math.min(rect.width * 0.047, rect.height * 0.075);
    for (var i = 0; i < 10; i++) {
      final row = i ~/ 5;
      final column = i % 5;
      final reveal = _stagger(value, i, 10, begin: 0.22, end: 0.96);
      final center = Offset(
        gridLeft + column * columnGap + columnGap * 0.28,
        gridTop + row * rowGap,
      );
      final color = i == 9 ? secondary : accent;
      canvas.drawCircle(
        center,
        markerRadius * reveal,
        _fill(color, (i == 9 ? _strongAlpha : _softAlpha + 0.12) * reveal),
      );
      canvas.drawCircle(
        center,
        markerRadius * 1.30 * reveal,
        _stroke(color, _strongAlpha * reveal, width: 0.52),
      );
    }
  }

  void _drawPartedSea(
    Canvas canvas,
    Offset center,
    double size,
    double reveal,
  ) {
    final pathTop = center.dy - size * 0.18;
    final pathBottom = center.dy + size * 0.27;
    final dryPath = Path()
      ..moveTo(center.dx - size * 0.055, pathTop)
      ..lineTo(center.dx - size * 0.18, pathBottom)
      ..lineTo(center.dx + size * 0.18, pathBottom)
      ..lineTo(center.dx + size * 0.055, pathTop)
      ..close();
    final pathReveal = _phase(reveal, 0.24, 1);
    canvas.drawPath(
      dryPath,
      _fill(secondary, _softAlpha * 0.78 * pathReveal),
    );
    _drawPathProgress(
      canvas,
      dryPath,
      _stroke(secondary, _strongAlpha, width: 0.72),
      pathReveal,
    );

    final leftWave = Path()
      ..moveTo(center.dx - size * 0.08, pathTop)
      ..cubicTo(
        center.dx - size * 0.17,
        center.dy - size * 0.31,
        center.dx - size * 0.28,
        center.dy - size * 0.13,
        center.dx - size * 0.42,
        center.dy - size * 0.22,
      )
      ..cubicTo(
        center.dx - size * 0.34,
        center.dy - size * 0.04,
        center.dx - size * 0.42,
        center.dy + size * 0.13,
        center.dx - size * 0.20,
        pathBottom,
      );
    final rightWave = Path()
      ..moveTo(center.dx + size * 0.08, pathTop)
      ..cubicTo(
        center.dx + size * 0.17,
        center.dy - size * 0.31,
        center.dx + size * 0.28,
        center.dy - size * 0.13,
        center.dx + size * 0.42,
        center.dy - size * 0.22,
      )
      ..cubicTo(
        center.dx + size * 0.34,
        center.dy - size * 0.04,
        center.dx + size * 0.42,
        center.dy + size * 0.13,
        center.dx + size * 0.20,
        pathBottom,
      );
    _drawPathProgress(
      canvas,
      leftWave,
      _stroke(accent, _strongAlpha, width: 1.70),
      reveal,
    );
    _drawPathProgress(
      canvas,
      rightWave,
      _stroke(accent, _strongAlpha, width: 1.70),
      reveal,
    );

    for (var i = 0; i < 2; i++) {
      final y = center.dy + size * (0.02 + i * 0.12);
      final detailReveal = _phase(reveal, 0.38 + i * 0.08, 1);
      _drawWaveStroke(
        canvas,
        Offset(center.dx - size * 0.43, y),
        size * 0.20,
        detailReveal,
        false,
      );
      _drawWaveStroke(
        canvas,
        Offset(center.dx + size * 0.23, y),
        size * 0.20,
        detailReveal,
        true,
      );
    }
    _drawTenGlyph(
      canvas,
      Offset(center.dx, center.dy - size * 0.28),
      size * 0.22,
      size * 0.16,
      _phase(reveal, 0.56, 1),
    );
  }

  void _drawWaveStroke(
    Canvas canvas,
    Offset start,
    double width,
    double reveal,
    bool reverse,
  ) {
    final sign = reverse ? -1.0 : 1.0;
    final wave = Path()
      ..moveToPoint(start)
      ..cubicTo(
        start.dx + width * 0.25,
        start.dy - width * 0.10 * sign,
        start.dx + width * 0.50,
        start.dy + width * 0.10 * sign,
        start.dx + width * 0.75,
        start.dy,
      )
      ..quadraticBezierTo(
        start.dx + width * 0.90,
        start.dy - width * 0.08 * sign,
        start.dx + width,
        start.dy,
      );
    _drawPathProgress(
      canvas,
      wave,
      _stroke(secondary, _softAlpha + 0.18, width: 0.72),
      reveal,
    );
  }

  void _drawTenGlyph(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double reveal,
  ) {
    final left = center.dx - width * 0.50;
    final top = center.dy - height * 0.50;
    final one = Path()
      ..moveTo(left, top + height * 0.22)
      ..lineTo(left + width * 0.17, top)
      ..lineTo(left + width * 0.17, top + height)
      ..moveTo(left + width * 0.04, top + height)
      ..lineTo(left + width * 0.32, top + height);
    _drawPathProgress(
      canvas,
      one,
      _stroke(secondary, _strongAlpha, width: 1.28),
      reveal,
    );
    final zero = Path()
      ..addOval(
        Rect.fromLTWH(
          left + width * 0.44,
          top,
          width * 0.46,
          height,
        ),
      );
    _drawPathProgress(
      canvas,
      zero,
      _stroke(secondary, _strongAlpha, width: 1.28),
      _phase(reveal, 0.14, 1),
    );
  }

  void _drawServingBowlAndCup(
    Canvas canvas,
    Offset center,
    double size,
    double reveal,
  ) {
    final bowlLeft = center.dx - size * 0.43;
    final bowlRight = center.dx + size * 0.08;
    final rimY = center.dy - size * 0.03;
    final bowlBottom = center.dy + size * 0.22;
    final bowl = Path()
      ..moveTo(bowlLeft, rimY)
      ..quadraticBezierTo(
        center.dx - size * 0.31,
        bowlBottom,
        center.dx - size * 0.17,
        bowlBottom,
      )
      ..quadraticBezierTo(
        center.dx - size * 0.03,
        bowlBottom,
        bowlRight,
        rimY,
      )
      ..close();
    canvas.drawPath(
      bowl,
      _fill(accent, _softAlpha * 0.64 * _phase(reveal, 0.28, 1)),
    );
    _drawPathProgress(
      canvas,
      bowl,
      _stroke(accent, _strongAlpha, width: 1.20),
      reveal,
    );
    _drawLineProgress(
      canvas,
      Offset(bowlLeft, rimY),
      Offset(bowlRight, rimY),
      _stroke(secondary, _strongAlpha, width: 0.90),
      _phase(reveal, 0.12, 0.72),
    );

    final cupRect = Rect.fromLTWH(
      center.dx + size * 0.16,
      center.dy - size * 0.08,
      size * 0.21,
      size * 0.29,
    );
    final cup = Path()
      ..moveTo(cupRect.left, cupRect.top)
      ..lineTo(cupRect.right, cupRect.top)
      ..lineTo(cupRect.right - size * 0.03, cupRect.bottom)
      ..lineTo(cupRect.left + size * 0.03, cupRect.bottom)
      ..close();
    _drawPathProgress(
      canvas,
      cup,
      _stroke(secondary, _strongAlpha, width: 1.05),
      _phase(reveal, 0.18, 0.90),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cupRect.right + size * 0.045, cupRect.center.dy),
        width: size * 0.13,
        height: size * 0.16,
      ),
      -math.pi / 2,
      math.pi * 1.45 * _phase(reveal, 0.42, 1),
      false,
      _stroke(secondary, _strongAlpha, width: 0.86),
    );
  }

  void _drawFullMoon(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal,
    bool emphasized,
  ) {
    if (reveal <= 0) return;
    final color = emphasized ? secondary : accent;
    final fillReveal = _phase(reveal, 0.24, 1);
    canvas.drawCircle(
      center,
      radius * fillReveal,
      _fill(color, (_softAlpha + 0.18) * fillReveal),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * reveal,
      false,
      _stroke(color, _strongAlpha, width: emphasized ? 1.18 : 0.92),
    );
    final craterReveal = _phase(reveal, 0.48, 1);
    final craterPaint = _fill(
      emphasized ? accent : secondary,
      _softAlpha * 0.76 * craterReveal,
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.30, -radius * 0.18),
      radius * 0.17 * craterReveal,
      craterPaint,
    );
    canvas.drawCircle(
      center + Offset(radius * 0.24, radius * 0.24),
      radius * 0.13 * craterReveal,
      craterPaint,
    );
  }

  void _drawWeekCalendar(
    Canvas canvas,
    Rect rect,
    double reveal,
    Set<int> selected, {
    bool compact = false,
    void Function(Canvas, Offset, double, double)? interior,
  }) {
    if (reveal <= 0) return;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.08)),
      );
    canvas.drawPath(
      outline,
      _fill(accent, _softAlpha * 0.16 * _phase(reveal, 0.30, 1)),
    );
    _drawPathProgress(
      canvas,
      outline,
      _stroke(accent, _strongAlpha, width: 1.12),
      reveal,
    );
    final headerY = rect.top + rect.height * (compact ? 0.29 : 0.31);
    _drawLineProgress(
      canvas,
      Offset(rect.left, headerY),
      Offset(rect.right, headerY),
      _stroke(secondary, _strongAlpha, width: 0.82),
      _phase(reveal, 0.10, 0.60),
    );
    _drawCalendarBindings(canvas, rect, reveal);

    if (interior != null) {
      interior(
        canvas,
        Offset(rect.center.dx, headerY + (rect.bottom - headerY) * 0.53),
        math.min(rect.width, rect.height) * 0.16,
        _phase(reveal, 0.34, 1),
      );
      return;
    }

    final usableWidth = rect.width * 0.82;
    final firstX = rect.left + rect.width * 0.09;
    final cellWidth = usableWidth / 7;
    final y = headerY + (rect.bottom - headerY) * 0.53;
    final radius = math.min(cellWidth * 0.28, rect.height * 0.075);
    for (var i = 0; i < 7; i++) {
      final cellReveal = _stagger(reveal, i, 7, begin: 0.20, end: 0.94);
      final center = Offset(firstX + cellWidth * (i + 0.5), y);
      if (selected.contains(i)) {
        canvas.drawCircle(
          center,
          radius * 1.28 * cellReveal,
          _fill(accent, _softAlpha * 0.74 * cellReveal),
        );
        final check = Path()
          ..moveTo(
            center.dx - radius * 0.70,
            center.dy,
          )
          ..lineTo(
            center.dx - radius * 0.12,
            center.dy + radius * 0.52,
          )
          ..lineTo(
            center.dx + radius * 0.82,
            center.dy - radius * 0.62,
          );
        _drawPathProgress(
          canvas,
          check,
          _stroke(secondary, _strongAlpha, width: 0.92),
          _phase(cellReveal, 0.26, 1),
        );
      } else {
        canvas.drawCircle(
          center,
          radius * cellReveal,
          _stroke(secondary, _softAlpha * cellReveal, width: 0.58),
        );
      }
    }
  }

  void _drawCalendarBindings(Canvas canvas, Rect rect, double reveal) {
    for (final x in [
      rect.left + rect.width * 0.28,
      rect.right - rect.width * 0.28
    ]) {
      _drawLineProgress(
        canvas,
        Offset(x, rect.top - rect.height * 0.09),
        Offset(x, rect.top + rect.height * 0.12),
        _stroke(secondary, _strongAlpha, width: 1.06),
        _phase(reveal, 0.06, 0.56),
      );
    }
  }

  void _drawLineFromCenter(
    Canvas canvas,
    _MotifGeometry g,
    double y,
    Paint paint,
    double reveal,
  ) {
    _drawLineProgress(canvas, g.p(0.5, y), g.p(0.08, y), paint, reveal);
    _drawLineProgress(canvas, g.p(0.5, y), g.p(0.92, y), paint, reveal);
  }

  void _drawCorner(
    Canvas canvas,
    _MotifGeometry g,
    double x,
    double y,
    double reveal,
    Paint paint,
  ) {
    final signX = x < 0.5 ? 1.0 : -1.0;
    final signY = y < 0.5 ? 1.0 : -1.0;
    final origin = g.p(x, y);
    _drawLineProgress(
      canvas,
      origin,
      origin + Offset(g.unit * 0.09 * signX, 0),
      paint,
      reveal,
    );
    _drawLineProgress(
      canvas,
      origin,
      origin + Offset(0, g.unit * 0.09 * signY),
      paint,
      reveal,
    );
  }

  void _drawRegistrationMark(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    double reveal,
  ) {
    _drawLineProgress(canvas, center - Offset(radius, 0),
        center + Offset(radius, 0), paint, reveal);
    _drawLineProgress(canvas, center - Offset(0, radius),
        center + Offset(0, radius), paint, reveal);
  }

  void _drawLineProgress(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
    double reveal,
  ) {
    if (reveal <= 0) return;
    canvas.drawLine(from, Offset.lerp(from, to, reveal)!, paint);
  }

  void _drawPathProgress(
    Canvas canvas,
    Path path,
    Paint paint,
    double reveal,
  ) {
    if (reveal <= 0) return;
    if (reveal >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics().toList(growable: false);
    final total = metrics.fold<double>(0, (sum, metric) => sum + metric.length);
    var remaining = total * reveal;
    final partial = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(metric.length, remaining);
      partial.addPath(metric.extractPath(0, length), Offset.zero);
      remaining -= length;
    }
    canvas.drawPath(partial, paint);
  }

  Path _filledCrescentPath(Offset center, double radius) {
    final innerCenter = center + Offset(radius * 0.43, -radius * 0.07);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(
        Rect.fromCircle(center: innerCenter, radius: radius * 0.82),
      );
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i <= 10; i++) {
      final pointRadius = i.isEven ? radius : radius * 0.43;
      final angle = -math.pi / 2 + math.pi * i / 5;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * pointRadius;
      if (i == 0) {
        path.moveToPoint(point);
      } else {
        path.lineToPoint(point);
      }
    }
    path.close();
    return path;
  }

  Path _spiralPath(Offset center, double outerRadius) {
    const segments = 44;
    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = -math.pi * 0.18 + t * math.pi * 3.55;
      final radius = outerRadius * (1 - t * 0.82);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveToPoint(point);
      } else {
        path.lineToPoint(point);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CanonicalEventMotifPainter oldDelegate) =>
      oldDelegate.eventKey != eventKey ||
      oldDelegate.host != host ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.progress != progress ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.highContrast != highContrast;
}

class _MotifGeometry {
  const _MotifGeometry({
    required this.rect,
    required this.textDirection,
  });

  final Rect rect;
  final TextDirection textDirection;

  double get unit => math.min(rect.width, rect.height);

  Rect get motifRect => Rect.fromCenter(
        center: rect.center,
        width: math.min(rect.width, unit * 1.72),
        height: unit,
      );

  Offset p(double x, double y) {
    final directionalX = textDirection == TextDirection.rtl ? 1 - x : x;
    return Offset(
      rect.left + rect.width * directionalX,
      rect.top + rect.height * y,
    );
  }

  Offset m(double x, double y) {
    final stage = motifRect;
    final directionalX = textDirection == TextDirection.rtl ? 1 - x : x;
    return Offset(
      stage.left + stage.width * directionalX,
      stage.top + stage.height * y,
    );
  }
}

extension on Path {
  void moveToPoint(Offset point) => moveTo(point.dx, point.dy);

  void lineToPoint(Offset point) => lineTo(point.dx, point.dy);

  void quadraticBezierToPoint(Offset control, Offset end) =>
      quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
}
