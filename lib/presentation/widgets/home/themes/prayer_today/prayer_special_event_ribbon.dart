import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/special_event/canonical_event_motif.dart';
import 'package:huda/presentation/widgets/home/special_event/ceremonial_event_reveal.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';

class PrayerSpecialEventRibbon extends StatefulWidget {
  const PrayerSpecialEventRibbon({
    super.key,
    required this.presentation,
    required this.onActivate,
  });

  final IslamicEventPresentation presentation;
  final VoidCallback onActivate;

  @override
  State<PrayerSpecialEventRibbon> createState() =>
      _PrayerSpecialEventRibbonState();
}

class _PrayerSpecialEventRibbonState extends State<PrayerSpecialEventRibbon> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _active => _hovered || _focused || _pressed;

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused != value) setState(() => _focused = value);
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final highContrast = media.highContrast;
    final textScale = media.textScaler.scale(1);
    final textDirection = Directionality.of(context);
    final palette = widget.presentation.palette;
    final accent = Color.lerp(
      const Color(0xFFFFDEA0),
      palette.accent,
      0.48,
    )!;
    final secondary = Color.lerp(
      Colors.white,
      palette.glow,
      0.42,
    )!;
    final interactionDuration =
        reduceMotion ? Duration.zero : PrayerTodayMotion.interaction;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 3, 20, 7),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: CeremonialEventReveal(
            eventKey: widget.presentation.event.eventKey,
            duration: const Duration(milliseconds: 1040),
            curve: Curves.easeOutCubic,
            builder: (context, reveal) => Semantics(
              key: const ValueKey('prayer-special-event'),
              button: true,
              focusable: true,
              focused: _focused,
              label: widget.presentation.semanticLabel,
              onTap: widget.onActivate,
              child: ExcludeSemantics(
                child: AnimatedScale(
                  scale: _pressed ? 0.994 : 1,
                  duration: interactionDuration,
                  curve: Curves.easeOutCubic,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('prayer-special-event-action'),
                      onTap: widget.onActivate,
                      onHover: _setHovered,
                      onFocusChange: _setFocused,
                      onHighlightChanged: _setPressed,
                      mouseCursor: SystemMouseCursors.click,
                      customBorder: const _PrayerEventHitShape(),
                      focusColor: accent.withValues(
                        alpha: highContrast ? 0.19 : 0.12,
                      ),
                      hoverColor: accent.withValues(
                        alpha: highContrast ? 0.14 : 0.075,
                      ),
                      splashColor: accent.withValues(alpha: 0.13),
                      highlightColor: accent.withValues(alpha: 0.08),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              accent.withValues(
                                alpha: _active
                                    ? (highContrast ? 0.12 : 0.075)
                                    : (highContrast ? 0.075 : 0.038),
                              ),
                              Colors.white.withValues(
                                alpha: _active ? 0.055 : 0.025,
                              ),
                              accent.withValues(
                                alpha: _active
                                    ? (highContrast ? 0.085 : 0.045)
                                    : 0.018,
                              ),
                            ],
                            stops: const [0, 0.54, 1],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _PrayerCelestialThresholdPainter(
                                      progress: reveal,
                                      accent: accent,
                                      secondary: secondary,
                                      active: _active,
                                      focused: _focused,
                                      highContrast: highContrast,
                                      textDirection: textDirection,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: textScale >= 1.6 ? 112 : 78,
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  textScale >= 1.6 ? 9 : 11,
                                  textScale >= 1.6 ? 11 : 9,
                                  textScale >= 1.6 ? 8 : 10,
                                  textScale >= 1.6 ? 11 : 9,
                                ),
                                child: _PrayerEventInstrumentContent(
                                  presentation: widget.presentation,
                                  reveal: reveal,
                                  accent: accent,
                                  secondary: secondary,
                                  active: _active,
                                  highContrast: highContrast,
                                  textScale: textScale,
                                  textDirection: textDirection,
                                ),
                              ),
                            ),
                          ],
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

class _PrayerEventInstrumentContent extends StatelessWidget {
  const _PrayerEventInstrumentContent({
    required this.presentation,
    required this.reveal,
    required this.accent,
    required this.secondary,
    required this.active,
    required this.highContrast,
    required this.textScale,
    required this.textDirection,
  });

  final IslamicEventPresentation presentation;
  final Animation<double> reveal;
  final Color accent;
  final Color secondary;
  final bool active;
  final bool highContrast;
  final double textScale;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final foreground = Colors.white.withValues(alpha: 0.98);
    final supporting = Colors.white.withValues(
      alpha: highContrast ? 0.92 : 0.76,
    );
    final contentOpacity = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: contentOpacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350 || textScale >= 1.45;
          final motifExtent = compact ? 56.0 : 68.0;
          final titleLines = textScale >= 1.6 ? null : 2;
          final subtitleLines = textScale >= 1.6 ? null : 2;

