import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/special_event/canonical_event_motif.dart';
import 'package:huda/presentation/widgets/home/special_event/ceremonial_event_reveal.dart';
import 'package:huda/presentation/widgets/home/special_event/event_visual_identity.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';

class QuranSpecialEventFolio extends StatefulWidget {
  const QuranSpecialEventFolio({
    super.key,
    required this.presentation,
    required this.onActivate,
  });

  final IslamicEventPresentation presentation;
  final VoidCallback onActivate;

  @override
  State<QuranSpecialEventFolio> createState() => _QuranSpecialEventFolioState();
}

class _QuranSpecialEventFolioState extends State<QuranSpecialEventFolio> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _active => _hovered || _focused || _pressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highContrast = media.highContrast;
    final textScale = media.textScaler.scale(1);
    final direction = Directionality.of(context);
    final palette = widget.presentation.palette;
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final accent = Color.lerp(
      illumination,
      palette.accent,
      isDark ? 0.38 : 0.31,
    )!;
    final secondary = Color.lerp(
      illumination,
      palette.glow,
      isDark ? 0.44 : 0.36,
    )!;
    final ink = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final paperWash = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.105 : 0.048),
      surface,
    );
    final marginWash = Color.alphaBlend(
      secondary.withValues(alpha: isDark ? 0.075 : 0.032),
      surface,
    );
    final baseRule = QuranJourneyVisualStyle.rule(context, strong: true);
    final rule = highContrast ? Color.lerp(baseRule, ink, 0.62)! : baseRule;
    final identity = EventVisualIdentity.resolve(
      widget.presentation.event.eventKey,
    );
    const shape = _QuranIndexShape();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 2),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: CeremonialEventReveal(
            eventKey: widget.presentation.event.eventKey,
            duration: const Duration(milliseconds: 1160),
            curve: Curves.easeOutCubic,
            builder: (context, reveal) => Semantics(
              key: const ValueKey('quran-special-event'),
              button: true,
              focusable: true,
              focused: _focused,
              label: widget.presentation.semanticLabel,
              onTap: widget.onActivate,
              child: ExcludeSemantics(
                child: QuranJourneyPressTransform(
                  pressed: _pressed,
                  child: Material(
                    color: Colors.transparent,
                    shape: shape,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('quran-special-event-action'),
                      onTap: widget.onActivate,
                      onHover: (value) {
                        if (_hovered != value) {
                          setState(() => _hovered = value);
                        }
                      },
                      onFocusChange: (value) {
                        if (_focused != value) {
                          setState(() => _focused = value);
                        }
                      },
                      onHighlightChanged: (value) {
                        if (_pressed != value) {
                          setState(() => _pressed = value);
                        }
                      },
                      customBorder: shape,
                      focusColor: accent.withValues(
                        alpha: highContrast ? 0.20 : 0.12,
                      ),
                      hoverColor: accent.withValues(
                        alpha: highContrast ? 0.15 : 0.075,
                      ),
                      splashColor: accent.withValues(alpha: 0.13),
                      highlightColor: accent.withValues(alpha: 0.075),
                      child: Ink(
                        decoration: ShapeDecoration(
                          shape: shape,
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [marginWash, surface, paperWash],
                            stops: const [0, 0.47, 1],
                          ),
                        ),
                        child: CustomPaint(
                          painter: _QuranIlluminatedIndexPainter(
                            progress: reveal,
                            rule: rule,
                            accent: accent,
                            ink: ink,
                            active: _active,
                            highContrast: highContrast,
                            textDirection: direction,
                            structuralCount: identity.structuralCount,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 350 ||
                                  textScale > 1.35;
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: compact ? 126 : 104,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    14,
                                    12,
                                    12,
                                    12,
                                  ),
                                  child: compact
                                      ? _buildCompactEntry(
                                          context,
                                          reveal: reveal,
                                          accent: accent,
                                          secondary: secondary,
                                          ink: ink,
                                          highContrast: highContrast,
                                          direction: direction,
                                        )
                                      : _buildWideEntry(
                                          context,
                                          reveal: reveal,
                                          accent: accent,
                                          secondary: secondary,
                                          ink: ink,
                                          highContrast: highContrast,
                                          direction: direction,
                                        ),
                                ),
                              );
                            },
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
      ),
    );
  }

  Widget _buildWideEntry(
    BuildContext context, {
    required Animation<double> reveal,
    required Color accent,
    required Color secondary,
    required Color ink,
    required bool highContrast,
    required TextDirection direction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _QuranIlluminatedInitial(
          eventKey: widget.presentation.event.eventKey,
          reveal: reveal,
          accent: accent,
          secondary: secondary,
          active: _active,
          highContrast: highContrast,
          textDirection: direction,
          extent: 72,
        ),
        const SizedBox(width: 14),
        _QuranIndexSpine(
          reveal: reveal,
          accent: accent,
          highContrast: highContrast,
          height: 70,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuranEventCopy(
            presentation: widget.presentation,
            reveal: reveal,
            ink: ink,
            accent: accent,
            highContrast: highContrast,
            textDirection: direction,
          ),
        ),
        const SizedBox(width: 10),
        _QuranEntryActionMark(
          accent: accent,
          active: _active,
          highContrast: highContrast,
        ),
      ],
    );
  }

  Widget _buildCompactEntry(
    BuildContext context, {
    required Animation<double> reveal,
    required Color accent,
    required Color secondary,
    required Color ink,
    required bool highContrast,
    required TextDirection direction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _QuranIlluminatedInitial(
              eventKey: widget.presentation.event.eventKey,
              reveal: reveal,
              accent: accent,
              secondary: secondary,
              active: _active,
              highContrast: highContrast,
              textDirection: direction,
              extent: 58,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuranIndexRule(
                reveal: reveal,
                accent: accent,
                highContrast: highContrast,
              ),
            ),
            const SizedBox(width: 10),
            _QuranEntryActionMark(
              accent: accent,
              active: _active,
              highContrast: highContrast,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuranEventCopy(
          presentation: widget.presentation,
          reveal: reveal,
          ink: ink,
          accent: accent,
          highContrast: highContrast,
          textDirection: direction,
        ),
      ],
    );
  }
}

