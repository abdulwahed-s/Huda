import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/focused_theme_layout.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_activities.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_focus.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_header.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_special_event_folio.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_supporting_tools.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';

class QuranJourneyHome extends StatefulWidget {
  const QuranJourneyHome({
    super.key,
    required this.configuration,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.onCustomize,
    required this.onRetry,
    this.data,
  });

  final HomeThemeConfiguration configuration;
  final HomeLoaded? data;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final VoidCallback onCustomize;
  final VoidCallback onRetry;

  @override
  State<QuranJourneyHome> createState() => _QuranJourneyHomeState();
}

class _QuranJourneyHomeState extends State<QuranJourneyHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _entranceStarted = false;
  bool _entranceScheduled = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: QuranJourneyMotion.entrance,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (_reduceMotion) {
      _entranceController
        ..stop()
        ..value = 1;
      _entranceStarted = true;
      return;
    }
    if (!_entranceStarted && _tickerEnabled) _scheduleEntrance();
  }

  void _scheduleEntrance() {
    if (_entranceStarted || _entranceScheduled) return;
    _entranceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceScheduled = false;
      if (!mounted || _entranceStarted) return;
      if (_reduceMotion) {
        _entranceController.value = 1;
        _entranceStarted = true;
        return;
      }
      if (!_tickerEnabled) return;
      _entranceStarted = true;
      _entranceController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle =
        (widget.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
    );
    final data = widget.data;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('quran-home-system-overlay'),
      value: overlayStyle,
      child: data != null
          ? _documentForState(data)
          : BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => _documentForState(state),
            ),
    );
  }

  Widget _documentForState(HomeState state) {
    final stateBody = switch (state) {
      HomeLoaded() => _QuranJourneyLoadedBody(
          key: const ValueKey('quran-journey-loaded'),
          configuration: widget.configuration,
          data: state,
          features: widget.features,
          actions: widget.actions,
          isDark: widget.isDark,
          openLastReadSurah: widget.openLastReadSurah,
          openLastReciterAudio: widget.openLastReciterAudio,
          openLastRadioStation: widget.openLastRadioStation,
          entranceAnimation: _entranceController,
        ),
      HomeError(:final message) => _QuranJourneyError(
          key: const ValueKey('quran-journey-error'),
          message: message,
          onRetry: widget.onRetry,
        ),
      _ => const _QuranJourneyLoading(
          key: ValueKey('quran-journey-loading'),
        ),
    };

    return Column(
      key: const ValueKey('quran-journey-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuranManuscriptScene(
          isDark: widget.isDark,
          entranceAnimation: _entranceController,
          header: QuranJourneyHeaderSection(
            entranceAnimation: _entranceController,
            onCustomize: widget.onCustomize,
          ),
          event: QuranJourneyEntranceReveal(
            key: const ValueKey('quran-special-event-reveal'),
            animation: _entranceController,
            begin: 0.10,
            end: 0.38,
            distance: 4,
            beginScale: 0.997,
            startOpacity: 0.78,
            child: ActiveIslamicEventBuilder(
              isDark: widget.isDark,
              builder: (context, presentation, onActivate) =>
                  QuranSpecialEventFolio(
                presentation: presentation,
                onActivate: onActivate,
              ),
            ),
          ),
          child: _QuranJourneyStateTransition(
            stateKey: ValueKey(state.runtimeType),
            child: stateBody,
          ),
        ),
      ],
    );
  }
}

class _QuranJourneyLoadedBody extends StatelessWidget {
  const _QuranJourneyLoadedBody({
    super.key,
    required this.configuration,
    required this.data,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.entranceAnimation,
  });

  final HomeThemeConfiguration configuration;
  final HomeLoaded data;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranJourneyFocus(
          configuration: configuration,
          data: data,
          actions: actions,
          isDark: isDark,
          openLastReadSurah: openLastReadSurah,
          entranceAnimation: entranceAnimation,
        ),
        QuranJourneyActivities(
          data: data,
          actions: actions,
          isDark: isDark,
          openLastReciterAudio: openLastReciterAudio,
          openLastRadioStation: openLastRadioStation,
          entranceAnimation: entranceAnimation,
        ),
        QuranJourneySupportingTools(
          configuration: configuration,
          features: features,
          isDark: isDark,
          entranceAnimation: entranceAnimation,
        ),
      ],
    );
  }
}