          return Row(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: motifExtent,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _PrayerMotifOrbitPainter(
                      progress: reveal,
                      accent: accent,
                      secondary: secondary,
                      active: active,
                      highContrast: highContrast,
                      textDirection: textDirection,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 8 : 9),
                      child: CanonicalEventMotif(
                        eventKey: presentation.event.eventKey,
                        host: EventVisualHost.prayer,
                        accent: accent,
                        secondary: secondary,
                        progress: reveal,
                        textDirection: textDirection,
                        strokeWidth: highContrast ? 2 : 1.45,
                        highContrast: highContrast,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      maxLines: titleLines,
                      overflow: textScale >= 1.6
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            height: 1.17,
                            letterSpacing: 0.08,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presentation.subtitle,
                      maxLines: subtitleLines,
                      overflow: textScale >= 1.6
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: supporting,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 5 : 9),
              _PrayerEventGateAffordance(
                active: active,
                accent: accent,
                highContrast: highContrast,
                textDirection: textDirection,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrayerEventGateAffordance extends StatelessWidget {
  const _PrayerEventGateAffordance({
    required this.active,
    required this.accent,
    required this.highContrast,
    required this.textDirection,
  });

  final bool active;
  final Color accent;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    return AnimatedSlide(
      offset: active ? Offset(0.055 * direction, 0) : Offset.zero,
      duration: reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
        width: 25,
        height: 42,
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: accent.withValues(
                alpha: highContrast ? 0.95 : (active ? 0.68 : 0.38),
              ),
              width: highContrast ? 1.5 : 0.8,
            ),
          ),
        ),
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: 17,
          height: 22,
          child: CustomPaint(
            painter: _PrayerGateGlyphPainter(
              accent: accent,
              active: active,
              highContrast: highContrast,
              textDirection: textDirection,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerGateGlyphPainter extends CustomPainter {
  const _PrayerGateGlyphPainter({
    required this.accent,
    required this.active,
    required this.highContrast,
    required this.textDirection,
  });

  final Color accent;
  final bool active;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final forward = textDirection == TextDirection.ltr ? 1.0 : -1.0;
    final center = size.center(Offset.zero);
    final tipX = center.dx + 5.5 * forward;
    final stemX = center.dx - 5 * forward;
    final shoulderX = center.dx + 0.5 * forward;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = highContrast ? 2 : 1.25
      ..color = accent.withValues(
        alpha: highContrast ? 1 : (active ? 0.96 : 0.74),
      );

    canvas
      ..drawLine(Offset(stemX, center.dy), Offset(tipX, center.dy), paint)
      ..drawLine(
        Offset(shoulderX, center.dy - 5),
        Offset(tipX, center.dy),
        paint,
      )
      ..drawLine(
        Offset(tipX, center.dy),
        Offset(shoulderX, center.dy + 5),
        paint,
      );

    final register = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(
        alpha: highContrast ? 0.94 : (active ? 0.68 : 0.42),
      );
    canvas.drawCircle(
        Offset(stemX, center.dy), highContrast ? 1.8 : 1.25, register);
  }

  @override
  bool shouldRepaint(covariant _PrayerGateGlyphPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}

class _PrayerCelestialThresholdPainter extends CustomPainter {
  _PrayerCelestialThresholdPainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.active,
    required this.focused,
    required this.highContrast,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color secondary;
  final bool active;
  final bool focused;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final value = progress.value.clamp(0.0, 1.0).toDouble();
    final lineProgress = _phase(value, 0, 0.58);
    final detailProgress = _phase(value, 0.28, 0.82);
    final settleProgress = _phase(value, 0.58, 1);
    final leadingOnLeft = textDirection == TextDirection.ltr;
    final anchorX = leadingOnLeft
        ? math.min(45.0, size.width * 0.18)
        : size.width - math.min(45.0, size.width * 0.18);

    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    final glowCenter = Offset(anchorX, size.height * 0.5);
    final glowRadius = math.min(150.0, size.width * 0.34);
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: active ? 0.105 : 0.06),
            secondary.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: glowRadius),
        ),
    );

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.55 : 0.85
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(
        alpha: highContrast ? 0.94 : (active ? 0.64 : 0.42),
      );
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.05 : 0.55
      ..strokeCap = StrokeCap.round
      ..color = secondary.withValues(
        alpha: highContrast ? 0.75 : (active ? 0.31 : 0.19),
      );

    final left = anchorX + (0 - anchorX) * lineProgress;
    final right = anchorX + (size.width - anchorX) * lineProgress;
    canvas
      ..drawLine(Offset(left, 0.75), Offset(right, 0.75), outer)
      ..drawLine(
        Offset(left + 8 * lineProgress, 4),
        Offset(right - 8 * lineProgress, 4),
        inner,
      )
      ..drawLine(
        Offset(left + 8 * lineProgress, size.height - 4),
        Offset(right - 8 * lineProgress, size.height - 4),
        inner,
      )
      ..drawLine(
        Offset(left, size.height - 0.75),
        Offset(right, size.height - 0.75),
        outer,
      );