class _QuranEventCopy extends StatelessWidget {
  const _QuranEventCopy({
    required this.presentation,
    required this.reveal,
    required this.ink,
    required this.accent,
    required this.highContrast,
    required this.textDirection,
  });

  final IslamicEventPresentation presentation;
  final Animation<double> reveal;
  final Color ink;
  final Color accent;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.20, 0.78, curve: Curves.easeOutCubic),
    );
    final shift = Tween<Offset>(
      begin: Offset(textDirection == TextDirection.rtl ? 0.025 : -0.025, 0),
      end: Offset.zero,
    ).animate(entrance);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: ink.withValues(alpha: highContrast ? 1 : 0.96),
          fontWeight: FontWeight.w700,
          height: 1.18,
          letterSpacing: 0.1,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ink.withValues(alpha: highContrast ? 0.90 : 0.72),
          height: 1.38,
        );

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: shift,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(presentation.title, style: titleStyle),
            const SizedBox(height: 5),
            Text(presentation.subtitle, style: subtitleStyle),
            const SizedBox(height: 7),
            FractionallySizedBox(
              widthFactor: 0.34,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                height: 1,
                color: accent.withValues(alpha: highContrast ? 1 : 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranIlluminatedInitial extends StatelessWidget {
  const _QuranIlluminatedInitial({
    required this.eventKey,
    required this.reveal,
    required this.accent,
    required this.secondary,
    required this.active,
    required this.highContrast,
    required this.textDirection,
    required this.extent,
  });

  final String eventKey;
  final Animation<double> reveal;
  final Color accent;
  final Color secondary;
  final bool active;
  final bool highContrast;
  final TextDirection textDirection;
  final double extent;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.018 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : QuranJourneyMotion.interaction,
      curve: Curves.easeOutCubic,
      child: SizedBox.square(
        dimension: extent,
        child: CustomPaint(
          painter: _QuranIlluminatedInitialPainter(
            progress: reveal,
            accent: accent,
            secondary: secondary,
            active: active,
            highContrast: highContrast,
          ),
          child: Padding(
            padding: EdgeInsets.all(extent < 64 ? 9 : 11),
            child: CanonicalEventMotif(
              eventKey: eventKey,
              host: EventVisualHost.quran,
              accent: accent,
              secondary: secondary,
              progress: reveal,
              textDirection: textDirection,
              strokeWidth: highContrast ? 2.05 : 1.45,
              highContrast: highContrast,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranEntryActionMark extends StatelessWidget {
  const _QuranEntryActionMark({
    required this.accent,
    required this.active,
    required this.highContrast,
  });

  final Color accent;
  final bool active;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return QuranJourneyDirectionalShift(
      active: active,
      child: SizedBox(
        width: 30,
        height: 44,
        child: CustomPaint(
          painter: _QuranActionRegistrationPainter(
            accent: accent,
            active: active,
            highContrast: highContrast,
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            textDirection: Directionality.of(context),
            color: accent.withValues(
              alpha: highContrast ? 1 : (active ? 0.96 : 0.78),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranIndexSpine extends StatelessWidget {
  const _QuranIndexSpine({
    required this.reveal,
    required this.accent,
    required this.highContrast,
    required this.height,
  });

  final Animation<double> reveal;
  final Color accent;
  final bool highContrast;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: height,
      child: CustomPaint(
        painter: _QuranSpinePainter(
          progress: reveal,
          accent: accent,
          highContrast: highContrast,
        ),
      ),
    );
  }
}

class _QuranIndexRule extends StatelessWidget {
  const _QuranIndexRule({
    required this.reveal,
    required this.accent,
    required this.highContrast,
  });

  final Animation<double> reveal;
  final Color accent;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: CustomPaint(
        painter: _QuranHorizontalIndexPainter(
          progress: reveal,
          accent: accent,
          highContrast: highContrast,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _QuranIndexShape extends ShapeBorder {
  const _QuranIndexShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const cut = 8.0;
    final rtl = textDirection == TextDirection.rtl;
    if (rtl) {
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right - cut, rect.top)
        ..lineTo(rect.right, rect.top + cut)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left + cut, rect.bottom)
        ..lineTo(rect.left, rect.bottom - cut)
        ..close();
    }
    return Path()
      ..moveTo(rect.left + cut, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom - cut)
      ..lineTo(rect.right - cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + cut)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const _QuranIndexShape();
}

class _QuranIlluminatedIndexPainter extends CustomPainter {
  _QuranIlluminatedIndexPainter({
    required this.progress,
    required this.rule,
    required this.accent,
    required this.ink,
    required this.active,
    required this.highContrast,
    required this.textDirection,
    required this.structuralCount,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color rule;
  final Color accent;
  final Color ink;
  final bool active;
  final bool highContrast;
  final TextDirection textDirection;
  final int structuralCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = progress.value.clamp(0.0, 1.0);
    final rtl = textDirection == TextDirection.rtl;
    final startX = rtl ? size.width : 0.0;
    final endX = rtl ? 0.0 : size.width;
    final rulePaint = Paint()
      ..color = rule.withValues(
        alpha: highContrast ? 1 : (active ? 0.96 : 0.78),
      )
      ..strokeWidth = highContrast ? 1.35 : 0.85
      ..strokeCap = StrokeCap.square;
    final accentPaint = Paint()
      ..color = accent.withValues(
        alpha: highContrast ? 1 : (active ? 0.76 : 0.48),
      )
      ..strokeWidth = highContrast ? 1.2 : 0.75
      ..style = PaintingStyle.stroke;
    final outerProgress = _interval(p, 0, 0.58);
    final innerProgress = _interval(p, 0.12, 0.68);

    double lineEnd(double progressValue) =>
        startX + (endX - startX) * progressValue;
    canvas
      ..drawLine(
        Offset(startX, 0.5),
        Offset(lineEnd(outerProgress), 0.5),
        rulePaint,
      )
      ..drawLine(
        Offset(startX, size.height - 0.5),
        Offset(lineEnd(outerProgress), size.height - 0.5),
        rulePaint,
      )
      ..drawLine(
        Offset(startX, 4),
        Offset(lineEnd(innerProgress), 4),
        accentPaint,
      )
      ..drawLine(
        Offset(startX, size.height - 4),
        Offset(lineEnd(innerProgress), size.height - 4),
        accentPaint,
      );

    final railX = rtl ? size.width - 8 : 8.0;
    final railProgress = _interval(p, 0.08, 0.54);
    final railHalf = (size.height / 2 - 9) * railProgress;
    canvas.drawLine(
      Offset(railX, size.height / 2 - railHalf),
      Offset(railX, size.height / 2 + railHalf),
      accentPaint,
    );

    final markCount = structuralCount.clamp(1, 10);
    final available = (size.width - 54).clamp(1.0, double.infinity).toDouble();
    for (var index = 0; index < markCount; index++) {
      final local = _interval(
        p,
        0.28 + index * 0.025,
        0.54 + index * 0.025,
      );
      if (local <= 0) continue;
      final fraction = markCount == 1 ? 0.5 : index / (markCount - 1);
      final logicalX = 27 + available * fraction;
      final x = rtl ? size.width - logicalX : logicalX;
      final length = (2.5 + (index.isEven ? 2 : 0)) * local;
      canvas.drawLine(
        Offset(x, 4),
        Offset(x, 4 + length),
        accentPaint,
      );
    }

    final registrationProgress = _interval(p, 0.46, 0.86);
    _drawRegistration(
      canvas,
      Offset(rtl ? 8 : size.width - 8, size.height / 2),
      3.5 * registrationProgress,
      accentPaint,
    );

    if (active && p > 0.72) {
      final wash = Paint()
        ..color = ink.withValues(alpha: highContrast ? 0.035 : 0.018)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, wash);
    }
  }

  @override
  bool shouldRepaint(covariant _QuranIlluminatedIndexPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rule != rule ||
      oldDelegate.accent != accent ||
      oldDelegate.ink != ink ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.structuralCount != structuralCount;
}

class _QuranIlluminatedInitialPainter extends CustomPainter {
  _QuranIlluminatedInitialPainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.active,
    required this.highContrast,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color secondary;
  final bool active;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = progress.value.clamp(0.0, 1.0);
    final rect = Offset.zero & size;
    final outer = _chamferedPath(rect.deflate(0.75), size.shortestSide * 0.12);
    final inner = _chamferedPath(rect.deflate(4), size.shortestSide * 0.085);
    final fill = Paint()
      ..color = accent.withValues(alpha: active ? 0.12 : 0.07)
      ..style = PaintingStyle.fill;
    final outerPaint = Paint()
      ..color = accent.withValues(
        alpha: highContrast ? 1 : (active ? 0.88 : 0.62),
      )
      ..strokeWidth = highContrast ? 1.55 : 1
      ..style = PaintingStyle.stroke;
    final innerPaint = Paint()
      ..color = secondary.withValues(
        alpha: highContrast ? 0.92 : (active ? 0.68 : 0.42),
      )
      ..strokeWidth = highContrast ? 1.2 : 0.75
      ..style = PaintingStyle.stroke;

    canvas.drawPath(outer, fill);
    _drawAnimatedPath(canvas, outer, _interval(p, 0, 0.52), outerPaint);
    _drawAnimatedPath(canvas, inner, _interval(p, 0.12, 0.66), innerPaint);

    final registrationPaint = Paint()
      ..color = accent.withValues(alpha: highContrast ? 1 : 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.2 : 0.8;
    final registration = _interval(p, 0.36, 0.72);
    if (registration > 0) {
      final center = size.center(Offset.zero);
      final radius = size.shortestSide * 0.075 * registration;
      _drawRegistration(canvas, center, radius, registrationPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuranIlluminatedInitialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast;
}

class _QuranSpinePainter extends CustomPainter {
  _QuranSpinePainter({
    required this.progress,
    required this.accent,
    required this.highContrast,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _interval(progress.value, 0.16, 0.68);
    final paint = Paint()
      ..color = accent.withValues(alpha: highContrast ? 1 : 0.54)
      ..strokeWidth = highContrast ? 1.25 : 0.75;
    final center = size.center(Offset.zero);
    final half = size.height * 0.5 * p;
    canvas
      ..drawLine(
          Offset(2, center.dy - half), Offset(2, center.dy + half), paint)
      ..drawLine(
          Offset(6, center.dy - half), Offset(6, center.dy + half), paint);
    _drawRegistration(canvas, center, 2.2 * p, paint);
  }

  @override
  bool shouldRepaint(covariant _QuranSpinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.highContrast != highContrast;
}

class _QuranHorizontalIndexPainter extends CustomPainter {
  _QuranHorizontalIndexPainter({
    required this.progress,
    required this.accent,
    required this.highContrast,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _interval(progress.value, 0.14, 0.66);
    final rtl = textDirection == TextDirection.rtl;
    final startX = rtl ? size.width : 0.0;
    final endX = rtl ? size.width * (1 - p) : size.width * p;
    final paint = Paint()
      ..color = accent.withValues(alpha: highContrast ? 1 : 0.55)
      ..strokeWidth = highContrast ? 1.2 : 0.75;
    canvas
      ..drawLine(Offset(startX, 6), Offset(endX, 6), paint)
      ..drawLine(Offset(startX, 12), Offset(endX, 12), paint);
  }

  @override
  bool shouldRepaint(covariant _QuranHorizontalIndexPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}

class _QuranActionRegistrationPainter extends CustomPainter {
  const _QuranActionRegistrationPainter({
    required this.accent,
    required this.active,
    required this.highContrast,
  });

  final Color accent;
  final bool active;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(
        alpha: highContrast ? 1 : (active ? 0.78 : 0.46),
      )
      ..strokeWidth = highContrast ? 1.2 : 0.75
      ..style = PaintingStyle.stroke;
    final center = size.center(Offset.zero);
    canvas
      ..drawLine(const Offset(1, 5), const Offset(1, 39), paint)
      ..drawLine(Offset(size.width - 1, 5), Offset(size.width - 1, 39), paint);
    _drawRegistration(canvas, center, active ? 4 : 3, paint);
  }

  @override
  bool shouldRepaint(covariant _QuranActionRegistrationPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast;
}

Path _chamferedPath(Rect rect, double cut) => Path()
  ..moveTo(rect.left + cut, rect.top)
  ..lineTo(rect.right - cut, rect.top)
  ..lineTo(rect.right, rect.top + cut)
  ..lineTo(rect.right, rect.bottom - cut)
  ..lineTo(rect.right - cut, rect.bottom)
  ..lineTo(rect.left + cut, rect.bottom)
  ..lineTo(rect.left, rect.bottom - cut)
  ..lineTo(rect.left, rect.top + cut)
  ..close();

void _drawAnimatedPath(
  Canvas canvas,
  Path path,
  double progress,
  Paint paint,
) {
  if (progress <= 0) return;
  for (final metric in path.computeMetrics()) {
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
      paint,
    );
  }
}

void _drawRegistration(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint,
) {
  if (radius <= 0) return;
  final diamond = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius, center.dy)
    ..close();
  canvas.drawPath(diamond, paint);
}

double _interval(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return (value - start) / (end - start);
}
