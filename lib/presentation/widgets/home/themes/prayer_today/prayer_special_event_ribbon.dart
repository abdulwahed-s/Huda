import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = _hovered || _focused || _pressed;
    final accent = Color.lerp(
      const Color(0xFFF3D58A),
      widget.presentation.palette.accent,
      0.32,
    )!;
    final foreground = Colors.white.withValues(alpha: 0.96);
    final supporting = Colors.white.withValues(alpha: 0.72);
    final duration =
        reduceMotion ? Duration.zero : PrayerTodayMotion.interaction;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 3, 20, 7),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Semantics(
            key: const ValueKey('prayer-special-event'),
            button: true,
            label: widget.presentation.semanticLabel,
            onTap: widget.onActivate,
            child: ExcludeSemantics(
              child: AnimatedScale(
                scale: _pressed ? 0.992 : 1,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('prayer-special-event-action'),
                    onTap: widget.onActivate,
                    onHover: (value) => setState(() => _hovered = value),
                    onFocusChange: (value) => setState(() => _focused = value),
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    focusColor: accent.withValues(alpha: 0.13),
                    hoverColor: accent.withValues(alpha: 0.08),
                    splashColor: accent.withValues(alpha: 0.12),
                    highlightColor: accent.withValues(alpha: 0.07),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: active ? 0.105 : 0.065),
                            Colors.white.withValues(
                              alpha: active ? 0.085 : 0.052,
                            ),
                            accent.withValues(alpha: active ? 0.08 : 0.045),
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _PrayerOccasionRibbonPainter(
                          accent: accent,
                          emphasized: active,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 62),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              11,
                              8,
                              9,
                              8,
                            ),
                            child: Row(
                              children: [
                                _PrayerEventMedallion(
                                  icon: widget.presentation.icon,
                                  accent: accent,
                                  active: active,
                                ),
                                const SizedBox(width: 11),
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
                                              color: foreground,
                                              fontWeight: FontWeight.w700,
                                              height: 1.15,
                                              letterSpacing: 0.1,
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
                                              color: supporting,
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedSlide(
                                  offset: active
                                      ? const Offset(0.08, 0)
                                      : Offset.zero,
                                  duration: duration,
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 17,
                                    color: accent.withValues(alpha: 0.82),
                                    textDirection: Directionality.of(context),
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

class _PrayerEventMedallion extends StatelessWidget {
  const _PrayerEventMedallion({
    required this.icon,
    required this.accent,
    required this.active,
  });

  final IconData icon;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : PrayerTodayMotion.interaction,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: active ? 0.16 : 0.105),
        border: Border.all(
          color: accent.withValues(alpha: active ? 0.72 : 0.48),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: active ? 0.12 : 0.06),
            blurRadius: active ? 12 : 7,
          ),
        ],
      ),
      child: Icon(icon, size: 21, color: accent),
    );
  }
}

class _PrayerOccasionRibbonPainter extends CustomPainter {
  const _PrayerOccasionRibbonPainter({
    required this.accent,
    required this.emphasized,
  });

  final Color accent;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rule = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.06),
          accent.withValues(alpha: emphasized ? 0.58 : 0.39),
          Colors.white.withValues(alpha: emphasized ? 0.25 : 0.17),
          accent.withValues(alpha: emphasized ? 0.58 : 0.39),
          accent.withValues(alpha: 0.06),
        ],
        stops: const [0, 0.18, 0.5, 0.82, 1],
      ).createShader(rect)
      ..strokeWidth = 0.8;
    final fineRule = Paint()
      ..color = accent.withValues(alpha: emphasized ? 0.24 : 0.15)
      ..strokeWidth = 0.55;

    canvas
      ..drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), rule)
      ..drawLine(
        const Offset(8, 3.5),
        Offset(size.width - 8, 3.5),
        fineRule,
      )
      ..drawLine(
        Offset(8, size.height - 3.5),
        Offset(size.width - 8, size.height - 3.5),
        fineRule,
      )
      ..drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        rule,
      );
  }

  @override
  bool shouldRepaint(covariant _PrayerOccasionRibbonPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.emphasized != emphasized;
}