    final axisHalf = (size.height * 0.5 - 8) * detailProgress;
    canvas.drawLine(
      Offset(anchorX, size.height * 0.5 - axisHalf),
      Offset(anchorX, size.height * 0.5 + axisHalf),
      inner,
    );

    for (var index = 0; index < 5; index++) {
      final local = _phase(detailProgress, index * 0.07, 0.46 + index * 0.07);
      if (local <= 0) continue;
      final x = size.width * (index + 1) / 6;
      final radius = (highContrast ? 1.8 : 1.25) * local;
      canvas
        ..drawCircle(Offset(x, 4), radius, outer)
        ..drawCircle(Offset(x, size.height - 4), radius, outer);
    }

    final registrationAlpha = settleProgress * (active ? 0.72 : 0.46);
    final registration = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.4 : 0.75
      ..color = accent.withValues(alpha: registrationAlpha);
    final diamond = Path()
      ..moveTo(anchorX, 0.5)
      ..lineTo(anchorX + 4, 4)
      ..lineTo(anchorX, 7.5)
      ..lineTo(anchorX - 4, 4)
      ..close();
    canvas
      ..drawPath(diamond, registration)
      ..save()
      ..translate(0, size.height)
      ..scale(1, -1)
      ..drawPath(diamond, registration)
      ..restore();

    if (focused) {
      _drawFocusBrackets(canvas, size, accent, highContrast);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrayerCelestialThresholdPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.active != active ||
      oldDelegate.focused != focused ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}

class _PrayerMotifOrbitPainter extends CustomPainter {
  _PrayerMotifOrbitPainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.active,
    required this.highContrast,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color secondary;
  final bool active;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final value = progress.value.clamp(0.0, 1.0).toDouble();
    final orbitProgress = _phase(value, 0.04, 0.68);
    final marksProgress = _phase(value, 0.30, 0.88);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width - 3,
      height: size.height - 3,
    );
    final direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.55 : 0.85
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(
        alpha: highContrast ? 0.92 : (active ? 0.66 : 0.46),
      );
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.05 : 0.55
      ..strokeCap = StrokeCap.round
      ..color = secondary.withValues(
        alpha: highContrast ? 0.72 : (active ? 0.35 : 0.22),
      );

    canvas
      ..drawArc(
        rect,
        -math.pi * 0.72 * direction,
        math.pi * 1.44 * orbitProgress * direction,
        false,
        orbit,
      )
      ..drawArc(
        rect.deflate(5),
        math.pi * 0.32 * direction,
        -math.pi * 1.18 * orbitProgress * direction,
        false,
        inner,
      );

    final center = size.center(Offset.zero);
    final markRadius = size.shortestSide * 0.48;
    for (var index = 0; index < 4; index++) {
      final local = _phase(marksProgress, index * 0.08, 0.48 + index * 0.08);
      if (local <= 0) continue;
      final angle = -math.pi / 2 + index * math.pi / 2;
      final point = Offset(
        center.dx + math.cos(angle) * markRadius,
        center.dy + math.sin(angle) * markRadius,
      );
      canvas.drawCircle(
        point,
        (highContrast ? 2 : 1.45) * local,
        orbit,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerMotifOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}

class _PrayerEventHitShape extends ShapeBorder {
  const _PrayerEventHitShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(1), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const cut = 8.0;
    return Path()
      ..moveTo(rect.left + cut, rect.top)
      ..lineTo(rect.right - cut, rect.top)
      ..lineTo(rect.right, rect.top + cut)
      ..lineTo(rect.right, rect.bottom - cut)
      ..lineTo(rect.right - cut, rect.bottom)
      ..lineTo(rect.left + cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cut)
      ..lineTo(rect.left, rect.top + cut)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

void _drawFocusBrackets(
  Canvas canvas,
  Size size,
  Color accent,
  bool highContrast,
) {
  const extent = 14.0;
  const inset = 1.5;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = highContrast ? 2.2 : 1.6
    ..strokeCap = StrokeCap.square
    ..color = accent.withValues(alpha: 1);

  final path = Path()
    ..moveTo(inset, extent)
    ..lineTo(inset, inset)
    ..lineTo(extent, inset)
    ..moveTo(size.width - extent, inset)
    ..lineTo(size.width - inset, inset)
    ..lineTo(size.width - inset, extent)
    ..moveTo(size.width - inset, size.height - extent)
    ..lineTo(size.width - inset, size.height - inset)
    ..lineTo(size.width - extent, size.height - inset)
    ..moveTo(extent, size.height - inset)
    ..lineTo(inset, size.height - inset)
    ..lineTo(inset, size.height - extent);
  canvas.drawPath(path, paint);
}

double _phase(double value, double begin, double end) {
  if (end <= begin) return value >= end ? 1 : 0;
  final normalized = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return Curves.easeOutCubic.transform(normalized);
}
