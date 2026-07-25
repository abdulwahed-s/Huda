import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused || _pressed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final accent = Color.lerp(
      illumination,
      widget.presentation.palette.accent,
      0.34,
    )!;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 2),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Semantics(
            key: const ValueKey('quran-special-event'),
            button: true,
            label: widget.presentation.semanticLabel,
            onTap: widget.onActivate,
            child: ExcludeSemantics(
              child: QuranJourneyPressTransform(
                pressed: _pressed,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('quran-special-event-action'),
                    onTap: widget.onActivate,
                    onHover: (value) => setState(() => _hovered = value),
                    onFocusChange: (value) => setState(() => _focused = value),
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    focusColor: accent.withValues(alpha: 0.10),
                    hoverColor: accent.withValues(alpha: 0.065),
                    splashColor: accent.withValues(alpha: 0.11),
                    highlightColor: accent.withValues(alpha: 0.055),
                    child: Ink(
                      color: accent.withValues(
                        alpha: active
                            ? (isDark ? 0.072 : 0.036)
                            : (isDark ? 0.045 : 0.021),
                      ),
                      child: CustomPaint(
                        painter: _QuranOccasionFolioPainter(
                          rule: QuranJourneyVisualStyle.rule(
                            context,
                            strong: true,
                          ),
                          accent: accent,
                          emphasized: active,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 64),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              12,
                              9,
                              10,
                              9,
                            ),
                            child: Row(
                              children: [
                                _QuranEventSeal(
                                  icon: widget.presentation.icon,
                                  accent: accent,
                                  active: active,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.presentation.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: ink.withValues(
                                                alpha: 0.94,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              height: 1.15,
                                              letterSpacing: 0.15,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.presentation.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ink.withValues(
                                                alpha: isDark ? 0.70 : 0.66,
                                              ),
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                QuranJourneyDirectionalShift(
                                  active: active,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: accent.withValues(alpha: 0.76),
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
        ),
      ),
    );
  }
}

class _QuranEventSeal extends StatelessWidget {
  const _QuranEventSeal({
    required this.icon,
    required this.accent,
    required this.active,
  });

  final IconData icon;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.025 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : QuranJourneyMotion.interaction,
      curve: Curves.easeOutCubic,
      child: CustomPaint(
        painter: _QuranEventSealPainter(accent: accent, active: active),
        child: SizedBox.square(
          dimension: 42,
          child: Icon(icon, size: 19, color: accent),
        ),
      ),
    );
  }
}

class _QuranEventSealPainter extends CustomPainter {
  const _QuranEventSealPainter({required this.accent, required this.active});

  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    Path diamond(double radius) => Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    final outer = Paint()
      ..color = accent.withValues(alpha: active ? 0.70 : 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final inner = Paint()
      ..color = accent.withValues(alpha: active ? 0.34 : 0.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;
    canvas
      ..drawPath(diamond(19), outer)
      ..drawPath(diamond(15.5), inner)
      ..drawCircle(center, 12, inner);
  }

  @override
  bool shouldRepaint(covariant _QuranEventSealPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.active != active;
}

class _QuranOccasionFolioPainter extends CustomPainter {
  const _QuranOccasionFolioPainter({
    required this.rule,
    required this.accent,
    required this.emphasized,
  });

  final Color rule;
  final Color accent;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = Paint()
      ..color = rule.withValues(alpha: emphasized ? 0.95 : 0.78)
      ..strokeWidth = QuranJourneyVisualStyle.ruleWidth;
    final inner = Paint()
      ..color = accent.withValues(alpha: emphasized ? 0.45 : 0.29)
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;
    final registration = Paint()
      ..color = accent.withValues(alpha: emphasized ? 0.58 : 0.37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;

    canvas
      ..drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), outer)
      ..drawLine(const Offset(6, 4), Offset(size.width - 6, 4), inner)
      ..drawLine(
        Offset(6, size.height - 4),
        Offset(size.width - 6, size.height - 4),
        inner,
      )
      ..drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        outer,
      );

    void mark(double x) {
      final center = Offset(x, size.height / 2);
      final diamond = Path()
        ..moveTo(center.dx, center.dy - 3)
        ..lineTo(center.dx + 3, center.dy)
        ..lineTo(center.dx, center.dy + 3)
        ..lineTo(center.dx - 3, center.dy)
        ..close();
      canvas
        ..drawLine(Offset(x, 4), Offset(x, 11), registration)
        ..drawLine(
          Offset(x, size.height - 11),
          Offset(x, size.height - 4),
          registration,
        )
        ..drawPath(diamond, registration);
    }

    mark(7);
    mark(size.width - 7);
  }

  @override
  bool shouldRepaint(covariant _QuranOccasionFolioPainter oldDelegate) =>
      oldDelegate.rule != rule ||
      oldDelegate.accent != accent ||
      oldDelegate.emphasized != emphasized;
}
