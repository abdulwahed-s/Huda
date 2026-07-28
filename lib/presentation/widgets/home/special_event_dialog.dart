import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/special_event/canonical_event_motif.dart';
import 'package:huda/presentation/widgets/home/special_event/ceremonial_event_reveal.dart';
import 'package:huda/presentation/widgets/home/special_event/event_visual_identity.dart';
import 'package:huda/presentation/widgets/home/special_event_card.dart';

final Expando<bool> _openEventDialogs = Expando<bool>('openEventDialogs');

Future<void> showSpecialEventDialog(
  BuildContext context,
  String eventKey,
  bool isDarkMode,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_openEventDialogs[navigator] ?? false) return;
  _openEventDialogs[navigator] = true;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  try {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: isDarkMode ? 0.72 : 0.64),
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 460),
      pageBuilder: (_, __, ___) => SpecialEventDialogPreview(
        eventKey: eventKey,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ClipPath(
            clipper: _CeremonialRouteClipper(curved.value),
            child: child,
          ),
        );
      },
    );
  } finally {
    _openEventDialogs[navigator] = false;
  }
}

class SpecialEventDialogPreview extends StatelessWidget {
  const SpecialEventDialogPreview({
    super.key,
    required this.eventKey,
    this.routeSemantics = true,
  });

  final String eventKey;
  final bool routeSemantics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final palette = EventPalette.forEvent(eventKey, themeIsDark);
    final content = _DialogEventContent.forEvent(eventKey, l10n);
    final identity = EventVisualIdentity.resolve(eventKey);
    final media = MediaQuery.of(context);
    final highContrast = media.highContrast;
    final textScale = media.textScaler.scale(1);
    final direction = Directionality.of(context);

    return SafeArea(
      minimum: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final nearFullScreen = constraints.maxWidth < 370 || textScale > 1.55;
          final width = nearFullScreen
              ? constraints.maxWidth
              : math.min(constraints.maxWidth * 0.92, 600.0);
          final maxHeight = nearFullScreen
              ? constraints.maxHeight
              : constraints.maxHeight * 0.91;
          return Center(
            child: Semantics(
              key: const ValueKey('special-event-dialog'),
              scopesRoute: routeSemantics,
              namesRoute: routeSemantics,
              explicitChildNodes: true,
              label: IslamicEventPresentation.titleFor(l10n, eventKey),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: CeremonialEventReveal(
                      eventKey: eventKey,
                      duration: const Duration(milliseconds: 1320),
                      curve: Curves.easeOutCubic,
                      builder: (context, reveal) => ClipPath(
                        clipper: _DialogFrameClipper(
                          compact: nearFullScreen,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                palette.gradient.first,
                                palette.gradient[1],
                                palette.gradient.last,
                              ],
                              stops: const [0, 0.42, 1],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow,
                                blurRadius: 46,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _CeremonialDialogFramePainter(
                              progress: reveal,
                              accent: palette.accent,
                              border: palette.border,
                              glow: palette.glow,
                              structuralCount: identity.structuralCount,
                              highContrast: highContrast,
                              textDirection: direction,
                            ),
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  key: const ValueKey('event-dialog-scroll'),
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    nearFullScreen ? 20 : 34,
                                    nearFullScreen ? 58 : 52,
                                    nearFullScreen ? 20 : 34,
                                    nearFullScreen ? 24 : 34,
                                  ),
                                  child: _EventDialogBody(
                                    eventKey: eventKey,
                                    palette: palette,
                                    content: content,
                                    reveal: reveal,
                                    textScale: textScale,
                                    highContrast: highContrast,
                                  ),
                                ),
                                PositionedDirectional(
                                  top: nearFullScreen ? 8 : 12,
                                  end: nearFullScreen ? 8 : 12,
                                  child: _DialogCloseButton(
                                    label: l10n.close,
                                    color: palette.text,
                                    accent: palette.accent,
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
          );
        },
      ),
    );
  }
}

class _EventDialogBody extends StatelessWidget {
  const _EventDialogBody({
    required this.eventKey,
    required this.palette,
    required this.content,
    required this.reveal,
    required this.textScale,
    required this.highContrast,
  });