class _QuranJourneyStateTransition extends StatelessWidget {
  const _QuranJourneyStateTransition({
    required this.stateKey,
    required this.child,
  });

  final Key stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyedChild = KeyedSubtree(key: stateKey, child: child);
    if (MediaQuery.disableAnimationsOf(context)) return keyedChild;

    return AnimatedSize(
      duration: QuranJourneyMotion.stateChange,
      curve: QuranJourneyMotion.stateCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: QuranJourneyMotion.stateChange,
        switchInCurve: QuranJourneyMotion.entranceCurve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: keyedChild,
      ),
    );
  }
}

class _QuranJourneyLoading extends StatelessWidget {
  const _QuranJourneyLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuranSkeletonBlock(
            height: 248,
            color: context.primaryColor.withValues(alpha: 0.08),
          ),
          const SizedBox(height: QuranJourneyVisualStyle.regionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 72,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => _QuranSkeletonBlock(
                  height: 72,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.055),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuranSkeletonBlock extends StatelessWidget {
  const _QuranSkeletonBlock({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: QuranJourneyVisualStyle.rule(context),
          width: QuranJourneyVisualStyle.ruleWidth,
        ),
      ),
    );
  }
}

class _QuranJourneyError extends StatelessWidget {
  const _QuranJourneyError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: QuranJourneyFramedRegion(
        doubleFrame: true,
        tint: QuranJourneyVisualStyle.illumination(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: context.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('quran-journey-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranManuscriptScene extends StatelessWidget {
  const _QuranManuscriptScene({
    required this.isDark,
    required this.entranceAnimation,
    required this.header,
    required this.event,
    required this.child,
  });

  final bool isDark;
  final Animation<double> entranceAnimation;
  final Widget header;
  final Widget event;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paper = Color.alphaBlend(
      context.primaryColor.withValues(alpha: isDark ? 0.075 : 0.022),
      scheme.surface,
    );
    final paperEdge = Color.alphaBlend(
      context.accentColor.withValues(alpha: isDark ? 0.07 : 0.025),
      paper,
    );
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final headerBoundary = MediaQuery.paddingOf(context).top +
        QuranJourneyHeaderSection.contentExtent;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height,
      ),
      child: Stack(
        key: const ValueKey('quran-journey-canvas'),
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              key: const ValueKey('quran-manuscript-background'),
              child: CustomPaint(
                painter: _QuranManuscriptAtmospherePainter(
                  paper: paper,
                  paperEdge: paperEdge,
                  ink: context.primaryColor,
                  secondaryInk: context.primaryVariantColor,
                  illumination: illumination,
                  revealAnimation: entranceAnimation,
                  isDark: isDark,
                  headerBoundary: headerBoundary,
                ),
              ),
            ),
          ),
          FocusedThemeContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                event,
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 28),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranManuscriptAtmospherePainter extends CustomPainter {
  const _QuranManuscriptAtmospherePainter({
    required this.paper,
    required this.paperEdge,
    required this.ink,
    required this.secondaryInk,
    required this.illumination,
    required this.revealAnimation,
    required this.isDark,
    required this.headerBoundary,
  }) : super(repaint: revealAnimation);

  final Color paper;
  final Color paperEdge;
  final Color ink;
  final Color secondaryInk;
  final Color illumination;
  final Animation<double> revealAnimation;
  final bool isDark;
  final double headerBoundary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final reveal = revealAnimation.value.clamp(0.0, 1.0);
    final atmosphere = QuranJourneyMotion.phase(
      reveal,
      begin: 0,
      end: 0.34,
    );
    final rules = QuranJourneyMotion.phase(
      reveal,
      begin: 0.04,
      end: 0.50,
    );
    final gutter = QuranJourneyMotion.phase(
      reveal,
      begin: 0.16,
      end: 0.62,
    );
    final seal = QuranJourneyMotion.phase(
      reveal,
      begin: 0.10,
      end: 0.44,
    );
    final pageEdge = QuranJourneyMotion.phase(
      reveal,
      begin: 0.56,
      end: 0.88,
    );

    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    _drawLayeredPaper(canvas, size, atmosphere);
    _drawMarginDepth(canvas, size, atmosphere);
    if (size.width >= 760) {
      _drawOpenPageGutter(canvas, size, gutter);
    }

    final outerRule = Paint()
      ..color = ink.withValues(
        alpha: (isDark ? 0.27 : 0.15) * rules,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.ruleWidth;
    final innerRule = Paint()
      ..color = illumination.withValues(
        alpha: (isDark ? 0.28 : 0.19) * rules,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;

    _drawFrames(canvas, size, outerRule, innerRule, rules);
    _drawIlluminatedCorners(
      canvas,
      size,
      outerRule,
      innerRule,
      headerBoundary,
    );
    _drawRegistrationSeal(canvas, size, seal, headerBoundary);

    final pageOuterRule = Paint()
      ..color = ink.withValues(
        alpha: (isDark ? 0.27 : 0.15) * pageEdge,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.ruleWidth;
    final pageInnerRule = Paint()
      ..color = illumination.withValues(
        alpha: (isDark ? 0.28 : 0.19) * pageEdge,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;
    _drawPageEdge(canvas, size, pageOuterRule, pageInnerRule);
    canvas.restore();
  }

  void _drawLayeredPaper(Canvas canvas, Size size, double atmosphere) {
    final pageRect = Offset.zero & size;
    Color field(Color source, double alpha) => Color.alphaBlend(
          source.withValues(alpha: alpha * atmosphere),
          paper,
        );

    final topField = field(ink, isDark ? 0.13 : 0.052);
    final focusField = field(illumination, isDark ? 0.095 : 0.062);
    final middlePaper = Color.lerp(
      paper,
      paperEdge,
      0.50 * atmosphere,
    )!;
    final lowerField = field(secondaryInk, isDark ? 0.10 : 0.038);
    final indexApproach = field(ink, isDark ? 0.12 : 0.045);

    canvas.drawRect(
      pageRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topField,
            focusField,
            middlePaper,
            lowerField,
            indexApproach,
          ],
          stops: const [0, 0.22, 0.52, 0.78, 1],
        ).createShader(pageRect),
    );

    final warmRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      math.min(size.height * 0.50, 760),
    );
    canvas.drawRect(
      warmRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.72),
          radius: 1.08,
          colors: [
            illumination.withValues(
              alpha: (isDark ? 0.105 : 0.072) * atmosphere,
            ),
            illumination.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(warmRect),
    );

    final readingTop = math.min(size.height * 0.12, 180.0);
    final readingHeight = math.min(size.height * 0.43, 720.0);
    final readingRect = Rect.fromLTWH(
      0,
      readingTop,
      size.width,
      readingHeight,
    );
    canvas.drawRect(
      readingRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.02,
          colors: [
            ink.withValues(
              alpha: (isDark ? 0.048 : 0.025) * atmosphere,
            ),
            ink.withValues(alpha: 0),
          ],
        ).createShader(readingRect),
    );
  }