  final String eventKey;
  final EventPalette palette;
  final _DialogEventContent content;
  final Animation<double> reveal;
  final double textScale;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final direction = Directionality.of(context);
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w800,
          height: 1.16,
          letterSpacing: 0.1,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: palette.subtitle,
          height: 1.45,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: textScale > 1.55 ? 112 : 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(textScale > 1.55 ? 112 : 142,
                      textScale > 1.55 ? 112 : 142),
                  painter: _DialogIdentityAperturePainter(
                    progress: reveal,
                    accent: palette.accent,
                    secondary: palette.glow,
                    highContrast: highContrast,
                  ),
                ),
                SizedBox.square(
                  dimension: textScale > 1.55 ? 82 : 106,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: CanonicalEventMotif(
                      eventKey: eventKey,
                      host: EventVisualHost.dialog,
                      accent: palette.accent,
                      secondary: palette.glow,
                      progress: reveal,
                      textDirection: direction,
                      strokeWidth: highContrast ? 2.2 : 1.65,
                      highContrast: highContrast,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: reveal,
            curve: const Interval(0.22, 0.68, curve: Curves.easeOut),
          ),
          child: Column(
            children: [
              Text(
                IslamicEventPresentation.titleFor(l10n, eventKey),
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                IslamicEventPresentation.subtitleFor(l10n, eventKey),
                textAlign: TextAlign.center,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _CeremonialRule(color: palette.accent, progress: reveal),
        const SizedBox(height: 24),
        if (content.arabicText.isNotEmpty)
          Text(
            content.arabicText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 20,
              color: palette.accent,
              fontWeight: FontWeight.w500,
              height: 1.85,
            ),
          ),
        if (!isArabic && content.translation.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            content.translation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.subtitle,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
          ),
        ],
        if (content.source.isNotEmpty) ...[
          const SizedBox(height: 22),
          _EventSourceLine(
            source: content.source,
            color: palette.accent,
            highContrast: highContrast,
          ),
        ],
        const SizedBox(height: 24),
        _CeremonialRule(color: palette.accent, progress: reveal),
        const SizedBox(height: 20),
        if (content.guidance.isNotEmpty)
          CustomPaint(
            painter: _GuidancePanelPainter(
              accent: palette.accent,
              highContrast: highContrast,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 20),
              child: Text(
                content.guidance,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.text.withValues(alpha: 0.9),
                      height: 1.68,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({
    required this.label,
    required this.color,
    required this.accent,
  });

  final String label;
  final Color color;
  final Color accent;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  late final FocusNode _focusNode;

  bool get _focused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'special-event-dialog-close')
      ..addListener(_handleFocus);
  }

  void _handleFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void dismiss() => Navigator.of(context).pop();

    return Semantics(
      key: const ValueKey('special-event-dialog-close'),
      button: true,
      label: widget.label,
      onTap: dismiss,
      child: ExcludeSemantics(
        child: IconButton(
          focusNode: _focusNode,
          tooltip: widget.label,
          onPressed: dismiss,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            foregroundColor: widget.color,
            backgroundColor: widget.accent.withValues(alpha: 0.08),
            side: BorderSide(
              color: widget.accent.withValues(alpha: _focused ? 0.95 : 0.42),
              width: _focused ? 2 : 1,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _CeremonialRule extends StatelessWidget {
  const _CeremonialRule({required this.color, required this.progress});

  final Color color;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 13,
        child: CustomPaint(
          painter: _CeremonialRulePainter(color: color, progress: progress),
        ),
      ),
    );
  }
}

class _EventSourceLine extends StatelessWidget {
  const _EventSourceLine({
    required this.source,
    required this.color,
    required this.highContrast,
  });

  final String source;
  final Color color;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              source,
              textAlign: TextAlign.center,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color.withValues(alpha: highContrast ? 1 : 0.84),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _DialogEventContent {
  const _DialogEventContent({
    required this.arabicText,
    required this.translation,
    required this.source,
    required this.guidance,
  });

  final String arabicText;
  final String translation;
  final String source;
  final String guidance;

  static _DialogEventContent forEvent(String eventKey, AppLocalizations l10n) {
    return switch (eventKey) {
      'ramadan' => _DialogEventContent(
          arabicText: l10n.eventRamadanArabic,
          translation: l10n.eventRamadanTranslation,
          source: l10n.eventRamadanSource,
          guidance: l10n.eventRamadanGuidance,
        ),
      'last_ten_ramadan' => _DialogEventContent(
          arabicText: l10n.eventLastTenRamadanArabic,
          translation: l10n.eventLastTenRamadanTranslation,
          source: l10n.eventLastTenRamadanSource,
          guidance: l10n.eventLastTenRamadanGuidance,
        ),
      'eid_al_fitr' => _DialogEventContent(
          arabicText: l10n.eventEidAlFitrArabic,
          translation: l10n.eventEidAlFitrTranslation,
          source: l10n.eventEidAlFitrSource,
          guidance: l10n.eventEidAlFitrGuidance,
        ),
      'eid_al_adha' => _DialogEventContent(
          arabicText: l10n.eventEidAlAdhaArabic,
          translation: l10n.eventEidAlAdhaTranslation,
          source: l10n.eventEidAlAdhaSource,
          guidance: l10n.eventEidAlAdhaGuidance,
        ),
      'day_of_arafah' => _DialogEventContent(
          arabicText: l10n.eventDayOfArafahArabic,
          translation: l10n.eventDayOfArafahTranslation,
          source: l10n.eventDayOfArafahSource,
          guidance: l10n.eventDayOfArafahGuidance,
        ),
      'first_ten_dhul_hijjah' => _DialogEventContent(
          arabicText: l10n.eventFirstTenDhulHijjahArabic,
          translation: l10n.eventFirstTenDhulHijjahTranslation,
          source: l10n.eventFirstTenDhulHijjahSource,
          guidance: l10n.eventFirstTenDhulHijjahGuidance,
        ),
      'ashura' => _DialogEventContent(
          arabicText: l10n.eventAshuraArabic,
          translation: l10n.eventAshuraTranslation,
          source: l10n.eventAshuraSource,
          guidance: l10n.eventAshuraGuidance,
        ),
      'days_of_tashreeq' => _DialogEventContent(
          arabicText: l10n.eventDaysTashreeqArabic,
          translation: l10n.eventDaysTashreeqTranslation,
          source: l10n.eventDaysTashreeqSource,
          guidance: l10n.eventDaysTashreeqGuidance,
        ),
      'white_days_fasting' => _DialogEventContent(
          arabicText: l10n.eventWhiteDaysFastingArabic,
          translation: l10n.eventWhiteDaysFastingTranslation,
          source: l10n.eventWhiteDaysFastingSource,
          guidance: l10n.eventWhiteDaysFastingGuidance,
        ),
      'monday_thursday_fasting' => _DialogEventContent(
          arabicText: l10n.eventMondayThursdayFastingArabic,
          translation: l10n.eventMondayThursdayFastingTranslation,
          source: l10n.eventMondayThursdayFastingSource,
          guidance: l10n.eventMondayThursdayFastingGuidance,
        ),
      'white_days_monday_thursday_fasting' => _DialogEventContent(
          arabicText: l10n.eventWhiteDaysMondayThursdayFastingArabic,
          translation: l10n.eventWhiteDaysMondayThursdayFastingTranslation,
          source: l10n.eventWhiteDaysMondayThursdayFastingSource,
          guidance: l10n.eventWhiteDaysMondayThursdayFastingGuidance,
        ),
      _ => _DialogEventContent(
          arabicText: '',
          translation: '',
          source: '',
          guidance: l10n.eventSpecialOccasionGuidance,
        ),
    };
  }
}

class _CeremonialRouteClipper extends CustomClipper<Path> {
  const _CeremonialRouteClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final eased = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final halfHeight = size.height * 0.5 * eased;
    final horizontalInset = size.width * 0.5 * (1 - eased);
    return Path()
      ..addRect(
        Rect.fromLTRB(
          horizontalInset,
          size.height * 0.5 - halfHeight,
          size.width - horizontalInset,
          size.height * 0.5 + halfHeight,
        ),
      );
  }

  @override
  bool shouldReclip(covariant _CeremonialRouteClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _DialogFrameClipper extends CustomClipper<Path> {
  const _DialogFrameClipper({required this.compact});

  final bool compact;

  @override
  Path getClip(Size size) => _dialogFramePath(size, compact: compact);

  @override
  bool shouldReclip(covariant _DialogFrameClipper oldClipper) =>
      oldClipper.compact != compact;
}

Path _dialogFramePath(Size size, {required bool compact}) {
  final cut = compact ? 12.0 : 22.0;
  final shoulder = compact ? 34.0 : 54.0;
  final center = size.width / 2;
  return Path()
    ..moveTo(cut, 0)
    ..lineTo(center - shoulder, 0)
    ..lineTo(center - shoulder * 0.72, 7)
    ..lineTo(center + shoulder * 0.72, 7)
    ..lineTo(center + shoulder, 0)
    ..lineTo(size.width - cut, 0)
    ..lineTo(size.width, cut)
    ..lineTo(size.width, size.height - cut)
    ..lineTo(size.width - cut, size.height)
    ..lineTo(cut, size.height)
    ..lineTo(0, size.height - cut)
    ..lineTo(0, cut)
    ..close();
}

class _CeremonialDialogFramePainter extends CustomPainter {
  _CeremonialDialogFramePainter({
    required this.progress,
    required this.accent,
    required this.border,
    required this.glow,
    required this.structuralCount,
    required this.highContrast,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color border;
  final Color glow;
  final int structuralCount;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final value = progress.value.clamp(0.0, 1.0);
    final frame = _dialogFramePath(size, compact: size.width < 370);
    final metrics = frame.computeMetrics();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = highContrast ? 2 : 1.15
      ..color = Color.lerp(border, accent, 0.28)!
          .withValues(alpha: highContrast ? 1 : 0.86);
    for (final metric in metrics) {
      canvas.drawPath(metric.extractPath(0, metric.length * value), paint);
    }

    final glowCenter = Offset(
      textDirection == TextDirection.rtl
          ? size.width * 0.75
          : size.width * 0.25,
      size.height * 0.08,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.12), glow.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: size.width * 0.42),
      );
    canvas.drawCircle(glowCenter, size.width * 0.42, glowPaint);

    final count = structuralCount.clamp(2, 10);
    final markProgress = ((value - 0.32) / 0.58).clamp(0.0, 1.0);
    final markPaint = Paint()
      ..color = accent.withValues(alpha: highContrast ? 0.65 : 0.24)
      ..strokeWidth = highContrast ? 1.4 : 0.8;
    for (var index = 0; index < count; index++) {
      final local = (markProgress * count - index).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = size.height * (index + 1) / (count + 1);
      final length = (index.isEven ? 12.0 : 7.0) * local;
      canvas
        ..drawLine(Offset(5, y), Offset(5 + length, y), markPaint)
        ..drawLine(
          Offset(size.width - 5, y),
          Offset(size.width - 5 - length, y),
          markPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CeremonialDialogFramePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.border != border ||
      oldDelegate.glow != glow ||
      oldDelegate.structuralCount != structuralCount ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}

class _DialogIdentityAperturePainter extends CustomPainter {
  _DialogIdentityAperturePainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.highContrast,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color secondary;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value.clamp(0.0, 1.0);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.43;
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: 0.16),
          accent.withValues(alpha: 0.055),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, wash);

    final ring = Paint()
      ..color = accent.withValues(alpha: highContrast ? 0.8 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.8 : 1;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.79),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      ring,
    );
    final diamondRadius = radius * 0.94 * value;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - diamondRadius)
      ..lineTo(center.dx + diamondRadius, center.dy)
      ..lineTo(center.dx, center.dy + diamondRadius)
      ..lineTo(center.dx - diamondRadius, center.dy)
      ..close();
    canvas.drawPath(diamond, ring..color = accent.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(covariant _DialogIdentityAperturePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.highContrast != highContrast;
}

class _CeremonialRulePainter extends CustomPainter {
  _CeremonialRulePainter({required this.color, required this.progress})
      : super(repaint: progress);

  final Color color;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value.clamp(0.0, 1.0);
    final center = size.center(Offset.zero);
    final extent = size.width * 0.46 * value;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 0.9;
    canvas
      ..drawLine(Offset(center.dx - extent, center.dy), center, paint)
      ..drawLine(center, Offset(center.dx + extent, center.dy), paint);
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 4 * value)
      ..lineTo(center.dx + 4 * value, center.dy)
      ..lineTo(center.dx, center.dy + 4 * value)
      ..lineTo(center.dx - 4 * value, center.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = color.withValues(alpha: 0.72));
  }

  @override
  bool shouldRepaint(covariant _CeremonialRulePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GuidancePanelPainter extends CustomPainter {
  const _GuidancePanelPainter({
    required this.accent,
    required this.highContrast,
  });

  final Color accent;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 12.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();
    canvas
      ..drawPath(
        path,
        Paint()..color = accent.withValues(alpha: highContrast ? 0.11 : 0.065),
      )
      ..drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: highContrast ? 0.72 : 0.26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = highContrast ? 1.4 : 0.8,
      );
  }

  @override
  bool shouldRepaint(covariant _GuidancePanelPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.highContrast != highContrast;
}