  void _drawMarginDepth(Canvas canvas, Size size, double atmosphere) {
    final marginRect = Offset.zero & size;
    final edgeOpacity = (isDark ? 0.052 : 0.027) * atmosphere;
    canvas.drawRect(
      marginRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            ink.withValues(alpha: edgeOpacity),
            ink.withValues(alpha: 0),
            ink.withValues(alpha: 0),
            ink.withValues(alpha: edgeOpacity),
          ],
          stops: const [0, 0.13, 0.87, 1],
        ).createShader(marginRect),
    );
  }

  void _drawOpenPageGutter(Canvas canvas, Size size, double atmosphere) {
    final center = size.width / 2;
    final gutter = Rect.fromLTWH(center - 42, 8, 84, size.height - 16);
    canvas.drawRect(
      gutter,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            ink.withValues(
              alpha: (isDark ? 0.025 : 0.012) * atmosphere,
            ),
            illumination.withValues(
              alpha: (isDark ? 0.032 : 0.016) * atmosphere,
            ),
            ink.withValues(
              alpha: (isDark ? 0.025 : 0.012) * atmosphere,
            ),
            Colors.transparent,
          ],
          stops: const [0, 0.32, 0.5, 0.68, 1],
        ).createShader(gutter),
    );

    final gutterRule = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          ink.withValues(
            alpha: (isDark ? 0.09 : 0.045) * atmosphere,
          ),
          illumination.withValues(
            alpha: (isDark ? 0.08 : 0.04) * atmosphere,
          ),
          Colors.transparent,
        ],
        stops: const [0, 0.18, 0.68, 1],
      ).createShader(gutter)
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;
    canvas
      ..drawLine(
        Offset(center - 1.5, 18),
        Offset(center - 1.5, size.height - 22),
        gutterRule,
      )
      ..drawLine(
        Offset(center + 1.5, 18),
        Offset(center + 1.5, size.height - 22),
        gutterRule,
      );
  }

  void _drawFrames(
    Canvas canvas,
    Size size,
    Paint outerRule,
    Paint innerRule,
    double progress,
  ) {
    final resolvedWidth = size.width * progress;
    canvas
      ..save()
      ..clipRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: resolvedWidth,
          height: size.height,
        ),
      )
      ..drawRect(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        outerRule,
      )
      ..drawRect(
        Rect.fromLTWH(7.5, 7.5, size.width - 15, size.height - 15),
        innerRule,
      )
      ..restore();
  }

  void _drawIlluminatedCorners(
    Canvas canvas,
    Size size,
    Paint outerRule,
    Paint innerRule,
    double headerBoundary,
  ) {
    final span = (size.width * 0.22).clamp(72.0, 148.0);
    final baseline = (headerBoundary - 8)
        .clamp(
          52.0,
          math.max(52.0, size.height - 20),
        )
        .toDouble();

    void drawCorner({required bool trailing}) {
      final direction = trailing ? -1.0 : 1.0;
      final origin = trailing ? size.width - 12 : 12.0;
      final outer = Path()
        ..moveTo(origin, baseline - 30)
        ..lineTo(origin, baseline)
        ..lineTo(origin + direction * span, baseline);
      final stepped = Path()
        ..moveTo(origin + direction * 5, baseline - 26)
        ..lineTo(origin + direction * 5, baseline - 7)
        ..lineTo(origin + direction * 34, baseline - 7)
        ..lineTo(origin + direction * 34, baseline - 1)
        ..lineTo(origin + direction * (span - 26), baseline - 1)
        ..lineTo(origin + direction * (span - 26), baseline - 7)
        ..lineTo(origin + direction * (span - 5), baseline - 7);
      canvas
        ..drawPath(outer, outerRule)
        ..drawPath(stepped, innerRule);
    }

    drawCorner(trailing: false);
    drawCorner(trailing: true);
  }

  void _drawRegistrationSeal(
    Canvas canvas,
    Size size,
    double opacity,
    double headerBoundary,
  ) {
    if (opacity <= 0) return;
    final centerY = (headerBoundary - 8)
        .clamp(
          52.0,
          math.max(52.0, size.height - 20),
        )
        .toDouble();
    final center = Offset(size.width / 2, centerY);
    final line = Paint()
      ..color = illumination.withValues(
        alpha: (isDark ? 0.38 : 0.28) * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = QuranJourneyVisualStyle.innerRuleWidth;
    final star = Path();
    for (var index = 0; index < 16; index++) {
      final radius = index.isEven ? 8.0 : 3.8;
      final angle = -math.pi / 2 + index * math.pi / 8;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      index == 0
          ? star.moveTo(point.dx, point.dy)
          : star.lineTo(point.dx, point.dy);
    }
    final scale = 0.88 + 0.12 * opacity;
    final rotation = (1 - opacity) * -0.07;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-center.dx, -center.dy)
      ..drawPath(star..close(), line)
      ..drawCircle(center, 2.2, line)
      ..restore();
  }

  void _drawPageEdge(
    Canvas canvas,
    Size size,
    Paint outerRule,
    Paint innerRule,
  ) {
    canvas
      ..drawLine(
        Offset(13, size.height - 13),
        Offset(size.width - 13, size.height - 13),
        outerRule,
      )
      ..drawLine(
        Offset(17, size.height - 17),
        Offset(size.width - 17, size.height - 17),
        innerRule,
      );
  }

  @override
  bool shouldRepaint(covariant _QuranManuscriptAtmospherePainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.paperEdge != paperEdge ||
      oldDelegate.ink != ink ||
      oldDelegate.secondaryInk != secondaryInk ||
      oldDelegate.illumination != illumination ||
      oldDelegate.revealAnimation != revealAnimation ||
      oldDelegate.isDark != isDark ||
      oldDelegate.headerBoundary != headerBoundary;
}
